# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
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

fun c_strtoll 2 {
  $s
  $end
  @s 1 param = ;
  @end 0 param = ;

  $base
  @base 10 = ;
  $value
  @value i64_init = ;
  $pos
  @pos 0 = ;

  $c
  @c s pos + **c = ;
  if c '0' == {
    @pos pos 1 + = ;
    @c s pos + **c = ;
    if c 'x' == c 'X' == || {
      @base 16 = ;
      @pos pos 1 + = ;
    } else {
      @base 8 = ;
    }
  }

  $long_base
  @long_base i64_init = ;
  long_base base i64_from_u32 ;
  $long_digit
  @long_digit i64_init = ;

  $cont
  @cont 1 = ;
  while cont {
    $stop
    @stop 1 = ;
    @c s pos + **c = ;
    $digit

    if '0' c <= c '9' <= && {
      @digit c '0' - = ;
      @stop 0 = ;
    }

    if 'a' c <= c 'f' <= && {
      @digit c 'a' - 10 + = ;
      @stop 0 = ;
    }

    if 'A' c <= c 'F' <= && {
      @digit c 'A' - 10 + = ;
      @stop 0 = ;
    }

    if stop {
      @cont 0 = ;
    } else {
      digit base < "c_strtoll: invalid digit for current base" digit base assert_msg_int_int ;
      long_digit digit i64_from_u32 ;
      value long_base i64_mul ;
      value long_digit i64_add ;
      @pos pos 1 + = ;
    }
  }

  long_base i64_destroy ;
  long_digit i64_destroy ;
  end s pos + = ;

  value ret ;
}
