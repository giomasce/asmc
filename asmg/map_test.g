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

fun map_test_print_closure 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  ctx key map_has ! "map_test_print_closure: value already seen" assert_msg ;
  ctx key value map_set ;
}

fun map_test_print_closure2 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  ctx key map_has "map_test_print_closure2: value not seen" assert_msg ;
}

fun map_test 0 {
  $map
  @map map_init = ;

  $elem_num
  @elem_num 1000 = ;

  $i
  @i 0 = ;
  while i elem_num < {
    map i itoa i map_set ;
    @i i 1 + = ;
  }

  $check_map
  @check_map map_init = ;

  map @map_test_print_closure check_map map_foreach ;
  map @map_test_print_closure2 check_map map_foreach ;

  map map_size elem_num == "map_test: size unexpected" assert_msg ;
  check_map map_size elem_num == "map_test: check size unexpected" assert_msg ;

  check_map map_destroy ;
  @check_map map_init = ;

  @i 1 = ;
  while i elem_num < {
    map i itoa map_erase ;
    @i i 2 + = ;
  }

  map @map_test_print_closure check_map map_foreach ;
  map @map_test_print_closure2 check_map map_foreach ;

  map map_size elem_num 2 / == "map_test: size unexpected" assert_msg ;
  check_map map_size elem_num 2 / == "map_test: check size unexpected" assert_msg ;

  check_map map_destroy ;
  map map_destroy ;

  "Map tests successfully passed!\n" 1 platform_log ;
}
