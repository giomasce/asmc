# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

fun resolve_symbol 3 {
  $loc
  $nameptr
  $offptr
  @loc 2 param = ;
  @nameptr 1 param = ;
  @offptr 0 param = ;

  $i
  @i 0 = ;
  offptr 0 = ;
  nameptr "<unknown>" = ;
  while i __symbol_num < {
    $this_loc
    @this_loc __symbol_locs i 4 * + ** = ;
    $this_name
    @this_name __symbol_names i __max_symbol_name_len * + = ;
    if this_loc loc <= this_loc offptr ** >= && {
      offptr this_loc = ;
      nameptr this_name = ;
    }
    @i i 1 + = ;
  }
  offptr loc offptr ** - = ;
}

fun dump_frame 1 {
  $frame_ptr
  @frame_ptr 0 param = ;

  if frame_ptr 0 == {
    ret ;
  }

  $prev_frame_ptr
  $ret_addr
  @prev_frame_ptr frame_ptr ** = ;
  @ret_addr frame_ptr 4 + ** = ;
  $name
  $off
  ret_addr @name @off resolve_symbol ;

  "Frame pointer: " 1 platform_log ;
  frame_ptr itoa 1 platform_log ;
  "; previous frame pointer: " 1 platform_log ;
  prev_frame_ptr itoa 1 platform_log ;
  "; return address: " 1 platform_log ;
  ret_addr itoa 1 platform_log ;
  " (" 1 platform_log ;
  name 1 platform_log ;
  "+" 1 platform_log ;
  off itoa 1 platform_log ;
  ")\n" 1 platform_log ;

  prev_frame_ptr dump_frame ;
}

fun dump_stacktrace 0 {
  $frame_ptr
  @frame_ptr __frame_ptr = ;
  frame_ptr dump_frame ;
}

$assert_pos

fun set_assert_pos 1 {
  @assert_pos 0 param = ;
}

fun assert 1 {
  if 0 param ! {
    "\nASSERTION FAILED\n" 1 platform_log ;
    dump_stacktrace ;
    platform_panic ;
  }
}

fun assert_msg 2 {
  if 1 param ! {
    "\nASSERTION FAILED at line " 1 platform_log ;
    assert_pos itoa 1 platform_log ;
    "\n" 1 platform_log ;
    0 param 1 platform_log ;
    "\n" 1 platform_log ;
    dump_stacktrace ;
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

fun strlen 1 {
  $ptr
  @ptr 0 param = ;

  $len
  @len 0 = ;
  while ptr **c 0 != {
    @len len 1 + = ;
    @ptr ptr 1 + = ;
  }
  len ret ;
}

fun strcmp 2 {
  $a
  $b
  @a 1 param = ;
  @b 0 param = ;

  while a **c b **c == {
    if a **c 0 == {
      0 ret ;
    }
    @a a 1 + = ;
    @b b 1 + = ;
  }
  if a **c b **c < {
    1 ret ;
  } else {
    0 1 - ret ;
  }
}

fun strcpy 2 {
  $src
  $dest
  @src 1 param = ;
  @dest 0 param = ;

  while src **c 0 != {
    dest src **c =c ;
    @src src 1 + = ;
    @dest dest 1 + = ;
  }
  dest 0 =c ;
}

fun memcpy 3 {
  $n
  $src
  $dest
  @n 2 param = ;
  @src 1 param = ;
  @dest 0 param = ;

  while n 0 > {
    dest src **c =c ;
    @src src 1 + = ;
    @dest dest 1 + = ;
    @n n 1 - = ;
  }
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

  while 1 {
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
          @sign_found 1 = ;
          if base 0 == {
            if c '0' == {
              @base 8 = ;
              @ptr ptr 1 + = ;
              @c ptr **c = ;
              if c 'x' == c 'X' == || {
                @base 16 = ;
                @ptr ptr 1 + = ;
                @c ptr **c = ;
              }
            } else {
              @base 10 = ;
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
                @c 0x100 = ;
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

fun atoi 1 {
  $ptr
  @ptr 0 param = ;

  ptr 0 != "atoi: invalid null pointer" assert_msg ;
  ptr **c 0 != "atoi: invalid empty string" assert_msg ;

  $end
  $res
  @res ptr @end 0 strtol = ;

  end **c 0 == "atoi: invalid number" assert_msg ;

  res ret ;
}

fun memset 3 {
  $s
  $c
  $n
  @s 2 param = ;
  @c 1 param = ;
  @n 0 param = ;

  $i
  @i 0 = ;
  while i n < {
    s i + c =c ;
    @i i 1 + = ;
  }
}

fun memcheck 3 {
  $s
  $c
  $n
  @s 2 param = ;
  @c 1 param = ;
  @n 0 param = ;

  $i
  @i 0 = ;
  while i n < {
    if s i + **c c != {
      0 ret ;
    }
    @i i 1 + = ;
  }
  1 ret ;
}

fun dump_nibble 1 {
  $x
  @x 0 param = ;
  @x x 0xf & = ;
  if x 0 == { '0' 1 platform_write_char ; }
  if x 1 == { '1' 1 platform_write_char ; }
  if x 2 == { '2' 1 platform_write_char ; }
  if x 3 == { '3' 1 platform_write_char ; }
  if x 4 == { '4' 1 platform_write_char ; }
  if x 5 == { '5' 1 platform_write_char ; }
  if x 6 == { '6' 1 platform_write_char ; }
  if x 7 == { '7' 1 platform_write_char ; }
  if x 8 == { '8' 1 platform_write_char ; }
  if x 9 == { '9' 1 platform_write_char ; }
  if x 10 == { 'a' 1 platform_write_char ; }
  if x 11 == { 'b' 1 platform_write_char ; }
  if x 12 == { 'c' 1 platform_write_char ; }
  if x 13 == { 'd' 1 platform_write_char ; }
  if x 14 == { 'e' 1 platform_write_char ; }
  if x 15 == { 'f' 1 platform_write_char ; }
}

fun dump_byte 1 {
  $x
  @x 0 param = ;
  x 4 >> dump_nibble ;
  x dump_nibble ;
  ' ' 1 platform_write_char ;
}

fun dump_mem 2 {
  $ptr
  $size
  @ptr 1 param = ;
  @size 0 param = ;

  @size size ptr + = ;
  while ptr size < {
    ptr **c dump_byte ;
    @ptr ptr 1 + = ;
  }
}

fun get_char_type 1 {
  $x
  @x 0 param = ;
  if x '\n' == { 1 ret ; }
  if x '\t' == x ' ' == || { 2 ret ; }
  if x '0' >= x '9' <= && x 'a' >= x 'z' <= && || x 'A' >= x 'Z' <= && || x '_' == || { 3 ret ; }
  4 ret ;
}
