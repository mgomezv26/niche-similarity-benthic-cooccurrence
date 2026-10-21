"""Technical tests only: all inputs and outputs are tiny, synthetic and temporary."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from tools.safe_paths import SafetyError, create_run, load_config, preflight


class SafePathsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="niche_safety_")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.repo = self.base / "repo"
        self.repo.mkdir()
        for name in ("inputs", "reference", "originals"):
            (self.base / name).mkdir()
        self.input = self.base / "inputs" / "tiny.csv"
        self.reference = self.base / "reference" / "tiny.txt"
        self.input.write_bytes(b"id,value\nfake,1\n")
        self.reference.write_bytes(b"synthetic reference\n")
        self.data = {
            "schema_version": 1,
            "inputs_root": "../inputs",
            "reference_root": "../reference",
            "results_root": "results/runs",
            "protected_sources": ["../originals"],
            "required_files": [
                {"id": "dummy", "root": "inputs", "path": "tiny.csv",
                 "sha256": hashlib.sha256(self.input.read_bytes()).hexdigest()},
                {"id": "dummy_reference", "root": "reference", "path": "tiny.txt",
                 "sha256": hashlib.sha256(self.reference.read_bytes()).hexdigest()},
            ],
        }
        self.config_file = self.repo / "test.json"

    def config(self):
        self.config_file.write_text(json.dumps(self.data), encoding="utf-8")
        return load_config("test.json", repo_root=self.repo)

    def test_relative_roots_do_not_depend_on_working_directory(self):
        config = self.config()
        self.assertEqual(config.inputs, self.input.parent)
        self.assertEqual(preflight(config)["dummy"], self.input)
        self.assertFalse(config.results.exists())

    def test_environment_and_external_output_root(self):
        self.data["inputs_root"] = "${NICHE_TEST_INPUT}"
        self.data["results_root"] = str(self.base / "external-runs")
        with patch.dict(os.environ, {"NICHE_TEST_INPUT": str(self.input.parent)}):
            run = create_run(self.config())
        self.assertEqual(run.path.parent, self.base / "external-runs")

    def test_missing_environment_variable(self):
        self.data["inputs_root"] = "${NICHE_TEST_MISSING}"
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(SafetyError):
                self.config()

    def test_missing_input_creates_no_run(self):
        config = self.config()
        self.input.unlink()
        with self.assertRaises(SafetyError):
            create_run(config)
        self.assertFalse(config.results.exists())

    def test_missing_reference(self):
        config = self.config()
        self.reference.unlink()
        with self.assertRaises(SafetyError):
            create_run(config)
        self.assertFalse(config.results.exists())

    def test_changed_input_after_successful_preflight(self):
        config = self.config()
        preflight(config)
        self.input.write_bytes(b"changed synthetic data")
        with self.assertRaises(SafetyError):
            create_run(config)
        self.assertFalse(config.results.exists())

    def test_overlap_both_directions_and_protected_sources(self):
        for target in ("../inputs", "../inputs/nested", "..", "../reference",
                       "../reference/nested", "../originals", "../originals/nested"):
            with self.subTest(target=target):
                self.data["results_root"] = target
                with self.assertRaises(SafetyError):
                    self.config()

    def test_repository_output_restricted_to_runs(self):
        for target in (".", "scripts/new", "docs", ".git", "results"):
            with self.subTest(target=target):
                self.data["results_root"] = target
                with self.assertRaises(SafetyError):
                    self.config()

    def test_input_and_reference_overlap(self):
        self.data["reference_root"] = "../inputs"
        with self.assertRaises(SafetyError):
            self.config()

    def test_unique_runs_and_no_personal_paths_in_metadata(self):
        config = self.config()
        a, b = create_run(config), create_run(config)
        self.assertNotEqual(a.path, b.path)
        text = (a.path / "run.json").read_text()
        self.assertNotIn(str(self.base), text)
        self.assertIn("directory_reserved_no_scientific_execution", text)
        self.assertEqual(self.input.read_bytes(), b"id,value\nfake,1\n")
        self.assertEqual(self.reference.read_bytes(), b"synthetic reference\n")

    def test_existing_run_is_rejected_even_if_empty(self):
        config = self.config()
        (config.results / "existing").mkdir(parents=True)
        with self.assertRaises(FileExistsError):
            create_run(config, run_id="existing")

    def test_existing_output_and_metadata_cannot_be_overwritten(self):
        run = create_run(self.config())
        result = run.write_bytes("nested/result.txt", b"first")
        with self.assertRaises(FileExistsError):
            run.write_bytes("nested/result.txt", b"second")
        with self.assertRaises(FileExistsError):
            run.write_bytes("run.json", b"replacement")
        self.assertEqual(result.read_bytes(), b"first")

    def test_traversal_absolute_and_windows_special_paths(self):
        run = create_run(self.config())
        for target in ("../escape", "/absolute", "C:/absolute", "C:relative",
                       "dir/../escape", "dir\\escape", "a//b", "NUL.txt",
                       "a/CON", "file:stream", "trailing.", ""):
            with self.subTest(target=target):
                with self.assertRaises(SafetyError):
                    run.write_bytes(target, b"data")
        for run_id in ("../escape", "/absolute", "CON", "a/b"):
            with self.subTest(run_id=run_id):
                with self.assertRaises(SafetyError):
                    create_run(run.config, run_id=run_id)

    def test_input_traversal_rejected(self):
        self.data["required_files"][0]["path"] = "../originals/file"
        with self.assertRaises(SafetyError):
            self.config()

    def test_ambiguous_configured_output_roots_rejected(self):
        for target in ("../originals.", "../originals ", "../originals:stream",
                       "results/runs/NUL", "results/runs/name?", "C:relative"):
            with self.subTest(target=target):
                self.data["results_root"] = target
                with self.assertRaises(SafetyError):
                    self.config()

    def test_existing_file_cannot_be_results_root(self):
        target = self.repo / "results" / "runs"
        target.parent.mkdir()
        target.write_bytes(b"keep")
        with self.assertRaises(SafetyError):
            self.config()
        self.assertEqual(target.read_bytes(), b"keep")

    def test_results_root_redirected_after_preflight(self):
        config = self.config()
        preflight(config)
        config.results.parent.mkdir(parents=True)
        self.link_directory(config.results, self.base / "originals")
        with self.assertRaises(SafetyError):
            create_run(config)
        self.assertEqual(list((self.base / "originals").iterdir()), [])

    def test_required_hash_and_nonempty_declarations(self):
        self.data["required_files"][0]["sha256"] = "placeholder"
        with self.assertRaises(SafetyError):
            self.config()
        self.data["required_files"] = []
        with self.assertRaises(SafetyError):
            self.config()

    def test_duplicate_ids_and_json_keys(self):
        self.data["required_files"][1]["id"] = "dummy"
        with self.assertRaises(SafetyError):
            self.config()
        self.config_file.write_text('{"schema_version":1,"schema_version":1}')
        with self.assertRaises(SafetyError):
            load_config(self.config_file, repo_root=self.repo)

    def test_hardlinked_existing_output_rejected(self):
        run = create_run(self.config())
        os.link(self.input, run.path / "linked.csv")
        with self.assertRaises(FileExistsError):
            run.write_bytes("linked.csv", b"overwrite")
        self.assertEqual(self.input.read_bytes(), b"id,value\nfake,1\n")

    def link_directory(self, link, target):
        if os.name == "nt":
            # Junction creation needs no Developer Mode; both paths are in our
            # temporary fixture. Cleanup unlinks only the junction, never target.
            command = f'cmd /c mklink /J "{link}" "{target}"'
            completed = subprocess.run(command, capture_output=True)
            if completed.returncode:
                self.skipTest("Temporary junction creation unavailable.")
            self.addCleanup(lambda: os.rmdir(link) if os.path.lexists(link) else None)
        else:
            link.symlink_to(target, target_is_directory=True)
            self.addCleanup(lambda: link.unlink() if link.is_symlink() else None)

    def test_output_link_to_protected_source_rejected(self):
        link = self.base / "linked-output"
        self.link_directory(link, self.base / "originals")
        self.data["results_root"] = str(link / "new")
        with self.assertRaises(SafetyError):
            self.config()
        self.assertFalse((self.base / "originals" / "new").exists())

    def test_nested_output_link_introduced_after_creation(self):
        run = create_run(self.config())
        self.link_directory(run.path / "redirect", self.input.parent)
        with self.assertRaises(SafetyError):
            run.write_bytes("redirect/new.csv", b"blocked")
        self.assertFalse((self.input.parent / "new.csv").exists())

    def test_input_link_escaping_declared_root_rejected(self):
        self.link_directory(self.input.parent / "escape", self.reference.parent)
        self.data["required_files"][0]["path"] = "escape/tiny.txt"
        self.data["required_files"][0]["sha256"] = self.data["required_files"][1]["sha256"]
        with self.assertRaises(SafetyError):
            preflight(self.config())


if __name__ == "__main__":
    unittest.main()
