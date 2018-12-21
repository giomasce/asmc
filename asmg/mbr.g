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

fun read_mbr 1 {
  $atapio
  @atapio 0 param = ;

  # Read MBR
  $mbr
  @mbr atapio 0 atapio_read_sect = ;

  # Check if this is an actual MBR
  $res
  if mbr 510 + **c 0x55 == mbr 511 + **c 0xaa == && {
    @res 8 vector_init = ;
    $i
    @i 0 = ;
    while i 4 < {
      $start
      $size
      @start mbr 0x1be + i 16 * + 8 + ** = ;
      @size mbr 0x1be + i 16 * + 12 + ** = ;
      if start 0 != {
        $idx
        @idx res vector_size = ;
        res start vector_push_back ;
        res idx vector_at_addr 4 + size = ;
      }
      @i i 1 + = ;
    }
  } else {
    @res 0 = ;
  }

  mbr free ;

  res ret ;
}

fun mbr_vfs_scan_drive 3 {
  $vfs
  $base
  $master
  @vfs 2 param = ;
  @base 1 param = ;
  @master 0 param = ;

  $count
  @count 1 = ;

  $a
  @a base master atapio_init = ;
  if a atapio_print_identify {
    $parts
    @parts a read_mbr = ;
    if parts 0 != {
      "Found MBR!\n" 1 platform_log ;
      $i
      @i 0 = ;
      while i parts vector_size < {
        "  Partition starting at LBA " 1 platform_log ;
        parts i vector_at itoa 1 platform_log ;
        " of size " 1 platform_log ;
        parts i vector_at_addr 4 + ** itoa 1 platform_log ;
        "\n" 1 platform_log ;

        # Read the first sector to see if there is a known file system
        $sect
        @sect a parts i vector_at atapio_read_sect = ;
        if sect ** "DISK" ** == sect 4 + ** "FS  " ** == && {
          "    Found a diskfs file system!\n" 1 platform_log ;
          $mount
          @mount a atapio_duplicate 512 parts i vector_at * diskmount_init = ;
          $point
          @point "disk" strdup count itoa append_to_str = ;
          vfs point  mount 0 "vfsinst_mount" platform_get_symbol \3 ;
          point free ;
          @count count 1 + = ;
        } else {
          if sect ** "DEBU" ** == sect 4 + ** "GFS " ** == && {
            "    Found a debugfs file system!\n" 1 platform_log ;
            $debugfs
            @debugfs a atapio_duplicate parts i vector_at parts i vector_at_addr 4 + ** debugfsinst_init = ;
            debugfs debugfs_set ;
          }
        }
        sect free ;

        @i i 1 + = ;
      }
      parts vector_destroy ;
    } else {
      "No MBR found...\n" 1 platform_log ;
    }
  }

  a atapio_destroy ;
}

fun mbr_vfs_scan 1 {
  $vfs
  @vfs 0 param = ;

  vfs 0x1f0 1 mbr_vfs_scan_drive ;
  vfs 0x1f0 0 mbr_vfs_scan_drive ;
  # vfs 0x170 1 mbr_vfs_scan_drive ;
  # vfs 0x170 0 mbr_vfs_scan_drive ;
}

fun mbr_read_test_drive 2 {
  $base
  $master
  @base 1 param = ;
  @master 0 param = ;

  $a
  @a base master atapio_init = ;
  if a atapio_print_identify {
    $parts
    @parts a read_mbr = ;
    $i
    @i 0 = ;
    while i parts vector_size < {
      "Partition starting at LBA " 1 platform_log ;
      parts i vector_at itoa 1 platform_log ;
      " of size " 1 platform_log ;
      parts i vector_at_addr 4 + ** itoa 1 platform_log ;
      "\n" 1 platform_log ;
      @i i 1 + = ;
    }
    parts vector_destroy ;
  }

  a atapio_destroy ;
}

fun mbr_read_test 0 {
  0x1f0 1 mbr_read_test_drive ;
  0x1f0 0 mbr_read_test_drive ;
  # 0x170 1 mbr_read_test_drive ;
  # 0x170 0 mbr_read_test_drive ;
}
