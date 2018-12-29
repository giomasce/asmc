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

$_i64_not
$_i64_and
$_i64_or
$_i64_xor
$_i64_lnot
$_i64_land
$_i64_lor

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

  @_i64_not int64_runtime "i64_not" asmctx_get_symbol_addr = ;
  @_i64_and int64_runtime "i64_and" asmctx_get_symbol_addr = ;
  @_i64_or int64_runtime "i64_or" asmctx_get_symbol_addr = ;
  @_i64_xor int64_runtime "i64_xor" asmctx_get_symbol_addr = ;
  @_i64_lnot int64_runtime "i64_lnot" asmctx_get_symbol_addr = ;
  @_i64_land int64_runtime "i64_land" asmctx_get_symbol_addr = ;
  @_i64_lor int64_runtime "i64_lor" asmctx_get_symbol_addr = ;

  int64_runtime asmctx_destroy ;
}

fun int64_destroy 0 {
  #int64_runtime asmctx_destroy ;
}

fun i64_copy 2 {
  $to
  $from
  @to 1 param = ;
  @from 0 param = ;

  8 from to memcpy ;
}

fun i64_eq 2 {
  $x
  $y
  @x 1 param = ;
  @y 0 param = ;

  x ** y ** == x 4 + ** y 4 + ** == && ret ;
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

  "Tests for int64 successfully passed!\n" 1 platform_log ;
}
