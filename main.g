
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
  &y 10 100 <= = ;
  &x 5 3 * = ;
  while x {
    x y test ;
    &x x 1 - = ;
  }
  &x 32 = ;
  &y 3 = ;
  $z
  $w
  &z x y << = ;
  &w x y >> = ;
  w z test ;
  w &w @ test ;
}
