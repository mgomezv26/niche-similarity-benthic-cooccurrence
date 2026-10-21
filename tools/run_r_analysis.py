"""Launcher for the global Rmd only; no installation or automatic data selection.

Run from repository root:
 python -B tools/run_r_analysis.py --config config/paths.local.json --format html
Configuration must explicitly declare DP043, DP044, DP049, DP050 as inputs.
A hash match establishes identity, not scientific approval or publication rights.
Rendering containment remains pending an authorised end-to-end render test.
"""
import argparse
from contextlib import contextmanager
import errno
import hashlib
import json
import os
import secrets
from pathlib import Path
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from safe_paths import (SafetyError, Run, load_config, preflight, create_run,
                        _no_links, _relative)

REPO = Path(__file__).resolve().parents[1]
RMD = 'scripts/05_global_analyses/14_Mantel_test_clean.Rmd'
INPUT_IDS = ('DP043', 'DP044', 'DP049', 'DP050')
OUTPUTS = tuple(
    ['global/matrices/' + stem + ext for stem in
     ('schoener_matrix', 'niche_jaccard_matrix', 'niche_distance_matrix', 'cooc_jaccard_matrix')
     for ext in ('.rds', '.csv')]
    + ['global/species_order.csv', 'global/mantel_df_coocurrence.csv']
    + ['global/mantel_residuals_' + metric + '.rds' for metric in ('schoener', 'jaccard', 'centroid')]
    + ['global/residual_summary_' + metric + '.csv' for metric in ('schoener', 'jaccard')]
    + ['global/' + metric + '_residual_' + sign + '.csv'
       for metric in ('Schoener', 'Jaccard') for sign in ('positive', 'negative')]
    + ['global/residual_spectrum_' + metric + '.png' for metric in ('schoener', 'jaccard')]
    + ['figures/' + name + '.png' for name in
       ('plot1_nichesimilarity_DSchoener_co_mentel', 'plot2_nichesimilarity_Jaccard_co_mentel',
        'plot3_nicheproximity_co_mentel', 'Combined_plot_coocurrence_niche', 'residual_spectrum_facet')]
)


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def _lock(stream, *, release=False, shared=False):
    """Process-owned, non-inherited lifetime lock; no heartbeat or PID reuse."""
    if os.name == 'nt':
        import ctypes
        from ctypes import wintypes
        import msvcrt
        class Overlapped(ctypes.Structure):
            _fields_ = [('Internal', ctypes.c_size_t), ('InternalHigh', ctypes.c_size_t),
                        ('Offset', wintypes.DWORD), ('OffsetHigh', wintypes.DWORD),
                        ('hEvent', wintypes.HANDLE)]
        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        handle = wintypes.HANDLE(msvcrt.get_osfhandle(stream.fileno()))
        overlap = Overlapped()
        if release:
            fn = kernel.UnlockFileEx
            fn.argtypes = [wintypes.HANDLE, wintypes.DWORD, wintypes.DWORD,
                           wintypes.DWORD, ctypes.POINTER(Overlapped)]
            ok = fn(handle, 0, 1, 0, ctypes.byref(overlap))
        else:
            fn = kernel.LockFileEx
            fn.argtypes = [wintypes.HANDLE, wintypes.DWORD, wintypes.DWORD,
                           wintypes.DWORD, wintypes.DWORD, ctypes.POINTER(Overlapped)]
            ok = fn(handle, 1 if shared else 3, 0, 1, 0, ctypes.byref(overlap))
        if not ok:
            error = ctypes.get_last_error()
            if error == 33:  # ERROR_LOCK_VIOLATION: conflicting exclusive owner.
                raise BlockingIOError(errno.EAGAIN, 'Execution lock is held.')
            raise ctypes.WinError(error)
    else:
        import fcntl
        mode = fcntl.LOCK_SH if shared else fcntl.LOCK_EX
        fcntl.flock(stream.fileno(), fcntl.LOCK_UN if release else mode | fcntl.LOCK_NB)


@contextmanager
def active_run(run):
    """Activate once. Normal exits revoke; process death releases the OS lock.

    This gates NEW authorisations, not a write already authorised in R. A local
    filesystem with working OS locks is required; this is not an OS sandbox.
    """
    run._check()
    for name in ('state_active.json', 'state_revoked.json', 'state_finished.json'):
        if os.path.lexists(run.path / name):
            raise SafetyError('An execution cannot be activated again.')
    context = json.loads((run.path / 'context.json').read_text())
    lease = run.path / 'lease.lock'
    _no_links(lease)
    with lease.open('x+b') as stream:
        stream.write(b'1')
        stream.flush()
        os.set_inheritable(stream.fileno(), False)
        _lock(stream)
        try:
            info = os.fstat(stream.fileno())
            run.write_bytes('state_active.json', json.dumps({
                'status': 'running', 'authorization_id': context['authorization_id'],
                'lease_identity': [info.st_dev, info.st_ino]}).encode())
            yield
        finally:
            try:
                run.write_bytes('state_revoked.json', b'{"status":"revoked"}\n')
            finally:
                _lock(stream, release=True)


def _require_active(run, context):
    for name in ('state_revoked.json', 'state_finished.json'):
        if os.path.lexists(run.path / name):
            raise SafetyError('Execution is revoked or finished.')
    active = run.path / 'state_active.json'
    lease = run.path / 'lease.lock'
    _no_links(active)
    _no_links(lease)
    try:
        record = json.loads(active.read_text())
        if (record['status'] != 'running' or
                record['authorization_id'] != context['authorization_id']):
            raise SafetyError('Execution state or authorisation identifier is invalid.')
        with lease.open('r+b') as stream:
            info = os.fstat(stream.fileno())
            if [info.st_dev, info.st_ino] != record['lease_identity']:
                raise SafetyError('Execution lifetime lock was replaced.')
            try:
                # Shared probes cannot mistake each other for the exclusive
                # launcher lock when authorisations arrive concurrently.
                _lock(stream, shared=True)
            except OSError as exc:
                if exc.errno not in (errno.EACCES, errno.EAGAIN):
                    raise
                # Expected: the launcher still owns the exclusive lock.
            else:
                _lock(stream, release=True, shared=True)
                raise SafetyError('Launcher is no longer active.')
    except (OSError, ValueError, KeyError) as exc:
        raise SafetyError(f'No valid active execution: {exc}') from exc


def prepare(config_path, *, repo=REPO):
    config_path = Path(config_path)
    if not config_path.is_absolute():
        config_path = repo / config_path
    config_path = config_path.resolve(strict=True)
    config = load_config(config_path, repo_root=repo)
    entries = {f.id: f for f in config.required}
    if any(i not in entries or entries[i].root != 'inputs' for i in INPUT_IDS):
        raise SafetyError('Declare DP043, DP044, DP049 and DP050 explicitly as inputs.')
    inputs = preflight(config)
    # Fail before reserving a directory if the approved source is unavailable.
    source = (repo / RMD).read_bytes()
    run = create_run(config)
    for name in ('global/matrices', 'figures/knitr', 'report', 'intermediates', 'work', 'tmp', 'cache'):
        (run.path / name).mkdir(parents=True, exist_ok=True)
    context = {'repo': str(repo), 'config': str(config_path),
               'authorization_id': secrets.token_hex(32),
               'config_sha256': digest(config_path), 'run': str(run.path),
               'identity': list(run.identity),
               'inputs': {i: str(inputs[i]) for i in INPUT_IDS},
               'outputs': list(OUTPUTS)}
    run.write_bytes('context.json', json.dumps(context, indent=2).encode())
    # R source contains only escaped literals generated by Python, not user code.
    def rq(value):
        return json.dumps(str(value).replace('\\', '/'), ensure_ascii=True)
    r_context = ('safe_context <- list(\n'
                 f'python={rq(sys.executable)}, bridge={rq(REPO / "tools/run_r_analysis.py")},\n'
                 f'context_file={rq(run.path / "context.json")}, run={rq(run.path)},\n'
                 'inputs=c(' + ','.join(f'{i}={rq(inputs[i])}' for i in INPUT_IDS) + '))\n')
    run.write_bytes('context.R', r_context.encode())
    run.write_bytes('report/analysis.Rmd', source)
    run.write_bytes('state_started.json', b'{"status":"prepared_not_executed"}\n')
    return run


def authorize(context_path, destination, *, read=False):
    """Reuse Python guards for every explicit R write; one claim per product."""
    context_path = Path(context_path).resolve(strict=True)
    ctx = json.loads(context_path.read_text())
    if digest(Path(ctx['config'])) != ctx['config_sha256']:
        raise SafetyError('Configuration changed after reservation.')
    config = load_config(ctx['config'], repo_root=ctx['repo'])
    run = Run(config, Path(ctx['run']), tuple(ctx['identity']))
    run._check()
    if context_path != run.path / 'context.json':
        raise SafetyError('Context is outside its reserved run.')
    _require_active(run, ctx)
    destination = Path(destination)
    if not destination.is_absolute():
        raise SafetyError('R must supply an explicit absolute destination.')
    # Use the exact spelling in the allowlist; traversal and aliases are refused.
    allowed = {str(run.path / _relative(name)): name for name in ctx['outputs']}
    if str(destination) not in allowed:
        raise SafetyError('Destination is not in the authorised product list.')
    _no_links(destination)
    if read:
        if not destination.is_file():
            raise SafetyError('Generated intermediate is absent.')
    else:
        if os.path.lexists(destination):
            raise SafetyError('Destination already exists.')
        run.write_bytes('claims/' + allowed[str(destination)] + '.claim', b'reserved\n')
    _require_active(run, ctx)
    return str(destination).replace('\\', '/')


def product_records(run):
    run._check()
    records = []
    for folder, dirs, files in os.walk(run.path, followlinks=False):
        for name in dirs + files:
            _no_links(Path(folder) / name)
        for name in files:
            path = Path(folder) / name
            if path == run.path / 'lease.lock':
                continue  # OS lock byte is not a scientific product or credential.
            records.append({'path': path.relative_to(run.path).as_posix(),
                            'bytes': path.stat().st_size, 'sha256': digest(path)})
    return sorted(records, key=lambda x: x['path'])


def execute(config_path, *, repo=REPO, rscript='Rscript', output_format='html', runner=None):
    """No retries, reuse or recursive cleanup. Partial runs remain for inspection."""
    formats = {'html': 'html_document', 'pdf': 'pdf_document', 'word': 'word_document'}
    if output_format not in formats:
        raise SafetyError('Unsupported report format.')
    run = prepare(config_path, repo=repo)
    env = os.environ.copy()
    env.update({key: str(run.path / 'tmp') for key in ('TMP', 'TEMP', 'TMPDIR')})
    command = [rscript, '--vanilla', str(REPO / 'tools/safe_r_io.R'), '--render',
               str(run.path / 'context.R'), formats[output_format]]
    status, error = 'failed', None
    try:
        # Log handles are exclusive. Never capture a large rendered report in RAM.
        with active_run(run), (run.path / 'stdout.log').open('xb') as out, (run.path / 'stderr.log').open('xb') as err:
            result = (runner or subprocess.run)(command, cwd=run.path / 'work', env=env,
                                                stdout=out, stderr=err, check=False)
        if result.returncode != 0:
            raise SafetyError(f'R exited with code {result.returncode}.')
        missing = [p for p in OUTPUTS if not (run.path / p).is_file()]
        ext = {'html': 'html', 'pdf': 'pdf', 'word': 'docx'}[output_format]
        if missing or not (run.path / 'report' / ('analysis.' + ext)).is_file():
            raise SafetyError('Expected products/report are incomplete.')
        preflight(run.config)  # Check declared originals again, without modifying them.
        status = 'completed'
    except (KeyboardInterrupt, SystemExit) as exc:
        status, error = 'cancelled', f'{type(exc).__name__}: {exc}'
    except Exception as exc:
        error = f'{type(exc).__name__}: {exc}'
    try:
        records = product_records(run)
        run.write_bytes('products.json', json.dumps(records, indent=2).encode())
    except Exception as exc:
        status, error = 'failed', f'Product verification failed: {type(exc).__name__}: {exc}'
    run.write_bytes('state_finished.json', json.dumps(
        {'status': status, 'error': error, 'render_containment': 'pending_end_to_end_validation',
         'products_manifest': 'products.json',
         'note': 'products.json and state_finished.json are not self-hashed; lease.lock is excluded.'}, indent=2).encode())
    return run, status


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config')
    parser.add_argument('--rscript', default='Rscript')
    parser.add_argument('--format', choices=('html', 'pdf', 'word'), default='html')
    parser.add_argument('--authorize', nargs=2, metavar=('CONTEXT', 'DESTINATION'))
    parser.add_argument('--read-generated', action='store_true')
    args = parser.parse_args()
    if args.authorize:
        print(authorize(*args.authorize, read=args.read_generated))
    elif args.config:
        run, status = execute(args.config, rscript=args.rscript, output_format=args.format)
        print(f'{status}: {run.path}')
        return 0 if status == 'completed' else 1
    else:
        parser.error('--config or --authorize is required')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (SafetyError, OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
