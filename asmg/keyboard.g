# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2019 Giovanni Mascellani <gio@debian.org>
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

# This simple keyboard driver is inspired by pc_kbd.c in iPXE

$kbd_status

const KBD_SHIFT 1
const KBD_CTRL 2
const KBD_CAPS 4

fun kbd_get_scancode 0 {
  if 0x64 inb 1 & ! {
    0 ret ;
  }

  $scan
  @scan 0x60 inb = ;

  if scan 0x2a == scan 0x36 == || {
    @kbd_status kbd_status KBD_SHIFT | = ;
  }
  if scan 0xaa == scan 0xb6 == || {
    @kbd_status kbd_status KBD_SHIFT ~ & = ;
  }
  if scan 0x1d == {
    @kbd_status kbd_status KBD_CTRL | = ;
  }
  if scan 0x9d == {
    @kbd_status kbd_status KBD_CTRL ~ & = ;
  }
  if scan 0x3a == {
    @kbd_status kbd_status KBD_CAPS ^ = ;
  }

  if scan 0x80 & {
    0 ret ;
  }
  scan ret ;
}

fun kbd_maybe_getc 0 {
  $scan
  @scan kbd_get_scancode = ;

  if scan 0 == {
    0 ret ;
  }
  if scan 0x54 >= {
    0 ret ;
  }

  # Convert scan code to character
  $c
  if kbd_status KBD_SHIFT & ! {
    @c "\0\01234567890-=\0\tqwertyuiop[]\n\0asdfghjkl;\'`\0\\zxcvbnm,./\0*\0 \0\0\0\0\0\0\0\0\0\0\0\0\0789-456+1230." scan + **c = ;
  } else {
    @c "\0\0!@#$%^&*()_+\0\tQWERTYUIOP{}\n\0ASDFGHJKL:\"~\0|ZXCVBNM<>?\0\0\0 \0\0\0\0\0\0\0\0\0\0\0\0\0789-456+1230." scan + **c = ;
  }

  # Fix some characters that cannot be represented into a string
  if scan 0x01 == {
    @c 0x1b = ;
  }
  if scan 0x0e == {
    @c 0x08 = ;
  }

  # If caps lock is on, invert lower and upper case
  if kbd_status KBD_CAPS & {
    if 'A' c <= c 'Z' <= && 'a' c <= c 'z' <= && || {
      @c c 'A' ^ 'a' ^ = ;
    }
  }

  c ret ;
}

fun kbd_getc 0 {
  while 1 {
    $c
    @c kbd_maybe_getc = ;

   if c {
      c ret ;
    }
  }
}
