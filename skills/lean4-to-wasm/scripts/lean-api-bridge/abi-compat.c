#include <lean/lean.h>
/* Keep these wrappers in sync with the ABI renames in build.sh's compile_support. */
extern lean_object *lean_run_init_with_world(lean_object*,lean_object*,lean_object*,lean_object*,lean_object*);
extern lean_object *lean_compacted_region_read_with_world(lean_object*,lean_object*,lean_object*);
extern lean_object *lean_compacted_region_save_with_world(lean_object*,lean_object*,lean_object*,lean_object*,lean_object*,uint8_t,lean_object*);
extern lean_object *lean_compacted_region_free_with_world(lean_object*,lean_object*);
lean_object *lean_run_init(lean_object*a,lean_object*b,lean_object*c,lean_object*d) { return lean_run_init_with_world(a,b,c,d,lean_box(0)); }
lean_object *lean_compacted_region_read(lean_object*a,lean_object*b) { return lean_compacted_region_read_with_world(a,b,lean_box(0)); }
lean_object *lean_compacted_region_save(lean_object*a,lean_object*b,lean_object*c,lean_object*d,lean_object*e,uint8_t f) { return lean_compacted_region_save_with_world(a,b,c,d,e,f,lean_box(0)); }
lean_object *lean_compacted_region_free(lean_object*a) { return lean_compacted_region_free_with_world(a,lean_box(0)); }
