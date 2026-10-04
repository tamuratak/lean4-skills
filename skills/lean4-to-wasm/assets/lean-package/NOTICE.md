# Attribution and adaptations

These bridge/build components are adapted from `lean-explainer`
(Takashi Tamura, 2026), commit
`f6f31d322ef08aaf28d89b486cc00f5833a8556c`, copied on 2026-10-04.
The source's MIT license is retained in `LICENSE`.

- `build.sh`: rewritten in Bash from `scripts/lean-wasm/build-parser.py`; accepts an external
  application source and C symbols, resolves bridge paths locally, omits
  native comparator/application distribution, and rebuilds archives without
  stale members. Its dependency build and ABI adjustments are retained;
  compiler versions and source revisions are recorded rather than enforced,
  and modified or non-Git source trees are accepted.
- `bridge.c`: from `lean/parser-bridge.c`; makes the initializer and exported
  function configurable, renames public entry points, and removes memory metrics.
- `runtime.mjs`: from `src/lean-wasm/parser-runtime.mjs`; renames bridge entry
  points, returns the application's string directly, and removes metrics.
- `support-init.cpp`: from `scripts/lean-wasm/parser-support-init.cpp`;
  renames initialization functions to match the bridge.
- `abi-compat.c` and `excluded-elaboration.c`: unchanged copies of
  `scripts/lean-wasm/parser-abi-compat.c` and
  `scripts/lean-wasm/parser-excluded-elaboration.c`.

The skill's existing sysroot helpers are reused. Application Lean code,
elaborator implementation, seeds, generated assets, and UI are not included.
Lean runtime/standard-library sources are supplied externally; their copyright
notices and Apache License 2.0 terms remain applicable.

Usage: [references/lean-package.md](../../references/lean-package.md).
