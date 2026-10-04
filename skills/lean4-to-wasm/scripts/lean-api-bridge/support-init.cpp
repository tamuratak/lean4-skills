#include "util/init_module.h"
#include "kernel/init_module.h"
#include "library/init_module.h"
extern "C" void lean_wasm_initialize_util(void) { lean::initialize_util_module(); }
extern "C" void lean_wasm_initialize_support(void) {
    lean::initialize_kernel_module();
    lean::initialize_library_core_module();
    lean::initialize_library_module();
}
