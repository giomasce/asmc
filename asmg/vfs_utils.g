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

fun dump_file 1 {
  $name
  @name 0 param = ;

  $fd
  @fd name vfs_open = ;
  while 1 {
    $c
    @c fd vfs_read = ;
    if c 0xffffffff == {
      fd vfs_close ;
      ret ;
    }
    c 1 platform_write_char ;
  }
}

fun dump_hex_file 1 {
  $name
  @name 0 param = ;

  $fd
  @fd name vfs_open = ;
  while 1 {
    $c
    @c fd vfs_read = ;
    if c 0xffffffff == {
      fd vfs_close ;
      ret ;
    }
    c dump_byte ;
  }
}

fun dump_debug 1 {
  $name
  @name 0 param = ;

  "--DUMP-- " log ;
  name log ;
  "\n" log ;
  name dump_hex_file ;
  "\n--END_DUMP--\n" log ;
}

fun vfs_write_string 2 {
  $fd
  $s
  @fd 1 param = ;
  @s 0 param = ;

  while s **c 0 != {
    fd s **c vfs_write ;
    @s s 1 + = ;
  }
}
