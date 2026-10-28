"""Install the pinned official Linux editor and desktop export templates, verifying SHA-512."""
import hashlib
import os
from pathlib import Path
import shutil
import tempfile
import urllib.request
import zipfile

VERSION = '4.6.3'
BASE = f'https://github.com/godotengine/godot/releases/download/{VERSION}-stable/'
ARTIFACTS = {
    f'Godot_v{VERSION}-stable_linux.x86_64.zip': 'a035258da32b77f966a5376f9fa29c30a6adde826a85ba918e1605bd1fc9823eba7d85f1dd5e748956bd2ba72827c0025ffa11bb82aec91128c407a2e723c99c',
    f'Godot_v{VERSION}-stable_export_templates.tpz': 'da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68',
}
TOOLS = Path(__file__).resolve().parents[1] / '.tools'
DATA = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share')))
TEMPLATES = DATA / 'godot/export_templates' / f'{VERSION}.stable'
NAMES = ['windows_release_x86_64.exe', 'windows_debug_x86_64.exe', 'linux_release.x86_64', 'linux_debug.x86_64']

def download(name, digest, target):
    print(f'Downloading and verifying {name}', flush=True)
    with urllib.request.urlopen(BASE + name, timeout=120) as source, target.open('wb') as out:
        shutil.copyfileobj(source, out)
    with target.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha512').hexdigest()
    if actual != digest:
        target.unlink()
        raise RuntimeError(f'Checksum mismatch: {name}')

TOOLS.mkdir(exist_ok=True)
TEMPLATES.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory() as temporary:
    for name, digest in ARTIFACTS.items():
        is_templates = name.endswith('.tpz')
        if is_templates and all((TEMPLATES / n).is_file() for n in NAMES):
            print('Reusing installed export templates')
            continue
        if not is_templates and (TOOLS / 'godot').is_file():
            print('Reusing installed editor')
            continue
        archive = Path(temporary) / name
        download(name, digest, archive)
        with zipfile.ZipFile(archive) as z:
            if is_templates:
                for entry in NAMES:
                    (TEMPLATES / entry).write_bytes(z.read('templates/' + entry))
            else:
                (TOOLS / 'godot').write_bytes(z.read(f'Godot_v{VERSION}-stable_linux.x86_64'))
                (TOOLS / 'godot').chmod(0o755)
print(f'Godot: {TOOLS / "godot"}\nTemplates: {TEMPLATES}')
