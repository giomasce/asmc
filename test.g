
fun 1 test {

}

fun 2 main {
  $argc
  $argv
  &argc 0 param = ;
  &argv 1 param = ;
  $x
  &x argc argv + = ;
  argc test ;
  &argv argc = ;
  if x {
    &x 2 = ;
  } else {
    &x 4 = ;
  }
  x ret ;
  while x {
    &x x 1 - = ;
  }
}
