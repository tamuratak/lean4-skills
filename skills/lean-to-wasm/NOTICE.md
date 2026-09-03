# Attribution and provenance

The helper files under `scripts/` are original to this repository. They are not copied or substantially reproduced from the Lean 4 repository or from Emscripten.

Their design was informed by, but not copied from:

- The Lean 4 source tree layout, including `src/runtime__, `src/include/lean__, and `stage0/stdlib`.
- The Lean 4 Emscripten settings in `src/CMakeLists.txt`.
- The Lean 4 `script/lib/update-stage0` workflow for handling generated stage-0 C files.

These references are implementation guidance only and do not imply endorsement by Lean 4 or Emscripten.

The scripts compile source files supplied through `LEAN_SOURCE_DIR`; this repository does not redistribute the Lean 4 runtime or standard-library source files. Lean 4 source files retain their own copyright notices and are licensed under the Apache License 2.0. See the Lean 4 repository and its `LICENSE` file for the applicable terms.

`example/Main.c` is generated output produced by the Lean compiler from `example/Main.lean`. The repository's own files are covered by the repository `LICENSE`.
