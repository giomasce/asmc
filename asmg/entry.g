# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018-2019 Giovanni Mascellani <gio@debian.org>
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

const TERM_ROW_NUM 25
const TERM_COL_NUM 80
const TERM_BASE_ADDR 0xb8000

$term_row
$term_col

# See https://wiki.osdev.org/Text_Mode_Cursor
fun term_set_cursor 0 {
  $pos
  @pos term_col term_row TERM_COL_NUM * + = ;
  0x3d4 0x0f outb ;
  0x3d5 pos 0xff & outb ;
  0x3d4 0x0e outb ;
  0x3d5 pos 8 >> 0xff & outb ;
}

fun term_setup 0 {
  $i
  @i 0 = ;
  while i TERM_ROW_NUM TERM_COL_NUM * < {
    TERM_BASE_ADDR 2 i * + ' ' =c ;
    TERM_BASE_ADDR 2 i * + 1 + 0x07 =c ;
    @i i 1 + = ;
  }
  @term_row 0 = ;
  @term_col 0 = ;
  term_set_cursor ;
}

fun term_shift 0 {
  $i
  @i 0 = ;
  # Copy data one row up
  while i TERM_ROW_NUM 1 - TERM_COL_NUM * < {
    TERM_BASE_ADDR 2 i * + TERM_BASE_ADDR 2 i * + 2 TERM_COL_NUM * + **c =c ;
    TERM_BASE_ADDR 2 i * + 1 + TERM_BASE_ADDR 2 i * + 2 TERM_COL_NUM * + 1 + **c =c ;
    @i i 1 + = ;
  }
  # Clear last row
  while i TERM_ROW_NUM TERM_COL_NUM * < {
    TERM_BASE_ADDR 2 i * + ' ' =c ;
    TERM_BASE_ADDR 2 i * + 1 + 0x07 =c ;
    @i i 1 + = ;
  }
}

fun term_write 1 {
  $c
  @c 0 param = ;

  $newline
  @newline 0 = ;
  if c '\n' == {
    @newline 1 = ;
  } else {
    TERM_BASE_ADDR term_row TERM_COL_NUM * term_col + 2 * + c =c ;
    @term_col term_col 1 + = ;
    if term_col TERM_COL_NUM == {
      @newline 1 = ;
    }
  }

  if newline {
    @term_col 0 = ;
    @term_row term_row 1 + = ;
    if term_row TERM_ROW_NUM == {
      @term_row term_row 1 - = ;
      term_shift ;
    }
  }

  term_set_cursor ;
}

const SERIAL_PORT 0x3f8

# Send command as indicated in https://wiki.osdev.org/Serial_Port
fun serial_setup 0 {
  SERIAL_PORT 1 + 0x00 outb ;
  SERIAL_PORT 3 + 0x80 outb ;
  SERIAL_PORT 0 + 0x03 outb ;
  SERIAL_PORT 1 + 0x00 outb ;
  SERIAL_PORT 3 + 0x03 outb ;
  SERIAL_PORT 2 + 0xc7 outb ;
  SERIAL_PORT 4 + 0x0b outb ;
}

fun serial_write 1 {
  $c
  @c 0 param = ;

  while SERIAL_PORT 5 + inb 0x20 & ! { }
  SERIAL_PORT c outb ;
}

fun serial_maybe_read 0 {
  if SERIAL_PORT 5 + inb 0x01 & ! {
    0 ret ;
  }

  $c
  @c SERIAL_PORT inb = ;
  c ret ;
}

fun serial_read 0 {
  while 1 {
    $c
    @c serial_maybe_read = ;

    if c {
      c ret ;
    }
  }
}

fun write 1 {
  $c
  @c 0 param = ;

  c term_write ;
  c serial_write ;
}

fun log 1 {
  $s
  @s 0 param = ;

  while s **c '\0' != {
   s **c write ;
   @s s 1 + = ;
  }
}

const ITOA_BUF_LEN 32

$_itoa_buf_ptr

fun itoa_setup 0 {
  @_itoa_buf_ptr ITOA_BUF_LEN platform_allocate = ;
}

fun itoa 1 {
  $n
  @n 0 param = ;

  # Setup position pointer and write a terminator at the end
  $pos
  @pos _itoa_buf_ptr ITOA_BUF_LEN + 1 - = ;
  pos '\0' =c ;
  @pos pos 1 - = ;

  # Handle the zero case
  if n 0 == {
    pos '0' =c ;
    pos ret ;
  }

  # Recursively compute quotient and remainder to write down the digits
  while n 0 != {
    pos n 10 % '0' + =c ;
    @pos pos 1 - = ;
    @n n 10 / = ;
  }

  pos 1 + ret ;
}

fun entry 0 {
  serial_setup ;
  term_setup ;
  itoa_setup ;

  "Hello, G!\n" log ;

  "Compiling main.g... " log ;
  "main.g" platform_g_compile ;
  "done!\n" log ;

  "Entering main program!\n" log ;
  0 "main" platform_get_symbol \0 ;
}
