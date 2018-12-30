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

fun test_print_closure 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  key 1 platform_log ;
  ": " 1 platform_log ;
  value itoa 1 platform_log ;
  "\n" 1 platform_log ;
}

fun map_test 0 {
  $map
  @map map_init = ;
  map "one" 1 map_set ;
  map "two" 2 map_set ;
  map "three" 3 map_set ;
  map @test_print_closure 0 map_foreach ;
  map map_destroy ;
}
