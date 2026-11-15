"""Rebuild the pinned local integration checkout from owner commits and reviewed files."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[3])
parser.add_argument('--output', type=Path)
args = parser.parse_args()
repo = args.repo.resolve()
package = Path(__file__).resolve().parent
manifest = json.loads((package / 'manifest.json').read_text(encoding='utf-8'))
output = (args.output or repo / 'exports/team-alignment-20261115').resolve()
if not output.is_relative_to((repo / 'exports').resolve()):
    raise SystemExit('Choose an output directory inside this repository exports directory.')
output.mkdir(parents=True, exist_ok=True)

def git(*arguments):
    return subprocess.check_output(['git', '-C', str(repo), *arguments])

for commit in manifest['commits'].values():
    git('cat-file', '-e', commit + '^{commit}')

archive_path = repo / 'exports/team-alignment-base.zip'
subprocess.run(['git', '-C', str(repo), 'archive', '--format=zip',
                '--output=' + str(archive_path), manifest['commits']['KE3']], check=True)
with zipfile.ZipFile(archive_path) as archive:
    if not all((output / name).resolve().is_relative_to(output) for name in archive.namelist()):
        raise SystemExit('Archive member escapes the output directory.')
    archive.extractall(output)

for owner in ['KE1', 'HPC']:
    for path in manifest['owner_overlays'][owner]:
        target = output / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(git('show', manifest['commits'][owner] + ':' + path))

for path, item in manifest['payload'].items():
    source = package / 'files' / path
    content = source.read_bytes()
    if hashlib.sha256(content).hexdigest() != item['sha256']:
        raise SystemExit('Review payload hash differs for ' + path)
    target = output / path
    if not target.resolve().is_relative_to(output):
        raise SystemExit('Payload member escapes the output directory.')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(content)

(output / 'team-alignment-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print('Assembled owner integration checkout at ' + str(output))
print('Expanded scoring uses the explicit local preview entry point.')
