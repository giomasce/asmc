
const COMPILE_ASM 1
const COMPILE_C 1
const RUN_ASM 0
const RUN_C 1

const USE_TRIVIAL_MALLOC 0
const USE_SIMPLE_MALLOC 0
const USE_CHECKED_MALLOC 1

fun main 0 {
  "Hello, G!\n" 1 platform_log ;

  "Memory break after entering main: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;

  "Compiling utils.g... " 1 platform_log ;
  "utils.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  if USE_TRIVIAL_MALLOC {
    "Compiling triv_malloc.g... " 1 platform_log ;
    "triv_malloc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  if USE_SIMPLE_MALLOC {
    "Compiling simple_malloc.g... " 1 platform_log ;
    "simple_malloc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  if USE_CHECKED_MALLOC {
    "Compiling check_malloc.g... " 1 platform_log ;
    "check_malloc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  "Compiling malloc_utils.g... " 1 platform_log ;
  "malloc_utils.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling vector.g... " 1 platform_log ;
  "vector.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling map.g... " 1 platform_log ;
  "map.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling utils2.g... " 1 platform_log ;
  "utils2.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  if COMPILE_ASM {
    #"Memory break before ASM assembler compilation: " 1 platform_log ;
    #0 platform_allocate itoa 1 platform_log ;
    #"\n" 1 platform_log ;

    "Compiling asm_regs.g... " 1 platform_log ;
    "asm_regs.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling asm_preproc.g... " 1 platform_log ;
    "asm_preproc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling asm_opcodes.g... " 1 platform_log ;
    "asm_opcodes.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling asm_compile.g... " 1 platform_log ;
    "asm_compile.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    #"Memory break after ASM assembler compilation: " 1 platform_log ;
    #0 platform_allocate itoa 1 platform_log ;
    #"\n" 1 platform_log ;
  }

  if COMPILE_C {
    "Compiling c_ast.g... " 1 platform_log ;
    "c_ast.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling c_preproc.g... " 1 platform_log ;
    "c_preproc.g" platform_g_compile ;
    "done!\n" 1 platform_log ;

    "Compiling c_compile.g... " 1 platform_log ;
    "c_compile.g" platform_g_compile ;
    "done!\n" 1 platform_log ;
  }

  "Memory break after compilers compilation: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;

  if RUN_ASM {
    "test.asm" 0 "parse_asm" platform_get_symbol \1 ;
  }

  if RUN_C {
    "test2.c" 0 "parse_c" platform_get_symbol \1 ;
  }

  "Memory break before exiting main: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;

  0 "malloc_stats" platform_get_symbol \0 ;
}
