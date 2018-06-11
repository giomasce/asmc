
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

fun strcmp_case 2 {
  $s1
  $s2
  @s1 1 param = ;
  @s2 0 param = ;
  $diff
  @diff 'A' 'a' - = ;
  while 1 {
    $c1
    $c2
    @c1 s1 **c = ;
    @c2 s2 **c = ;
    if 'A' c1 <= c1 'Z' <= && {
      @c1 c1 diff - = ;
    }
    if 'A' c2 <= c2 'Z' <= && {
      @c2 c2 diff - = ;
    }
    if c1 c2 < {
      0xffffffff ret ;
    }
    if c1 c2 > {
      1 ret ;
    }
    if c1 0 == {
      0 ret ;
    }
    @s1 s1 1 + = ;
    @s2 s2 1 + = ;
  }
}
