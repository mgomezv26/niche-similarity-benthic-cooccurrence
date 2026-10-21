"""Synthetic launcher tests; no Rmd evaluation, rendering or scientific packages."""
import hashlib
import importlib.util
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import run_r_analysis as bridge


class StaticPreservationTests(unittest.TestCase):
    def test_all_54_blocks_preserve_non_io_code(self):
        text = (ROOT / bridge.RMD).read_text(encoding='utf-8')
        chunks = re.findall(r'^```\{r[^\n]*\}\s*\n(.*?)^```\s*$', text, re.M | re.S)
        self.assertEqual(len(chunks), 54)
        self.assertEqual(text.count('permutations = 1000'), 3)
        self.assertNotIn('set.seed', text)
        restored = []
        for i, chunk in enumerate(chunks, 1):
            if i == 3:  # Only the original working-directory configuration block.
                continue
            chunk = chunk.replace('safe_require_context()\n', '')
            for new, old in [('safe_write_csv(', 'write.csv('),
                             ('safe_save_rds(', 'saveRDS('),
                             ('safe_ggsave(', 'ggsave('),
                             ('safe_read_rds(', 'readRDS(')]:
                chunk = chunk.replace(new, old)
            replacements = {
                'DP043': 'paste0(niche_overlap_dir,"/02_Shoener/schoener_D_pairs_round_1_n_100000.csv")',
                'DP044': 'paste0(niche_overlap_dir,"/pairwise_hypervolume_overlap_all_species.csv")',
                'DP049': 'paste0(coocurrence_dir,"/jaccard_distance_matrix.rds")',
                'DP050': 'paste0(coocurrence_dir,"/jaccard_distance_matrix_long_format.csv")',
            }
            for key, old in replacements.items():
                chunk = chunk.replace(f'safe_input("{key}")', old)
            restored.append('\n'.join(line.rstrip() for line in chunk.split('\n')))
        # Derived from the pre-adaptation Rmd SHA256:
        # b766bc3c90c861ac599f48ce8dcb5614361470d49f7970c6f2617ad29bf3d232
        checksum = hashlib.sha256(json.dumps(restored, ensure_ascii=True).encode()).hexdigest()
        self.assertEqual(checksum, '8ceef69e583ebcbe22a54b81f7aeac780d8306380f73473eca0efdb10b088fc5')
        self.assertIsNone(re.search(r'(?<![\w.])(write\.csv|saveRDS|ggsave|setwd)\s*\(', text))

    def test_R_syntax_only_without_evaluation(self):
        executable = shutil.which('Rscript')
        if not executable:
            self.skipTest('Existing Rscript unavailable')
        text = (ROOT / bridge.RMD).read_text(encoding='utf-8')
        chunks = re.findall(r'^```\{r[^\n]*\}\s*\n(.*?)^```\s*$', text, re.M | re.S)
        with tempfile.TemporaryDirectory(prefix='niche syntax ') as tmp:
            path = Path(tmp) / 'chunks.R'
            path.write_text('\n'.join(chunks), encoding='utf-8')
            expression = ('a <- commandArgs(TRUE); '
                          'invisible(parse(file=a[1], encoding="UTF-8")); '
                          'invisible(parse(file=a[2], encoding="UTF-8"))')
            result = subprocess.run([executable, '--vanilla', '-e', expression,
                                     str(path), str(ROOT / 'tools/safe_r_io.R')],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='niche launcher spaces ')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.repo = self.base / 'repository with spaces'
        (self.repo / Path(bridge.RMD).parent).mkdir(parents=True)
        (self.repo / bridge.RMD).write_text('Synthetic placeholder: NEVER evaluated.')
        for name in ('inputs', 'reference', 'originals'):
            (self.base / name).mkdir()
        self.files = []
        for file_id in bridge.INPUT_IDS:
            p = self.base / 'inputs' / (file_id + '.txt')
            p.write_bytes(b'fictional\n')
            self.files.append({'id': file_id, 'root': 'inputs', 'path': p.name,
                               'sha256': hashlib.sha256(p.read_bytes()).hexdigest()})
        self.config = self.repo / 'private config.json'
        self.config.write_text(json.dumps({'schema_version': 1, 'inputs_root': '../inputs',
            'reference_root': '../reference', 'protected_sources': ['../originals'],
            'results_root': 'results/runs', 'required_files': self.files}))

    def prepare(self):
        run = bridge.prepare(self.config, repo=self.repo)
        activation = bridge.active_run(run)
        activation.__enter__()
        self.addCleanup(activation.__exit__, None, None, None)
        return run

    def test_prepared_run_has_no_authority(self):
        run = bridge.prepare(self.config, repo=self.repo)
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[0])

    def test_terminal_states_reject_even_with_live_launcher(self):
        for state in ('completed', 'failed', 'cancelled'):
            with self.subTest(state=state):
                run = self.prepare()
                run.write_bytes('state_finished.json', json.dumps({'status': state}).encode())
                with self.assertRaises(bridge.SafetyError):
                    bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[0])
                self.assertFalse((run.path / 'claims').exists())

    def test_revocation_and_reactivation_rejected(self):
        run = bridge.prepare(self.config, repo=self.repo)
        with bridge.active_run(run):
            bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[0])
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[1])
        with self.assertRaises(bridge.SafetyError):
            with bridge.active_run(run):
                self.fail('Reactivation must be impossible')

    def test_previous_authorization_id_cannot_be_reused(self):
        first, second = self.prepare(), self.prepare()
        old = json.loads((first.path / 'context.json').read_text())
        new_path = second.path / 'context.json'
        new = json.loads(new_path.read_text())
        self.assertNotEqual(first.path.name, second.path.name)
        self.assertNotEqual(old['authorization_id'], new['authorization_id'])
        new['authorization_id'] = old['authorization_id']
        new_path.write_text(json.dumps(new))
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(new_path, second.path / bridge.OUTPUTS[0])

    def test_keyboard_interrupt_revokes_and_records_cancellation(self):
        def interrupted(*args, **kwargs):
            raise KeyboardInterrupt('synthetic cancellation')
        run, state = bridge.execute(self.config, repo=self.repo, runner=interrupted)
        self.assertEqual(state, 'cancelled')
        self.assertEqual(json.loads((run.path / 'state_finished.json').read_text())['status'], 'cancelled')
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[0])

    def test_unexpected_launcher_death_revokes_without_final_state(self):
        run = bridge.prepare(self.config, repo=self.repo)
        code = f'''import sys, json
from pathlib import Path
sys.path.insert(0, {str(ROOT / 'tools')!r})
import run_r_analysis as b
c = json.loads(Path({str(run.path / 'context.json')!r}).read_text())
r = b.Run(b.load_config(c['config'], repo_root=c['repo']), Path(c['run']), tuple(c['identity']))
with b.active_run(r):
    print('ACTIVE', flush=True)
    sys.stdin.read()
'''
        child = subprocess.Popen([sys.executable, '-B', '-c', code],
                                 stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE, text=True)
        try:
            self.assertEqual(child.stdout.readline().strip(), 'ACTIVE')
            bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[0])
            child.kill()  # Only this synthetic launcher process; no R subprocess.
            child.wait(timeout=10)
            self.assertFalse((run.path / 'state_finished.json').exists())
            self.assertFalse((run.path / 'state_revoked.json').exists())
            with self.assertRaises(bridge.SafetyError):
                bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[1])
            # A concurrent shared liveness probe is NOT an active launcher.
            with (run.path / 'lease.lock').open('r+b') as probe:
                bridge._lock(probe, shared=True)
                try:
                    with self.assertRaises(bridge.SafetyError):
                        bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[1])
                finally:
                    bridge._lock(probe, release=True, shared=True)
            with self.assertRaises(bridge.SafetyError):
                with bridge.active_run(run):
                    self.fail('Crashed runs cannot be reactivated')
        finally:
            if child.poll() is None:
                child.kill()
            child.communicate(timeout=10)

    def test_prepare_and_paths_with_spaces(self):
        run = self.prepare()
        self.assertTrue((run.path / 'context.R').is_file())
        dest = run.path / bridge.OUTPUTS[0]
        self.assertEqual(Path(bridge.authorize(run.path / 'context.json', dest)), dest)
        self.assertFalse(dest.exists())

    def test_missing_and_corrupt_inputs_before_reservation(self):
        p = self.base / 'inputs' / 'DP043.txt'
        for corrupt in (True, False):
            if corrupt:
                p.write_bytes(b'corrupt')
            else:
                p.unlink()
            with self.assertRaises(bridge.SafetyError):
                self.prepare()
            self.assertFalse((self.repo / 'results').exists())

    def test_missing_inventory_id(self):
        data = json.loads(self.config.read_text())
        data['required_files'].pop()
        self.config.write_text(json.dumps(data))
        with self.assertRaises(bridge.SafetyError):
            self.prepare()

    def test_overlaps_rejected(self):
        data = json.loads(self.config.read_text())
        for target in ('../inputs', '../reference', '../originals/nested', '..'):
            data['results_root'] = target
            self.config.write_text(json.dumps(data))
            with self.assertRaises(bridge.SafetyError):
                self.prepare()

    def test_unlisted_absolute_traversal_and_relative_destinations(self):
        run = self.prepare()
        for dest in (self.base / 'originals' / 'bad.csv', run.path / 'unknown.csv',
                     run.path / 'global' / '..' / 'bad.csv', Path('relative.csv')):
            with self.assertRaises(bridge.SafetyError):
                bridge.authorize(run.path / 'context.json', dest)

    def test_second_claim_and_existing_product_rejected(self):
        run = self.prepare()
        context = run.path / 'context.json'
        dest = run.path / bridge.OUTPUTS[0]
        bridge.authorize(context, dest)
        with self.assertRaises(FileExistsError):
            bridge.authorize(context, dest)
        dest.write_bytes(b'fictional product')
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(context, dest)
        self.assertEqual(Path(bridge.authorize(context, dest, read=True)), dest)

    def test_configuration_changed_is_rejected(self):
        run = self.prepare()
        self.config.write_text(self.config.read_text() + '\n')
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[0])

    def test_success_with_fake_subprocess_and_product_hashes(self):
        def fake(command, **kwargs):
            root = Path(kwargs['cwd']).parent
            self.assertEqual(kwargs['env']['TMPDIR'], str(root / 'tmp'))
            for name in bridge.OUTPUTS:
                (root / name).write_bytes(b'fake output')
            (root / 'report/analysis.html').write_bytes(b'fake report')
            return SimpleNamespace(returncode=0)
        run, state = bridge.execute(self.config, repo=self.repo, runner=fake)
        self.assertEqual(state, 'completed')
        records = json.loads((run.path / 'products.json').read_text())
        row = next(r for r in records if r['path'] == bridge.OUTPUTS[0])
        self.assertEqual(row['sha256'], hashlib.sha256(b'fake output').hexdigest())
        self.assertEqual(json.loads((run.path / 'state_finished.json').read_text())['status'], 'completed')
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[0])

    def test_failure_partial_files_preserved_and_next_run_is_new(self):
        def failing(command, **kwargs):
            (Path(kwargs['cwd']) / 'partial.txt').write_bytes(b'partial')
            return SimpleNamespace(returncode=7)
        first, state = bridge.execute(self.config, repo=self.repo, runner=failing)
        second, _ = bridge.execute(self.config, repo=self.repo, runner=failing)
        self.assertEqual(state, 'failed')
        self.assertNotEqual(first.path, second.path)
        self.assertEqual((first.path / 'work/partial.txt').read_bytes(), b'partial')
        self.assertTrue((first.path / 'state_finished.json').exists())
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(first.path / 'context.json', first.path / bridge.OUTPUTS[0])

    def test_missing_executable_recorded_as_failure(self):
        def missing(*args, **kwargs):
            raise FileNotFoundError('synthetic missing executable')
        run, state = bridge.execute(self.config, repo=self.repo, runner=missing)
        self.assertEqual(state, 'failed')
        self.assertTrue((run.path / 'products.json').exists())

    def test_zero_exit_without_products_is_failure(self):
        run, state = bridge.execute(self.config, repo=self.repo,
            runner=lambda *a, **k: SimpleNamespace(returncode=0))
        self.assertEqual(state, 'failed')

    def test_link_to_originals_is_rejected(self):
        run = self.prepare()
        link = run.path / 'global/matrices'
        link.rmdir()  # Empty synthetic directory, never a scientific source.
        target = self.base / 'originals'
        if os.name == 'nt':
            result = subprocess.run(f'cmd /c mklink /J "{link}" "{target}"', capture_output=True)
            if result.returncode:
                self.skipTest('Temporary junction unavailable')
            self.addCleanup(lambda: os.rmdir(link) if os.path.lexists(link) else None)
        else:
            link.symlink_to(target, target_is_directory=True)
            self.addCleanup(lambda: link.unlink() if link.is_symlink() else None)
        with self.assertRaises(bridge.SafetyError):
            bridge.authorize(run.path / 'context.json', run.path / bridge.OUTPUTS[0])
        with self.assertRaises(bridge.SafetyError):
            bridge.product_records(run)
        self.assertEqual(list(target.iterdir()), [])

    def test_real_base_R_adapter_with_fictional_csv_and_rds_only(self):
        executable = shutil.which('Rscript')
        if not executable:
            self.skipTest('Existing Rscript unavailable; no installation attempted')
        run = self.prepare()
        quote = lambda p: json.dumps(str(p).replace('\\', '/'))
        code = f'''source({quote(ROOT / 'tools/safe_r_io.R')})
source({quote(run.path / 'context.R')})
safe_context$launched <- TRUE
p <- file.path(safe_context$run, "global/matrices/schoener_matrix.csv")
safe_write_csv(data.frame(fake=1), p, row.names=FALSE)
stopifnot(inherits(try(safe_write_csv(data.frame(fake=2), p), silent=TRUE), "try-error"))
r <- file.path(safe_context$run, "global/matrices/schoener_matrix.rds")
safe_save_rds(list(fake=1), r)
stopifnot(identical(safe_read_rds(r), list(fake=1)))
stopifnot(inherits(try(safe_write_csv(data.frame(fake=1), {quote(self.base / 'originals/no.csv')}), silent=TRUE), "try-error"))
'''
        script = self.base / 'technical test.R'
        script.write_text(code, encoding='utf-8')
        result = subprocess.run([executable, '--vanilla', str(script)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.base / 'originals/no.csv').exists())


if __name__ == '__main__':
    unittest.main()
