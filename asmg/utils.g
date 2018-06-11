
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

fun isspace 1 {
  $c
  @c 0 param = ;
  if c '\n' == { 1 ret ; }
  if c '\r' == { 1 ret ; }
  if c '\f' == { 1 ret ; }
  if c '\v' == { 1 ret ; }
  if c '\t' == { 1 ret ; }
  if c ' ' == { 1 ret ; }
  0 ret ;
}

fun strtol 3 {
  $ptr
  $endptr
  $base
  @ptr 2 param = ;
  @endptr 1 param = ;
  @base 0 param = ;

  $positive
  @positive 1 = ;
  $white
  @white 1 = ;
  $sign_found
  @sign_found 0 = ;
  $val
  @val 0 = ;

  while ptr **c 0 != {
    $c
    @c ptr **c = ;
    if c 0 == {
      if endptr 0 != {
        endptr ptr = ;
      }
      val positive * ret ;
    }
    base 0 >= base 1 != && base 36 <= && "strtol: wrong base" assert_msg ;
    if c isspace {
      white "strtol: wrong whitespace" assert_msg ;
    } else {
      @white 0 = ;
      if c '+' == {
        sign_found ! "strtol: more than one sign found" assert_msg ;
        @sign_found 1 = ;
      } else {
        if c '-' == {
          sign_found ! "strtol: more than one sign found" assert_msg ;
          @sign_found 1 = ;
          @positive 0 1 - = ;
        } else {
          if base 0 == {
            if c '0' == {
              base 8 = ;
              @ptr ptr 1 + = ;
              @c ptr **c = ;
              if c 'x' == c 'X' == || {
                base 16 = ;
                @ptr ptr 1 + = ;
                @c ptr **c = ;
              }
            } else {
              base 10 = ;
            }
          }
          if '0' c <= c '9' <= && {
            @c c '0' - = ;
          } else {
            if 'a' c <= c 'z' <= && {
              @c c 'a' - 10 + = ;
            } else {
              if 'A' c <= c 'Z' <= && {
                @c c 'A' - 10 + = ;
              } else {
                @c 255 = ;
              }
            }
          }
          if c base >= {
            if endptr 0 != {
              endptr ptr = ;
            }
            val positive * ret ;
          }
          @val val base * c + = ;
        }
      }
    }
    @ptr ptr 1 + = ;
  }
}
