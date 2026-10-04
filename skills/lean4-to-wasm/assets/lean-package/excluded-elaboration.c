#include <lean/lean.h>
/* These APIs are outside the fixed parser contract. Never fabricate results. */
lean_object *lean_eval_check_meta(lean_object *a, lean_object *b) { lean_internal_panic("Fixed parser: meta evaluation is unavailable"); }
lean_object *lean_get_structural_rec_arg_pos(lean_object *a, lean_object *b, lean_object *c) { lean_internal_panic("Fixed parser: structural elaboration is unavailable"); }
lean_object *lean_is_expr_def_eq(lean_object *a, lean_object *b, lean_object *c, lean_object *d, lean_object *e, lean_object *f) { lean_internal_panic("Fixed parser: expression elaboration is unavailable"); }
lean_object *lean_is_level_def_eq(lean_object *a, lean_object *b, lean_object *c, lean_object *d, lean_object *e, lean_object *f) { lean_internal_panic("Fixed parser: level elaboration is unavailable"); }
lean_object *lean_synth_pending(lean_object *a, lean_object *b, lean_object *c, lean_object *d, lean_object *e) { lean_internal_panic("Fixed parser: instance synthesis is unavailable"); }
