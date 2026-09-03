/*
 * The Emscripten sysroot used by this skill does not link native libuv.
 * Keep the diagnostic path in Lean's IO runtime linkable.
 */
extern "C" const char* uv_strerror(int) {
    return "libuv is unavailable in this Emscripten sysroot";
}
