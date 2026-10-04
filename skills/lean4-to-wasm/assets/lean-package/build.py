"""Build a caller-supplied Lean module with the parser-oriented Lean-package bridge."""
import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import re
import subprocess
import time

arguments = argparse.ArgumentParser(description=__doc__)
arguments.add_argument('input', type=Path, help='Lean source file supplied by the application')
arguments.add_argument('--initializer', required=True, help='Generated C module initializer symbol')
arguments.add_argument('--function', required=True, help='Exported Lean String -> IO String symbol')
args = arguments.parse_args()
for symbol in [args.initializer, args.function]:
    if not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', symbol):
        arguments.error('Initializer and function must be C identifiers')
program_source = args.input.resolve()
if not program_source.is_file():
    arguments.error('Input Lean file does not exist')
started = time.monotonic()
lean = os.environ.get('LEAN', 'lean')
prefix = Path(subprocess.check_output([lean, '--print-prefix'], text=True).strip())
version = subprocess.check_output([lean, '--version'], text=True).strip()
source = Path(os.environ['LEAN_SOURCE_DIR']).resolve()
revision = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
if not re.search(r'version 4\.33\.1,', version) or revision != '23393b959b33e3a8d15796b2397f8a04c315b9f4':
    raise SystemExit('The fixed parser build requires Lean 4.33.1 and Lean source commit 23393b959b33e3a8d15796b2397f8a04c315b9f4; see references/lean-package.md')
if subprocess.run(['git', '-C', str(source), 'diff', '--quiet', 'HEAD', '--', 'src']).returncode != 0:
    raise SystemExit('The parser ABI bridges require an unchanged Lean source tree')
root = prefix / 'src/lean'
out = Path(os.environ.get('LEAN_WASM_BUILD_DIR', 'build/lean-package')).resolve()
sysroot = Path(os.environ['LEAN_WASM_SYSROOT']).resolve()
scripts = Path(__file__).resolve().parent
for directory in ['c', 'obj', 'support-obj']:
    (out / directory).mkdir(parents=True, exist_ok=True)
jobs = int(os.environ.get('JOBS', '1'))

def run(arguments):
    subprocess.run(list(map(str, arguments)), check=True)

def generate(name):
    target = out / 'c' / (name + '.c')
    src = root.joinpath(*name.split('.')).with_suffix('.lean')
    if not src.is_file():
        raise SystemExit(f'{name}: this minimal builder handles installed standard-library imports only; add project module build inputs explicitly')
    if not target.exists() or target.stat().st_mtime < src.stat().st_mtime:
        run([lean, '--root=' + str(root), '--c=' + str(target), src])
    return re.findall(r'import (?:all )?([A-Za-z0-9_.]+)', target.read_text().splitlines()[2])

program = out / 'Application.c'
lean_root = Path(os.environ.get('LEAN_ROOT', str(program_source.parent))).resolve()
run([lean, '--root=' + str(lean_root), '--c=' + str(program), program_source])
pending = {'Init'} | set(re.findall(r'import (?:all )?([A-Za-z0-9_.]+)', program.read_text().splitlines()[2]))
seen = set()
with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
    while pending:
        batch = sorted(pending - seen)
        pending = set()
        seen.update(batch)
        for dependencies in pool.map(generate, batch):
            pending.update(set(dependencies) - seen)
print(f'Lean-package build: {len(seen)} generated standard-library modules', flush=True)
generation_seconds = time.monotonic() - started

c_flags = ['-O2', '-DLEAN_EMSCRIPTEN', '-pthread', '-Dmain=lean_wasm_cli_main', '-I' + str(sysroot / 'include')]
cpp_flags = ['-std=c++20', '-O2', '-DNDEBUG', '-DLEAN_EMSCRIPTEN', '-pthread', '-fwasm-exceptions',
             '-I' + str(sysroot / 'include'), '-I' + str(sysroot), '-I' + str(source / 'src')]

def compile_c(name):
    src = out / 'c' / (name + '.c')
    target = out / 'obj' / (name + '.o')
    if not target.exists() or target.stat().st_mtime < src.stat().st_mtime:
        run(['emcc', *c_flags, '-c', src, '-o', target])
    return target

with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
    objects = list(pool.map(compile_c, sorted(seen)))
library = out / 'libModules.a'
library.unlink(missing_ok=True)
run(['emar', 'rcs', library, *objects])

support_sources = [p for group in ['util', 'kernel', 'library', 'library/constructions']
                   for p in (source / 'src' / group).glob('*.cpp') if p.name not in ['ffi.cpp', 'shell.cpp']]

def compile_support(src):
    target = out / 'support-obj' / (str(src.relative_to(source / 'src')).replace('/', '.') + '.o')
    flags = []
    if src.name == 'module.cpp':
        flags = ['-Dlean_compacted_region_' + name + '=lean_compacted_region_' + name + '_with_world'
                 for name in ['read', 'save', 'free']]
    if src.name == 'ir_interpreter.cpp':
        flags = ['-Dlean_run_init=lean_run_init_with_world']
    if not target.exists() or target.stat().st_mtime < src.stat().st_mtime:
        run(['em++', *cpp_flags, *flags, '-c', src, '-o', target])
    return target

with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
    support = list(pool.map(compile_support, support_sources))
support_library = out / 'libSupport.a'
support_library.unlink(missing_ok=True)
run(['emar', 'rcs', support_library, *support])
bridge = out / 'bridge.o'
run(['emcc', *c_flags, '-DLEAN_WASM_INITIALIZER=' + args.initializer, '-DLEAN_WASM_PROCESS=' + args.function,
     '-c', scripts / 'bridge.c', '-o', bridge])
run(['emcc', *c_flags, '-c', program, '-o', out / 'Application.o'])
extras = []
for name in ['support-init.cpp', 'abi-compat.c', 'excluded-elaboration.c']:
    target = out / (name + '.o')
    run(['em++' if name.endswith('.cpp') else 'emcc', *(cpp_flags if name.endswith('.cpp') else c_flags),
         '-c', scripts / name, '-o', target])
    extras.append(target)
run(['em++', out / 'Application.o', bridge, *extras, '-L' + str(out), '-L' + str(sysroot / 'lib'),
     '-Wl,--fatal-warnings', '-Wl,--start-group', '-lModules', '-lSupport', '-lleanrt', '-Wl,--end-group',
     '-O2', '-pthread', '-fwasm-exceptions', '--no-entry', '-sSTACK_SIZE=2097152',
     '-sALLOW_MEMORY_GROWTH=1', '-sENVIRONMENT=web,worker,node', '-sMODULARIZE=1', '-sEXPORT_ES6=1',
     '-sEXPORTED_FUNCTIONS=["_lean_wasm_init","_lean_wasm_call","_malloc","_free"]',
     '-sEXPORTED_RUNTIME_METHODS=["UTF8ToString","stringToUTF8","lengthBytesUTF8","HEAPU8"]',
     '-o', out / 'module.mjs'])
(out / 'manifest.json').write_text(json.dumps({'compiler': version, 'sourceCommit': revision,
    'modules': sorted(seen), 'generationSeconds': generation_seconds,
    'buildSeconds': time.monotonic() - started, 'sysroot': str(sysroot)}, indent=2))
