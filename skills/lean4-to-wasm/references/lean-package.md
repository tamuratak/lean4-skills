# Using Lean-package APIs in WebAssembly

Read this when the application uses Lean's parser or other Lean-package APIs.
The basic skill helpers build only the runtime and `Init`/`Std`.
[assets/lean-package](../assets/lean-package/) contains build/bridge components
adapted from `lean-explainer`, not application Lean code. Supply that code in
the consuming project. Provenance and adaptations are recorded in
[NOTICE.md](../assets/lean-package/NOTICE.md).

## Included components

| File | Purpose |
| --- | --- |
| `build.sh` | Generate the imported standard-library C, build native support for Wasm, and link the caller's module |
| `bridge.c` | Initialize the module and call its exported Lean function from C |
| `support-init.cpp` | Initialize C++ utility, kernel, and library support |
| `abi-compat.c` | Adapt run-init and compacted-region world arguments for the tested ABI |
| `excluded-elaboration.c` | Stop if parser-only execution reaches excluded elaboration APIs |
| `runtime.mjs` | Load the module and manage UTF-8 buffers across JS/C |

`NOTICE.md` and `LICENSE` retain attribution. The existing skill's sysroot
builder and runtime stubs are reused; there is no second copy, distribution
wrapper, application Worker, elaborator seed, JSON schema, or Lean example.

## Contract and build

The application supplies a Lean module exporting a function with the type
`String → IO String`. The caller specifies both its exported C symbol and the
module initializer symbol found in generated C. `bridge.c` receives them as
`LEAN_WASM_PROCESS` and `LEAN_WASM_INITIALIZER` compile definitions. Check the
generated C signatures: this bridge assumes the one-argument IO ABI used by
the tested compiler, and a one-argument module initializer.

The preserved ABI adjustments are tested with Lean **4.33.1** and C++ source
commit **23393b959b33e3a8d15796b2397f8a04c315b9f4**. `build.sh` checks both and
requires no tracked modifications in the source checkout's `src/`. These
checks apply to this adapted bridge, not the basic skill. The source project
used Emscripten **6.0.9** and Node.js **24.19.0**. The installed Lean toolchain
must include `src/lean`; the C++ checkout must be complete.

Activate Emscripten, choose the compiler/source, and build a sysroot with the
existing helper. `<skill-dir>` is the absolute path to this skill. Run these
commands from the consuming project; replace the input path and symbol names
with those of its module:

```sh
source /path/to/emsdk/emsdk_env.sh
export LEAN=/path/to/lean-4.33.1/bin/lean
export LEAN_SOURCE_DIR=/path/to/lean4
export LEAN_WASM_SYSROOT="$PWD/build/wasm-sysroot"
export LEAN_WASM_BUILD_DIR="$PWD/build/lean-package"
export JOBS=1
export OPENSSL_CONF=/dev/null
export EMCC_BATCH_BUILD=0
export EM_CACHE="$PWD/build/emcache"
<skill-dir>/scripts/build_wasm_sysroot.sh --out-dir "$LEAN_WASM_SYSROOT" --stdlib init --jobs "$JOBS"
bash <skill-dir>/assets/lean-package/build.sh /path/to/project/Application.lean \
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
Use a fresh output directory and sysroot when changing toolchain, source,
headers, flags, or ABI: incremental compilation uses source timestamps.

Copy `runtime.mjs` into the consuming project, then call `createLeanWasm`
with the loader URL:

```js
import { createLeanWasm } from './runtime.mjs';
const lean = await createLeanWasm(new URL('./build/lean-package/module.mjs', import.meta.url));
const output = lean.call(input);
```

The result is a string; parse JSON only if the supplied Lean function returns
JSON. Calls are synchronous and should be serialized per module instance.

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
the missing initialization and Lean-package/native support.

The C bridge creates a Lean string, calls the exported function, checks its
IO result, and copies the returned UTF-8 string into a `malloc` buffer before
releasing the Lean result. The JavaScript adapter frees input and output
buffers in `finally`, including error paths. It rejects raw NUL and encodes
well-formed UTF-8. Do not return `lean_string_cstr` after releasing its owner.

`abi-compat.c` supplies the world argument to renamed native implementations
of `lean_run_init` and compacted-region read/save/free. The existing sysroot
helper includes the temporary-file/directory ABI adapter. Inspect signatures
again for another compiler/source combination. The linker keeps signature
warnings fatal through `--fatal-warnings`.

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
