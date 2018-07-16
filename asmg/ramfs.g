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

const RAMFD_DESTROY 0
const RAMFD_READ 4
const RAMFD_WRITE 8
const RAMFD_TRUNCATE 12
const RAMFD_RESET 16
const RAMFD_FILE 20
const RAMFD_POS 24
const SIZEOF_RAMFD 28

fun ramfd_destroy 1 {
  $fd
  @fd 0 param = ;
  fd free ;
}

fun ramfd_read 1 {
  $fd
  @fd 0 param = ;

  $file
  $pos
  @file fd RAMFD_FILE take = ;
  @pos fd RAMFD_POS take = ;
  $c
  @c file pos ramfile_read = ;
  fd RAMFD_POS take_addr pos 1 + = ;
  c ret ;
}

fun ramfd_write 2 {
  $fd
  $c
  @fd 1 param = ;
  @c 0 param = ;

  $file
  $pos
  @file fd RAMFD_FILE take = ;
  @pos fd RAMFD_POS take = ;
  file pos c ramfile_write ;
  fd RAMFD_POS take_addr pos 1 + = ;
}

fun ramfd_truncate 1 {
  $fd
  @fd 0 param = ;

  $file
  @file fd RAMFD_FILE take = ;
  file ramfile_truncate ;
}

fun ramfd_reset 1 {
  $fd
  @fd 0 param = ;

  fd RAMFD_POS take_addr 0 = ;
}

fun ramfd_init 1 {
  $file
  @file 0 param = ;

  $fd
  @fd SIZEOF_RAMFD malloc = ;
  fd RAMFD_DESTROY take_addr @ramfd_destroy = ;
  fd RAMFD_READ take_addr @ramfd_read = ;
  fd RAMFD_WRITE take_addr @ramfd_write = ;
  fd RAMFD_TRUNCATE take_addr @ramfd_truncate = ;
  fd RAMFD_RESET take_addr @ramfd_reset = ;
  fd RAMFD_FILE take_addr file = ;
  fd RAMFD_POS take_addr 0 = ;

  fd ret ;
}

const RAMMOUNT_DESTROY 0
const RAMMOUNT_OPEN 4
const RAMMOUNT_FILES 8
const SIZEOF_RAMMOUNT 12

fun rammount_destroy 1 {
  $ram
  @ram 0 param = ;

  $files
  @files ram RAMMOUNT_FILES take = ;
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

fun rammount_open 2 {
  $mount
  $name
  @mount 1 param = ;
  @name 0 param = ;

  $files
  @files mount RAMMOUNT_FILES take = ;
  $file
  if files name map_has ! {
    @file ramfile_init = ;
    files name file map_set ;
  } else {
    @file files name map_at = ;
  }
  $fd
  @fd file ramfd_init = ;
  fd ret ;
}

fun rammount_init 0 {
  $ram
  @ram SIZEOF_RAMMOUNT malloc = ;
  ram RAMMOUNT_DESTROY take_addr @rammount_destroy = ;
  ram RAMMOUNT_OPEN take_addr @rammount_open = ;
  ram RAMMOUNT_FILES take_addr map_init = ;
  ram ret ;
}
