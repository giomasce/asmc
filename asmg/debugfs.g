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

const DEBUGFS_ATAPIO 0
const DEBUGFS_START 4
const DEBUGFS_END 8
const DEBUGFS_POS 12
const DEBUGFS_BUF 16
const DEBUGFS_BUF_POS 20
const SIZEOF_DEBUGFS 24

fun debugfsinst_init 3 {
  $atapio
  $start
  $size
  @atapio 2 param = ;
  @start 1 param = ;
  @size 0 param = ;

  $debugfs
  @debugfs SIZEOF_DEBUGFS malloc = ;
  debugfs DEBUGFS_ATAPIO take_addr atapio = ;
  debugfs DEBUGFS_START take_addr start = ;
  debugfs DEBUGFS_END take_addr start size + = ;
  debugfs DEBUGFS_POS take_addr start 1 + = ;
  debugfs DEBUGFS_BUF take_addr 0 = ;
  debugfs ret ;
}

fun debugfsinst_destroy 1 {
  $debugfs
  @debugfs 0 param = ;

  debugfs DEBUGFS_ATAPIO take atapio_destroy ;
  debugfs DEBUGFS_BUF take free ;
  debugfs free ;
}

fun debugfsinst_begin_file 2 {
  $debugfs
  $filename
  @debugfs 1 param = ;
  @filename 0 param = ;

  debugfs DEBUGFS_BUF take 0 == "debugfsinst_begin_file: already in file" assert_msg ;
  debugfs DEBUGFS_BUF take_addr 512 1 calloc = ;
  debugfs DEBUGFS_BUF_POS take_addr 0 = ;

  filename strlen 511 < "debugfsinst_begin_file: filename too long" assert_msg ;
  $sector
  @sector 512 1 calloc = ;
  filename sector strcpy ;
  debugfs DEBUGFS_POS take debugfs DEBUGFS_END take != "debugfsinst_begin_file: partition limit exceeded" assert_msg ;
  debugfs DEBUGFS_ATAPIO take debugfs DEBUGFS_POS take sector atapio_write_sect ;
  sector free ;
  debugfs DEBUGFS_POS take_addr debugfs DEBUGFS_POS take 1 + = ;
}

fun _debugfsinst_flush_buffer 1 {
  $debugfs
  @debugfs 0 param = ;

  debugfs DEBUGFS_BUF take 0 != "_debugfsinst_flush_buffer: not in file" assert_msg ;
  debugfs DEBUGFS_POS take debugfs DEBUGFS_END take != "_debugfsinst_flush_buffer: partition limit exceeded" assert_msg ;
  debugfs DEBUGFS_ATAPIO take debugfs DEBUGFS_POS take debugfs DEBUGFS_BUF take atapio_write_sect ;
  debugfs DEBUGFS_BUF take free ;
  debugfs DEBUGFS_BUF take_addr 512 1 calloc = ;
  debugfs DEBUGFS_BUF_POS take_addr 0 = ;
  debugfs DEBUGFS_POS take_addr debugfs DEBUGFS_POS take 1 + = ;
}

fun debugfsinst_write_char 2 {
  $debugfs
  $c
  @debugfs 1 param = ;
  @c 0 param = ;

  debugfs DEBUGFS_BUF take debugfs DEBUGFS_BUF_POS take + c =c ;
  debugfs DEBUGFS_BUF_POS take_addr debugfs DEBUGFS_BUF_POS take 1 + = ;
  if debugfs DEBUGFS_BUF_POS take 512 == {
    debugfs _debugfsinst_flush_buffer ;
  }
}

fun debugfsinst_finish_file 1 {
  $debugfs
  @debugfs 0 param = ;

  debugfs DEBUGFS_BUF take 0 != "debugfsinst_finish_file: not in file" assert_msg ;
  if debugfs DEBUGFS_BUF_POS take 0 != {
    debugfs _debugfsinst_flush_buffer ;
  }

  # Write an empty sector
  debugfs '\0' debugfsinst_write_char ;
  debugfs _debugfsinst_flush_buffer ;

  debugfs DEBUGFS_BUF take free ;
  debugfs DEBUGFS_BUF take_addr 0 = ;
}

$global_debugfs

fun debugfs_set 1 {
  $debugfs
  @debugfs 0 param = ;

  if global_debugfs {
    global_debugfs debugfsinst_destroy ;
  }
  @global_debugfs debugfs = ;
}

fun debugfs_deinit 0 {
  0 debugfs_set ;
}

fun debugfs_begin_file 1 {
  $filename
  @filename 0 param = ;

  if global_debugfs {
    global_debugfs filename debugfsinst_begin_file ;
  }
}

fun debugfs_write_char 1 {
  $c
  @c 0 param = ;

  if global_debugfs {
    global_debugfs c debugfsinst_write_char ;
  }
}

fun debugfs_finish_file 0 {
  if global_debugfs {
    global_debugfs debugfsinst_finish_file ;
  }
}
