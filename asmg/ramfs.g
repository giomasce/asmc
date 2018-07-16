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

const RAMFILE_SIZE 0
const RAMFILE_DATA 4
const SIZEOF_RAMFILE 8

fun ramfile_init 0 {
  $file
  @file SIZEOF_RAMFILE malloc = ;
  file RAMFILE_SIZE take_addr 0 = ;
  file RAMFILE_DATA take_addr 4 vector_init = ;
  file ret ;
}

fun ramfile_destroy 1 {
  $file
  @file 0 param = ;
  file RAMFILE_DATA take vector_destroy ;
  file free ;
}

fun ramfile_truncate 1 {
  $file
  @file 0 param = ;
  file RAMFILE_DATA take vector_destroy ;
  file RAMFILE_DATA take_addr 4 vector_init = ;
  file RAMFILE_SIZE take_addr 0 ;
}

fun ramfile_read 2 {
  $file
  $pos
  @file 1 param = ;
  @pos 0 param = ;
  pos file RAMFILE_SIZE take < "ramfile_read: invalid read position" assert_msg ;
  pos file RAMFILE_DATA take vector_size 4 * < "ramfile_read: error 1" assert_msg ;
  file RAMFILE_DATA take vector_data pos + **c ret ;
}

fun ramfile_write 3 {
  $file
  $pos
  $c
  @file 2 param = ;
  @pos 1 param = ;
  @c 0 param = ;
  $size
  $data
  @size file RAMFILE_SIZE take = ;
  @data file RAMFILE_DATA take = ;
  pos size <= "ramfile_write: invalid write position" assert_msg ;
  if pos size == {
    @size size 1 + = ;
    file RAMFILE_SIZE take_addr size = ;
    if pos data vector_size 4 * == {
      data 0 vector_push_back ;
    }
  }
  pos file RAMFILE_SIZE take < "ramfile_write: error 1" assert_msg ;
  pos file RAMFILE_DATA take vector_size 4 * < "ramfile_write: error 2" assert_msg ;
  file RAMFILE_DATA take vector_data pos + c =c ;
}

const RAMFS_FILES 0
const SIZEOF_RAMFS 4

fun ramfs_init 0 {
  $ram
  @ram SIZEOF_RAMFS malloc = ;
  ram RAMFS_FILES take_addr map_init = ;
  ram ret ;
}

fun ramfs_destroy 1 {
  $ram
  @ram 0 param = ;

  $files
  @files ram RAMFS_FILES take = ;
  $i
  @i 0 = ;
  while i files map_size < {
    if files i map_has_idx {
      files i map_at_idx ramfile_destroy ;
    }
    @i i 1 + = ;
  }
  files map_destroy ;

  ram free ;
}
