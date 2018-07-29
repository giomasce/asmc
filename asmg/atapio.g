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

const ATAPIO_PORT_DATA 0
const ATAPIO_PORT_FEATURES_ERROR 1
const ATAPIO_PORT_SECTOR_COUNT 2
const ATAPIO_PORT_LBA_LO 3
const ATAPIO_PORT_LBA_MID 4
const ATAPIO_PORT_LBA_HI 5
const ATAPIO_PORT_DRIVE 6
const ATAPIO_PORT_COMMAND 7

const ATAPIO_BASE 0
const ATAPIO_MASTER 4
const SIZEOF_ATAPIO 8

fun atapio_init 2 {
  $base
  $master
  @base 1 param = ;
  @master 0 param = ;

  $a
  @a SIZEOF_ATAPIO malloc = ;
  a ATAPIO_BASE take_addr base = ;
  a ATAPIO_MASTER take_addr master = ;
  a ret ;
}

fun atapio_destroy 1 {
  $a
  @a 0 param = ;
  a free ;
}

fun _atapio_poll 1 {
  $a
  @a 0 param = ;

  $base
  @base a ATAPIO_BASE take = ;

  # Ignore the first four reads
  base ATAPIO_PORT_COMMAND + inb ;
  base ATAPIO_PORT_COMMAND + inb ;
  base ATAPIO_PORT_COMMAND + inb ;
  base ATAPIO_PORT_COMMAND + inb ;

  while 1 {
    $status
    @status base ATAPIO_PORT_COMMAND + inb = ;
    status 0x01 & ! "_atapio_poll: ERR is set" assert_msg ;
    status 0x20 & ! "_atapio_poll: DF is set" assert_msg ;
    if status 0x08 & status 0x80 & ! && { 1 ret ; }
  }
}

fun _atapio_in_sector 1 {
  $a
  @a 0 param = ;

  $base
  @base a ATAPIO_BASE take = ;
  $i
  @i 0 = ;
  $buf
  @buf 512 malloc = ;
  while i 256 < {
    $bytes
    @bytes base ATAPIO_PORT_DATA + inw = ;
    buf 2 i * + @bytes **c =c ;
    buf 2 i * + 1 + @bytes 1 + **c =c ;
    @i i 1 + = ;
  }

  # Discard four status reads
  base ATAPIO_PORT_COMMAND + inb ;
  base ATAPIO_PORT_COMMAND + inb ;
  base ATAPIO_PORT_COMMAND + inb ;
  base ATAPIO_PORT_COMMAND + inb ;

  buf ret ;
}

fun atapio_identify 1 {
  $a
  @a 0 param = ;

  $base
  $master
  @base a ATAPIO_BASE take = ;
  @master a ATAPIO_MASTER take = ;
  if master {
    base ATAPIO_PORT_DRIVE + 0xa0 outb ;
  } else {
    base ATAPIO_PORT_DRIVE + 0xb0 outb ;
  }
  base ATAPIO_PORT_SECTOR_COUNT + 0 outb ;
  base ATAPIO_PORT_LBA_LO + 0 outb ;
  base ATAPIO_PORT_LBA_MID + 0 outb ;
  base ATAPIO_PORT_LBA_HI + 0 outb ;
  base ATAPIO_PORT_COMMAND + 0xec outb ;

  while 1 {
    $status
    @status base ATAPIO_PORT_COMMAND + inb = ;
    if status 0 == {
      0 ret ;
    }

    # Wait for BSY (busy) to clear
    if status 0x80 & ! {
      # Check for noncompliant implementations
      if base ATAPIO_PORT_LBA_MID + inb 0 != {
        0 ret ;
      }
      if base ATAPIO_PORT_LBA_HI + inb 0 != {
        0 ret ;
      }

      # Check for ERR (error)
      status 0x01 & ! "atapio_identify: drive returned an error" assert_msg ;

      # Check for DRQ (drive is ready)
      if status 0x08 & {
        $data
        @data a _atapio_in_sector = ;
        # The following checks are useful when usin LBA48
        #data 2 83 * + 1 + **c 0x04 & "atapio_print_idenfity: 48 bits address not supported" assert_msg ;
        #data 2 102 * + **c 0 == "atapio_print_identify: drive is too big" assert_msg ;
        #data 2 102 * + 1 + **c 0 == "atapio_print_identify: drive is too big" assert_msg ;
        #data 2 103 * + **c 0 == "atapio_print_identify: drive is too big" assert_msg ;
        #data 2 103 * + 1 + **c 0 == "atapio_print_identify: drive is too big" assert_msg ;
        data ret ;
      }
    }
  }
}

fun atapio_read_sect 2 {
  $a
  $lba
  @a 1 param = ;
  @lba 0 param = ;

  $base
  $master
  @base a ATAPIO_BASE take = ;
  @master a ATAPIO_MASTER take = ;

  # 28 bits request
  lba 0xf0000000 & 0 == "atapio_read_sect: sector number exceeds 28 bits" assert_msg ;
  if master {
    base ATAPIO_PORT_DRIVE + 0xe0 lba 24 >> | outb ;
  } else {
    base ATAPIO_PORT_DRIVE + 0xf0 lba 24 >> | outb ;
  }
  #base ATAPIO_PORT_FEATURES_ERROR + 0 outb ;
  base ATAPIO_PORT_SECTOR_COUNT + 1 outb ;
  base ATAPIO_PORT_LBA_LO + lba outb ;
  base ATAPIO_PORT_LBA_MID + lba 8 >> outb ;
  base ATAPIO_PORT_LBA_HI + lba 16 >> outb ;
  base ATAPIO_PORT_COMMAND + 0x20 outb ;

  # 48 bits request
  # if master {
  #   base ATAPIO_PORT_DRIVE + 0x40 outb ;
  # } else {
  #   base ATAPIO_PORT_DRIVE + 0x50 outb ;
  # }
  # base ATAPIO_PORT_SECTOR_COUNT + 0 outb ;
  # base ATAPIO_PORT_LBA_LO + lba 24 >> outb ;
  # base ATAPIO_PORT_LBA_MID + 0 outb ;
  # base ATAPIO_PORT_LBA_HI + 0 outb ;
  # base ATAPIO_PORT_SECTOR_COUNT + 1 outb ;
  # base ATAPIO_PORT_LBA_LO + lba outb ;
  # base ATAPIO_PORT_LBA_MID + lba 8 >> outb ;
  # base ATAPIO_PORT_LBA_HI + lba 16 >> outb ;
  # base ATAPIO_PORT_COMMAND + 0x24 outb ;

  a _atapio_poll ;

  a _atapio_in_sector ret ;
}

fun atapio_print_identify 1 {
  $a
  @a 0 param = ;

  $data
  @data a atapio_identify = ;
  if data 0 == {
    "Drive does not exist (or it is not ATA)\n" 1 platform_log ;
    0 ret ;
  }

  # "ATA IDENTIFY result:\n" 1 platform_log ;
  # data 512 dump_mem ;
  # "\n" 1 platform_log ;

  "Model number: " 1 platform_log ;
  $i
  @i 27 = ;
  while i 47 < {
    data 2 i * + 1 + **c 1 platform_write_char ;
    data 2 i * + **c 1 platform_write_char ;
    @i i 1 + = ;
  }
  "\n" 1 platform_log ;

  "Serial number: " 1 platform_log ;
  $i
  @i 10 = ;
  while i 20 < {
    data 2 i * + 1 + **c 1 platform_write_char ;
    data 2 i * + **c 1 platform_write_char ;
    @i i 1 + = ;
  }
  "\n" 1 platform_log ;

  "Firmware revision: " 1 platform_log ;
  $i
  @i 23 = ;
  while i 27 < {
    data 2 i * + 1 + **c 1 platform_write_char ;
    data 2 i * + **c 1 platform_write_char ;
    @i i 1 + = ;
  }
  "\n" 1 platform_log ;

  $size
  @size data 2 60 * + ** = ;
  "Drive has " 1 platform_log ;
  size itoa 1 platform_log ;
  " sectors\n" 1 platform_log ;

  data free ;

  1 ret ;
}

fun atapio_test_drive 2 {
  $base
  $master
  @base 1 param = ;
  @master 0 param = ;

  $a
  @a base master atapio_init = ;
  if a atapio_print_identify {
    "First sector:\n" 1 platform_log ;
    $data
    @data a 0 atapio_read_sect = ;
    data 512 dump_mem ;
    data free ;
    "\n" 1 platform_log ;
  }

  a atapio_destroy ;
}

fun atapio_test 0 {
  0x1f0 1 atapio_test_drive ;
  0x1f0 0 atapio_test_drive ;
  0x170 1 atapio_test_drive ;
  0x170 0 atapio_test_drive ;
}
