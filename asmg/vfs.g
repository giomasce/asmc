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

const SEEK_SET 0
const SEEK_CUR 1
const SEEK_END 2

const FD_DESTROY 0
const FD_READ 4
const FD_WRITE 8
const FD_TRUNCATE 12
const FD_SEEK 16

const MOUNT_DESTROY 0
const MOUNT_OPEN 4

const INITFD_DESTROY 0
const INITFD_READ 4
const INITFD_WRITE 8
const INITFD_TRUNCATE 12
const INITFD_SEEK 16
const INITFD_FD 20
const SIZEOF_INITFD 24

fun initfd_destroy 1 {
  $fd
  @fd 0 param = ;
  fd free ;
}

fun initfd_read 1 {
  $fd
  @fd 0 param = ;
  fd INITFD_FD take platform_read_char ret ;
}

fun initfd_write 2 {
  0 "initfd_write: not supported" assert_msg ;
}

fun initfd_truncate 1 {
  0 "initfd_truncate: not supported" assert_msg ;
}

fun initfd_seek 3 {
  $fd
  $off
  $whence
  @fd 2 param = ;
  @off 1 param = ;
  @whence 0 param = ;

  if whence SEEK_SET == off 0 == && {
    fd INITFD_FD take platform_reset_file ;
    0 ret ;
  }

  0 "initfd_seek: unsupported seek" assert_msg ;
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
  fd INITFD_SEEK take_addr @initfd_seek = ;
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

  "Mounting file system /" 1 platform_log ;
  point 1 platform_log ;
  "\n" 1 platform_log ;

  $mounts
  @mounts vfsinst VFSINST_MOUNTS take = ;
  mounts point mount map_set ;
}

fun find_slash 1 {
  $s
  @s 0 param = ;
  $t
  @t s = ;
  while 1 {
    $c
    @c t **c = ;
    if c 0 == c '/' == || {
      t s - ret ;
    }
    @t t 1 + = ;
  }
}

fun vfsinst_open 2 {
  $vfsinst
  $name
  @vfsinst 1 param = ;
  @name 0 param = ;

  name **c '/' == "vfsinst_open: missing initial slash" assert_msg ;
  @name name 1 + = ;
  $mountname
  @mountname name strdup = ;
  $slash_pos
  @slash_pos mountname find_slash = ;
  mountname slash_pos + **c '/' == "vfsinst_open: missing mountpoint slash" assert_msg ;
  mountname slash_pos + 0 =c ;
  $mountpath
  @mountpath mountname slash_pos + 1 + = ;

  $mount
  mount vfsinst VFSINST_MOUNTS take mountname map_has "vfsinst_open: mount point does not exist" assert_msg ;
  @mount vfsinst VFSINST_MOUNTS take mountname map_at = ;
  $res
  @res mount mountpath mount MOUNT_OPEN take \2 = ;

  mountname free ;

  res ret ;
}

$vfs

fun vfs_init 0 {
  @vfs vfsinst_init = ;
  vfs "init" initmount_init vfsinst_mount ;
  vfs "ram" rammount_init vfsinst_mount ;
  vfs mbr_vfs_scan ;
}

fun vfs_destroy 0 {
  vfs vfsinst_destroy ;
}

fun vfs_open 1 {
  $name
  @name 0 param = ;
  vfs name vfsinst_open ret ;
}

fun vfs_close 1 {
  $fd
  @fd 0 param = ;
  fd fd FD_DESTROY take \1 ;
}

fun vfs_read 1 {
  $fd
  @fd 0 param = ;
  fd fd FD_READ take \1 ret ;
}

fun vfs_write 2 {
  $fd
  $c
  @fd 1 param = ;
  @c 0 param = ;

  fd c fd FD_WRITE take \1 ;
}

fun vfs_truncate 1 {
  $fd
  @fd 0 param = ;
  fd fd FD_TRUNCATE take \1 ;
}

fun vfs_seek 3 {
  $fd
  $off
  $whence
  @fd 2 param = ;
  @off 1 param = ;
  @whence 0 param = ;

  fd off whence fd FD_SEEK take \3 ret ;
}

fun vfs_reset 1 {
  $fd
  @fd 0 param = ;
  fd 0 SEEK_SET vfs_seek ;
}
