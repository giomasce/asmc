# This file is part of asmc, a bootstrapping OS with minimal seed
# https://gitlab.com/giomasce/asmc

# This file is based on the 64-bit division procedure implemented in
# the Pintos project, available at [1]. The code was translated from C
# to G by Giovanni Mascellani <gio@debian.org>, with little
# modifications to better fit G syntax, and is left under the same
# license terms as the original file. The original file is licensed
# under the following license (avaiable at [2]):

# Copyright © 2004, 2005, 2006 Board of Trustees, Leland Stanford
# Jr. University. All rights reserved.

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#  [1] https://www.cs.usfca.edu/~benson/cs326/pintos/pintos/src/lib/arithmetic.c
#  [2] https://web.stanford.edu/class/cs140/projects/pintos/pintos_14.html

fun nlz 1 {
  $x
  @x 0 param = ;

  $n
  @n 0 = ;
  if x 0xffff0000 & ! {
    @n n 16 + = ;
    @x x 16 << = ;
  }
  if x 0xff000000 & ! {
    @n n 8 + = ;
    @x x 8 << = ;
  }
  if x 0xf0000000 & ! {
    @n n 4 + = ;
    @x x 4 << = ;
  }
  if x 0xc0000000 & ! {
    @n n 2 + = ;
    @x x 2 << = ;
  }
  if x 0x80000000 & ! {
    @n n 1 + = ;
    @x x 1 << = ;
  }
  n ret ;
}

fun i64_udiv 2 {
  $n
  $d
  @n 1 param = ;
  @d 0 param = ;

  # Just to be sure, assert that the denominator is not zero
  d ** 0 != d 4 + ** 0 != || "i64_udiv: denominator is zero" assert_msg ;

  if d 4 + ** 0 == {
    # The denominator is only 32 bits, so we can basically use the
    # division 64 by 32 already implemented in the processor, except
    # that we have to check that there is no overflow (which would
    # cause a trap). See the original file for proof of correctness.
    $n1
    $d0
    @n1 n 4 + ** = ;
    @d0 d ** = ;
    # Mod the numerator upper dword by the denominator
    n 4 + n1 d0 %u = ;
    # Do the 64 by 32 division
    n d0 i64_udiv_64_by_32 ;
    # Add the correction term to the upper dword
    n 4 + n 4 + ** n1 d0 /u + = ;
  } else {
    # The denominator has more than 32 bits. The trick here is
    # basically to discard the least significant bits to make it only
    # 32 bits. This (1) causes a further division by some power of 2,
    # which is easy to correct, and (2) it might introduce some
    # error. However, by the analysis in [3] (see "Unsigned Doubleword
    # Division"), the only bad thing that can happen is that the
    # result is one unit too large. So we test if there is need to fix
    # it (again, see [3] for the details and proofs).
    #  [3] http://www.hackersdelight.org/revisions.pdf
    $cmp_
    $cmp
    @cmp n i64_copy ;
    @cmp d i64_ul ;
    if cmp {
      n 0 i64_from_u32 ;
    } else {
      $d1
      @d1 d 4 + ** = ;
      $s
      @s d1 nlz = ;
      $tmp1_
      $tmp1
      $tmp2
      $tmp2_
      $one
      $one_
      @one 1 i64_from_u32 ;
      @tmp1 s i64_from_u32 ;
      $dcopy_
      $dcopy
      @dcopy d i64_copy ;
      @dcopy @tmp1 i64_shl ;
      $q_
      $q
      @q n i64_copy ;
      @q @one i64_shr ;
      @q dcopy_ i64_udiv_64_by_32 ;
      @tmp1 31 s - i64_from_u32 ;
      @q @tmp1 i64_shr ;
      @q @one i64_sub ;
      @tmp1 @q i64_copy ;
      @tmp1 d i64_mul ;
      @tmp2 @n i64_copy ;
      @tmp2 @tmp1 i64_sub ;
      @tmp2 d i64_ul ;
      if tmp2 ! {
        @q @one i64_add ;
      }
      n @q i64_copy ;
    }
  }
}

fun i64_sdiv 2 {
  $n
  $d
  @n 1 param = ;
  @d 0 param = ;

  $sign
  @sign 0 = ;
  $tmp1_
  $tmp1
  $tmp2_
  $tmp2

  @tmp1 n i64_copy ;
  if tmp1_ 0x80000000 & {
    @tmp1 i64_neg ;
    @sign sign 1 ^ = ;
  }

  @tmp2 d i64_copy ;
  if tmp2_ 0x80000000 & {
    @tmp2 i64_neg ;
    @sign sign 1 ^ = ;
  }

  # If one of the operand already has the minimum possible value, it
  # does not become positive by negation, but it becomes the right
  # thing anyway
  tmp1_ 0x80000000 & ! tmp1_ 0x80000000 == || "i64_sdiv: error 1" assert_msg ;
  tmp2_ 0x80000000 & ! tmp2_ 0x80000000 == || "i64_sdiv: error 2" assert_msg ;
  @tmp1 @tmp2 i64_udiv ;
  if sign {
    @tmp1 i64_neg ;
  }

  n @tmp1 i64_copy ;
}

fun i64_umod 2 {
  $n
  $d
  @n 1 param = ;
  @d 0 param = ;

  $tmp_
  $tmp
  @tmp n i64_copy ;
  @tmp d i64_udiv ;
  @tmp d i64_mul ;
  n @tmp i64_sub ;
}

fun i64_smod 2 {
  $n
  $d
  @n 1 param = ;
  @d 0 param = ;

  $tmp_
  $tmp
  @tmp n i64_copy ;
  @tmp d i64_sdiv ;
  @tmp d i64_mul ;
  n @tmp i64_sub ;
}

fun int64_test_one_div 2 {
  $n
  $d
  @n 1 param = ;
  @d 0 param = ;

  # "n_up: " 1 platform_log ;
  # n 4 + ** itoa 1 platform_log ;
  # "\n" 1 platform_log ;
  # "n: " 1 platform_log ;
  # n ** itoa 1 platform_log ;
  # "\n" 1 platform_log ;
  # "d_up: " 1 platform_log ;
  # d 4 + ** itoa 1 platform_log ;
  # "\n" 1 platform_log ;
  # "d: " 1 platform_log ;
  # d ** itoa 1 platform_log ;
  # "\n" 1 platform_log ;

  # Do unsigned division and mod
  $tmp1_
  $tmp1
  $tmp2_
  $tmp2
  @tmp1 n i64_copy ;
  @tmp2 n i64_copy ;
  @tmp1 d i64_udiv ;
  @tmp2 d i64_umod ;

  # "div_up: " 1 platform_log ;
  # tmp1_ itoa 1 platform_log ;
  # "\n" 1 platform_log ;
  # "div: " 1 platform_log ;
  # tmp1 itoa 1 platform_log ;
  # "\n" 1 platform_log ;
  # "mod_up: " 1 platform_log ;
  # tmp2_ itoa 1 platform_log ;
  # "\n" 1 platform_log ;
  # "mod: " 1 platform_log ;
  # tmp2 itoa 1 platform_log ;
  # "\n" 1 platform_log ;

  # Check that mod is smaller then denominator
  $tmp3_
  $tmp3
  @tmp3 @tmp2 i64_copy ;
  @tmp3 d i64_ul ;
  tmp3 "int64_test_one_div: mod is not smaller than denominator after unsigned division" assert_msg ;

  # Check that mod + div * d equals n
  @tmp3 @tmp1 i64_copy ;
  @tmp3 d i64_mul ;
  @tmp3 @tmp2 i64_add ;
  @tmp3 n i64_eq ;
  tmp3 "int64_test_one_div: unsigned division did not work" assert_msg ;

  # Do signed division and mod
  $tmp1_
  $tmp1
  $tmp2_
  $tmp2
  @tmp1 n i64_copy ;
  @tmp2 n i64_copy ;
  @tmp1 d i64_sdiv ;
  @tmp2 d i64_smod ;

  # Check that the division sign is correct
  if tmp1 0 != tmp1_ 0 != || {
    tmp1_ 0x80000000 & n 4 + ** 0x80000000 & d 4 + ** 0x80000000 & ^ == "int64_test_one_div: division sign is wrong" assert_msg ;
  }

  # Check that mod is smaller then denominator
  $tmp3_
  $tmp3
  @tmp3 @tmp2 i64_copy ;
  @tmp3 d i64_l ;
  tmp3 "int64_test_one_div: mod is not smaller than denominator after signed division" assert_msg ;

  # Check that mod is smaller then denominator
  $tmp3_
  $tmp3
  @tmp3 @tmp2 i64_copy ;
  @tmp3 i64_neg ;
  @tmp3 d i64_l ;
  tmp3 "int64_test_one_div: minus mod is not smaller than denominator after signed division" assert_msg ;

  # Check that mod + div * d equals n
  @tmp3 @tmp1 i64_copy ;
  @tmp3 d i64_mul ;
  @tmp3 @tmp2 i64_add ;
  @tmp3 n i64_eq ;
  tmp3 "int64_test_one_div: signed division did not work" assert_msg ;
}

fun int64_test_div 0 {
  $x_
  $x
  $y_
  $y

  @x_ 0x00000000 = ;
  @x 0x47295583 = ;
  @y_ 0x110 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0x00000000 = ;
  @x 0x47295583 = ;
  @y_ 0x1101223 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0x00000000 = ;
  @x 0x47295583 = ;
  @y_ 0x0 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0x00000000 = ;
  @x 0x47295583 = ;
  @y_ 0x0 = ;
  @y 0x1 = ;
  @x @y int64_test_one_div ;

  @x_ 0x10000000 = ;
  @x 0x47295583 = ;
  @y_ 0x110 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0x10000000 = ;
  @x 0x47295583 = ;
  @y_ 0x1101223 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0x10000000 = ;
  @x 0x47295583 = ;
  @y_ 0x0 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0x10000000 = ;
  @x 0x47295583 = ;
  @y_ 0x0 = ;
  @y 0x1 = ;
  @x @y int64_test_one_div ;

  @x_ 0xf0000000 = ;
  @x 0x47295583 = ;
  @y_ 0x110 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0xf0000000 = ;
  @x 0x47295583 = ;
  @y_ 0x1101223 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0xf0000000 = ;
  @x 0x47295583 = ;
  @y_ 0x0 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0xf0000000 = ;
  @x 0x47295583 = ;
  @y_ 0x0 = ;
  @y 0x1 = ;
  @x @y int64_test_one_div ;

  @x_ 0xffffffff = ;
  @x 0x47295583 = ;
  @y_ 0x110 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0xffffffff = ;
  @x 0x47295583 = ;
  @y_ 0x1101223 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0xffffffff = ;
  @x 0x47295583 = ;
  @y_ 0x0 = ;
  @y 0x2328 = ;
  @x @y int64_test_one_div ;

  @x_ 0xffffffff = ;
  @x 0x47295583 = ;
  @y_ 0x0 = ;
  @y 0x1 = ;
  @x @y int64_test_one_div ;

  "Tests for int64 division successfully passed!\n" 1 platform_log ;
}
