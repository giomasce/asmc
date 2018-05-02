
fun test 2 {
  0 param itoa 1 platform_log ;
  " " 1 platform_log ;
  1 param itoa 1 platform_log ;
  "\n" 1 platform_log ;
}

fun main 0 {
  "Hello, G!\n" 1 platform_log ;
  $x
  $y
  &y 100 = ;
  &x 10 = ;
  while x {
    x y test ;
    &x x 1 - = ;
  }
}
