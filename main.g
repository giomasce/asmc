
fun main 0 {
  "Hello, G!\n" 1 platform_log ;

  "Compiling utils.g... " 1 platform_log ;
  "utils.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling malloc.g... " 1 platform_log ;
  "malloc.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  "Compiling preproc.g... " 1 platform_log ;
  "preproc.g" platform_g_compile ;
  "done!\n" 1 platform_log ;

  #"test.c" "parse_c" call ;
}
