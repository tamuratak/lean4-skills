# Using Lean APIs in WebAssembly

Read this when JavaScript must call a Lean function, or the application uses
Lean's parser or other Lean APIs.
The basic skill helpers build only the runtime and `Init`/`Std`.
[scripts/lean-api-bridge](../scripts/lean-api-bridge/) contains build/bridge components
adapted from `lean-explainer` commit
`f6f31d322ef08aaf28d89b486cc00f5833a8556c`, not application Lean code. Supply
that code in the consuming project. The build script is rewritten in Bash;
the bridge accepts application-specific C symbols.

## Choosing a build path

| Goal | Application build path | Execution entry point |
| --- | --- | --- |
| Run a basic `Init`/`Std` program with `main` | `scripts/lean_to_wasm.sh` | Generated `main`, through the Node loader |
| Call an exported Lean function from JavaScript | `scripts/lean-api-bridge/build.sh` | `_lean_wasm_init`, then `_lean_wasm_call` |

Both paths use an Emscripten JavaScript loader. The distinction is running
`main` versus calling individual Lean functions, not whether JavaScript is
used. Function calls require initialization, value conversion, and memory
management; the supplied API bridge is one implementation of those operations,
and applications may supply their own instead.

Both paths first use `scripts/build_wasm_sysroot.sh` to build the Wasm runtime.
Then choose one application builder: the bridge path does not also use
`lean_to_wasm.sh`, and the basic path does not need `bridge.c`. The bridge
directory alone is not a complete runtime/toolchain; it reuses that sysroot.

The bridge's function-call interface does not require the supplied Lean function
to use Lean's parser or other Lean-package APIs. Ordinary Lean logic can also
be exposed through the `String → IO String` contract below. This is the intended
interface, not a claim that all ordinary programs have been validated: the
current build adds C++ kernel/library support even for simple functions and
has been exercised with the source project's parser. It does not run an
ordinary `main` unchanged, support arbitrary function signatures, or provide
every Lean API. Adapt the bridge for other signatures and follow the extension
guidance below for elaborator and other unsupported execution paths.

## Included components

| File | Purpose |
| --- | --- |
| `build.sh` | Generate the imported standard-library C, build native support for Wasm, and link the caller's module |
| `bridge.c` | Initialize the module and call its exported Lean function from C |
| `support-init.cpp` | Initialize C++ utility, kernel, and library support |
| `abi-compat.c` | Adapt run-init and compacted-region world arguments for the tested ABI |
| `excluded-elaboration.c` | Stop if parser-only execution reaches excluded elaboration APIs |

These files use the repository's license. The existing skill's sysroot
builder and runtime stubs are reused; there is no second copy, distribution
wrapper, application Worker, elaborator seed, JSON schema, or Lean example.

## Contract and build

The application supplies a Lean module exporting a function with the type
`String → IO String`. The caller specifies both its exported C symbol and the
module initializer symbol found in generated C. `bridge.c` receives them as
`LEAN_WASM_PROCESS` and `LEAN_WASM_INITIALIZER` compile definitions. Check the
generated C signatures: this bridge assumes the one-argument IO ABI used by
the tested compiler, and a one-argument module initializer.

The preserved ABI adjustments were tested with Lean **4.33.1** and C++ source
commit **23393b959b33e3a8d15796b2397f8a04c315b9f4**, using Emscripten
**6.0.9** and Node.js **24.19.0**. This is a tested configuration, not a required
version or commit. `build.sh` allows other versions, revisions, modified source
trees, and source distributions without Git metadata. It still requires the
installed standard-library source, complete C++ sources, and a Wasm sysroot;
compilation and linking failures remain errors.

Activate Emscripten, choose the compiler/source, and build a sysroot with the
existing helper. `<skill-dir>` is the absolute path to this skill. Run these
commands from the consuming project; replace the input path and symbol names
with those of its module:

```sh
source /path/to/emsdk/emsdk_env.sh
export LEAN=/path/to/lean-toolchain/bin/lean
export LEAN_SOURCE_DIR=/path/to/lean4
export LEAN_WASM_SYSROOT="$PWD/build/wasm-sysroot"
export LEAN_WASM_BUILD_DIR="$PWD/build/lean-api-bridge"
export JOBS=1
export OPENSSL_CONF=/dev/null
export EMCC_BATCH_BUILD=0
export EM_CACHE="$PWD/build/emcache"
<skill-dir>/scripts/build_wasm_sysroot.sh --out-dir "$LEAN_WASM_SYSROOT" --stdlib init --jobs "$JOBS"
bash <skill-dir>/scripts/lean-api-bridge/build.sh /path/to/project/Application.lean \
  --initializer initialize_Application --function application_process
```

The compiler, Emscripten, Bash 3.2 or later, and Node.js must already be installed. If
Node's `uv.h` is not detected, set `LEAN_WASM_UV_INCLUDE` as described in
`SKILL.md`. Set `LEAN_ROOT` if the input module's project root differs from its
parent directory. The minimal builder follows imports from generated C and
handles installed standard-library modules; project-local imported modules
need their own generation/link inputs. It does not build a Lake project.

The output directory contains `module.mjs`, `module.wasm`, generated C,
objects, archives, and `manifest.json`. Keep the loader beside its Wasm file.
The manifest records the actual compiler and source commit, with `unknown`
when Git metadata is unavailable. `sourceModified` records tracked changes
under `src/` as a boolean, or `null` if that information is unavailable; it
does not include untracked files or act as a compatibility check.
Use a fresh output directory and sysroot when changing toolchain, source,
headers, flags, or ABI: incremental compilation uses source timestamps.

## Calling from application JavaScript

The generated `module.mjs` is the Emscripten loader; no handwritten JavaScript
wrapper is supplied or required. Implement the following operations in the
application, using whatever wrapper structure fits it:

1. Import the loader's default module factory and await its result. The build
   uses `--no-entry`, so loader creation does not execute a Lean `main` or the
   bridge initialization.
2. Call the resulting module's `_lean_wasm_init()` before any processing.
   A nonzero result is an initialization failure; do not continue to calls.
3. Encode the input as well-formed UTF-8 without embedded NUL. Allocate
   `lengthBytesUTF8(input) + 1` bytes with `_malloc`, check for allocation
   failure, and use `stringToUTF8` to write the NUL-terminated input.
4. Pass the input pointer to `_lean_wasm_call`. A zero result is an execution
   or output allocation failure. Otherwise decode the returned pointer with
   `UTF8ToString`. Parse JSON only if the application function returns JSON.
5. Release both input and returned output buffers with `_free`, including
   failure paths, for example in `finally`. Decode the result before freeing it.

Calls are synchronous and should be serialized per module instance. These
initialization and ownership operations are required by the current bridge;
they do not require a particular JavaScript file or class structure.

## Initialization, linking, and ownership

`build.sh` compiles generated standard-library C and the C++ `util`, `kernel`,
`library`, and `library/constructions` support, excluding `ffi.cpp` and
`shell.cpp`. It links their archives with the Wasm runtime in a linker group.
It renames a generated `main`, uses `--no-entry`, and exports the bridge entry
points instead. Host archives cannot be linked into this target.

`lean_wasm_init` initializes utility support (which initializes the runtime),
calls the application's generated initializer with `builtin = 1`, checks and
releases its IO result, initializes kernel/library support, then calls
`lean_io_mark_end_initialization`. Successful initialization is cached. This
custom path is the concrete alternative used by the source project's parser;
it is not equivalent to a dummy `lean_initialize` or a runtime-only call.
If generated `main` reports a missing `lean_initialize`, inspect its call and
the linked inputs: the basic sysroot omits `src/initialize/init.cpp`, which
defines that broader entry point. Matching version numbers alone do not add
the missing initialization and Lean API/native support.

The C bridge creates a Lean string, calls the exported function, checks its
IO result, and copies the returned UTF-8 string into a `malloc` buffer before
releasing the Lean result. Application JavaScript owns both C buffers and must
free them as described above. Do not return `lean_string_cstr` after releasing
its owner.

`abi-compat.c` supplies the world argument to renamed native implementations
of `lean_run_init` and compacted-region read/save/free. The existing sysroot
helper includes the temporary-file/directory ABI adapter. Inspect signatures
again for another compiler/source combination: these adapters assume specific
argument lists and may need to be changed or removed. Allowing another version
does not automatically adapt the bridge to its ABI. The linker keeps signature
warnings fatal through `--fatal-warnings`; link success alone does not establish
runtime compatibility. Verify the application's actual execution paths against
native results, including initialization and errors.

## Extending beyond parser execution

The bundled link configuration is the parser-oriented one from
`lean-explainer`. `excluded-elaboration.c` stops on meta evaluation,
definitional equality, instance synthesis, and structural elaboration;
it does not implement those APIs. To execute them:

- Remove the corresponding stop stubs and import/link the actual standard
  implementations, such as `Lean.Meta.ExprDefEq`, `Lean.Meta.LevelDefEq`,
  `Lean.Meta.SynthInstance`, `Lean.Compiler.IR.Meta`, structural-equation and
  match-equation modules. Regenerate the dependency closure.
- Supply the environment needed by the application. The source elaborator
  used a kernel-checked fixed declaration seed, attributes, matcher metadata,
  and explicit parser/macro registration to avoid distributing `.olean`
  imports. A basic empty parser environment is insufficient for elaboration.
- For the source project's `IO.Promise` paths, rebuild runtime/support with
  `LEAN_MULTI_THREAD`, start the task manager, configure the pthread pool and
  stacks, and save stack information after initialization. Its Wasm stack-size
  correction uses base minus end in a private copy of `stackinfo.cpp`.
- Implement the filesystem/import/plugin/native-library dependencies of the
  chosen API, or explicitly stop unsupported execution paths. Do not replace
  missing functions with fabricated successful results.

These extensions are intentionally not shipped as another application in this
skill. Compare the supplied application's native and Wasm results, including
errors, Unicode, and repeated calls, after adapting imports/initialization.
For browsers, use an application Worker as needed and serve pthread builds
with COOP `same-origin` and COEP `require-corp`; check cross-origin isolation
and loader/Wasm URLs. Native or Node results alone do not verify browser use.
