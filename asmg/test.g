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

# Comments
# Other comments

const LEN 1024

$glob
%array 100
%array2 LEN

ifun test 1

fun main 2 {
  $argc
  $argv
  @argc 0 param = ;
  @argv 1 param = ;
  $x
  @x argc argv + = ;
  argc test ;
  @argv argc = ;
  if x {
    @x 2 = ;
  } else {
    @x 4 = ;
  }
  while x {
    @x x 1 - = ;
  }
  @x glob = ;
  @glob x = ;
  x ret ;
  @glob LEN = ;
  @x '\n' = ;
  @x 100 = ;
  #@glob "Hello, ASM!" = ;
  #@glob "String\nwith\tescapes\"\'" = ;
}

fun test2 0 {
  0 test ;
}

fun test 1 {

}

ifun test 1
