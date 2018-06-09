
fun assert 1 {
  if 0 param ! {
    platform_panic ;
  }
}

fun assert_msg 2 {
  if 1 param ! {
    "\nASSERTION FAILED:\n" 1 platform_log ;
    0 param 1 platform_log ;
    "\n" 1 platform_log ;
    platform_panic ;
  }
}

fun min 2 {
  $x
  $y
  @x 0 param = ;
  @y 1 param = ;
  if x y < {
    x ret ;
  } else {
    y ret ;
  }
}

fun max 2 {
  $x
  $y
  @x 0 param = ;
  @y 1 param = ;
  if x y > {
    x ret ;
  } else {
    y ret ;
  }
}

fun take 2 {
  # The two parameters are actually perfectly interchangable...
  $ptr
  $off
  @ptr 1 param = ;
  @off 0 param = ;
  ptr off + ** ret ;
}

fun takec 2 {
  # The two parameters are actually perfectly interchangable...
  $ptr
  $off
  @ptr 1 param = ;
  @off 0 param = ;
  ptr off + **c ret ;
}

fun take_addr 2 {
  # The two parameters are actually perfectly interchangable...
  $ptr
  $off
  @ptr 1 param = ;
  @off 0 param = ;
  ptr off + ret ;
}
