
fun main 0 {
  "Hello, G!\n" 1 platform_log ;

  "Memory break after entering main: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;

  "Compiling utils.g... " 1 platform_log ;
  "utils.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling triv_malloc.g... " 1 platform_log ;
  "triv_malloc.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling vector.g... " 1 platform_log ;
  "vector.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling map.g... " 1 platform_log ;
  "map.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling ast.g... " 1 platform_log ;
  "ast.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling preproc.g... " 1 platform_log ;
  "preproc.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Memory break after C compiler compilation: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;

  "test.c" 0 "parse_c" platform_get_symbol \1 ;

  "Memory break before exiting main: " 1 platform_log ;
  0 platform_allocate itoa 1 platform_log ;
  "\n" 1 platform_log ;
}
