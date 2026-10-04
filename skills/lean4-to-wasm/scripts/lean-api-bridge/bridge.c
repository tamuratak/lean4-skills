#include <lean/lean.h>
#include <stdlib.h>
#include <string.h>
extern lean_object *LEAN_WASM_INITIALIZER(uint8_t);
extern lean_object *LEAN_WASM_PROCESS(lean_object *);
void lean_wasm_initialize_util(void);
void lean_wasm_initialize_support(void);
int lean_wasm_init(void) {
    static int initialized = 0;
    if (initialized) return 0;
    lean_wasm_initialize_util();
    lean_object *r = LEAN_WASM_INITIALIZER(1);
    if (lean_io_result_is_error(r)) { lean_io_result_show_error(r); lean_dec(r); return 1; }
    lean_dec(r);
    lean_wasm_initialize_support();
    lean_io_mark_end_initialization();
    initialized = 1;
    return 0;
}
char *lean_wasm_call(const char *input) {
    lean_object *r = LEAN_WASM_PROCESS(lean_mk_string(input));
    if (lean_io_result_is_error(r)) { lean_io_result_show_error(r); lean_dec(r); return NULL; }
    lean_object *value = lean_io_result_get_value(r);
    const char *s = lean_string_cstr(value);
    size_t size = lean_string_size(value);
    /* The JavaScript interface uses NUL-terminated UTF-8; reject unrepresentable output. */
    if (memchr(s, '\0', size - 1)) { lean_dec(r); return NULL; }
    char *copy = malloc(size);
    if (copy) memcpy(copy, s, size);
    lean_dec(r);
    return copy;
}
