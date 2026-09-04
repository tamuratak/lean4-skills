#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    'Usage: build_wasm_sysroot.sh [options]' \
    '' \
    'Options:' \
    '  --lean-source DIR  Lean 4 source tree (or use LEAN_SOURCE_DIR)' \
    '  --out-dir DIR      Output sysroot (default: build/wasm-sysroot)' \
    '  --stdlib MODE      init or init-std (default: init)' \
    '  --jobs N           Parallel standard-library C compilation (default: 4)' \
    '  --help             Show this help'
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

out_dir=${LEAN_WASM_SYSROOT:-build/wasm-sysroot}
lean_source=${LEAN_SOURCE_DIR:-}
stdlib_mode=init
parallel_jobs=${JOBS:-4}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --lean-source)
      [ "$#" -ge 2 ] || die '--lean-source needs a directory'
      lean_source=$2
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
    --jobs)
      [ "$#" -ge 2 ] || die '--jobs needs a positive integer'
      parallel_jobs=$2
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

case "$stdlib_mode" in
  init|init-std) ;;
  *) die '--stdlib must be init or init-std' ;;
esac

case "$parallel_jobs" in
  ''|*[!0-9]*) die '--jobs must be a positive integer' ;;
esac
[ "$parallel_jobs" -gt 0 ] || die '--jobs must be a positive integer'

lean_cmd=${LEAN:-lean}
emcc_cmd=${EMCC:-emcc}
emxx_cmd=${EMXX:-em++}
emar_cmd=${EMAR:-emar}

lean_bin=$(command -v "$lean_cmd" 2>/dev/null || true)
emcc_bin=$(command -v "$emcc_cmd" 2>/dev/null || true)
emxx_bin=$(command -v "$emxx_cmd" 2>/dev/null || true)
emar_bin=$(command -v "$emar_cmd" 2>/dev/null || true)
[ -n "$lean_bin" ] || die "cannot find $lean_cmd"
[ -n "$emcc_bin" ] || die "cannot find $emcc_cmd"
[ -n "$emxx_bin" ] || die "cannot find $emxx_cmd"
[ -n "$emar_bin" ] || die "cannot find $emar_cmd"

# Keep Emscripten's generated cache out of the source tree by default.
export EM_CACHE=${EM_CACHE:-${TMPDIR:-/tmp}/leanscripten-emcache}
# Some macOS Emscripten Node bundles expect a system OpenSSL config file.
export OPENSSL_CONF=${OPENSSL_CONF:-/dev/null}

if [ -z "$lean_source" ]; then
  for candidate in "$PWD" "$PWD/../lean4" "$PWD/lean4"; do
    if [ -d "$candidate/src/runtime" ] && [ -f "$candidate/src/include/lean/lean.h" ]; then
      lean_source=$candidate
      break
    fi
  done
fi
[ -n "$lean_source" ] || die 'set LEAN_SOURCE_DIR to a Lean 4 source tree'
[ -d "$lean_source" ] || die "Lean source directory does not exist: $lean_source"
lean_source=$(cd "$lean_source" && pwd -P)

runtime_source_dir=$lean_source/src/runtime
include_source_dir=$lean_source/src/include
stage0_stdlib_dir=$lean_source/stage0/stdlib
[ -d "$runtime_source_dir" ] || die "missing Lean runtime: $runtime_source_dir"
[ -f "$include_source_dir/lean/lean.h" ] || die "missing Lean headers: $include_source_dir/lean/lean.h"
[ -d "$stage0_stdlib_dir" ] || die "missing generated standard library: $stage0_stdlib_dir"

case "$stdlib_mode" in
  init)
    packages=(Init)
    ;;
  init-std)
    packages=(Init Std)
    ;;
esac

for package in "${packages[@]}"; do
  [ -f "$stage0_stdlib_dir/$package.c" ] || die "missing $stage0_stdlib_dir/$package.c"
  [ -d "$stage0_stdlib_dir/$package" ] || die "missing $stage0_stdlib_dir/$package"
done

mkdir -p "$out_dir"
out_dir=$(cd "$out_dir" && pwd -P)
mkdir -p "$out_dir/include/lean" "$out_dir/lib" "$out_dir/runtime-obj" "$out_dir/stdlib-obj"

lean_prefix=$("$lean_bin" --print-prefix 2>/dev/null | tail -n 1)
version_header=$lean_prefix/include/lean/version.h
[ -f "$version_header" ] || die "cannot find Lean version header: $version_header"

# Use headers from the same Lean source tree as the C++ runtime.
cp -R "$include_source_dir/lean/." "$out_dir/include/lean/"
cp "$version_header" "$out_dir/include/lean/version.h"
printf '%s\n' '#pragma once' '#include <lean/version.h>' '#define LEAN_IS_STAGE0 0' > "$out_dir/include/lean/config.h"

git_hash=unknown
if git_hash=$(git -C "$lean_source" rev-parse HEAD 2>/dev/null); then
  :
fi
printf '%s\n' '#pragma once' "#define LEAN_GITHASH \"$git_hash\"" > "$out_dir/githash.h"

uv_include=${LEAN_WASM_UV_INCLUDE:-}
if [ -n "$uv_include" ]; then
  [ -f "$uv_include/uv.h" ] || die "LEAN_WASM_UV_INCLUDE does not contain uv.h: $uv_include"
fi

if [ -z "$uv_include" ] && [ -n "${EMSDK_NODE:-}" ]; then
  if node_root=$(cd "$(dirname "$EMSDK_NODE")/.." && pwd -P 2>/dev/null); then
    if [ -f "$node_root/include/node/uv.h" ]; then
      uv_include=$node_root/include/node
    fi
  fi
fi

if [ -z "$uv_include" ] && [ -n "${EMSDK:-}" ]; then
  for candidate in "$EMSDK"/node/*/include/node; do
    if [ -f "$candidate/uv.h" ]; then
      uv_include=$candidate
      break
    fi
  done
fi
[ -n "$uv_include" ] || die 'cannot find uv.h; set LEAN_WASM_UV_INCLUDE to an Emscripten Node include directory'
uv_include=$(cd "$uv_include" && pwd -P) || die "cannot resolve uv include directory: $uv_include"

runtime_sources=(
  debug.cpp thread.cpp mpz.cpp utf8.cpp object.cpp apply.cpp exception.cpp
  interrupt.cpp memory.cpp stackinfo.cpp compact.cpp init_module.cpp io.cpp
  hash.cpp byteslice.cpp platform.cpp alloc.cpp allocprof.cpp sharecommon.cpp
  stack_overflow.cpp process.cpp object_ref.cpp mpn.cpp mutex.cpp libuv.cpp
  openssl.cpp
)

printf '%s\n' 'Compiling Lean runtime for Emscripten...'
io_abi_compat=0
for runtime_source in "${runtime_sources[@]}"; do
  source_file=$runtime_source_dir/$runtime_source
  [ -f "$source_file" ] || die "missing runtime source: $source_file"
  printf '  %s\n' "$runtime_source"
  runtime_flags=(-DLEAN_EMSCRIPTEN -DNDEBUG)
  if [ "$runtime_source" = io.cpp ] && grep -q 'lean_io_create_tempfile(lean_object' "$source_file"; then
    runtime_flags+=(
      -Dlean_io_create_tempfile=lean_io_create_tempfile_with_world
      -Dlean_io_create_tempdir=lean_io_create_tempdir_with_world
    )
    io_abi_compat=1
  fi
  "$emxx_bin" -std=c++20 -O2 -pthread -fwasm-exceptions \
    "${runtime_flags[@]}" \
    -I"$out_dir/include" -I"$out_dir" -I"$lean_source/src" -I"$uv_include" \
    -c "$source_file" -o "$out_dir/runtime-obj/${runtime_source%.cpp}.o"
done

# Native runtime/uv/*.cpp is intentionally not included; libuv.cpp supplies the Emscripten stubs.
stub_source=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/uv_strerror_stub.cpp
"$emxx_bin" -std=c++20 -O2 -DLEAN_EMSCRIPTEN -DNDEBUG -pthread -fwasm-exceptions \
  -I"$out_dir/include" -c "$stub_source" -o "$out_dir/runtime-obj/uv_strerror_stub.o"
if [ "$io_abi_compat" -eq 1 ]; then
  io_stub_source=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/io_abi_stub.cpp
  "$emxx_bin" -std=c++20 -O2 -DLEAN_EMSCRIPTEN -DNDEBUG -pthread -fwasm-exceptions \
    -I"$out_dir/include" -c "$io_stub_source" -o "$out_dir/runtime-obj/io_abi_stub.o"
fi

runtime_archive_tmp=$out_dir/lib/libleanrt.a.tmp.$$
"$emar_bin" rcs "$runtime_archive_tmp" "$out_dir"/runtime-obj/*.o
mv -f "$runtime_archive_tmp" "$out_dir/lib/libleanrt.a"

build_package() {
  package=$1
  package_source_dir=$stage0_stdlib_dir/$package
  package_obj_dir=$out_dir/stdlib-obj/$package
  mkdir -p "$package_obj_dir"

  printf '%s\n' "Compiling $package standard library for Emscripten..."
  "$emcc_bin" -O2 -DLEAN_EMSCRIPTEN -pthread -I"$out_dir/include" \
    -c "$stage0_stdlib_dir/$package.c" -o "$package_obj_dir/__root__.o"

  export L4W_STAGE0_ROOT=$stage0_stdlib_dir
  export L4W_OUT_DIR=$out_dir
  export L4W_EMCC=$emcc_bin
  find "$package_source_dir" -type f -name '*.c' -print0 | \
    xargs -0 -n 1 -P "$parallel_jobs" sh -c '
      source_file=$1
      relative=${source_file#"$L4W_STAGE0_ROOT/"}
      object_file="$L4W_OUT_DIR/stdlib-obj/${relative%.c}.o"
      mkdir -p "$(dirname "$object_file")"
      "$L4W_EMCC" -O2 -DLEAN_EMSCRIPTEN -pthread -I"$L4W_OUT_DIR/include" \
        -c "$source_file" -o "$object_file"
    ' sh

  archive_tmp=$out_dir/lib/lib$package.a.tmp.$$
  find "$package_obj_dir" -type f -name '*.o' -print0 | \
    xargs -0 "$emar_bin" rcs "$archive_tmp"
  mv -f "$archive_tmp" "$out_dir/lib/lib$package.a"
}

for package in "${packages[@]}"; do
  build_package "$package"
done

{
  printf 'lean=%s\n' "$("$lean_bin" --version 2>/dev/null | head -n 1)"
  printf 'lean_githash=%s\n' "$("$lean_bin" --githash 2>/dev/null | tail -n 1)"
  printf 'lean_source=%s\n' "$lean_source"
  printf 'stdlib=%s\n' "$stdlib_mode"
  printf 'emcc=%s\n' "$("$emcc_bin" --version 2>&1 | head -n 1)"
  printf 'uv_include=%s\n' "$uv_include"
} > "$out_dir/BUILD_INFO"

printf '%s\n' "Wasm sysroot: $out_dir"
printf '%s\n' "Libraries: $out_dir/lib/libleanrt.a $out_dir/lib/libInit.a"
if [ "$stdlib_mode" = init-std ]; then
  printf '%s\n' "$out_dir/lib/libStd.a"
fi
