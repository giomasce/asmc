
# Comments
# Other comments

const LEN 1024

$glob
%array 100
%array2 LEN

fun test 1 {

}

fun main 2 {
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
  while x {
    &x x 1 - = ;
  }
  &x glob = ;
  &glob x = ;
  x ret ;
  &glob LEN = ;
  &x '\0 = ;
  &glob "hello!" = ;
}
