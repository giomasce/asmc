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

const DISKFD_DESTROY 0
const DISKFD_READ 4
const DISKFD_WRITE 8
const DISKFD_TRUNCATE 12
const DISKFD_SEEK 16
const DISKFD_POS 20
const DISKFD_ATAPIO 24
const DISKFD_SIZE 28
const DISKFD_START 32
const DISKFD_CACHE 36
const SIZEOF_DISKFD 40

fun diskfd_destroy 1 {
  $fd
  @fd 0 param = ;

  fd DISKFD_CACHE take free ;
  fd free ;
}

fun diskfd_read 1 {
  $fd
  @fd 0 param = ;

  fd DISKFD_POS take fd DISKFD_SIZE take <= "diskfd_read: invalid read position" assert_msg ;
  if fd DISKFD_POS take fd DISKFD_SIZE take == {
    0xffffffff ret ;
  }
  $pos
  @pos fd DISKFD_POS take fd DISKFD_START take + = ;
  $sect_pos
  @sect_pos pos 512 % = ;
  $cache
  @cache fd DISKFD_CACHE take = ;
  if cache 0 == {
    $sect_num
    @sect_num pos 512 / = ;
    $atapio
    @atapio fd DISKFD_ATAPIO take = ;
    @cache atapio sect_num atapio_read_sect = ;
    fd DISKFD_CACHE take_addr cache = ;
  }
  $c
  @c cache sect_pos + **c = ;
  if sect_pos 511 == {
    cache free ;
    fd DISKFD_CACHE take_addr 0 = ;
  }
  fd DISKFD_POS take_addr fd DISKFD_POS take 1 + = ;
  # "Read char " 1 platform_log ;
  # c itoa 1 platform_log ;
  # "\n" 1 platform_log ;
  c ret ;
}

fun diskfd_write 2 {
  $fd
  $c
  @fd 1 param = ;
  @c 0 param = ;

  0 "diskfd_write: not supported" assert_msg ;
}

fun diskfd_truncate 1 {
  $fd
  @fd 0 param = ;

  0 "diskfd_truncate: not supported" assert_msg ;
}

fun diskfd_seek 3 {
  $fd
  $off
  $whence
  @fd 2 param = ;
  @off 1 param = ;
  @whence 0 param = ;

  $size
  @size fd DISKFD_SIZE take = ;
  if whence 1 == {
    @off off fd DISKFD_POS take + = ;
  }
  if whence 2 == {
    @off off size + = ;
  }
  if off size > {
    @off size = ;
  }

  fd DISKFD_POS take_addr off  = ;
  fd DISKFD_CACHE take free ;
  fd DISKFD_CACHE take_addr 0 = ;

  off ret ;
}

fun diskfd_init 3 {
  $atapio
  $start
  $size
  @atapio 2 param = ;
  @start 1 param = ;
  @size 0 param = ;

  $fd
  @fd SIZEOF_DISKFD malloc = ;
  fd DISKFD_DESTROY take_addr @diskfd_destroy = ;
  fd DISKFD_READ take_addr @diskfd_read = ;
  fd DISKFD_WRITE take_addr @diskfd_write = ;
  fd DISKFD_TRUNCATE take_addr @diskfd_truncate = ;
  fd DISKFD_SEEK take_addr @diskfd_seek = ;
  fd DISKFD_POS take_addr 0 = ;
  fd DISKFD_ATAPIO take_addr atapio = ;
  fd DISKFD_START take_addr start = ;
  fd DISKFD_SIZE take_addr size = ;
  fd DISKFD_CACHE take_addr 0 = ;

  fd ret ;
}

const DISKMOUNT_DESTROY 0
const DISKMOUNT_OPEN 4
const DISKMOUNT_ATAPIO 8
const DISKMOUNT_STARTS 12
const DISKMOUNT_SIZES 16
const SIZEOF_DISKMOUNT 20

fun diskmount_destroy 1 {
  $disk
  @disk 0 param = ;

  disk DISKMOUNT_STARTS take map_destroy ;
  disk DISKMOUNT_SIZES take map_destroy ;
  disk DISKMOUNT_ATAPIO take atapio_destroy ;
  disk free ;
}

fun diskmount_open 2 {
  $disk
  $name
  @disk 1 param = ;
  @name 0 param = ;

  if disk DISKMOUNT_STARTS take name map_has ! {
    0 ret ;
  }

  disk DISKMOUNT_SIZES take name map_has "diskmount_open: error 1" assert_msg ;
  disk DISKMOUNT_ATAPIO take disk DISKMOUNT_STARTS take name map_at disk DISKMOUNT_SIZES take name map_at diskfd_init ret ;
}

fun diskmount_init 2 {
  $atapio
  $start
  @atapio 1 param = ;
  @start 0 param = ;

  $disk
  @disk SIZEOF_DISKMOUNT malloc = ;
  disk DISKMOUNT_DESTROY take_addr @diskmount_destroy = ;
  disk DISKMOUNT_OPEN take_addr @diskmount_open = ;
  disk DISKMOUNT_ATAPIO take_addr atapio = ;
  disk DISKMOUNT_STARTS take_addr map_init = ;
  disk DISKMOUNT_SIZES take_addr map_init = ;

  # Parse the file table
  $fd
  @fd atapio start 0x7fffffff diskfd_init = ;

  # Discard the first eight byte (magic number)
  $i
  @i 0 = ;
  while i 8 < {
    fd diskfd_read ;
    @i i 1 + = ;
  }

  $cont
  @cont 1 = ;
  while cont {
    # Scan the filename
    $filename
    $cap
    $len
    @cap 10 = ;
    @len 0 = ;
    @filename cap malloc = ;
    $cont2
    @cont2 1 = ;
    while cont2 {
      if len cap == {
        @cap cap 2 * = ;
        @filename cap filename realloc = ;
      }
      len cap < "diskmount_init: error 1" assert_msg ;
      $c
      @c fd diskfd_read =c ;
      filename len + c =c ;
      if c 0 == {
        @cont2 0 = ;
      } else {
        @len len 1 + = ;
      }
    }

    if len 0 == {
      filename free ;
      @cont 0 = ;
    } else {
      # Read the position
      $pos
      @pos fd diskfd_read = ;
      @pos pos 8 << fd diskfd_read + = ;
      @pos pos 8 << fd diskfd_read + = ;
      @pos pos 8 << fd diskfd_read + = ;

      # Read the size
      $size
      @size fd diskfd_read = ;
      @size size 8 << fd diskfd_read + = ;
      @size size 8 << fd diskfd_read + = ;
      @size size 8 << fd diskfd_read + = ;

      # Store data in tables
      disk DISKMOUNT_STARTS take filename map_has ! "diskmount_init: duplicated file name" assert_msg ;
      disk DISKMOUNT_SIZES take filename map_has ! "diskmount_init: error 2" assert_msg ;
      disk DISKMOUNT_STARTS take filename start pos + map_set ;
      disk DISKMOUNT_SIZES take filename size map_set ;
      disk DISKMOUNT_STARTS take filename map_has "diskmount_init: error 3" assert_msg ;
      disk DISKMOUNT_SIZES take filename map_has "diskmount_init: error 4" assert_msg ;

      # Debug log
      # "File " 1 platform_log ;
      # filename 1 platform_log ;
      # " at position " 1 platform_log ;
      # pos itoa 1 platform_log ;
      # " of size " 1 platform_log ;
      # size itoa 1 platform_log ;
      # "\n" 1 platform_log ;

      filename free ;
    }
  }

  fd diskfd_destroy ;

  disk ret ;
}
