#include <lean/lean.h>
/* Stop when an API has no linked implementation; imported implementations take precedence. */
#define LEAN_WASM_FALLBACK __attribute__((weak))
LEAN_WASM_FALLBACK lean_object *lean_eval_check_meta(lean_object *a, lean_object *b) { lean_internal_panic("Lean API bridge: no linked implementation for meta evaluation"); }
LEAN_WASM_FALLBACK lean_object *lean_get_structural_rec_arg_pos(lean_object *a, lean_object *b, lean_object *c) { lean_internal_panic("Lean API bridge: no linked implementation for structural elaboration"); }
LEAN_WASM_FALLBACK lean_object *lean_is_expr_def_eq(lean_object *a, lean_object *b, lean_object *c, lean_object *d, lean_object *e, lean_object *f) { lean_internal_panic("Lean API bridge: no linked implementation for expression definitional equality"); }
LEAN_WASM_FALLBACK lean_object *lean_is_level_def_eq(lean_object *a, lean_object *b, lean_object *c, lean_object *d, lean_object *e, lean_object *f) { lean_internal_panic("Lean API bridge: no linked implementation for level definitional equality"); }
LEAN_WASM_FALLBACK lean_object *lean_synth_pending(lean_object *a, lean_object *b, lean_object *c, lean_object *d, lean_object *e) { lean_internal_panic("Lean API bridge: no linked implementation for instance synthesis"); }
