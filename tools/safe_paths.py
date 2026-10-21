"""Configuration and guarded output I/O only; never launches scientific scripts.

Python >= 3.10, standard library only.

Use load_config(path, repo_root=...), preflight(config), then create_run(config).
Only Run.write_bytes provides exclusive output creation. Existing scientific
scripts are not integrated. Hash checks do not lock inputs or set permissions;
this helper is not a sandbox against other processes or concurrent path changes.
Declare every required input/reference and every protected source directory.
"""

from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PureWindowsPath
import re
import stat
import uuid


class SafetyError(ValueError):
    """Configuration, integrity or output-safety violation."""


def _inside(path, parent):
    return path == parent or parent in path.parents


def _overlap(a, b):
    return _inside(a, b) or _inside(b, a)


def _relative(value):
    if not isinstance(value, str) or not value or "\\" in value:
        raise SafetyError("File paths must be nonempty relative paths using '/'.")
    parts = value.split("/")
    win = PureWindowsPath(value)
    if Path(value).is_absolute() or win.drive or win.root:
        raise SafetyError("Absolute or drive-relative file path rejected.")
    for part in parts:
        if part in ("", ".", "..") or part.endswith((" ", ".")):
            raise SafetyError("Empty, traversal or ambiguous path component.")
        if re.search(r'[<>:"|?*\x00-\x1f]', part):
            raise SafetyError("Unsafe path component.")
        if part.split(".")[0].upper() in {
            "CON", "PRN", "AUX", "NUL",
            *(f"COM{i}" for i in range(1, 10)),
            *(f"LPT{i}" for i in range(1, 10)),
        }:
            raise SafetyError("Reserved device name.")
    return Path(*parts)


def _configured_path(value, repo):
    if not isinstance(value, str) or not value.strip():
        raise SafetyError("A configured root is empty.")

    def replace(match):
        name = match.group(1)
        val = os.environ.get(name)
        if not val:
            raise SafetyError(f"Environment variable {name} is not set.")
        return val

    expanded = re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}", replace, value)
    if "$" in expanded or "%" in expanded or expanded.startswith("~"):
        raise SafetyError("Use literal paths or ${VARIABLE}; no other expansion.")
    win = PureWindowsPath(expanded)
    if (win.drive or (os.name == "nt" and win.root)) and not win.is_absolute():
        raise SafetyError("Drive-relative or root-relative paths are ambiguous.")
    path = Path(expanded)
    # Validate before normalisation: Windows may alias trailing dots/spaces or
    # interpret colons as alternate data streams. Keep relative '..' roots valid.
    for part in path.parts:
        if part not in (path.anchor, ".", ".."):
            _relative(part)
    if not path.is_absolute():
        path = repo / path
    return Path(os.path.abspath(path))


def _no_links(path):
    """Reject symlinks and Windows reparse points in existing output ancestors."""
    for part in (path, *path.parents):
        if os.path.lexists(part):
            info = part.lstat()
            if stat.S_ISLNK(info.st_mode) or (
                getattr(info, "st_file_attributes", 0) & 0x400
            ):
                raise SafetyError("Output path contains a link or reparse point.")


def _sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _unique_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise SafetyError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


@dataclass(frozen=True)
class RequiredFile:
    id: str
    root: str
    relative: Path
    sha256: str


@dataclass(frozen=True)
class Configuration:
    repo: Path
    inputs: Path
    reference: Path
    results: Path
    protected: tuple
    required: tuple


def load_config(config_path, *, repo_root):
    """Resolve relative paths against an explicit repo root, never the CWD."""
    repo = Path(repo_root).resolve(strict=True)
    if not repo.is_dir():
        raise SafetyError("Repository root is not a directory.")
    config_path = Path(config_path)
    if not config_path.is_absolute():
        config_path = repo / config_path
    with config_path.open(encoding="utf-8-sig") as stream:
        data = json.load(stream, object_pairs_hook=_unique_keys)
    keys = {"schema_version", "inputs_root", "reference_root", "results_root",
            "protected_sources", "required_files"}
    if not isinstance(data, dict) or set(data) != keys or data["schema_version"] != 1:
        raise SafetyError("Unsupported or incomplete configuration schema.")
    roots = {}
    for name in ("inputs", "reference"):
        roots[name] = _configured_path(data[name + "_root"], repo).resolve(strict=True)
        if not roots[name].is_dir():
            raise SafetyError(f"{name} root must be an existing directory.")
    if _overlap(roots["inputs"], roots["reference"]):
        raise SafetyError("Inputs and reference roots must be separate.")
    sources = data["protected_sources"]
    if not isinstance(sources, list) or not sources:
        raise SafetyError("Declare at least one existing protected source directory.")
    protected = []
    for source in sources:
        path = _configured_path(source, repo).resolve(strict=True)
        if not path.is_dir():
            raise SafetyError("Protected source must be an existing directory.")
        protected.append(path)
    results = _configured_path(data["results_root"], repo)
    _no_links(results)
    results = results.resolve()
    required = data["required_files"]
    if not isinstance(required, list) or not required:
        raise SafetyError("Declare the complete nonempty set of required files.")
    files = []
    ids = set()
    for item in required:
        if not isinstance(item, dict) or set(item) != {"id", "root", "path", "sha256"}:
            raise SafetyError("Invalid required-file entry.")
        file_id = item["id"]
        if not isinstance(file_id, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", file_id):
            raise SafetyError("Invalid required-file identifier.")
        if file_id in ids or item["root"] not in roots:
            raise SafetyError("Duplicate identifier or unknown file root.")
        if not isinstance(item["sha256"], str) or not re.fullmatch(
            r"[0-9a-fA-F]{64}", item["sha256"]
        ):
            raise SafetyError("Every required file needs an approved SHA256.")
        ids.add(file_id)
        files.append(RequiredFile(file_id, item["root"], _relative(item["path"]),
                                  item["sha256"].lower()))
    config = Configuration(repo, roots["inputs"], roots["reference"], results,
                           tuple(protected), tuple(files))
    _check_roots(config)
    return config


def _check_roots(config):
    # Refuse root changes, including links introduced after loading configuration.
    for path in (config.repo, config.inputs, config.reference, *config.protected):
        if not path.is_dir() or path.resolve(strict=True) != path:
            raise SafetyError("A source root is absent or has been redirected.")
    _no_links(config.results)
    if os.path.lexists(config.results) and not config.results.is_dir():
        raise SafetyError("Results root is not a directory.")
    for protected in (config.inputs, config.reference, *config.protected):
        if _overlap(config.results, protected):
            raise SafetyError("Results overlap an input, reference or protected source.")
    if _inside(config.repo, config.results):
        raise SafetyError("Results must not be the repository or its ancestor.")
    if _inside(config.results, config.repo):
        if not _inside(config.results, config.repo / "results" / "runs"):
            raise SafetyError("In-repository outputs are restricted to results/runs.")


def preflight(config):
    """Check all declared files and hashes without writing anything."""
    _check_roots(config)
    resolved = {}
    for item in config.required:
        root = getattr(config, item.root)
        try:
            path = (root / item.relative).resolve(strict=True)
        except FileNotFoundError as exc:
            raise SafetyError(f"Missing required file: {item.id}") from exc
        if not _inside(path, root) or not path.is_file():
            raise SafetyError(f"Required file escapes its root or is not a file: {item.id}")
        if _sha256(path) != item.sha256:
            raise SafetyError(f"SHA256 mismatch: {item.id}")
        resolved[item.id] = path
    return resolved


@dataclass(frozen=True)
class Run:
    config: Configuration
    path: Path
    identity: tuple

    def _check(self):
        _check_roots(self.config)
        _no_links(self.path)
        info = self.path.stat()
        if not self.path.is_dir() or (info.st_dev, info.st_ino) != self.identity:
            raise SafetyError("Run directory was replaced.")
        if self.path.parent != self.config.results:
            raise SafetyError("Run directory is outside the configured results root.")

    def write_bytes(self, relative_path, content):
        """Create a new output exclusively; existing files are never overwritten."""
        self._check()
        destination = self.path / _relative(relative_path)
        _no_links(destination)
        destination.parent.mkdir(parents=True, exist_ok=True)
        self._check()
        _no_links(destination)
        # 'xb' also rejects existing hard links, directories and symlinks.
        with destination.open("xb") as stream:
            stream.write(content)
        return destination


def create_run(config, *, run_id=None):
    """Preflight, then atomically reserve a NEW directory. Does not run analyses."""
    preflight(config)
    if run_id is None:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
        run_id = f"{stamp}_{uuid.uuid4().hex}"
    if not isinstance(run_id, str) or not re.fullmatch(
        r"[A-Za-z0-9][A-Za-z0-9_-]{0,119}", run_id
    ):
        raise SafetyError("Invalid run identifier.")
    _relative(run_id)
    _check_roots(config)
    config.results.mkdir(parents=True, exist_ok=True)
    _check_roots(config)
    destination = config.results / run_id
    _no_links(destination)
    destination.mkdir(exist_ok=False)
    info = destination.stat()
    run = Run(config, destination, (info.st_dev, info.st_ino))
    record = {
        "schema_version": 1,
        "run_id": run_id,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "status": "directory_reserved_no_scientific_execution",
        "required_files": [
            {"id": f.id, "root": f.root, "path": f.relative.as_posix(),
             "sha256": f.sha256}
            for f in config.required
        ],
    }
    run.write_bytes("run.json", (json.dumps(record, indent=2) + "\n").encode("utf-8"))
    return run
