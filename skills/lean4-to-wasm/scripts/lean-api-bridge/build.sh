#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    'Usage: build.sh SOURCE.lean --initializer SYMBOL --function SYMBOL' \
    'Build a caller-supplied module with the parser-oriented Lean API bridge.' \
    'Environment: LEAN, LEAN_ROOT, LEAN_SOURCE_DIR, LEAN_WASM_SYSROOT,' \
    '             LEAN_WASM_BUILD_DIR (default: build/lean-api-bridge), JOBS (default: 1)'
}
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

input_file=
initializer=
process_function=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --initializer|--function)
      [ "$#" -ge 2 ] || die "$1 needs a C symbol"
      if [ "$1" = --initializer ]; then initializer=$2; else process_function=$2; fi
      shift 2 ;;
    --help|-h) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) [ -z "$input_file" ] || die 'only one input file is supported'; input_file=$1; shift ;;
  esac
done
[ -f "$input_file" ] || die 'supply an existing Lean source file'
for symbol in "$initializer" "$process_function"; do
  [[ "$symbol" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die 'initializer and function must be C identifiers'
done
jobs=${JOBS:-1}
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || die 'JOBS must be a positive integer'
[ -n "${LEAN_SOURCE_DIR:-}" ] || die 'set LEAN_SOURCE_DIR'
[ -n "${LEAN_WASM_SYSROOT:-}" ] || die 'set LEAN_WASM_SYSROOT'
lean_cmd=${LEAN:-lean}
for tool in "$lean_cmd" emcc em++ emar node; do
  command -v "$tool" >/dev/null || die "cannot find $tool"
done
export OPENSSL_CONF=${OPENSSL_CONF:-/dev/null}
export EMCC_BATCH_BUILD=${EMCC_BATCH_BUILD:-0}
build_started=$(date +%s)
prefix=$("$lean_cmd" --print-prefix)
version=$("$lean_cmd" --version)
lean_source=$(cd "$LEAN_SOURCE_DIR" && pwd -P)
# Record provenance when available; version/revision differences do not establish ABI incompatibility.
revision=unknown
source_modified=unknown
if command -v git >/dev/null && revision=$(git -C "$lean_source" rev-parse HEAD 2>/dev/null); then
  if git -C "$lean_source" diff --quiet HEAD -- src; then
    source_modified=false
  else
    diff_status=$?
    if [ "$diff_status" -eq 1 ]; then source_modified=true; fi
  fi
else
  revision=unknown
fi
stdlib_root=$prefix/src/lean
[ -f "$stdlib_root/Init.lean" ] || die "installed standard-library source is missing: $stdlib_root/Init.lean"
for directory in runtime util kernel library library/constructions; do
  [ -d "$lean_source/src/$directory" ] || die "Lean source directory is missing: $lean_source/src/$directory"
done
scripts=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
input_file=$(cd "$(dirname "$input_file")" && pwd -P)/$(basename "$input_file")
lean_root=$(cd "${LEAN_ROOT:-$(dirname "$input_file")}" && pwd -P)
sysroot=$(cd "$LEAN_WASM_SYSROOT" && pwd -P)
[ -f "$sysroot/include/lean/lean.h" ] && [ -f "$sysroot/lib/libleanrt.a" ] || die 'sysroot headers or runtime are missing'
out=${LEAN_WASM_BUILD_DIR:-build/lean-api-bridge}
mkdir -p "$out/c" "$out/obj" "$out/support-obj"
out=$(cd "$out" && pwd -P)
scratch=$(mktemp -d "$out/.build-XXXXXX")
pids=()
cleanup() {
  for pid in "${pids[@]+${pids[@]}}"; do kill "$pid" 2>/dev/null || true; done
  for pid in "${pids[@]+${pids[@]}}"; do wait "$pid" 2>/dev/null || true; done
  rm -rf "$scratch"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Bash 3.2 has no wait -n. Drain bounded batches and propagate every worker failure.
wait_jobs() {
  local failed=0 pid
  for pid in "${pids[@]+${pids[@]}}"; do
    if wait "$pid"; then :; else failed=1; fi
  done
  pids=()
  [ "$failed" -eq 0 ] || die 'a build worker failed'
}
queue_job() {
  "$@" &
  pids+=("$!")
  if [ "${#pids[@]}" -ge "$jobs" ]; then wait_jobs; fi
}

# Generated C records direct imports on line three, including "import all".
imports() {
  awk 'NR == 3 {
    while (match($0, /import (all )?[A-Za-z0-9_.]+/)) {
      name = substr($0, RSTART, RLENGTH)
      sub(/^import (all )?/, "", name)
      print name
      $0 = substr($0, RSTART + RLENGTH)
    }
  }' "$1"
}
generate() {
  local name=$1 src target
  src=$stdlib_root/${name//.//}.lean
  target=$out/c/$name.c
  [ -f "$src" ] || die "$name: only installed standard-library imports are supported; add project module build inputs explicitly"
  if [ ! -f "$target" ] || [ "$src" -nt "$target" ]; then
    "$lean_cmd" "--root=$stdlib_root" "--c=$target" "$src"
  fi
}
program=$out/Application.c
"$lean_cmd" "--root=$lean_root" "--c=$program" "$input_file"
{ printf '%s\n' Init; imports "$program"; } > "$scratch/pending"
: > "$scratch/modules"
while [ -s "$scratch/pending" ]; do
  LC_ALL=C sort -u "$scratch/pending" > "$scratch/sorted"
  LC_ALL=C comm -23 "$scratch/sorted" "$scratch/modules" > "$scratch/batch"
  [ -s "$scratch/batch" ] || break
  while IFS= read -r name; do queue_job generate "$name"; done < "$scratch/batch"
  wait_jobs
  : > "$scratch/pending"
  while IFS= read -r name; do imports "$out/c/$name.c" >> "$scratch/pending"; done < "$scratch/batch"
  cat "$scratch/batch" "$scratch/modules" | LC_ALL=C sort -u > "$scratch/updated"
  mv "$scratch/updated" "$scratch/modules"
done
printf 'Lean API bridge build: %s generated standard-library modules\n' "$(wc -l < "$scratch/modules" | tr -d ' ')"
generation_seconds=$(( $(date +%s) - build_started ))
c_flags=(-O2 -DLEAN_EMSCRIPTEN -pthread -Dmain=lean_wasm_cli_main "-I$sysroot/include")
cpp_flags=(-std=c++20 -O2 -DNDEBUG -DLEAN_EMSCRIPTEN -pthread -fwasm-exceptions
  "-I$sysroot/include" "-I$sysroot" "-I$lean_source/src")
compile_c() {
  local src=$out/c/$1.c target=$out/obj/$1.o
  if [ ! -f "$target" ] || [ "$src" -nt "$target" ]; then
    emcc "${c_flags[@]}" -c "$src" -o "$target"
  fi
}
objects=()
while IFS= read -r name; do
  queue_job compile_c "$name"
  objects+=("$out/obj/$name.o")
done < "$scratch/modules"
wait_jobs
rm -f "$out/libModules.a"
emar rcs "$out/libModules.a" "${objects[@]}"

compile_support() {
  local src=$1 target=$2
  local flags=()
  case "${src##*/}" in
    module.cpp)
      flags=(-Dlean_compacted_region_read=lean_compacted_region_read_with_world
        -Dlean_compacted_region_save=lean_compacted_region_save_with_world
        -Dlean_compacted_region_free=lean_compacted_region_free_with_world) ;;
    ir_interpreter.cpp) flags=(-Dlean_run_init=lean_run_init_with_world) ;;
  esac
  if [ ! -f "$target" ] || [ "$src" -nt "$target" ]; then
    em++ "${cpp_flags[@]}" "${flags[@]+${flags[@]}}" -c "$src" -o "$target"
  fi
}
support=()
shopt -s nullglob
for group in util kernel library library/constructions; do
  for src in "$lean_source/src/$group/"*.cpp; do
    case "${src##*/}" in ffi.cpp|shell.cpp) continue ;; esac
    relative=${src#"$lean_source/src/"}
    target=$out/support-obj/${relative//\//.}.o
    queue_job compile_support "$src" "$target"
    support+=("$target")
  done
done
wait_jobs
[ "${#support[@]}" -gt 0 ] || die 'no C++ support sources found'
rm -f "$out/libSupport.a"
emar rcs "$out/libSupport.a" "${support[@]}"
emcc "${c_flags[@]}" "-DLEAN_WASM_INITIALIZER=$initializer" "-DLEAN_WASM_PROCESS=$process_function" \
  -c "$scripts/bridge.c" -o "$out/bridge.o"
emcc "${c_flags[@]}" -c "$program" -o "$out/Application.o"
em++ "${cpp_flags[@]}" -c "$scripts/support-init.cpp" -o "$out/support-init.cpp.o"
for name in abi-compat.c excluded-elaboration.c; do
  emcc "${c_flags[@]}" -c "$scripts/$name" -o "$out/$name.o"
done
em++ "$out/Application.o" "$out/bridge.o" "$out/support-init.cpp.o" \
  "$out/abi-compat.c.o" "$out/excluded-elaboration.c.o" "-L$out" "-L$sysroot/lib" \
  -Wl,--fatal-warnings -Wl,--start-group -lModules -lSupport -lleanrt -Wl,--end-group \
  -O2 -pthread -fwasm-exceptions --no-entry -sSTACK_SIZE=2097152 \
  -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web,worker,node -sMODULARIZE=1 -sEXPORT_ES6=1 \
  '-sEXPORTED_FUNCTIONS=["_lean_wasm_init","_lean_wasm_call","_malloc","_free"]' \
  '-sEXPORTED_RUNTIME_METHODS=["UTF8ToString","stringToUTF8","lengthBytesUTF8","HEAPU8"]' \
  -o "$out/module.mjs"
build_seconds=$(( $(date +%s) - build_started ))
# Node is already required by Emscripten; use it to escape manifest strings safely.
node - "$out" "$version" "$revision" "$sysroot" "$generation_seconds" "$build_seconds" "$scratch/modules" "$source_modified" <<'JS'
const fs = require('node:fs');
const [out, compiler, sourceCommit, sysroot, generationSeconds, buildSeconds, modulesFile, modified] = process.argv.slice(2);
const modules = fs.readFileSync(modulesFile, 'utf8').trim().split('\n');
const sourceModified = modified === 'unknown' ? null : modified === 'true';
fs.writeFileSync(`${out}/manifest.json`, JSON.stringify({compiler, sourceCommit, sourceModified, modules,
  generationSeconds: Number(generationSeconds), buildSeconds: Number(buildSeconds), sysroot}, null, 2));
JS
