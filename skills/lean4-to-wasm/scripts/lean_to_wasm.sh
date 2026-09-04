#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    'Usage: lean_to_wasm.sh [options] SOURCE.lean' \
    '' \
    'Options:' \
    '  --sysroot DIR      Emscripten Lean sysroot (required)' \
    '  --out-dir DIR      Output directory (default: build/wasm)' \
    '  --stdlib MODE      init or init-std (default: init)' \
    '  --help             Show this help' \
    '' \
    'Environment:' \
    '  LEAN_ROOT=DIR      Project root when SOURCE is outside the current directory' \
    '  EMCC_BATCH_BUILD=N Override Emscripten batch system-library compilation'
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

sysroot=
out_dir=build/wasm
stdlib_mode=init
source_file=

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sysroot)
      [ "$#" -ge 2 ] || die '--sysroot needs a directory'
      sysroot=$2
      shift 2
      ;;
    --out-dir)
      [ "$#" -ge 2 ] || die '--out-dir needs a directory'
      out_dir=$2
      shift 2
      ;;
    --stdlib)
      [ "$#" -ge 2 ] || die '--stdlib needs init or init-std'
      stdlib_mode=$2
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      [ -z "$source_file" ] || die 'only one Lean source file can be supplied'
      source_file=$1
      shift
      ;;
  esac
done

[ -n "$sysroot" ] || die '--sysroot is required'
[ -n "$source_file" ] || die 'a .lean source file is required'
case "$stdlib_mode" in
  init|init-std) ;;
  *) die '--stdlib must be init or init-std' ;;
esac
[ -f "$source_file" ] || die "Lean source file does not exist: $source_file"
case "$source_file" in
  *.lean) ;;
  *) die "source file must end in .lean: $source_file" ;;
esac

lean_cmd=${LEAN:-lean}
emcc_cmd=${EMCC:-emcc}
emxx_cmd=${EMXX:-em++}
lean_bin=$(command -v "$lean_cmd" 2>/dev/null || true)
emcc_bin=$(command -v "$emcc_cmd" 2>/dev/null || true)
emxx_bin=$(command -v "$emxx_cmd" 2>/dev/null || true)
[ -n "$lean_bin" ] || die "cannot find $lean_cmd"
[ -n "$emcc_bin" ] || die "cannot find $emcc_cmd"
[ -n "$emxx_bin" ] || die "cannot find $emxx_cmd"

# Keep Emscripten's generated cache out of the source tree by default.
export EM_CACHE=${EM_CACHE:-${TMPDIR:-/tmp}/leanscripten-emcache}
# Some macOS Emscripten Node bundles expect a system OpenSSL config file.
export OPENSSL_CONF=${OPENSSL_CONF:-/dev/null}
# Avoid invalid relative source paths in Emscripten's batch system-library builds.
export EMCC_BATCH_BUILD=${EMCC_BATCH_BUILD:-0}

sysroot=$(cd "$sysroot" 2>/dev/null && pwd -P) || die "sysroot does not exist: $sysroot"
[ -f "$sysroot/include/lean/lean.h" ] || die "missing sysroot header: $sysroot/include/lean/lean.h"
[ -f "$sysroot/lib/libleanrt.a" ] || die "missing sysroot runtime: $sysroot/lib/libleanrt.a"
[ -f "$sysroot/lib/libInit.a" ] || die "missing sysroot Init library: $sysroot/lib/libInit.a"
if [ "$stdlib_mode" = init-std ] && [ ! -f "$sysroot/lib/libStd.a" ]; then
  die "missing sysroot Std library: $sysroot/lib/libStd.a"
fi

source_file=$(cd "$(dirname "$source_file")" && pwd -P)/$(basename "$source_file")
project_root=${LEAN_ROOT:-$PWD}
project_root=$(cd "$project_root" 2>/dev/null && pwd -P) || die "project root does not exist: $project_root"
case "$source_file" in
  "$project_root"/*) ;;
  *)
    [ -n "${LEAN_ROOT:-}" ] || die 'source file is outside the current project root; set LEAN_ROOT'
    ;;
esac

mkdir -p "$out_dir"
out_dir=$(cd "$out_dir" && pwd -P)
source_basename=$(basename "$source_file")
module_name=${source_basename%.lean}
c_file=$out_dir/$module_name.c
object_file=$out_dir/$module_name.o
js_file=$out_dir/$module_name.js

printf '%s\n' "Generating C from $source_file..."
"$lean_bin" -R "$project_root" --c="$c_file" \
  -Dcompiler.postponeCompile=false "$source_file"

printf '%s\n' 'Compiling generated C with Emscripten...'
"$emcc_bin" -O2 -DLEAN_EMSCRIPTEN -pthread -I"$sysroot/include" \
  -c "$c_file" -o "$object_file"

libraries=(-lInit)
if [ "$stdlib_mode" = init-std ]; then
  libraries=(-lStd -lInit)
fi

printf '%s\n' 'Linking JavaScript and WebAssembly...'
"$emxx_bin" "$object_file" -L"$sysroot/lib" \
  -Wl,--start-group "${libraries[@]}" -Wl,--end-group -lleanrt \
  -pthread -fwasm-exceptions \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s EXIT_RUNTIME=1 \
  -s ENVIRONMENT=node \
  -s ERROR_ON_UNDEFINED_SYMBOLS=1 \
  -o "$js_file"

printf '%s\n' "C:    $c_file"
printf '%s\n' "JS:   $js_file"
printf '%s\n' "Wasm: ${js_file%.js}.wasm"
printf '%s\n' "Run:  OPENSSL_CONF=$OPENSSL_CONF node $js_file [arguments...]"
