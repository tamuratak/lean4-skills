# Lean 4 to C to WebAssembly: a complete example

This directory contains a small program and the artifacts produced while compiling it. It explains the example on its own; no other project documentation is required to understand what happened.

In the commands below, `<skill-dir>` means the absolute path to the parent
`lean4-to-wasm` directory. Paths under `build/` are relative to the directory
from which the command is run.

## The source

`<skill-dir>/example/Main.lean` defines the program entry point:

~~~lean
#lang lean4

def main (args : List String) : IO UInt32 := do
  IO.println (toString args)
  pure 0
~~~

The program receives command-line arguments, converts the list to a string, prints it, and returns exit code `0`.

## What was done

The Lean compiler was first asked to emit C:

~~~sh
lean -R <skill-dir> \
  --c=<skill-dir>/example/Main.c \
  -Dcompiler.postponeCompile=false \
  <skill-dir>/example/Main.lean
~~~

The result is `Main.c`. It is generated output, not hand-written application code. It includes `lean/lean.h`, declares the Lean runtime functions it uses, and contains the C `main` function that starts the Lean program.

The generated C cannot be linked by itself because it depends on the Lean runtime and the `Init` standard library. A target-specific Lean sysroot was therefore built with the helper scripts:

~~~sh
source /path/to/emsdk/emsdk_env.sh

LEAN_SOURCE_DIR=/path/to/lean4 \
  <skill-dir>/scripts/build_wasm_sysroot.sh \
  --out-dir build/wasm-sysroot \
  --stdlib init \
  --jobs 4
~~~

The application was then compiled and linked for WebAssembly:

~~~sh
LEAN_ROOT=<skill-dir> \
  <skill-dir>/scripts/lean_to_wasm.sh \
  --sysroot build/wasm-sysroot \
  --stdlib init \
  --out-dir build/example \
  <skill-dir>/example/Main.lean
~~~

That command produces `Main.c`, `Main.js`, and `Main.wasm` in `build/example`. The JavaScript file is the Emscripten loader; the WebAssembly file is the compiled program.

## The result

Running the generated Node.js program with two arguments:

~~~sh
OPENSSL_CONF=/dev/null node build/example/Main.js hello world
~~~

produces:

~~~text
[hello, world]
~~~

The same observed output is saved in `<skill-dir>/example/run-output.txt`. The checked-in `<skill-dir>/example/Main.c` is the C output from the first command, so it shows the intermediate representation produced by Lean.

## Why the sysroot is needed

The Lean-to-C compiler emits calls such as `lean_get_stdout`, `lean_run_main`, and `lean_string_push`. These functions are implemented by Lean's runtime and standard library, not by the C file itself. The sysroot builder compiles those dependencies with Emscripten so that every linked object targets WebAssembly instead of the host operating system.

This example uses only `Init`, so `--stdlib init` is sufficient. A program that imports `Std` must build and link the additional `Std` archive with `--stdlib init-std`.

If Emscripten cannot find `uv.h`, set `LEAN_WASM_UV_INCLUDE` to the Emscripten Node include directory, for example `/path/to/emsdk/node/<version>/include/node`.
