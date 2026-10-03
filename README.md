# lean4-skills

Reusable Codex skills for Lean 4 workflows.

## Available skills

### `lean4-to-wasm`

Compile Lean 4 programs to C, then build a matching Lean runtime and standard library for Node.js WebAssembly with Emscripten.

The skill lives in [`skills/lean4-to-wasm`](skills/lean4-to-wasm). It includes:

- `SKILL.md` with the workflow and requirements
- `scripts/` for building the Wasm sysroot and application
- `example/` with a complete Lean-to-Wasm example
- `NOTICE.md` with attribution and provenance

The toolchain requires Lean 4, Emscripten, and Node.js. See the skill's [`SKILL.md`](skills/lean4-to-wasm/SKILL.md) for setup and usage details.

### `lean4-explain-with-evidence`

Answer Lean 4 questions by running focused experiments and explaining the relevant computed results, inferred types, diagnostics, or proof states. Show only the evidence that helps answer the question; a successful check can be reported without displaying a log.

The skill lives in [`skills/lean4-explain-with-evidence`](skills/lean4-explain-with-evidence). See its [`SKILL.md`](skills/lean4-explain-with-evidence/SKILL.md) for the workflow and evidence presentation guidance.
