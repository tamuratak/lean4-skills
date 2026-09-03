#include <lean/lean.h>

extern "C" lean_object* lean_io_create_tempfile_with_world(lean_object*);
extern "C" lean_object* lean_io_create_tempdir_with_world(lean_object*);

extern "C" lean_object* lean_io_create_tempfile() {
    return lean_io_create_tempfile_with_world(nullptr);
}

extern "C" lean_object* lean_io_create_tempdir() {
    return lean_io_create_tempdir_with_world(nullptr);
}
