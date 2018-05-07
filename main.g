
fun main 0 {
  "Hello, G!\n" 1 platform_log ;

  "Compiling utils.g... " 1 platform_log ;
  "utils.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling malloc.g... " 1 platform_log ;
  "malloc.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling vector.g... " 1 platform_log ;
  "vector.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling map.g... " 1 platform_log ;
  "map.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling preproc.g... " 1 platform_log ;
  "preproc.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "test.c" 0 "parse_c" platform_get_symbol \1 ;
}
