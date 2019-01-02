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

$_i64_from_32
$_i64_from_u32
$_i64_not
$_i64_and
$_i64_or
$_i64_xor
$_i64_lnot
$_i64_land
$_i64_lor
$_i64_add
$_i64_sub
$_i64_mul
$_i64_shl
$_i64_shr
$_i64_sar
$_i64_eq
$_i64_neq
$_i64_le
$_i64_ule
$_i64_l
$_i64_ul
$_i64_ge
$_i64_uge
$_i64_g
$_i64_ug

fun int64_init 0 {
  $int64_runtime
  $fd
  @fd "/disk1/int64/int64.asm" vfs_open = ;
  @int64_runtime asmctx_init = ;
  #int64_runtime ASMCTX_VERBOSE take_addr 0 = ;
  int64_runtime ASMCTX_DEBUG take_addr 0 = ;
  int64_runtime fd asmctx_set_fd ;
  int64_runtime asmctx_compile ;
  fd vfs_close ;

  @_i64_from_32 int64_runtime "i64_from_32" asmctx_get_symbol_addr = ;
  @_i64_from_u32 int64_runtime "i64_from_u32" asmctx_get_symbol_addr = ;
  @_i64_not int64_runtime "i64_not" asmctx_get_symbol_addr = ;
  @_i64_and int64_runtime "i64_and" asmctx_get_symbol_addr = ;
  @_i64_or int64_runtime "i64_or" asmctx_get_symbol_addr = ;
  @_i64_xor int64_runtime "i64_xor" asmctx_get_symbol_addr = ;
  @_i64_lnot int64_runtime "i64_lnot" asmctx_get_symbol_addr = ;
  @_i64_land int64_runtime "i64_land" asmctx_get_symbol_addr = ;
  @_i64_lor int64_runtime "i64_lor" asmctx_get_symbol_addr = ;
  @_i64_add int64_runtime "i64_add" asmctx_get_symbol_addr = ;
  @_i64_sub int64_runtime "i64_sub" asmctx_get_symbol_addr = ;
  @_i64_mul int64_runtime "i64_mul" asmctx_get_symbol_addr = ;
  @_i64_shl int64_runtime "i64_shl" asmctx_get_symbol_addr = ;
  @_i64_shr int64_runtime "i64_shr" asmctx_get_symbol_addr = ;
  @_i64_sar int64_runtime "i64_sar" asmctx_get_symbol_addr = ;
  @_i64_eq int64_runtime "i64_eq" asmctx_get_symbol_addr = ;
  @_i64_neq int64_runtime "i64_neq" asmctx_get_symbol_addr = ;
  @_i64_le int64_runtime "i64_le" asmctx_get_symbol_addr = ;
  @_i64_ule int64_runtime "i64_ule" asmctx_get_symbol_addr = ;
  @_i64_l int64_runtime "i64_l" asmctx_get_symbol_addr = ;
  @_i64_ul int64_runtime "i64_ul" asmctx_get_symbol_addr = ;
  @_i64_ge int64_runtime "i64_ge" asmctx_get_symbol_addr = ;
  @_i64_uge int64_runtime "i64_uge" asmctx_get_symbol_addr = ;
  @_i64_g int64_runtime "i64_g" asmctx_get_symbol_addr = ;
  @_i64_ug int64_runtime "i64_ug" asmctx_get_symbol_addr = ;

  int64_runtime asmctx_destroy ;
}

fun int64_destroy 0 {
  #int64_runtime asmctx_destroy ;
}

fun i64_init 0 {
  $i
  @i 8 malloc = ;
  i 0 = ;
  i 4 + 0 = ;
  i ret ;
}

fun i64_destroy 1 {
  0 param free ;
}

fun i64_to_32 1 {
  0 param ** ret ;
}

fun i64_to_upper32 1 {
  0 param 4 + ** ret ;
}

fun i64_copy 2 {
  $to
  $from
  @to 1 param = ;
  @from 0 param = ;

  8 from to memcpy ;
}

fun i64_from_32 2 {
  1 param 0 param _i64_from_32 \2 ;
}

fun i64_from_u32 2 {
  1 param 0 param _i64_from_u32 \2 ;
}

fun i64_not 1 {
  0 param _i64_not \1 ;
}

fun i64_and 2 {
  1 param 0 param _i64_and \2 ;
}

fun i64_or 2 {
  1 param 0 param _i64_or \2 ;
}

fun i64_xor 2 {
  1 param 0 param _i64_xor \2 ;
}

fun i64_lnot 1 {
  0 param _i64_lnot \1 ;
}

fun i64_land 2 {
  1 param 0 param _i64_land \2 ;
}

fun i64_lor 2 {
  1 param 0 param _i64_lor \2 ;
}

fun i64_add 2 {
  1 param 0 param _i64_add \2 ;
}

fun i64_sub 2 {
  1 param 0 param _i64_sub \2 ;
}

fun i64_mul 2 {
  1 param 0 param _i64_mul \2 ;
}

fun i64_shl 2 {
  1 param 0 param _i64_shl \2 ;
}

fun i64_shr 2 {
  1 param 0 param _i64_shr \2 ;
}

fun i64_sar 2 {
  1 param 0 param _i64_sar \2 ;
}

fun i64_eq 2 {
  1 param 0 param _i64_eq \2 ;
}

fun i64_neq 2 {
  1 param 0 param _i64_neq \2 ;
}

fun i64_le 2 {
  1 param 0 param _i64_le \2 ;
}

fun i64_ule 2 {
  1 param 0 param _i64_ule \2 ;
}

fun i64_l 2 {
  1 param 0 param _i64_l \2 ;
}

fun i64_ul 2 {
  1 param 0 param _i64_ul \2 ;
}

fun i64_ge 2 {
  1 param 0 param _i64_ge \2 ;
}

fun i64_uge 2 {
  1 param 0 param _i64_uge \2 ;
}

fun i64_g 2 {
  1 param 0 param _i64_g \2 ;
}

fun i64_ug 2 {
  1 param 0 param _i64_ug \2 ;
}

fun int64_test_comparison 0 {
  $numbers

  $i
  $j

  # First fill it with unsigned numbers, in order
  @numbers 8 vector_init = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 0 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 1 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 100 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 0 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 1 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 1 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 1 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 100 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 1 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 0 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 100 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 1 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 100 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 100 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 100 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 0 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0xf0000000 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 1 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0xf0000000 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 100 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0xf0000000 = ;

  # Then do all possible pairwise comparisons
  @i 0 = ;
  while i numbers vector_size < {
    @j 0 = ;
    $y_
    $y
    @y numbers i vector_at_addr i64_copy ;
    while j numbers vector_size < {
      $x_
      $x

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_eq ;
      x_ 0 == "int64_test_comparison: error 1" assert_msg ;
      x j i == == "int64_test_comparison: error 2" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_neq ;
      x_ 0 == "int64_test_comparison: error 3" assert_msg ;
      x j i != == "int64_test_comparison: error 4" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_ul ;
      x_ 0 == "int64_test_comparison: error 5" assert_msg ;
      x j i < == "int64_test_comparison: error 6" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_ule ;
      x_ 0 == "int64_test_comparison: error 7" assert_msg ;
      x j i <= == "int64_test_comparison: error 8" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_ug ;
      x_ 0 == "int64_test_comparison: error 9" assert_msg ;
      x j i > == "int64_test_comparison: error 10" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_uge ;
      x_ 0 == "int64_test_comparison: error 11" assert_msg ;
      x j i >= == "int64_test_comparison: error 12" assert_msg ;

      @j j 1 + = ;
    }
    @i i 1 + = ;
  }

  numbers vector_destroy ;

  # Then again with signed numbers
  @numbers 8 vector_init = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 0 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0xf0000000 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 1 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0xf0000000 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 100 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0xf0000000 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 0 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 1 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 100 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 0 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 0 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 1 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 1 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 1 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 100 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 1 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 0 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 100 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 1 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 100 = ;
  numbers 0 vector_push_back ;
  numbers numbers vector_size 1 - vector_at_addr 100 = ;
  numbers numbers vector_size 1 - vector_at_addr 4 + 100 = ;

  # Then do all possible pairwise comparisons
  @i 0 = ;
  while i numbers vector_size < {
    @j 0 = ;
    $y_
    $y
    @y numbers i vector_at_addr i64_copy ;
    while j numbers vector_size < {
      $x_
      $x

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_eq ;
      x_ 0 == "int64_test_comparison: error 13" assert_msg ;
      x j i == == "int64_test_comparison: error 14" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_neq ;
      x_ 0 == "int64_test_comparison: error 15" assert_msg ;
      x j i != == "int64_test_comparison: error 16" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_l ;
      x_ 0 == "int64_test_comparison: error 17" assert_msg ;
      x j i < == "int64_test_comparison: error 18" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_le ;
      x_ 0 == "int64_test_comparison: error 19" assert_msg ;
      x j i <= == "int64_test_comparison: error 20" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_g ;
      x_ 0 == "int64_test_comparison: error 21" assert_msg ;
      x j i > == "int64_test_comparison: error 22" assert_msg ;

      @x numbers j vector_at_addr i64_copy ;
      @x @y i64_ge ;
      x_ 0 == "int64_test_comparison: error 23" assert_msg ;
      x j i >= == "int64_test_comparison: error 24" assert_msg ;

      @j j 1 + = ;
    }
    @i i 1 + = ;
  }

  numbers vector_destroy ;
}

fun int64_test 0 {
  $x_
  $x
  $y_
  $y
  $z_
  $z
  @x_ 0x45e5910e = ;
  @x 0xf38dc508 = ;
  @y_ 0x6f271c9a = ;
  @y 0x3c5af0de = ;

  @z @x i64_copy ;
  @z @x i64_eq "int64_test: error 1" assert_msg ;

  @z @x i64_copy ;
  @z i64_not ;
  z x ~ == "int64_test: error 2" assert_msg ;
  z_ x_ ~ == "int64_test: error 3" assert_msg ;

  @z @x i64_copy ;
  @z @y i64_and ;
  z x y & == "int64_test: error 4" assert_msg ;
  z_ x_ y_ & == "int64_test: error 5" assert_msg ;

  @z @x i64_copy ;
  @z @y i64_or ;
  z x y | == "int64_test: error 6" assert_msg ;
  z_ x_ y_ | == "int64_test: error 7" assert_msg ;

  @z @x i64_copy ;
  @z @y i64_xor ;
  z x y ^ == "int64_test: error 6" assert_msg ;
  z_ x_ y_ ^ == "int64_test: error 7" assert_msg ;

  @x 0 = ;
  @x_ 0 = ;
  @x i64_lnot ;
  x 1 == "int64_test: error 8" assert_msg ;
  x_ 0 == "int64_test: error 9" assert_msg ;

  @x 0x5555 = ;
  @x_ 0 = ;
  @x i64_lnot ;
  x 0 == "int64_test: error 10" assert_msg ;
  x_ 0 == "int64_test: error 11" assert_msg ;

  @x 0 = ;
  @x_ 1 = ;
  @x i64_lnot ;
  x 0 == "int64_test: error 12" assert_msg ;
  x_ 0 == "int64_test: error 13" assert_msg ;

  @x 0 = ;
  @x_ 0 = ;
  @y 0 = ;
  @y_ 0 = ;
  @x @y i64_land ;
  x 0 == "int64_test: error 14" assert_msg ;
  x_ 0 == "int64_test: error 15" assert_msg ;

  @x 0 = ;
  @x_ 123 = ;
  @y 0 = ;
  @y_ 0 = ;
  @x @y i64_land ;
  x 0 == "int64_test: error 16" assert_msg ;
  x_ 0 == "int64_test: error 17" assert_msg ;

  @x 0 = ;
  @x_ 123 = ;
  @y 456 = ;
  @y_ 0 = ;
  @x @y i64_land ;
  x 1 == "int64_test: error 18" assert_msg ;
  x_ 0 == "int64_test: error 19" assert_msg ;

  @x 0 = ;
  @x_ 0 = ;
  @y 0 = ;
  @y_ 0 = ;
  @x @y i64_lor ;
  x 0 == "int64_test: error 20" assert_msg ;
  x_ 0 == "int64_test: error 21" assert_msg ;

  @x 0 = ;
  @x_ 123 = ;
  @y 0 = ;
  @y_ 0 = ;
  @x @y i64_lor ;
  x 1 == "int64_test: error 22" assert_msg ;
  x_ 0 == "int64_test: error 23" assert_msg ;

  @x 0 = ;
  @x_ 123 = ;
  @y 456 = ;
  @y_ 0 = ;
  @x @y i64_lor ;
  x 1 == "int64_test: error 24" assert_msg ;
  x_ 0 == "int64_test: error 25" assert_msg ;

  @x 0 = ;
  @x_ 123 = ;
  @y 456 = ;
  @y_ 0 = ;
  @x @y i64_add ;
  x 456 == "int64_test: error 26" assert_msg ;
  x_ 123 == "int64_test: error 27" assert_msg ;

  @x 0x80001234 = ;
  @x_ 0 = ;
  @y 0x84560000 = ;
  @y_ 0 = ;
  @x @y i64_add ;
  x 0x4561234 == "int64_test: error 28" assert_msg ;
  x_ 1 == "int64_test: error 29" assert_msg ;

  @x 0 = ;
  @x_ 1 = ;
  @y 0x123 = ;
  @y_ 0 = ;
  @x @y i64_sub ;
  x 0 0x123 - == "int64_test: error 30" assert_msg ;
  x_ 0 == "int64_test: error 31" assert_msg ;

  @x 0x12312745 = ;
  @x_ 0x2137 = ;
  @y 0x3445 = ;
  @y_ 0 = ;
  @x @y i64_mul ;
  x 0xe3399999 == "int64_test: error 32" assert_msg ;
  x_ 0x6c82389 == "int64_test: error 33" assert_msg ;

  @y 0x12312745 = ;
  @y_ 0x2137 = ;
  @x 0x3445 = ;
  @x_ 0 = ;
  @x @y i64_mul ;
  x 0xe3399999 == "int64_test: error 34" assert_msg ;
  x_ 0x6c82389 == "int64_test: error 35" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x12345678 = ;
  @y 0x8 = ;
  @y_ 0 = ;
  @x @y i64_shl ;
  x 0x34567800 == "int64_test: error 36" assert_msg ;
  x_ 0x34567812 == "int64_test: error 37" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x12345678 = ;
  @y 0x24 = ;
  @y_ 0 = ;
  @x @y i64_shl ;
  x 0 == "int64_test: error 38" assert_msg ;
  x_ 0x23456780 == "int64_test: error 39" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x12345678 = ;
  @y 0x8 = ;
  @y_ 0 = ;
  @x @y i64_shr ;
  x 0x78123456 == "int64_test: error 40" assert_msg ;
  x_ 0x00123456 == "int64_test: error 41" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x12345678 = ;
  @y 0x24 = ;
  @y_ 0 = ;
  @x @y i64_shr ;
  x 0x01234567 == "int64_test: error 42" assert_msg ;
  x_ 0 == "int64_test: error 43" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x92345678 = ;
  @y 0x8 = ;
  @y_ 0 = ;
  @x @y i64_shr ;
  x 0x78123456 == "int64_test: error 44" assert_msg ;
  x_ 0x00923456 == "int64_test: error 45" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x92345678 = ;
  @y 0x24 = ;
  @y_ 0 = ;
  @x @y i64_shr ;
  x 0x09234567 == "int64_test: error 46" assert_msg ;
  x_ 0 == "int64_test: error 47" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x12345678 = ;
  @y 0x8 = ;
  @y_ 0 = ;
  @x @y i64_sar ;
  x 0x78123456 == "int64_test: error 48" assert_msg ;
  x_ 0x00123456 == "int64_test: error 49" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x12345678 = ;
  @y 0x24 = ;
  @y_ 0 = ;
  @x @y i64_sar ;
  x 0x01234567 == "int64_test: error 50" assert_msg ;
  x_ 0 == "int64_test: error 51" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x92345678 = ;
  @y 0x8 = ;
  @y_ 0 = ;
  @x @y i64_sar ;
  x 0x78123456 == "int64_test: error 52" assert_msg ;
  x_ 0xff923456 == "int64_test: error 53" assert_msg ;

  @x 0x12345678 = ;
  @x_ 0x92345678 = ;
  @y 0x24 = ;
  @y_ 0 = ;
  @x @y i64_sar ;
  x 0xf9234567 == "int64_test: error 54" assert_msg ;
  x_ 0xffffffff == "int64_test: error 55" assert_msg ;

  int64_test_comparison ;

  "Tests for int64 successfully passed!\n" 1 platform_log ;
}
