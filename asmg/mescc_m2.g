# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This file was ported from files in M2-Planet,
# which has the following copyright notices:
# Copyright (C) 2016 Jeremiah Orians

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

const M2TYPE_NEXT 0       # M2TYPE*
const M2TYPE_SIZE 4       # int
const M2TYPE_OFFSET 8     # int
const M2TYPE_INDIRECT 12  # M2TYPE*
const M2TYPE_MEMBERS 16   # M2TYPE*
const M2TYPE_TYPE 20      # M2TYPE*
const M2TYPE_NAME 24      # char*
const SIZEOF_M2TYPE 28

const M2TLIST_NEXT 0      # M2TLIST*
const M2TLIST_PREV 4      # M2TLIST*
const M2TLIST_ENTRY 8     # M2TLIST*
const M2TLIST_S 8         # char*
const M2TLIST_TYPE 12     # M2TYPE*
const M2TLIST_FILENAME 12 # char*
const M2TLIST_ARGS 16     # M2TLIST*
const M2TLIST_LINENUM 16  # int
const M2TLIST_LOCALS 20   # M2TLIST*
const M2TLIST_TEMPS 24    # int
const SIZEOF_M2TLIST 28

const M2CTX_TYPES 0       # M2TYPE*
const M2CTX_TOKEN 4       # M2TLIST*
const M2CTX_STRINGS 8     # M2TLIST*
const M2CTX_GLOBALS 12    # M2TLIST*
const SIZEOF_M2CTX 16

const M2_MAX_STRING 4096
const M2_LF 10

fun m2_upcase 1 {
  $a
  @a 0 param = ;

  if 97 a <= 122 a >= && {
    @a a 32 - = ;
  }
  a ret ;
}

fun m2_hexify 2 {
  $c
  $high
  @c 1 param = ;
  @high 0 param = ;

  $i
  @i c m1_char2hex = ;
  i 0 >= "m2_hexify: tried to print non-hex number" assert_msg ;
  if high {
    @i i 4 << = ;
  }
  i ret ;
}

fun m2_weird 1 {
  $string
  @string 0 param = ;

  if string **c 0 == { 0 ret ; }
  if string **c '\\' == {
    if string 1 + **c 'x' == {
      if string 2 + **c '0' == { 1 ret ; }
      if string 2 + **c '1' == { 1 ret ; }
      if string 2 + **c '2' == {
        if string 3 + **c '2' == { 1 ret ; }
	string 3 + m2_weird ret ;
      }
      if string 2 + **c '3' == {
        if string 3 + **c 'A' == { 1 ret ; }
	string 3 + m2_weird ret ;
      }
      if string 2 + **c '8' == { 1 ret ; }
      if string 2 + **c '9' == { 1 ret ; }
      if string 2 + **c 'a' == { 1 ret ; }
      if string 2 + **c 'A' == { 1 ret ; }
      if string 2 + **c 'b' == { 1 ret ; }
      if string 2 + **c 'B' == { 1 ret ; }
      if string 2 + **c 'c' == { 1 ret ; }
      if string 2 + **c 'C' == { 1 ret ; }
      if string 2 + **c 'd' == { 1 ret ; }
      if string 2 + **c 'D' == { 1 ret ; }
      if string 2 + **c 'e' == { 1 ret ; }
      if string 2 + **c 'E' == { 1 ret ; }
      if string 2 + **c 'f' == { 1 ret ; }
      if string 2 + **c 'F' == { 1 ret ; }
      string 3 + m2_weird ret ;
    }
    if string 1 + **c 'n' == {
      if string 2 + **c ':' == { 1 ret ; }
      string 2 + m2_weird ret ;
    }
    if string 1 + **c 't' == {
      string 2 + m2_weird ret ;
    }
    if string 1 + **c '\"' == { 1 ret ; }
    string 3 + m2_weird ret ;
  }
  string 1 + m2_weird ret ;
}

fun m2_escape_lookup 1 {
  $c
  @c 0 param = ;

  if c **c '\\' == c 1 + **c 'x' == & {
    $t1
    $t2
    @t1 c 2 + **c 1 m2_hexify = ;
    @t2 c 3 + **c 0 m2_hexify = ;
    t1 t2 + ret ;
  }
  if c **c '\\' == c 1 + **c 'n' == & { 10 ret ; }
  if c **c '\\' == c 1 + **c 't' == & { 9 ret ; }
  if c **c '\\' == c 1 + **c '\\' == & { 92 ret ; }
  if c **c '\\' == c 1 + **c '\'' == & { 39 ret ; }
  if c **c '\\' == c 1 + **c '\"' == & { 34 ret ; }
  if c **c '\\' == c 1 + **c 'r' == & { 13 ret ; }

  0 "m2_escape_lookup: unknown escape received" assert_msg ;
}

fun m2_collect_regular_string 1 {
  $string
  @string 0 param = ;

  $j
  @j 0 = ;
  $i
  @i 0 = ;
  $message
  @message 1 M2_MAX_STRING calloc = ;
  message 34 =c ;
  while string j + **c 0 != {
    if string j + **c '\\' == string j + 1 + **c 'x' == & {
      message i + string j + m2_escape_lookup =c ;
      @j j 4 + = ;
    } else {
      if string j + **c '\\' == {
        message i + string j + m2_escape_lookup =c ;
	@j j 2 + = ;
      } else {
        message i + string j + **c =c ;
      }
    }
    @i i 1 + = ;
  }
  message i + 34 =c ;
  message i + 1 + M2_LF =c ;
  message ret ;
}

fun m2_collect_weird_string 1 {
  $string
  @string 0 param = ;

  $j
  @j 1 = ;
  $k
  @k 1 = ;
  $temp
  $table
  @table "0123456789ABCDEF" = ;
  $hold
  @hold M2_MAX_STRING 1 calloc = ;

  hold 39 =c ;
  while string j + **c 0 != {
    hold k + ' ' =c ;
    if string j + **c '\\' == string j + 1 + **c 'x' == & {
      hold k + 1 + string j + 2 + **c m2_upcase =c ;
      hold k + 2 + string j + 3 + **c m2_upcase =c ;
      @j j 4 + = ;
    } else {
      if string j + **c '\\' == {
        @temp string j + m2_escape_lookup = ;
	hold k + 1 + table temp 4 >> + **c =c ;
	hold k + 2 + table temp 15 & + **c =c ;
	@j j 2 + = ;
      } else {
        hold k + 1 + table string j + **c 4 >> + **c =c ;
	hold k + 2 + table string j + **c 15 & + **c =c ;
	@j j 1 + = ;
      }
      @k k 3 + = ;
    }
  }
  hold k + ' ' =c ;
  hold k + 1 + '0' =c ;
  hold k + 2 + '0' =c ;
  hold k + 3 + 39 =c ;
  hold k + 4 + M2_LF =c ;
  hold ret ;
}

fun m2_parse_string 1 {
  $string
  @string 0 param = ;

  if string m2_weird ':' string 1 + **c == || {
    string m2_collect_weird_string ret ;
  } else {
    string m2_collect_regular_string ret ;
  }
}