"""Portable isolated KE3 preview verification. Python standard library only.

Does not launch or alter the team's main scene. Test commands run copied KE3
sources in output_dir/project using the isolated preview config, not root settings.
"""
from pathlib import Path
import argparse, hashlib, json, re, shutil, subprocess, sys

REPO = Path(__file__).resolve().parents[2]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True, help='Installed Godot 4.7.2 executable')
    parser.add_argument('--output-dir', type=Path, required=True, help='New output folder outside repository')
    parser.add_argument('--mode', choices=['headless', 'windowed', 'all'], default='all')
    parser.add_argument('--prepare-only', action='store_true', help='Create standalone preview project without running checks')
    args = parser.parse_args()
    out = args.output_dir.resolve()
    if out == REPO or REPO in out.parents:
        parser.error('Use an output directory outside the repository')
    if out.exists():
        parser.error('Output directory already exists; choose a new directory to preserve evidence')
    out.mkdir(parents=True)
    project = out / 'project'
    project.mkdir()
    for folder in ['ke3', 'preview', 'tests']:
        destination = project / folder
        if folder == 'tests':
            destination.mkdir()
            for name in ['empty_outline_check.gd', 'mission_fixture_check.gd', 'a03_operations_check.gd', 'a04_visual_check.gd', 'a05_debrief_check.gd', 'a06_retry_check.gd', 'a07_local_qa_check.gd', 'ke2_recorded_debrief_check.gd', 'ke2_validated_debrief_check.gd', 'ke2_reply_edges.gd']:
                shutil.copy2(REPO / folder / name, destination / name)
        else:
            shutil.copytree(REPO / folder, destination, ignore=shutil.ignore_patterns('.godot', '.git', '__pycache__'))
    shutil.copyfile(REPO / 'tools/ke3/preview_project.godot', project / 'project.godot')
    (project / 'verification').mkdir()
    (project / 'verification/.gdignore').write_text('')
    contracts = project / 'contract-examples'
    contracts.mkdir()
    for name in ['evaluation-nonterminal-error.example.json', 'evaluation-top-level-error.example.json']:
        shutil.copyfile(REPO / 'docs/contracts/v1-draft' / name, contracts / name)
    if args.prepare_only:
        print('Standalone preview ready:', project)
        return 0

    records = []
    def run(name, engine_args, expected=None, timeout=50):
        argv = [args.godot, '--path', str(project), *engine_args]
        try:
            completed = subprocess.run(argv, cwd=project, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout)
            output = completed.stdout + completed.stderr
            code = completed.returncode
        except subprocess.TimeoutExpired as exc:
            output = str(exc.stdout) + str(exc.stderr) + '\nWATCHDOG TIMEOUT'
            code = 124
        log = out / (name + '.log')
        log.write_text(output, encoding='utf-8')
        errors = bool(re.search(r'(?m)^ERROR:|SCRIPT ERROR:|Parse Error:|TEST FAILURE:', output))
        passed = code == 0 and not errors and (expected is None or expected in output)
        summary = [line for line in output.splitlines() if re.search(r'checks;|FIXTURE PASS|Engine v|Compatibility|REPLY EDGES', line)]
        records.append({'suite': name, 'argv': argv, 'exit': code, 'passed': passed, 'script_errors': errors, 'summary': summary, 'log': str(log)})
        (out / 'commands.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
        print(name, 'exit', code, 'PASS' if passed else 'FAIL', ' | '.join(summary[-2:]), flush=True)
        return passed

    run('version', ['--version'])
    if not run('import', ['--headless', '--editor', '--quit'], timeout=90):
        return 1
    modes = ['headless', 'windowed'] if args.mode == 'all' else [args.mode]
    suites = [
        ('a01-operations', 'empty_outline_check.gd', ['operations']),
        ('a01-results', 'empty_outline_check.gd', ['results']),
        ('a02', 'mission_fixture_check.gd', []),
        ('a03', 'a03_operations_check.gd', []),
        ('a04', 'a04_visual_check.gd', []),
        ('a04-restart-first', 'a04_visual_check.gd', ['--restart-first']),
        ('a04-restart-second', 'a04_visual_check.gd', ['--restart-second']),
        ('a05', 'a05_debrief_check.gd', []),
        ('a06', 'a06_retry_check.gd', []),
        ('old-recorded', 'ke2_recorded_debrief_check.gd', []),
        ('validated-recorded', 'ke2_validated_debrief_check.gd', []),
    ]
    for mode in modes:
        base = ['--headless'] if mode == 'headless' else ['--audio-driver', 'Dummy', '--resolution', '1280x960']
        for name, script, user_args in suites:
            output = out / (name + '-' + mode)
            output.mkdir()
            user_args = [*user_args, '--output-dir', str(output)] + (['--capture'] if mode == 'windowed' else [])
            run(name + '-' + mode, base + ['--script', 'res://tests/' + script, '--', *user_args], 'FIXTURE PASS')
        output = out / ('reply-edges-' + mode)
        output.mkdir()
        run('reply-edges-' + mode, base + ['--script', 'res://tests/ke2_reply_edges.gd', '--', str(output), str(contracts)] + (['--capture'] if mode == 'windowed' else []), 'FIXTURE PASS')
    if 'windowed' in modes:
        for label, size in [('1280x720', '1280x720'), ('1024x768', '1024x768'), ('900x680', '900x680'), ('repeat-1024x768', '1024x768')]:
            output = out / ('a07-' + label)
            output.mkdir()
            run('a07-' + label, ['--audio-driver', 'Dummy', '--resolution', size, '--script', 'res://tests/a07_local_qa_check.gd', '--', '--size', size, '--capture', '--output-dir', str(output)], 'FIXTURE PASS')
    for scene in ['ke3/operations_control.tscn', 'ke3/operations_screen.tscn', 'ke3/results_control.tscn', 'preview/a06_preview.tscn', 'preview/ke2_validated_preview.tscn']:
        run('scene-' + scene.replace('/', '_'), ['--headless', '--scene', 'res://' + scene, '--quit-after', '5'])
    def normalize(value):
        if isinstance(value, dict): return {key: normalize(item) for key, item in value.items()}
        if isinstance(value, list): return [normalize(item) for item in value]
        return re.sub(r'#\d+>', '#OBJECT_ID>', value) if isinstance(value, str) else value
    repeats = None
    if 'windowed' in modes:
        repeats = normalize(json.loads((out / 'a07-1024x768/results.json').read_text())) == normalize(json.loads((out / 'a07-repeat-1024x768/results.json').read_text()))
    summary = {'scope': 'KE3 isolated preview/component evidence; B02 and official B10 NOT TESTED', 'passed_commands': sum(record['passed'] for record in records), 'failed_commands': sum(not record['passed'] for record in records), 'semantic_repeatability': repeats, 'commands': records}
    (out / 'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    print('KE3 verification:', summary['passed_commands'], 'commands passed;', summary['failed_commands'], 'failed; repeatability=', repeats)
    return 0 if all(record['passed'] for record in records) and repeats is not False else 1

if __name__ == '__main__':
    sys.exit(main())
