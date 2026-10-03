---
name: lean4-explain-with-evidence
description: Answer questions about Lean 4 programming, types, elaboration, tactics, proofs, and errors by running focused Lean experiments and explaining the relevant observed evidence without overwhelming the user with logs.
---

# Lean 4 Explanations with Evidence

Ground answers to Lean questions in actual Lean execution. Gather enough evidence to support the explanation, then show only what helps the user understand it. Always briefly state what you ran, how you checked it, and what happened. A successful check can be reported in one sentence without displaying a log.

Before giving a technical answer, run Lean on a probe directly relevant to the user's question, subject to the execution limitations below.

## Establish the question and environment

- Identify the claim to verify: a computed value, an inferred type, a diagnostic, a goal transformation, or acceptance of a proof. For conceptual questions, choose a small example that demonstrates the relevant distinction.
- Use the user's code and project context when provided. Preserve the imports, options, and assumptions that affect the question; explain any simplification needed for a reproducer.
- Respect the project's `lean-toolchain`, Lake configuration, and dependency versions. Run `lake env lean --version` from the project root and use that environment for probes. For a standalone example, use `lean --version` and an isolated scratch directory.
- Prefer an already installed, matching toolchain over a moving toolchain alias that may trigger a download. Do not silently switch Lean or library versions. This skill targets Lean 4; do not present a Lean 4 run as evidence about Lean 3.
- Keep experiments separate from the user's source. Use a temporary file, placing it within the project when module resolution requires that location. Make permanent edits only when requested.
- If execution is explicitly prohibited, or no suitable permitted execution environment is available, state that the answer is unverified and explain the specific limitation. Never imply that an experiment ran when it did not.

## Choose evidence that answers the question

Use the smallest probe that distinguishes the relevant possibilities. Running Lean does not require collecting a detailed trace for every question.

| Question | Useful evidence | What to explain |
| --- | --- | --- |
| What does this expression compute? | `#eval expression`, or `lean --run Evidence.lean` for a program with `main` | The observed result or relevant runtime behavior. |
| What is its type or elaborated form? | `#check expression`, `#print declaration`, selectively scoped pretty-printing options | The inferred type or the elaborated detail responsible for the behavior. |
| Why does reduction or `rfl` behave this way? | `#reduce expression` and a small checked equality | How reduction relates to the claim about definitional equality. |
| Why does this fail? | Compile a reproducer of the failing code; when useful, check a minimal correction separately | The decisive diagnostic and the condition that causes it. |
| What does this tactic do? | `trace_state` before and after the tactic, or goal states obtained from an available Lean server | How the hypotheses or goals changed. |
| Does this proof or program work? | Check the exact source; run it as well when the claim concerns runtime behavior | Whether the requested check completed and any qualification affecting that conclusion. |
| Why does elaboration or instance search choose this result? | A narrowly scoped, relevant `trace.*` option or inspected elaborated term | The particular decision supported by the captured evidence. |

For unfamiliar commands or trace options, check the installed Lean sources or the version-appropriate [Lean reference manual](https://lean-lang.org/doc/reference/latest/). Do not guess trace option names. Increase diagnostic detail only when simpler evidence leaves the question unresolved.

## Execute and assess the evidence

Run a standalone probe from its scratch directory:

```sh
lean --version
lean Evidence.lean
```

Run a probe that uses project dependencies from the project root:

```sh
lake env lean --version
lake env lean Evidence.lean
```

Use `lean --run Evidence.lean` or `lake env lean --run Evidence.lean` when actually executing `main` is relevant. Compiling its definition alone does not establish its runtime behavior. Build only the dependencies or targets needed for the question if their artifacts are missing.

- Keep the tested source, command, working directory, Lean version, exit status, and relevant diagnostics available while reasoning. Record stdout and stderr; redirect noisy output to a temporary log and inspect the relevant portions rather than flooding the conversation. Check for failures or qualifications outside the selected excerpt.
- Wait for the run to finish before reporting success. An empty log alone does not show success, and a nonzero exit can be useful evidence when reproducing an error. A timeout or interrupted run leaves the check inconclusive.
- Inspect warnings and proof placeholders before calling a proof complete. Lean can accept a declaration using `sorry`; an exit status of zero does not establish that the proof has been completed. Never insert `sorry`, `admit`, or a new axiom to make a verification probe appear successful.
- When proof completeness or trust assumptions matter, use a named theorem and `#print axioms theoremName` to inspect transitive dependencies. Explain any dependency that affects the claim, including `sorryAx`, custom axioms, or trust in native computation. Do not infer that all reported axioms are errors.
- If a harness such as `#guard_msgs` succeeds by checking an expected diagnostic, report that the expected failure was reproduced; do not say that the original code was accepted.
- Distinguish observations from explanations. Evaluation is evidence about the tested inputs; a universal statement needs an appropriate checked proof. Printed goal states are snapshots, not a complete trace of the kernel or runtime.
- Keep the failing and corrected cases distinguishable. Instrumentation or a simplified example must not silently replace the exact code whose behavior is being explained.

## Present the answer with minimal burden

Lead with the answer, connect it to the observed evidence, and explain why that evidence supports it. Match the user's language and level of familiarity; the skill's English instructions do not require an English answer.

Include a concise verification note in the final answer, even when no logs are shown. Usually one sentence, or two when needed, is enough. Identify the tested expression, proof, or program; name the execution method, such as `#eval`, compilation with `lean` or `lake env lean`, or goal inspection with `trace_state`; and state the observed outcome. If you checked a simplified reproducer rather than the user's exact code, make that scope clear. Tool activity and progress updates do not replace this note, since the user may not see them.

Integrate the note into the explanation naturally. Include the Lean version or project environment when it affects the answer. Routine setup steps, temporary paths, full command transcripts, and a separate verification section are unnecessary unless they help the user reproduce or assess the result. A bare statement such as "verified" or "it works" does not identify what was actually checked.

- **Success confirmation:** Briefly identify the example, the checking method, and the successful result. Omit empty logs and routine setup details. For example, after a successful run: "I checked your `2 + 3 = 5` example with `lean` in a temporary file; it completed without errors."
- **Computed value or type:** Show the small relevant expression and its observed result or type. Explain only the details needed to answer the question.
- **Error explanation:** Quote the decisive diagnostic with enough surrounding information to preserve its meaning. Explain the cause and, when relevant, the independently checked correction.
- **Tactic or elaboration explanation:** Show the few goal states or trace lines that explain the change. Annotate their significance instead of pasting an entire trace.
- **Large output:** Summarize the relevant result and extract the necessary lines. Mark excerpts and omissions clearly. Never omit a warning or failure that changes the conclusion.
- **Reproduction or full evidence requested:** Provide the runnable source, environment, and command. If a saved artifact would be easier to inspect, link it and keep it available. Do not link a temporary log that has already been deleted.

Quote only output actually observed. Keep your annotations outside verbatim output, and label any reconstructed explanation as an explanation rather than an execution trace. Mention limitations only when they affect the answer; avoid turning a small question into a report of every verification step.

## Example probes

For a question about `intro`, run a complete proof with snapshots around the tactic:

```lean
theorem preserve (P : Prop) : P → P := by
  trace_state
  intro h
  trace_state
  exact h
```

Explain the transition from the goal `P → P` to the hypothesis `h : P` and goal `P`, using the captured states. Briefly say that you compiled this proof with `trace_state` before and after `intro h` to obtain those states. The complete proof lets Lean check that the illustrated transition leads to an accepted proof.

For a request to confirm that `example : 2 + 3 = 5 := by rfl` works, run that exact example. If it succeeds without a relevant qualification, briefly identify the example, say how you checked it, and report success; no log needs to be shown.
