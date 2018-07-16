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

const FILE_DESTROY 0
const FILE_READ 4
const FILE_WRITE 8
const FILE_TRUNCATE 12

const MOUNT_DESTROY 0
const MOUNT_OPEN 4

const INITFD_DESTROY 0
const INITFD_READ 4
const INITFD_WRITE 8
const INITFD_TRUNCATE 12
const INITFD_FD 16
const SIZEOF_INITFD 20

fun initfd_destroy 1 {
  $fd
  @fd 0 param = ;
  fd free ;
}

fun initfd_read 2 {
  $fd
  @fd 0 param = ;
  fd INITFD_FD take platform_read_char ret ;
}

fun initfd_write 3 {
  0 "initfd_write: not supported" assert_msg ;
}

fun initfd_truncate 1 {
  0 "initfd_truncate: not supported" assert_msg ;
}

fun initfd_init 1 {
  $name
  @name 0 param = ;

  $fd
  @fd SIZEOF_INITFD malloc = ;
  fd INITFD_DESTROY take_addr @initfd_destroy = ;
  fd INITFD_READ take_addr @initfd_read = ;
  fd INITFD_WRITE take_addr @initfd_write = ;
  fd INITFD_TRUNCATE take_addr @initfd_truncate = ;
  fd INITFD_FD take_addr name platform_open_file = ;
  fd ret ;
}

const INITMOUNT_DESTROY 0
const INITMOUNT_OPEN 4
const SIZEOF_INITMOUNT 8

fun initmount_destroy 1 {
  $mount
  @mount 0 param = ;
  mount free ;
}

fun initmount_open 2 {
  $mount
  $name
  @mount 1 param = ;
  @name 0 param = ;

  name initfd_init ret ;
}

fun initmount_init 0 {
  $mount
  @mount SIZEOF_INITMOUNT malloc = ;
  mount INITMOUNT_DESTROY take_addr @initmount_destroy = ;
  mount INITMOUNT_OPEN take_addr @initmount_open = ;
  mount ret ;
}

const VFSINST_MOUNTS 0
const SIZEOF_VFSINST 4

fun vfsinst_init 0 {
  $vfsinst
  @vfsinst SIZEOF_VFSINST malloc = ;
  vfsinst VFSINST_MOUNTS take_addr map_init = ;
  vfsinst ret ;
}

fun vfsinst_destroy 1 {
  $vfsinst
  @vfsinst 0 param = ;

  $mounts
  @mounts vfsinst VFSINST_MOUNTS take = ;
  $i
  @i 0 = ;
  while i mounts map_size < {
    if mounts i map_has_idx {
      $mount
      @mount mounts i map_at_idx = ;
      mount mount MOUNT_DESTROY take \1 ;
    }
    @i i 1 + = ;
  }
  mounts map_destroy ;

  vfsinst free ;
}

fun vfsinst_mount 3 {
  $vfsinst
  $point
  $mount
  @vfsinst 2 param = ;
  @point 1 param = ;
  @mount 0 param = ;

  $mounts
  @mounts vfsinst VFSINST_MOUNTS take = ;
  mounts point mount map_set ;
}

$vfs

fun vfs_init 0 {
  @vfs vfsinst_init = ;
  vfs "init" initmount_init vfsinst_mount ;
}

fun vfs_destroy 0 {
  vfs vfsinst_destroy ;
}
