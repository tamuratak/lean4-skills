// Lean compiler output
// Module: example.Main
// Imports: public import Init public meta import Init
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
lean_object* lean_string_append(lean_object*, lean_object*);
lean_object* lean_string_push(lean_object*, uint32_t);
lean_object* lean_get_stdout();
LEAN_EXPORT lean_object* l_IO_print___at___00IO_println___at___00main_spec__1_spec__2(lean_object*);
LEAN_EXPORT lean_object* l_IO_print___at___00IO_println___at___00main_spec__1_spec__2___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_IO_println___at___00main_spec__1(lean_object*);
LEAN_EXPORT lean_object* l_IO_println___at___00main_spec__1___boxed(lean_object*, lean_object*);
static const lean_string_object l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = ", "};
static const lean_object* l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0___closed__0 = (const lean_object*)&l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0___closed__0_value;
LEAN_EXPORT lean_object* l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0___boxed(lean_object*, lean_object*);
static const lean_string_object l_List_toString___at___00main_spec__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "[]"};
static const lean_object* l_List_toString___at___00main_spec__0___closed__0 = (const lean_object*)&l_List_toString___at___00main_spec__0___closed__0_value;
static const lean_string_object l_List_toString___at___00main_spec__0___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "["};
static const lean_object* l_List_toString___at___00main_spec__0___closed__1 = (const lean_object*)&l_List_toString___at___00main_spec__0___closed__1_value;
static const lean_string_object l_List_toString___at___00main_spec__0___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "]"};
static const lean_object* l_List_toString___at___00main_spec__0___closed__2 = (const lean_object*)&l_List_toString___at___00main_spec__0___closed__2_value;
LEAN_EXPORT lean_object* l_List_toString___at___00main_spec__0(lean_object*);
LEAN_EXPORT lean_object* l_List_toString___at___00main_spec__0___boxed(lean_object*);
LEAN_EXPORT lean_object* l_main___boxed__const__1;
LEAN_EXPORT lean_object* _lean_main(lean_object*);
LEAN_EXPORT lean_object* l_main___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_IO_print___at___00IO_println___at___00main_spec__1_spec__2(lean_object* v_s_1_){
_start:
{
lean_object* v___x_3_; lean_object* v_putStr_4_; lean_object* v___x_5_; 
v___x_3_ = lean_get_stdout();
v_putStr_4_ = lean_ctor_get(v___x_3_, 4);
lean_inc_ref(v_putStr_4_);
lean_dec_ref(v___x_3_);
v___x_5_ = lean_apply_2(v_putStr_4_, v_s_1_, lean_box(0));
return v___x_5_;
}
}
LEAN_EXPORT lean_object* l_IO_print___at___00IO_println___at___00main_spec__1_spec__2___boxed(lean_object* v_s_6_, lean_object* v_a_7_){
_start:
{
lean_object* v_res_8_; 
v_res_8_ = l_IO_print___at___00IO_println___at___00main_spec__1_spec__2(v_s_6_);
return v_res_8_;
}
}
LEAN_EXPORT lean_object* l_IO_println___at___00main_spec__1(lean_object* v_s_9_){
_start:
{
uint32_t v___x_11_; lean_object* v___x_12_; lean_object* v___x_13_; 
v___x_11_ = 10;
v___x_12_ = lean_string_push(v_s_9_, v___x_11_);
v___x_13_ = l_IO_print___at___00IO_println___at___00main_spec__1_spec__2(v___x_12_);
return v___x_13_;
}
}
LEAN_EXPORT lean_object* l_IO_println___at___00main_spec__1___boxed(lean_object* v_s_14_, lean_object* v_a_15_){
_start:
{
lean_object* v_res_16_; 
v_res_16_ = l_IO_println___at___00main_spec__1(v_s_14_);
return v_res_16_;
}
}
LEAN_EXPORT lean_object* l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0(lean_object* v_x_18_, lean_object* v_x_19_){
_start:
{
if (lean_obj_tag(v_x_19_) == 0)
{
return v_x_18_;
}
else
{
lean_object* v_head_20_; lean_object* v_tail_21_; lean_object* v___x_22_; lean_object* v___x_23_; lean_object* v___x_24_; 
v_head_20_ = lean_ctor_get(v_x_19_, 0);
v_tail_21_ = lean_ctor_get(v_x_19_, 1);
v___x_22_ = ((lean_object*)(l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0___closed__0));
v___x_23_ = lean_string_append(v_x_18_, v___x_22_);
v___x_24_ = lean_string_append(v___x_23_, v_head_20_);
v_x_18_ = v___x_24_;
v_x_19_ = v_tail_21_;
goto _start;
}
}
}
LEAN_EXPORT lean_object* l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0___boxed(lean_object* v_x_26_, lean_object* v_x_27_){
_start:
{
lean_object* v_res_28_; 
v_res_28_ = l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0(v_x_26_, v_x_27_);
lean_dec(v_x_27_);
return v_res_28_;
}
}
LEAN_EXPORT lean_object* l_List_toString___at___00main_spec__0(lean_object* v_x_32_){
_start:
{
if (lean_obj_tag(v_x_32_) == 0)
{
lean_object* v___x_33_; 
v___x_33_ = ((lean_object*)(l_List_toString___at___00main_spec__0___closed__0));
return v___x_33_;
}
else
{
lean_object* v_tail_34_; 
v_tail_34_ = lean_ctor_get(v_x_32_, 1);
if (lean_obj_tag(v_tail_34_) == 0)
{
lean_object* v_head_35_; lean_object* v___x_36_; lean_object* v___x_37_; lean_object* v___x_38_; lean_object* v___x_39_; 
v_head_35_ = lean_ctor_get(v_x_32_, 0);
v___x_36_ = ((lean_object*)(l_List_toString___at___00main_spec__0___closed__1));
v___x_37_ = lean_string_append(v___x_36_, v_head_35_);
v___x_38_ = ((lean_object*)(l_List_toString___at___00main_spec__0___closed__2));
v___x_39_ = lean_string_append(v___x_37_, v___x_38_);
return v___x_39_;
}
else
{
lean_object* v_head_40_; lean_object* v___x_41_; lean_object* v___x_42_; lean_object* v___x_43_; uint32_t v___x_44_; lean_object* v___x_45_; 
v_head_40_ = lean_ctor_get(v_x_32_, 0);
v___x_41_ = ((lean_object*)(l_List_toString___at___00main_spec__0___closed__1));
v___x_42_ = lean_string_append(v___x_41_, v_head_40_);
v___x_43_ = l_List_foldl___at___00List_toString___at___00main_spec__0_spec__0(v___x_42_, v_tail_34_);
v___x_44_ = 93;
v___x_45_ = lean_string_push(v___x_43_, v___x_44_);
return v___x_45_;
}
}
}
}
LEAN_EXPORT lean_object* l_List_toString___at___00main_spec__0___boxed(lean_object* v_x_46_){
_start:
{
lean_object* v_res_47_; 
v_res_47_ = l_List_toString___at___00main_spec__0(v_x_46_);
lean_dec(v_x_46_);
return v_res_47_;
}
}
static lean_object* _init_l_main___boxed__const__1(void){
_start:
{
uint32_t v___x_48_; lean_object* v___x_49_; 
v___x_48_ = 0;
v___x_49_ = lean_box_uint32(v___x_48_);
return v___x_49_;
}
}
LEAN_EXPORT lean_object* _lean_main(lean_object* v_args_50_){
_start:
{
lean_object* v___x_52_; lean_object* v___x_53_; 
v___x_52_ = l_List_toString___at___00main_spec__0(v_args_50_);
lean_dec(v_args_50_);
v___x_53_ = l_IO_println___at___00main_spec__1(v___x_52_);
if (lean_obj_tag(v___x_53_) == 0)
{
lean_object* v___x_55_; uint8_t v_isShared_56_; uint8_t v_isSharedCheck_61_; 
v_isSharedCheck_61_ = !lean_is_exclusive(v___x_53_);
if (v_isSharedCheck_61_ == 0)
{
lean_object* v_unused_62_; 
v_unused_62_ = lean_ctor_get(v___x_53_, 0);
lean_dec(v_unused_62_);
v___x_55_ = v___x_53_;
v_isShared_56_ = v_isSharedCheck_61_;
goto v_resetjp_54_;
}
else
{
lean_dec(v___x_53_);
v___x_55_ = lean_box(0);
v_isShared_56_ = v_isSharedCheck_61_;
goto v_resetjp_54_;
}
v_resetjp_54_:
{
lean_object* v___x_57_; lean_object* v___x_59_; 
v___x_57_ = l_main___boxed__const__1;
if (v_isShared_56_ == 0)
{
lean_ctor_set(v___x_55_, 0, v___x_57_);
v___x_59_ = v___x_55_;
goto v_reusejp_58_;
}
else
{
lean_object* v_reuseFailAlloc_60_; 
v_reuseFailAlloc_60_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v_reuseFailAlloc_60_, 0, v___x_57_);
v___x_59_ = v_reuseFailAlloc_60_;
goto v_reusejp_58_;
}
v_reusejp_58_:
{
return v___x_59_;
}
}
}
else
{
lean_object* v_a_63_; lean_object* v___x_65_; uint8_t v_isShared_66_; uint8_t v_isSharedCheck_70_; 
v_a_63_ = lean_ctor_get(v___x_53_, 0);
v_isSharedCheck_70_ = !lean_is_exclusive(v___x_53_);
if (v_isSharedCheck_70_ == 0)
{
v___x_65_ = v___x_53_;
v_isShared_66_ = v_isSharedCheck_70_;
goto v_resetjp_64_;
}
else
{
lean_inc(v_a_63_);
lean_dec(v___x_53_);
v___x_65_ = lean_box(0);
v_isShared_66_ = v_isSharedCheck_70_;
goto v_resetjp_64_;
}
v_resetjp_64_:
{
lean_object* v___x_68_; 
if (v_isShared_66_ == 0)
{
v___x_68_ = v___x_65_;
goto v_reusejp_67_;
}
else
{
lean_object* v_reuseFailAlloc_69_; 
v_reuseFailAlloc_69_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v_reuseFailAlloc_69_, 0, v_a_63_);
v___x_68_ = v_reuseFailAlloc_69_;
goto v_reusejp_67_;
}
v_reusejp_67_:
{
return v___x_68_;
}
}
}
}
}
LEAN_EXPORT lean_object* l_main___boxed(lean_object* v_args_71_, lean_object* v_a_72_){
_start:
{
lean_object* v_res_73_; 
v_res_73_ = _lean_main(v_args_71_);
return v_res_73_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_example_Main(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
l_main___boxed__const__1 = _init_l_main___boxed__const__1();
lean_mark_persistent(l_main___boxed__const__1);
return lean_io_result_mk_ok(lean_box(0));
}
char ** lean_setup_args(int argc, char ** argv);
void lean_initialize_runtime_module();
#if defined(WIN32) || defined(_WIN32)
#include <windows.h>
#endif
lean_object* run_main(int argc, char ** argv) {
    lean_object* in = lean_box(0);
    int i = argc;
    while (i > 1) {
      lean_object* n;
      i--;
      n = lean_alloc_ctor(1,2,0); lean_ctor_set(n, 0, lean_mk_string(argv[i])); lean_ctor_set(n, 1, in);
      in = n;
    }
    return _lean_main(in);
}
int main(int argc, char ** argv) {
#if defined(WIN32) || defined(_WIN32)
  SetErrorMode(SEM_FAILCRITICALERRORS);
  SetConsoleOutputCP(CP_UTF8);
#endif
  lean_object* res;
  argv = lean_setup_args(argc, argv);
  lean_initialize_runtime_module();
  res = initialize_example_Main(1 /* builtin */);
  lean_io_mark_end_initialization();
  if (lean_io_result_is_ok(res)) {
    lean_dec_ref(res);
    lean_init_task_manager();
    res = lean_run_main(&run_main, argc, argv);
  }
  lean_finalize_task_manager();
  if (lean_io_result_is_ok(res)) {
    int ret = lean_unbox_uint32(lean_io_result_get_value(res));
    lean_dec_ref(res);
    return ret;
  } else {
    lean_io_result_show_error(res);
    lean_dec_ref(res);
    return 1;
  }
}
#ifdef __cplusplus
}
#endif
