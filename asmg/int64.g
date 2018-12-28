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

$_int64_and
$_int64_or

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

  @_int64_and int64_runtime "int64_and" asmctx_get_symbol_addr = ;
  @_int64_or int64_runtime "int64_or" asmctx_get_symbol_addr = ;

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

fun i64_and 2 {
  1 param 0 param _int64_and \2 ;
}

fun i64_or 2 {
  1 param 0 param _int64_or \2 ;
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
  @z @y i64_and ;
  z x y & == "int64_test: error 2" assert_msg ;
  z_ x_ y_ & == "int64_test: error 3" assert_msg ;

  @z @x i64_copy ;
  @z @y i64_or ;
  z x y | == "int64_test: error 4" assert_msg ;
  z_ x_ y_ | == "int64_test: error 5" assert_msg ;

  "Tests for int64 successfully passed!\n" 1 platform_log ;
}
