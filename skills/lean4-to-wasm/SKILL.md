---
name: lean4-to-wasm
description: Compile Lean 4 source to C with lean, then cross-compile the generated C and a matching Lean runtime and standard library to WebAssembly with Emscripten.
metadata:
  short-description: Lean 4 to C and WebAssembly
---

# Lean 4 to WebAssembly

See [NOTICE.md](NOTICE.md) for attribution and provenance of the helper scripts.

Use this skill when a Lean 4 program must be compiled in two stages:

1. `lean` generates C from the Lean source.
2. Emscripten compiles that C, a target-specific Lean runtime, and the required standard library into a JavaScript loader and WebAssembly module.

The generated C is not standalone. It includes Lean runtime APIs from `lean/lean.h`, so host-side Lean archives must not be passed to Emscripten.

## Requirements

- `lean`, `emcc`, `em++`, `emar`, and Node.js are available on `PATH`.
- `LEAN_SOURCE_DIR` points to a Lean 4 source tree whose runtime and `stage0/stdlib` match the installed `lean` compiler. An installed toolchain's `src/lean` directory alone is not enough because it does not contain the C++ runtime sources.
- The Lean source tree contains `src/runtime`, `src/include/lean`, and generated C files under `stage0/stdlib`.
- Emscripten's Node headers are available. The helper detects them through `EMSDK_NODE` or `EMSDK`; set `LEAN_WASM_UV_INCLUDE` to the directory containing `uv.h` when detection fails.

The helper builds a small Node-oriented sysroot containing `libleanrt.a`, `libInit.a`, and optionally `libStd.a`. Native `runtime/uv/*.cpp` files are not linked; the top-level `libuv.cpp` stubs and the included diagnostic stub provide the Emscripten configuration used here.

## Build the target sysroot

Activate Emscripten first:

~~~sh
source /path/to/emsdk/emsdk_env.sh
lean --version
emcc --version
~~~

In the commands below, `<skill-dir>` means the absolute path to this
`lean4-to-wasm` directory. Paths under `build/` are relative to the directory
from which the command is run.

Build the `Init` runtime and standard library:

~~~sh
LEAN_SOURCE_DIR=/path/to/lean4 \
  <skill-dir>/scripts/build_wasm_sysroot.sh \
  --out-dir build/wasm-sysroot \
  --stdlib init \
  --jobs 4
~~~

If the program imports `Std`, build both packages:

~~~sh
LEAN_SOURCE_DIR=/path/to/lean4 \
  <skill-dir>/scripts/build_wasm_sysroot.sh \
  --out-dir build/wasm-sysroot \
  --stdlib init-std \
  --jobs 4
~~~

If `uv.h` cannot be found, provide the Emscripten Node include directory explicitly:

~~~sh
LEAN_SOURCE_DIR=/path/to/lean4 \
LEAN_WASM_UV_INCLUDE=/path/to/emsdk/node/<version>/include/node \
  <skill-dir>/scripts/build_wasm_sysroot.sh --out-dir build/wasm-sysroot
~~~

`stage0/stdlib` is generated C checked into the Lean source tree. If those files are absent, build or obtain a complete Lean source tree before running the helper.

## Compile an application

Use the application helper:

~~~sh
LEAN_ROOT=<skill-dir> \
  <skill-dir>/scripts/lean_to_wasm.sh \
  --sysroot build/wasm-sysroot \
  --stdlib init \
  --out-dir build/example \
  <skill-dir>/example/Main.lean

OPENSSL_CONF=/dev/null node build/example/Main.js hello world
~~~

The helper creates `Main.c`, `Main.js`, `Main.wasm`, and an intermediate object file in the output directory. The JavaScript file is the Emscripten loader; keep the `.wasm` file beside it.

Use `--stdlib init-std` for a source file that imports `Std`:

~~~sh
<skill-dir>/scripts/lean_to_wasm.sh \
  --sysroot build/wasm-sysroot \
  --stdlib init-std \
  --out-dir build/example \
  <input>.lean
~~~

The helper targets Node.js. Browser builds need different Emscripten settings, especially the `ENVIRONMENT` setting and the JavaScript module interface.

## Equivalent direct CLI steps

The first stage is:

~~~sh
lean -R <skill-dir> \
  --c=build/Main.c \
  -Dcompiler.postponeCompile=false \
  <skill-dir>/example/Main.lean
~~~

Compile the generated C:

~~~sh
emcc -O2 -DLEAN_EMSCRIPTEN -pthread \
  -Ibuild/wasm-sysroot/include \
  -c build/Main.c -o build/Main.o
~~~

Link the object file with the target-specific libraries:

~~~sh
em++ build/Main.o \
  -Lbuild/wasm-sysroot/lib \
  -Wl,--start-group -lInit -Wl,--end-group -lleanrt \
  -pthread -fwasm-exceptions \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s EXIT_RUNTIME=1 \
  -s ENVIRONMENT=node \
  -s ERROR_ON_UNDEFINED_SYMBOLS=1 \
  -o build/Main.js
~~~

For `Std`, use `-Wl,--start-group -lStd -lInit -Wl,--end-group` before `-lleanrt`.

## Version and ABI constraints

The compiler, Lean headers, runtime C++, and generated standard-library C must be kept in sync. `function signature mismatch` and missing Lean symbols generally indicate that `LEAN_SOURCE_DIR` does not match the installed `lean`. Do not silence those errors by reusing host archives.

The tested configuration was Lean 4.33.1, Emscripten 6.0.9, and Node.js 24.19.0. Emscripten's `-pthread` plus `ALLOW_MEMORY_GROWTH` warning is expected for this configuration.

Some macOS Node installations cannot read the system OpenSSL configuration in a restricted environment. In that case use `OPENSSL_CONF=/dev/null` both while invoking the helper and when running the generated JavaScript. Emscripten's cache must also be writable; set `EM_CACHE=/tmp/lean4-wasm-cache` when necessary.

External native libraries, Lean plugins, filesystem features, and network features need their own Emscripten builds. This sysroot is intended for basic Lean programs and Node execution.

## Example

`<skill-dir>/example/README.md` is a self-contained English explanation of the example. `<skill-dir>/example/Main.lean` is the source, `<skill-dir>/example/Main.c` is the C output produced by `lean`, and `<skill-dir>/example/run-output.txt` records the observed Node.js output.
