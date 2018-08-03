# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This file was ported from files in M2-Planet,
# which have the following copyright notices:
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

# Globals defined in cc.h
const M2CTX_GLOBAL_TYPES 0    # M2TYPE*
const M2CTX_GLOBAL_TOKEN 4    # M2TLIST*
const M2CTX_STRINGS_LIST 8    # M2TLIST*
const M2CTX_GLOBALS_LIST 12   # M2TLIST*
# Globals defined in cc_types.c
const M2CTX_MEMBER_SIZE 16    # int
# Globals defined in cc_reader.c
const M2CTX_INPUT 20          # FILE*
const M2CTX_TOKEN 24          # M2TLIST*
const M2CTX_LINE 28           # int
const M2CTX_FILE 32           # char*
const M2CTX_STRING_INDEX 36   # int
# Globals defined in cc_core.c
const M2CTX_GLOBAL_SYMBOL_LIST 40    # M2TLIST*
const M2CTX_GLOBAL_FUNCTION_LIST 44  # M2TLIST*
const M2CTX_GLOBAL_CONSTANT_LIST 48  # M2TLIST*
const M2CTX_BREAK_LOCALS 52          # M2TLIST*
const M2CTX_CURRENT_TARGET 56        # M2TYPE*
const M2CTX_BREAK_TARGET_HEAD 60     # char*
const M2CTX_BREAK_TARGET_FUNC 64     # char*
const M2CTX_BREAK_TARGET_NUM 68      # char*
const M2CTX_CURRENT_FUNCTION 72      # char*
const M2CTX_CURRENT_COUNT    76      # int
const M2CTX_LAST_TYPE 80             # M2TYPE*
const SIZEOF_M2CTX 84

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
	@j j 1 + = ;
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
    }
    @k k 3 + = ;
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

fun m2_initialize_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx M2CTX_GLOBAL_TYPES take_addr 1 SIZEOF_M2TYPE calloc = ;
  ctx M2CTX_GLOBAL_TYPES take M2TYPE_NAME take_addr "void" = ;
  ctx M2CTX_GLOBAL_TYPES take M2TYPE_SIZE take_addr 4 = ;
  ctx M2CTX_GLOBAL_TYPES take M2TYPE_TYPE take_addr ctx M2CTX_GLOBAL_TYPES take = ;
  ctx M2CTX_GLOBAL_TYPES take M2TYPE_INDIRECT take_addr ctx M2CTX_GLOBAL_TYPES take = ;

  $a
  @a 1 SIZEOF_M2TYPE calloc = ;
  a M2TYPE_NAME take_addr "int" = ;
  a M2TYPE_SIZE take_addr 4 = ;
  a M2TYPE_INDIRECT take_addr a = ;
  a M2TYPE_TYPE take_addr a = ;

  $b
  @b 1 SIZEOF_M2TYPE calloc = ;
  b M2TYPE_NAME take_addr "char*" = ;
  b M2TYPE_SIZE take_addr 4 = ;
  b M2TYPE_TYPE take_addr b = ;

  $c
  @c 1 SIZEOF_M2TYPE calloc = ;
  c M2TYPE_NAME take_addr "char" = ;
  c M2TYPE_SIZE take_addr 1 = ;
  c M2TYPE_TYPE take_addr c = ;

  c M2TYPE_INDIRECT take_addr b = ;
  b M2TYPE_INDIRECT take_addr c = ;

  $d
  @d 1 SIZEOF_M2TYPE calloc = ;
  d M2TYPE_NAME take_addr "FILE" = ;
  d M2TYPE_SIZE take_addr 4 = ;
  d M2TYPE_TYPE take_addr d = ;
  d M2TYPE_INDIRECT take_addr d = ;

  $e
  @e 1 SIZEOF_M2TYPE calloc = ;
  e M2TYPE_NAME take_addr "FUNCTION" = ;
  e M2TYPE_SIZE take_addr 4 = ;
  e M2TYPE_TYPE take_addr e = ;
  e M2TYPE_INDIRECT take_addr e = ;

  $f
  @f 1 SIZEOF_M2TYPE calloc = ;
  f M2TYPE_NAME take_addr "unsigned" = ;
  f M2TYPE_SIZE take_addr 4 = ;
  f M2TYPE_TYPE take_addr f = ;
  f M2TYPE_INDIRECT take_addr f = ;

  e M2TYPE_NEXT take_addr f = ;
  d M2TYPE_NEXT take_addr e = ;
  c M2TYPE_NEXT take_addr d = ;
  a M2TYPE_NEXT take_addr c = ;
  ctx M2CTX_GLOBAL_TYPES take M2TYPE_NEXT take_addr a = ;
}

fun m2_lookup_type 2 {
  $ctx
  $s
  @ctx 1 param = ;
  @s 0 param = ;

  $i
  @i ctx M2CTX_GLOBAL_TYPES take = ;
  while i 0 != {
    if i M2TYPE_NAME take s strcmp 0 == {
      i ret ;
    }
    @i i M2TYPE_NEXT take = ;
  }
  0 ret ;
}

ifun m2_type_name 1

fun m2_build_member 3 {
  $ctx
  $last
  $offset
  @ctx 2 param = ;
  @last 1 param = ;
  @offset 0 param = ;

  $member_type
  @member_type ctx m2_type_name = ;
  $i
  @i 1 SIZEOF_M2TYPE calloc = ;
  i M2TYPE_NAME take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take = ;
  i M2TYPE_MEMBERS take_addr last = ;
  i M2TYPE_SIZE take_addr member_type M2TYPE_SIZE take = ;
  ctx M2CTX_MEMBER_SIZE take_addr member_type M2TYPE_SIZE take = ;
  i M2TYPE_TYPE take_addr member_type = ;
  i M2TYPE_OFFSET take_addr offset = ;
  i ret ;
}

ifun m2_require_match 3

fun m2_build_union 3 {
  $ctx
  $last
  $offset
  @ctx 2 param = ;
  @last 1 param = ;
  @offset 0 param = ;

  $size
  @size 0 = ;
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  ctx "m2_build_union: missing {" "{" m2_require_match ;
  while '}' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c != {
    @last ctx last offset m2_build_member = ;
    if ctx M2CTX_MEMBER_SIZE take size > {
      @size ctx M2CTX_MEMBER_SIZE take = ;
    }
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    ctx "m2_build_token: missing ;" ";" m2_require_match ;
  }
  ctx M2CTX_MEMBER_SIZE take_addr size = ;
  last ret ;
}

fun m2_create_struct 1 {
  $ctx
  @ctx 0 param = ;

  $offset
  @offset 0 = ;
  $head
  @head 1 SIZEOF_M2TYPE calloc = ;
  $i
  @i 1 SIZEOF_M2TYPE calloc = ;
  head M2TYPE_NAME take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take = ;
  i M2TYPE_NAME take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take = ;
  head M2TYPE_INDIRECT take_addr i = ;
  i M2TYPE_INDIRECT take_addr head = ;
  head M2TYPE_NEXT take_addr ctx M2CTX_GLOBAL_TYPES take = ;
  ctx M2CTX_GLOBAL_TYPES take_addr head = ;
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  i M2TYPE_SIZE take_addr 4 = ;
  ctx "m2_create_struct: missing {" "{" m2_require_match ;

  $last
  @last 0 = ;
  while '}' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c != {
    if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take "union" strcmp 0 == {
      @last ctx last offset m2_build_union = ;
    } else {
      @last ctx last offset m2_build_member = ;
    }
    @offset offset ctx M2CTX_MEMBER_SIZE take + = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    ctx "m2_create_struct: missing ;" ";" m2_require_match ;
  }
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  ctx "m2_create_struct: missing ; at the end" ";" m2_require_match ;
  head M2TYPE_SIZE take_addr offset = ;
  head M2TYPE_MEMBERS take_addr last = ;
  head M2TYPE_INDIRECT take M2TYPE_MEMBERS take_addr last = ;
}

fun m2_type_name 1 {
  $ctx
  @ctx 0 param = ;

  $structure
  @structure 0 = ;
  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take "struct" strcmp 0 == {
    @structure 1 = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  }
  $r
  @r ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take m2_lookup_type = ;
  r 0 == structure ! && ! "m2_type_name: unknown type" assert_msg ;
  if r 0 == {
    ctx m2_create_struct ;
    0 ret ;
  }
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  while ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '*' == {
    @r r M2TYPE_INDIRECT take = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  }
  r ret ;
}

fun m2_require_match 3 {
  $ctx
  $message
  $required
  @ctx 2 param = ;
  @message 1 param = ;
  @required 0 param = ;

  ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take required strcmp 0 == message assert_msg ;
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
}

fun m2_clear_white_space 2 {
  $ctx
  $c
  @ctx 1 param = ;
  @c 0 param = ;

  if 32 c == 9 c == || {
    ctx ctx M2CTX_INPUT take vfs_read m2_clear_white_space ret ;
  }
  if 10 c == {
    ctx M2CTX_LINE take_addr ctx M2CTX_LINE take 1 + = ;
    ctx ctx M2CTX_INPUT take vfs_read m2_clear_white_space ret ;
  }
  c ret ;
}

fun m2_consume_byte 3 {
  $ctx
  $current
  $c
  @ctx 2 param = ;
  @current 1 param = ;
  @c 0 param = ;

  current M2TLIST_S take ctx M2CTX_STRING_INDEX take + c =c ;
  ctx M2CTX_STRING_INDEX take_addr ctx M2CTX_STRING_INDEX take 1 + = ;
  ctx M2CTX_INPUT take vfs_read ret ;
}

fun m2_consume_word 4 {
  $ctx
  $current
  $c
  $frequent
  @ctx 3 param = ;
  @current 2 param = ;
  @c 1 param = ;
  @frequent 0 param = ;

  $escape
  @escape 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    if escape ! '\\' c == && {
      @escape 1 = ;
    } else {
      @escape 0 = ;
    }
    @c ctx current c m2_consume_byte = ;
    @cont escape c frequent != || = ;
  }
  ctx M2CTX_INPUT take vfs_read ret ;
}

fun m2_fixup_label 2 {
  $ctx
  $current
  @ctx 1 param = ;
  @current 0 param = ;

  $hold
  @hold ':' = ;
  $prev
  $i
  @i 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    @prev hold = ;
    @hold current M2TLIST_S take i + **c = ;
    current M2TLIST_S take i + prev =c ;
    @i i 1 + = ;
    @cont 0 hold != = ;
  }
}

fun m2_preserve_keyword 3 {
  $ctx
  $current
  $c
  @ctx 2 param = ;
  @current 1 param = ;
  @c 0 param = ;

  while 'a' c <= c 'z' <= & 'A' c <= c 'Z' <= & | '0' c <= c '9' <= & | c '_' == | {
    @c ctx current c m2_consume_byte = ;
  }
  if c ':' == {
    ctx current m2_fixup_label ;
    32 ret ;
  }
  c ret ;
}

fun m2_preserve_symbol 3 {
  $ctx
  $current
  $c
  @ctx 2 param = ;
  @current 1 param = ;
  @c 0 param = ;

  while c '<' == c '=' == | c '>' == | c '|' == | c '&' == | c '!' == | c '-' == | {
    @c ctx current c m2_consume_byte = ;
  }
  c ret ;
}

fun m2_purge_macro 2 {
  $ctx
  $ch
  @ctx 1 param = ;
  @ch 0 param = ;

  while 10 ch != {
    @ch ctx M2CTX_INPUT take vfs_read = ;
  }
  ch ret ;
}

fun m2_get_token 2 {
  $ctx
  $c
  @ctx 1 param = ;
  @c 0 param = ;

  $current
  @current 1 SIZEOF_M2TLIST calloc = ;
  current M2TLIST_S take_addr 1 M2_MAX_STRING calloc = ;

  $cont
  @cont 1 = ;
  while cont {
    @cont 0 = ;
    $processed
    @processed 0 = ;
    ctx M2CTX_STRING_INDEX take_addr 0 = ;
    @c ctx c m2_clear_white_space = ;
    if c '#' == processed ! && {
      @c ctx c m2_purge_macro = ;
      @cont 1 = ;
      @processed 1 = ;
    }
    if 'a' c <= c 'z' <= & 'A' c <= c 'Z' <= & | '0' c <= c '9' <= & | c '_' == | processed ! && {
      @c ctx current c m2_preserve_keyword = ;
      @processed 1 = ;
    }
    if c '<' == c '=' == | c '>' == | c '|' == | c '&' == | c '!' == | c '-' == | processed ! && {
      @c ctx current c m2_preserve_symbol = ;
      @processed 1 = ; 
    }
    if c 39 == processed ! && {
      @c ctx current c 39 m2_consume_word = ;
      @processed 1 = ; 
    }
    if c '"' == processed ! && {
      @c ctx current c '"' m2_consume_word = ;
      @processed 1 = ;
    }
    if c '/' == processed ! && {
      @c ctx current c m2_consume_byte = ;
      if c '*' == {
        @c ctx M2CTX_INPUT take vfs_read = ;
        while c '/' != {
          while c '*' != {
    	    @c ctx M2CTX_INPUT take vfs_read = ;
    	    if c 10 == {
    	      ctx M2CTX_LINE take_addr ctx M2CTX_LINE take 1 + = ;
    	    }
    	  }
    	  @c ctx M2CTX_INPUT take vfs_read = ;
    	  if c 10 == {
    	    ctx M2CTX_LINE take_addr ctx M2CTX_LINE take 1 + = ;
    	  }
        }
    	@c ctx M2CTX_INPUT take vfs_read = ;
    	@cont 1 = ;
      } else {
        if c '/' == {
          @c ctx M2CTX_INPUT take vfs_read = ;
    	  @cont 1 = ;
    	}
      }
      @processed 1 = ;
    }
    if c 0 < processed ! && {
      current free ;
      c ret ;
    }
    if processed ! {
      @c ctx current c m2_consume_byte = ;
    }
  }

  current M2TLIST_PREV take_addr ctx M2CTX_TOKEN take = ;
  current M2TLIST_NEXT take_addr ctx M2CTX_TOKEN take = ;
  current M2TLIST_LINENUM take_addr ctx M2CTX_LINE take = ;
  current M2TLIST_FILENAME take_addr ctx M2CTX_FILE take = ;
  ctx M2CTX_TOKEN take_addr current = ;
  c ret ;
}

fun m2_reverse_list 1 {
  $head
  @head 0 param = ;

  $root
  @root 0 = ;
  while head 0 != {
    $next
    @next head M2TLIST_NEXT take = ;
    head M2TLIST_NEXT take_addr root = ;
    @root head = ;
    @head next = ;
  }
  root ret ;
}

fun m2_read_all_tokens 4 {
  $ctx
  $a
  $current
  $filename
  @ctx 3 param = ;
  @a 2 param = ;
  @current 1 param = ;
  @filename 0 param = ;

  ctx M2CTX_INPUT take_addr a = ;
  ctx M2CTX_LINE take_addr 1 = ;
  ctx M2CTX_FILE take_addr filename = ;
  ctx M2CTX_TOKEN take_addr current = ;
  $ch
  @ch ctx M2CTX_INPUT take vfs_read = ;
  while 0xffffffff ch != {
    @ch ctx ch m2_get_token = ;
  }
  ctx M2CTX_TOKEN take ret ;
}

fun m2_emit 3 {
  $ctx
  $s
  $head
  @ctx 2 param = ;
  @s 1 param = ;
  @head 0 param = ;

  $t
  @t 1 SIZEOF_M2TLIST calloc = ;
  t M2TLIST_NEXT take_addr head = ;
  t M2TLIST_S take_addr s = ;
  t ret ;
}

fun m2_sym_declare 4 {
  $ctx
  $s
  $t
  $list
  @ctx 3 param = ;
  @s 2 param = ;
  @t 1 param = ;
  @list 0 param = ;

  $a
  @a 1 SIZEOF_M2TLIST calloc = ;
  a M2TLIST_NEXT take_addr list = ;
  a M2TLIST_S take_addr s = ;
  a M2TLIST_TYPE take_addr t = ;
  a ret ;
}

fun m2_sym_lookup 3 {
  $ctx
  $s
  $symbol_list
  @ctx 2 param = ;
  @s 1 param = ;
  @symbol_list 0 param = ;

  $i
  @i symbol_list = ;
  while i 0 != {
    if i M2TLIST_S take s strcmp 0 == {
      i ret ;
    }
    @i i M2TLIST_NEXT take = ;
  }
  0 ret ;
}

fun m2_stack_index 3 {
  $ctx
  $a
  $function
  @ctx 2 param = ;
  @a 1 param = ;
  @function 0 param = ;

  $depth
  @depth 4 function M2TLIST_TEMPS take * = ;
  $i
  @i function M2TLIST_LOCALS take = ;
  while i 0 != {
    if i a == {
      depth ret ;
    } else {
      @depth depth 4 + = ;
    }
    @i i M2TLIST_NEXT take = ;
  }

  @depth depth 4 + = ;

  @i function M2TLIST_ARGS take = ;
  while i 0 != {
    if i a == {
      if "main" function M2TLIST_S take strcmp 0 == {
        if "argc" i M2TLIST_S take strcmp 0 == {
	  depth 4 - ret ;
	} else {
	  if "argv" i M2TLIST_S take strcmp 0 == {
	    depth 4 + ret ;
	  }
	}
      }
      depth ret ;
    } else {
      @depth depth 4 + = ;
    }
    @i i M2TLIST_NEXT take = ;
  }
  0 "m2_stack_index: symbol does not exist" assert_msg ;
}

ifun m2_expression 3

fun m2_numerate_number 1 {
  $a
  @a 0 param = ;

  $result
  @result 16 1 calloc = ;
  $i
  @i 0 = ;

  if 0 a == {
    result '0' =c ;
    result 1 + 10 =c ;
    result ret ;
  }
  if 0 a > {
    result '-' =c ;
    @i 1 = ;
    @a 0 a - = ;
  }

  $divisor
  @divisor 0x3b9aca00 = ;
  while a divisor / 0 == {
    @divisor divisor 10 / = ;
  }

  while 0 divisor < {
    result i + a divisor / 48 + =c ;
    @a a divisor % = ;
    @divisor divisor 10 / = ;
    @i i 1 + = ;
  }

  result ret ;
}

fun m2_function_call 5 {
  $ctx
  $out
  $function
  $s
  $bool
  @ctx 4 param = ;
  @out 3 param = ;
  @function 2 param = ;
  @s 1 param = ;
  @bool 0 param = ;

  ctx "m2_function_call: no ( was found" "(" m2_require_match ;
  $passed
  @passed 0 = ;
  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c ')' != {
    @out ctx out function m2_expression = ;
    @out ctx "PUSH_eax\t#_process_expression1\n" out m2_emit = ;
    function M2TLIST_TEMPS take_addr function M2TLIST_TEMPS take 1 + = ;
    @passed 1 = ;
    while ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c ',' == {
      ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
      @out ctx out function m2_expression = ;
      @out ctx "PUSH_eax\t#_process_expression2\n" out m2_emit = ;
      function M2TLIST_TEMPS take_addr function M2TLIST_TEMPS take 1 + = ;
      @passed passed 1 + = ;
    }
  }

  ctx "m2_function_call: no ) was found" ")" m2_require_match ;

  if bool 2 == {
    $a
    @a ctx s function M2TLIST_LOCALS take m2_sym_lookup = ;
    @out ctx "LOAD_EFFECTIVE_ADDRESS %" out m2_emit = ;
    @out ctx ctx a function m2_stack_index m2_numerate_number out m2_emit = ;
    @out ctx "\nLOAD_INTEGER\nCALL_eax\n" out m2_emit = ;
  } else {
    if bool 1 == {
      $a
      @a ctx s function M2TLIST_ARGS take m2_sym_lookup = ;
      @out ctx "LOAD_EFFECTIVE_ADDRESS %" out m2_emit = ;
      @out ctx ctx a function m2_stack_index m2_numerate_number out m2_emit = ;
      @out ctx "\nLOAD_INTEGER\nCALL_eax\n" out m2_emit = ;
    } else {
      @out ctx "CALL_IMMEDIATE %FUNCTION_" out m2_emit = ;
      @out ctx s out m2_emit = ;
      @out ctx "\n" out m2_emit = ;
    }
  }

  while passed 0 > {
    @out ctx "POP_ebx\t# _process_expression_locals\n" out m2_emit = ;
    function M2TLIST_TEMPS take_addr function M2TLIST_TEMPS take 1 - = ;
    @passed passed 1 - = ;
  }

  out ret ;
}

fun m2_sym_get_value 4 {
  $ctx
  $s
  $out
  $function
  @ctx 3 param = ;
  @s 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  $a
  @a ctx s ctx M2CTX_GLOBAL_CONSTANT_LIST take m2_sym_lookup = ;
  if a 0 != {
    @out ctx "LOAD_IMMEDIATE_eax %" out m2_emit = ;
    @out ctx a M2TLIST_ARGS take M2TLIST_S take out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    out ret ;
  }

  @a ctx s function M2TLIST_LOCALS take m2_sym_lookup = ;
  if a 0 != {
    if "FUNCTION" a M2TLIST_TYPE take M2TYPE_NAME take strcmp 0 == {
      if "(" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! {
        @out ctx "#Loading address of function\nLOAD_EFFECTIVE_ADDRESS %" out m2_emit = ;
	@out ctx ctx a function m2_stack_index m2_numerate_number out m2_emit = ;
	@out ctx "\nLOAD_INTEGER\n" out m2_emit = ;
	out ret ;
      }
      ctx out function s 2 m2_function_call ret ;
    }
    ctx M2CTX_CURRENT_TARGET take_addr a M2TLIST_TYPE take = ;
    @out ctx "LOAD_EFFECTIVE_ADDRESS %" out m2_emit = ;
    @out ctx ctx a function m2_stack_index m2_numerate_number out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    if "=" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! {
      @out ctx "LOAD_INTEGER\n" out m2_emit = ;
    }
    out ret ;
  }

  @a ctx s function M2TLIST_ARGS take m2_sym_lookup = ;
  if a 0 != {
    ctx M2CTX_CURRENT_TARGET take_addr a M2TLIST_TYPE take = ;
    if "FUNCTION" a M2TLIST_TYPE take M2TYPE_NAME take strcmp 0 == {
      if "(" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! {
        @out ctx "#Loading address of function\nLOAD_EFFECTIVE_ADDRESS %" out m2_emit = ;
	@out ctx ctx a function m2_stack_index m2_numerate_number out m2_emit = ;
	@out ctx "\nLOAD_INTEGER\n" out m2_emit = ;
	out ret ;
      }
      ctx out function s 1 m2_function_call ret ;
    }
    @out ctx "LOAD_EFFECTIVE_ADDRESS %" out m2_emit = ;
    @out ctx ctx a function m2_stack_index m2_numerate_number out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    if "=" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! "argv" s strcmp 0 == ! && {
      @out ctx "LOAD_INTEGER\n" out m2_emit = ;
    }
    out ret ;
  }

  @a ctx s ctx M2CTX_GLOBAL_FUNCTION_LIST take m2_sym_lookup = ;
  if 0 a != {
    if "(" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! {
      @out ctx "LOAD_IMMEDIATE_eax &FUNCTION_" out m2_emit = ;
      @out ctx s out m2_emit = ;
      @out ctx "\n" out m2_emit = ;
      out ret ;
    } else {
      ctx out function s 0 m2_function_call ret ;
    }
  }

  @a ctx s ctx M2CTX_GLOBAL_SYMBOL_LIST take m2_sym_lookup = ;
  if a 0 != {
    ctx M2CTX_CURRENT_TARGET take_addr a M2TLIST_TYPE take = ;
    @out ctx "LOAD_IMMEDIATE_eax &GLOBAL_" out m2_emit = ;
    @out ctx s out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    if "=" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! {
      @out ctx "LOAD_INTEGER\n" out m2_emit = ;
    }
    out ret ;
  }

  0 "m2_sym_get_value: undefined symbol" assert_msg ;
}

fun m2_primary_expr 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  $processed
  @processed 0 = ;

  if '0' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c <= ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '9' <= & processed ! && {
    @out ctx "LOAD_IMMEDIATE_eax %" out m2_emit = ;
    @out ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    @processed 1 = ;
  }

  if 'a' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c <= ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c 'z' <= & 'A' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c <= ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c 'Z' <= & | processed ! & {
    @out ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take out function m2_sym_get_value = ;
    @processed 1 = ;
  }

  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '(' == processed ! && {
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    @out ctx out function m2_expression = ;
    ctx "m2_primary_expr: did not get the )" ")" m2_require_match ;
    @processed 1 = ;
  }

  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c 39 == processed ! && {
    @out ctx "LOAD_IMMEDIATE_eax %" out m2_emit = ;
    if '\\' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take 1 + **c == {
      @out ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take 1 + m2_escape_lookup m2_numerate_number out m2_emit = ;
    } else {
      @out ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take 1 + **c m2_numerate_number out m2_emit = ;
    }
    @out ctx "\n" out m2_emit = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    @processed 1 = ;
  }

  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c 34 == processed ! && {
    $number_string
    @number_string ctx M2CTX_CURRENT_COUNT take m2_numerate_number = ;
    @out ctx "LOAD_IMMEDIATE_eax &STRING_" out m2_emit = ;
    @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
    @out ctx "_" out m2_emit = ;
    @out ctx number_string out m2_emit = ;
    @out ctx "\n" out m2_emit = ;

    ctx M2CTX_STRINGS_LIST take_addr ctx ":STRING_" ctx M2CTX_STRINGS_LIST take m2_emit = ;
    ctx M2CTX_STRINGS_LIST take_addr ctx ctx M2CTX_CURRENT_FUNCTION take ctx M2CTX_STRINGS_LIST take m2_emit = ;
    ctx M2CTX_STRINGS_LIST take_addr ctx "_" ctx M2CTX_STRINGS_LIST take m2_emit = ;
    ctx M2CTX_STRINGS_LIST take_addr ctx number_string ctx M2CTX_STRINGS_LIST take m2_emit = ;
    ctx M2CTX_STRINGS_LIST take_addr ctx "\n" ctx M2CTX_STRINGS_LIST take m2_emit = ;
    ctx M2CTX_STRINGS_LIST take_addr ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take m2_parse_string ctx M2CTX_STRINGS_LIST take m2_emit = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;

    ctx M2CTX_CURRENT_COUNT take_addr ctx M2CTX_CURRENT_COUNT take 1 + = ;

    @processed 1 = ;
  }

  processed "m2_primary_expr: invalid token" assert_msg ;

  out ret ;
}

fun m2_pre_recursion 3 {
  $ctx
  $out
  $func
  @ctx 2 param = ;
  @out 1 param = ;
  @func 0 param = ;

  ctx M2CTX_LAST_TYPE take_addr ctx M2CTX_CURRENT_TARGET take = ;
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  @out ctx "PUSH_eax\t#_common_recursion\n" out m2_emit = ;
  func M2TLIST_TEMPS take_addr func M2TLIST_TEMPS take 1 + = ;
  out ret ;
}

fun m2_promote_type 3 {
  $ctx
  $a
  $b
  @ctx 2 param = ;
  @a 1 param = ;
  @b 0 param = ;

  if a 0 == {
    b ret ;
  }
  if b 0 == {
    a ret ;
  }
  $i
  @i ctx M2CTX_GLOBAL_TYPES take = ;
  while i 0 != {
    if a M2TYPE_NAME take i M2TYPE_NAME take == {
      a ret ;
    }
    if b M2TYPE_NAME take i M2TYPE_NAME take == {
      b ret ;
    }
    if a M2TYPE_NAME take i M2TYPE_INDIRECT take M2TYPE_NAME take == {
      a ret ;
    }
    if b M2TYPE_NAME take i M2TYPE_INDIRECT take M2TYPE_NAME take == {
      b ret ;
    }
    @i i M2TYPE_NEXT take = ;
  }
  0 ret ;
}

fun m2_post_recursion 3 {
  $ctx
  $out
  $func
  @ctx 2 param = ;
  @out 1 param = ;
  @func 0 param = ;

  ctx M2CTX_CURRENT_TARGET take_addr ctx ctx M2CTX_CURRENT_TARGET take ctx M2CTX_LAST_TYPE take m2_promote_type = ;
  func M2TLIST_TEMPS take_addr func M2TLIST_TEMPS take 1 - = ;
  @out ctx "POP_ebx\t# _common_recursion\n" out m2_emit = ;
  out ret ;
}

fun m2_ceil_log2 1 {
  $a
  @a 0 param = ;

  $result
  @result 0 = ;
  if a a 1 - & 0 == {
    @result 0 1 - = ;
  }
  while a 0 > {
    @result result 1 + = ;
    @a a 1 >> = ;
  }
  result ret ;
}

fun m2_postfix_expr 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  @out ctx out function m2_primary_expr = ;
  while 1 {
    if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '[' == {
      $target
      @target ctx M2CTX_CURRENT_TARGET take = ;
      $a
      @a ctx M2CTX_CURRENT_TARGET take = ;
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_expression = ;
      @out ctx out function m2_post_recursion = ;

      if 1 a M2TYPE_INDIRECT take M2TYPE_SIZE take != {
        @out ctx "SAL_eax_Immediate8 !" out m2_emit = ;
	@out ctx a M2TYPE_INDIRECT take M2TYPE_SIZE take m2_ceil_log2 m2_numerate_number out m2_emit = ;
	@out ctx "\n" out m2_emit = ;
      }

      @out ctx "ADD_ebx_to_eax\n" out m2_emit = ;
      ctx M2CTX_CURRENT_TARGET take_addr target = ;

      if "=" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take M2TLIST_S take strcmp 0 == ! {
        if 4 a M2TYPE_INDIRECT take M2TYPE_SIZE take == {
	  @out ctx "LOAD_INTEGER\n" out m2_emit = ;
	} else {
	  @out ctx "LOAD_BYTE\n" out m2_emit = ;
	}
      }
      ctx "m2_postfix_expr: missing ]" "]" m2_require_match ;
    } else {
      if "->" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
        @out ctx "# looking up offset\n" out m2_emit = ;
	ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
	$i
	@i ctx M2CTX_CURRENT_TARGET take M2TYPE_MEMBERS take = ;
	$cont
	@cont 1 = ;
	while i 0 != cont && {
	  if i M2TYPE_NAME take ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
	    @cont 0 = ;
	  } else {
	    @i i M2TYPE_MEMBERS take = ;
	  }
	}
	i 0 != "m2_postfix_expr: field does not exist" assert_msg ;
	if 0 i M2TYPE_OFFSET take != {
	  @out ctx "# -> offset calculation\n" out m2_emit = ;
	  @out ctx "LOAD_IMMEDIATE_ebx %" out m2_emit = ;
	  @out ctx i M2TYPE_OFFSET take m2_numerate_number out m2_emit = ;
	  @out ctx "\nADD_ebx_to_eax\n" out m2_emit = ;
	}
	if "=" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take M2TLIST_S take strcmp 0 == ! {
	  @out ctx "LOAD_INTEGER\n" out m2_emit = ;
	}
	ctx M2CTX_CURRENT_TARGET take_addr i M2TYPE_TYPE take = ;
	ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
      } else {
        out ret ;
      }
    }
  }
}

fun m2_unary_expr 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  $processed
  @processed 0 = ;

  if "-" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
    @out ctx "LOAD_IMMEDIATE_eax %0\n" out m2_emit = ;
    @out ctx out function m2_pre_recursion = ;
    @out ctx out function m2_postfix_expr = ;
    @out ctx out function m2_post_recursion = ;
    @out ctx "SUBTRACT_eax_from_ebx_into_ebx\nMOVE_ebx_to_eax\n" out m2_emit = ;
    @processed 1 = ;
  }

  if "!" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
    @out ctx "LOAD_IMMEDIATE_eax %1\n" out m2_emit = ;
    @out ctx out function m2_pre_recursion = ;
    @out ctx out function m2_postfix_expr = ;
    @out ctx out function m2_post_recursion = ;
    @out ctx "XOR_ebx_eax_into_eax\n" out m2_emit = ;
    @processed 1 = ;
  }

  if "sizeof" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    ctx "m2_unary_expr: missing (" "(" m2_require_match ;
    $a
    @a ctx m2_type_name = ;
    ctx "m2_uniary_expr: missing )" ")" m2_require_match ;
    @out ctx "LOAD_IMMEDIATE_eax %" out m2_emit = ;
    @out ctx a M2TYPE_SIZE take m2_numerate_number out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    @processed 1 = ;
  }

  if processed ! {
    @out ctx out function m2_postfix_expr = ;
  }

  out ret ;
}

fun m2_additive_expr 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  @out ctx out function m2_unary_expr = ;

  while 1 {
    $processed
    @processed 0 = ;

    if "+" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_unary_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "ADD_ebx_to_eax\n" out m2_emit = ;
      @processed 1 = ;
    }

    if "-" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_unary_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "SUBTRACT_eax_from_ebx_into_ebx\nMOVE_ebx_to_eax\n" out m2_emit = ;
      @processed 1 = ;
    }

    if "*" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_unary_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "MULTIPLY_eax_by_ebx_into_eax\n" out m2_emit = ;
      @processed 1 = ;
    }

    if "/" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_unary_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "XCHG_eax_ebx\nLOAD_IMMEDIATE_edx %0\nDIVIDE_eax_by_ebx_into_eax\n" out m2_emit = ;
      @processed 1 = ;
    }

    if "%" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_unary_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "XCHG_eax_ebx\nLOAD_IMMEDIATE_edx %0\nMODULUS_eax_from_ebx_into_ebx\nMOVE_edx_to_eax\n" out m2_emit = ;
      @processed 1 = ;
    }

    if processed ! {
      out ret ;
    }
  }
}

fun m2_shift_expr 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  @out ctx out function m2_additive_expr = ;

  while 1 {
    $processed
    @processed 0 = ;

    if "<<" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_additive_expr = ;
      @out ctx out function m2_post_recursion = ;
      $old
      @old out M2TLIST_NEXT take = ;
      out free ;
      @out ctx "COPY_eax_to_ecx\nPOP_eax\nSAL_eax_cl\n" old m2_emit = ;
      @processed 1 = ;
    }

    if ">>" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_additive_expr = ;
      @out ctx out function m2_post_recursion = ;
      $old
      @old out M2TLIST_NEXT take = ;
      out free ;
      @out ctx "COPY_eax_to_ecx\nPOP_eax\nSAR_eax_cl\n" old m2_emit = ;
      @processed 1 = ;
    }

    if processed ! {
      out ret ;
    }
  }
}

fun m2_relational_expr 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  @out ctx out function m2_shift_expr = ;

  while 1 {
    $processed
    @processed 0 = ;

    if "<" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_shift_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "CMP\nSETL\nMOVEZBL\n" out m2_emit = ;
      @processed 1 = ;
    }

    if "<=" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_shift_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "CMP\nSETLE\nMOVEZBL\n" out m2_emit = ;
      @processed 1 = ;
    }

    if ">=" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_shift_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "CMP\nSETGE\nMOVEZBL\n" out m2_emit = ;
      @processed 1 = ;
    }

    if ">" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_shift_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "CMP\nSETG\nMOVEZBL\n" out m2_emit = ;
      @processed 1 = ;
    }

    if processed ! {
      out ret ;
    }
  }
}

fun m2_equality_expr 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  @out ctx out function m2_relational_expr = ;

  while 1 {
    $processed
    @processed 0 = ;

    if "==" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_shift_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "CMP\nSETE\nMOVEZBL\n" out m2_emit = ;
      @processed 1 = ;
    }

    if "!=" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_shift_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "CMP\nSETNE\nMOVEZBL\n" out m2_emit = ;
      @processed 1 = ;
    }

    if processed ! {
      out ret ;
    }
  }
}

fun m2_bitwise 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  @out ctx out function m2_equality_expr = ;

  while 1 {
    $processed
    @processed 0 = ;

    if '&' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_equality_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "AND_eax_ebx\n" out m2_emit = ;
      @processed 1 = ;
    }

    if '|' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_equality_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "OR_eax_ebx\n" out m2_emit = ;
      @processed 1 = ;
    }

    if '^' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c == processed ! && {
      @out ctx out function m2_pre_recursion = ;
      @out ctx out function m2_equality_expr = ;
      @out ctx out function m2_post_recursion = ;
      @out ctx "XOR_ebx_eax_into_eax\n" out m2_emit = ;
      @processed 1 = ;
    }

    if processed ! {
      out ret ;
    }
  }
}

fun m2_expression 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  @out ctx out function m2_bitwise = ;

  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '=' == {
    $target
    @target ctx M2CTX_CURRENT_TARGET take = ;
    $member
    @member "]" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_PREV take M2TLIST_S take strcmp 0 == = ;
    @out ctx out function m2_pre_recursion = ;
    @out ctx out function m2_expression = ;
    @out ctx out function m2_post_recursion = ;

    if member {
      if 1 target M2TYPE_INDIRECT take M2TYPE_SIZE take == {
        @out ctx "STORE_CHAR\n" out m2_emit = ;
      } else {
        if 4 target M2TYPE_INDIRECT take M2TYPE_SIZE take == {
	  @out ctx "STORE_INTEGER\n" out m2_emit = ;
	}
      }
    } else {
      @out ctx "STORE_INTEGER\n" out m2_emit = ;
    }
  }

  out ret ;
}

fun m2_collect_local 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  $type_size
  @type_size ctx m2_type_name = ;
  @out ctx "# Defining local " out m2_emit = ;
  @out ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  $a
  @a ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take type_size function M2TLIST_LOCALS take m2_sym_declare = ;
  function M2TLIST_LOCALS take_addr a = ;
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  function M2TLIST_TEMPS take_addr function M2TLIST_TEMPS take 1 - = ;

  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '=' == {
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    @out ctx out function m2_expression = ;
  }
  function M2TLIST_TEMPS take_addr function M2TLIST_TEMPS take 1 + = ;

  ctx "m2_collect_local: missing ;" ";" m2_require_match ;

  @out ctx "PUSH_eax\t#" out m2_emit = ;
  @out ctx a M2TLIST_S take out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  out ret ;
}

ifun m2_statement 3

fun m2_process_if 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  $number_string
  @number_string ctx M2CTX_CURRENT_COUNT take m2_numerate_number = ;
  ctx M2CTX_CURRENT_COUNT take_addr ctx M2CTX_CURRENT_COUNT take 1 + = ;

  @out ctx "# IF_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  ctx "m2_process_if: missing (" "(" m2_require_match ;
  @out ctx out function m2_expression = ;

  @out ctx "TEST\nJUMP_EQ %ELSE_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx "m2_process_if: missing )" ")" m2_require_match ;
  @out ctx out function m2_statement = ;

  @out ctx "JUMP %_END_IF_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n:ELSE_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  if "else" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    @out ctx out function m2_statement = ;
  }

  @out ctx ":_END_IF_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  out ret ;
}

fun m2_process_for 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  $number_string
  @number_string ctx M2CTX_CURRENT_COUNT take m2_numerate_number = ;
  ctx M2CTX_CURRENT_COUNT take_addr ctx M2CTX_CURRENT_COUNT take 1 + = ;

  $nested_break_head
  @nested_break_head ctx M2CTX_BREAK_TARGET_HEAD take = ;
  $nested_break_func
  @nested_break_func ctx M2CTX_BREAK_TARGET_FUNC take = ;
  $nested_break_num
  @nested_break_num ctx M2CTX_BREAK_TARGET_NUM take = ;
  $nested_locals
  @nested_locals ctx M2CTX_BREAK_LOCALS take = ;
  ctx M2CTX_BREAK_LOCALS take_addr function M2TLIST_LOCALS take = ;
  ctx M2CTX_BREAK_TARGET_HEAD take_addr "FOR_END_" = ;
  ctx M2CTX_BREAK_TARGET_FUNC take_addr ctx M2CTX_CURRENT_FUNCTION take = ;
  ctx M2CTX_BREAK_TARGET_NUM take_addr number_string = ;

  @out ctx "# FOR_initialization_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;

  ctx "m2_process_for: missing (" "(" m2_require_match ;
  if ";" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! {
    @out ctx out function m2_expression = ;
  }

  @out ctx ":FOR_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx "m2_process_for: missing first ;" ";" m2_require_match ;
  @out ctx out function m2_expression = ;

  @out ctx "TEST\nJUMP_EQ %FOR_END_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\nJUMP %FOR_THEN_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n:FOR_ITER_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx "m2_process_for: missing second ;" ";" m2_require_match ;
  @out ctx out function m2_expression = ;

  @out ctx "JUMP %FOR_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n:FOR_THEN_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx "m2_process_for: missing )" ")" m2_require_match ;
  @out ctx out function m2_statement = ;

  @out ctx "JUMP %FOR_ITER_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n:FOR_END_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx M2CTX_BREAK_TARGET_HEAD take_addr nested_break_head = ;
  ctx M2CTX_BREAK_TARGET_FUNC take_addr nested_break_func = ;
  ctx M2CTX_BREAK_TARGET_NUM take_addr nested_break_num = ;
  ctx M2CTX_BREAK_LOCALS take_addr nested_locals = ;

  out ret ;
}

fun m2_process_asm 2 {
  $ctx
  $out
  @ctx 1 param = ;
  @out 0 param = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  ctx "m2_process_asm: missing (" "(" m2_require_match ;
  while 34 ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c == {
    @out ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take 1 + out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  }
  ctx "m2_process_asm: missing )" ")" m2_require_match ;
  ctx "m2_process_asm: missing ;" ";" m2_require_match ;
  out ret ;
}

fun m2_process_do 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  $number_string
  @number_string ctx M2CTX_CURRENT_COUNT take m2_numerate_number = ;
  ctx M2CTX_CURRENT_COUNT take_addr ctx M2CTX_CURRENT_COUNT take 1 + = ;

  $nested_break_head
  @nested_break_head ctx M2CTX_BREAK_TARGET_HEAD take = ;
  $nested_break_func
  @nested_break_func ctx M2CTX_BREAK_TARGET_FUNC take = ;
  $nested_break_num
  @nested_break_num ctx M2CTX_BREAK_TARGET_NUM take = ;
  $nested_locals
  @nested_locals ctx M2CTX_BREAK_LOCALS take = ;
  ctx M2CTX_BREAK_LOCALS take_addr function M2TLIST_LOCALS take = ;
  ctx M2CTX_BREAK_TARGET_HEAD take_addr "DO_END_" = ;
  ctx M2CTX_BREAK_TARGET_FUNC take_addr ctx M2CTX_CURRENT_FUNCTION take = ;
  ctx M2CTX_BREAK_TARGET_NUM take_addr number_string = ;

  @out ctx ":DO_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  @out ctx out function m2_statement = ;

  ctx "m2_process_do: missing while" "while" m2_require_match ;
  ctx "m2_process_do: missing (" "(" m2_require_match ;
  @out ctx out function m2_expression = ;
  ctx "m2_process_do: )" ")" m2_require_match ;
  ctx "m2_process_do: ;" ";" m2_require_match ;

  @out ctx "TEST\nJUMP_NE %DO_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n:DO_END_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx M2CTX_BREAK_LOCALS take_addr nested_locals = ;
  ctx M2CTX_BREAK_TARGET_HEAD take_addr nested_break_head = ;
  ctx M2CTX_BREAK_TARGET_FUNC take_addr nested_break_func = ;
  ctx M2CTX_BREAK_TARGET_NUM take_addr nested_break_num = ;

  out ret ;
}

fun m2_process_while 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  $number_string
  @number_string ctx M2CTX_CURRENT_COUNT take m2_numerate_number = ;
  ctx M2CTX_CURRENT_COUNT take_addr ctx M2CTX_CURRENT_COUNT take 1 + = ;

  $nested_break_head
  @nested_break_head ctx M2CTX_BREAK_TARGET_HEAD take = ;
  $nested_break_func
  @nested_break_func ctx M2CTX_BREAK_TARGET_FUNC take = ;
  $nested_break_num
  @nested_break_num ctx M2CTX_BREAK_TARGET_NUM take = ;
  $nested_locals
  @nested_locals ctx M2CTX_BREAK_LOCALS take = ;
  ctx M2CTX_BREAK_LOCALS take_addr function M2TLIST_LOCALS take = ;
  ctx M2CTX_BREAK_TARGET_HEAD take_addr "END_WHILE_" = ;
  ctx M2CTX_BREAK_TARGET_FUNC take_addr ctx M2CTX_CURRENT_FUNCTION take = ;
  ctx M2CTX_BREAK_TARGET_NUM take_addr number_string = ;

  @out ctx ":WHILE_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  ctx "m2_process_while: missing (" "(" m2_require_match ;
  @out ctx out function m2_expression = ;

  @out ctx "TEST\nJUMP_EQ %END_WHILE_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n# THEN_while_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx "m2_process_while: missing )" ")" m2_require_match ;
  @out ctx out function m2_statement = ;

  @out ctx "JUMP %WHILE_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n:END_WHILE_" out m2_emit = ;
  @out ctx ctx M2CTX_CURRENT_FUNCTION take out m2_emit = ;
  @out ctx "_" out m2_emit = ;
  @out ctx number_string out m2_emit = ;
  @out ctx "\n" out m2_emit = ;

  ctx M2CTX_BREAK_LOCALS take_addr nested_locals = ;
  ctx M2CTX_BREAK_TARGET_HEAD take_addr nested_break_head = ;
  ctx M2CTX_BREAK_TARGET_FUNC take_addr nested_break_func = ;
  ctx M2CTX_BREAK_TARGET_NUM take_addr nested_break_num = ;

  out ret ;
}

fun m2_return_result 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c ';' != {
    @out ctx out function m2_expression = ;
  }

  ctx "m2_return_result: missing ;" ";" m2_require_match ;

  $i
  @i function M2TLIST_LOCALS take = ;
  while i 0 != {
    @out ctx "POP_ebx\t# _return_result_locals\n" out m2_emit = ;
    @i i M2TLIST_NEXT take = ;
  }

  @out ctx "RETURN\n" out m2_emit = ;

  out ret ;
}

fun m2_recursive_statement 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  $frame
  @frame function M2TLIST_LOCALS take = ;

  while "}" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! {
    @out ctx out function m2_statement = ;
  }
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;

  if 0 function M2TLIST_LOCALS take != {
    $i
    @i function M2TLIST_LOCALS take = ;
    while frame i != {
      if "RETURN\n" out M2TLIST_S take strcmp 0 == ! {
        @out ctx "POP_ebx\t# _recursive_statement_locals\n" out m2_emit = ;
      }
      function M2TLIST_LOCALS take_addr function M2TLIST_LOCALS take M2TLIST_NEXT take = ;
      @i i M2TLIST_NEXT take = ;
    }
  }

  out ret ;
}

fun m2_statement 3 {
  $ctx
  $out
  $function
  @ctx 2 param = ;
  @out 1 param = ;
  @function 0 param = ;

  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '{' == {
    @out ctx out function m2_recursive_statement = ;
    out ret ;
  }
  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c ':' == {
    @out ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take out m2_emit = ;
    @out ctx "\t#C goto label\n" out m2_emit = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    out ret ;
  }
  if 0 ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take function M2TLIST_LOCALS take m2_sym_lookup == 0 ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take function M2TLIST_ARGS take m2_sym_lookup == && 0 ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take m2_lookup_type != && "struct" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == || {
    @out ctx out function m2_collect_local = ;
    out ret ;
  }
  if "if" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    @out ctx out function m2_process_if = ;
    out ret ;
  }
  if "do" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    @out ctx out function m2_process_do = ;
    out ret ;
  }
  if "while" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    @out ctx out function m2_process_while = ;
    out ret ;
  }
  if "for" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    @out ctx out function m2_process_for = ;
    out ret ;
  }
  if "asm" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    @out ctx out m2_process_asm = ;
    out ret ;
  }
  if "goto" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    @out ctx "JUMP %" out m2_emit = ;
    @out ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    ctx "m2_statement: missing ;" ";" m2_require_match ;
    out ret ;
  }
  if "return" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    @out ctx out function m2_return_result = ;
    out ret ;
  }
  if "break" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    0 ctx M2CTX_BREAK_TARGET_HEAD take != "m2_statement: not inside a loop or case statement" assert_msg ;
    $i
    @i function M2TLIST_LOCALS take = ;
    while i 0 != i ctx M2CTX_BREAK_LOCALS take != && {
      @out ctx "POP_ebx\t# break_cleanup_locals\n" out m2_emit = ;
      @i i M2TLIST_NEXT take = ;
    }
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    @out ctx "JUMP %" out m2_emit = ;
    @out ctx ctx M2CTX_BREAK_TARGET_HEAD take out m2_emit = ;
    @out ctx ctx M2CTX_BREAK_TARGET_FUNC take out m2_emit = ;
    @out ctx "_" out m2_emit = ;
    @out ctx ctx M2CTX_BREAK_TARGET_NUM take out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    ctx "m2_statement: missing ;" ";" m2_require_match ;
    out ret ;
  }
  if "continue" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    @out ctx "\n#continue statement\n" out m2_emit = ;
    ctx "m2_statement: missing ;" ";" m2_require_match ;
    out ret ;
  }
  @out ctx out function m2_expression = ;
  ctx "m2_statement: missing ;" ";" m2_require_match ;
  out ret ;
}

fun m2_collect_arguments 2 {
  $ctx
  $function
  @ctx 1 param = ;
  @function 0 param = ;

  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;

  while ")" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == ! {
    $type_size
    @type_size ctx m2_type_name = ;
    if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c ')' == {
      ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_PREV take = ;
    } else {
      $a
      @a ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take type_size function M2TLIST_ARGS take m2_sym_declare = ;
      function M2TLIST_ARGS take_addr a = ;
    }
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c ',' == {
      ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
    }
  }
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
}

fun m2_declare_function 3 {
  $ctx
  $out
  $type
  @ctx 2 param = ;
  @out 1 param = ;
  @type 0 param = ;

  $essential
  @essential ctx M2CTX_GLOBAL_TOKEN take M2TLIST_PREV take M2TLIST_S take = ;
  ctx M2CTX_CURRENT_FUNCTION take_addr essential = ;
  ctx M2CTX_CURRENT_COUNT take_addr 0 = ;
  $func
  @func ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_PREV take M2TLIST_S take 1 SIZEOF_M2TYPE calloc ctx M2CTX_GLOBAL_FUNCTION_LIST take m2_sym_declare = ;
  func M2TLIST_TYPE take_addr type = ;
  ctx func m2_collect_arguments ;

  ctx M2CTX_GLOBAL_FUNCTION_LIST take_addr func = ;

  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c ';' == {
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
  } else {
    @out ctx "# Defining function " out m2_emit = ;
    @out ctx essential out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    @out ctx ":FUNCTION_" out m2_emit = ;
    @out ctx essential out m2_emit = ;
    @out ctx "\n" out m2_emit = ;
    @out ctx out func m2_statement = ;
    if "RETURN\n" out M2TLIST_S take strcmp 0 == ! {
      @out ctx "RETURN\n" out m2_emit = ;
    }
  }

  out ret ;
}

fun m2_program 2 {
  $ctx
  $out
  @ctx 1 param = ;
  @out 0 param = ;

  $type_size
  while 0 ctx M2CTX_GLOBAL_TOKEN take != {
    if "CONSTANT" ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take strcmp 0 == {
      ctx M2CTX_GLOBAL_CONSTANT_LIST take_addr ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take M2TLIST_S take 0 ctx M2CTX_GLOBAL_CONSTANT_LIST take m2_sym_declare = ;
      ctx M2CTX_GLOBAL_CONSTANT_LIST take M2TLIST_ARGS take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take M2TLIST_NEXT take = ;
      ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take M2TLIST_NEXT take M2TLIST_NEXT take = ;
    } else {
      @type_size ctx m2_type_name = ;
      if 0 type_size != {
        ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
	if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c ';' == {
	  ctx M2CTX_GLOBAL_SYMBOL_LIST take_addr ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_PREV take M2TLIST_S take type_size ctx M2CTX_GLOBAL_SYMBOL_LIST take m2_sym_declare = ;
	  ctx M2CTX_GLOBALS_LIST take_addr ctx ":GLOBAL_" ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	  ctx M2CTX_GLOBALS_LIST take_addr ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_PREV take M2TLIST_S take ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	  ctx M2CTX_GLOBALS_LIST take_addr ctx "\nNOP\n" ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
	} else {
	  if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '=' == {
	    ctx M2CTX_GLOBAL_SYMBOL_LIST take_addr ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_PREV take M2TLIST_S take type_size ctx M2CTX_GLOBAL_SYMBOL_LIST take m2_sym_declare = ;
	    ctx M2CTX_GLOBALS_LIST take_addr ctx ":GLOBAL_" ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	    ctx M2CTX_GLOBALS_LIST take_addr ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_PREV take M2TLIST_S take ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	    ctx M2CTX_GLOBALS_LIST take_addr ctx "\n" ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
	    if '0' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c <= ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '9' <= & {
	      ctx M2CTX_GLOBALS_LIST take_addr ctx "%" ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	      ctx M2CTX_GLOBALS_LIST take_addr ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	      ctx M2CTX_GLOBALS_LIST take_addr ctx "\n" ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	    } else {
	      if '\"' ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c <= {
	        ctx M2CTX_GLOBALS_LIST take_addr ctx ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take m2_parse_string ctx M2CTX_GLOBALS_LIST take m2_emit = ;
	      } else {
	        0 "m2_program: invalid token in program" assert_msg ;
	      }
	    }
	    ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take M2TLIST_NEXT take = ;
	    ctx "m2_program: missing ;" ";" m2_require_match ;
	  } else {
	    if ctx M2CTX_GLOBAL_TOKEN take M2TLIST_S take **c '(' == {
	      @out ctx out type_size m2_declare_function = ;
	    } else {
	      0 "m2_program: invalid token in program" assert_msg ;
	    }
	  }
	}
      }
    }
  }
  out ret ;
}

fun m2_recursive_output 2 {
  $i
  $out
  @i 1 param = ;
  @out 0 param = ;

  if 0 i == {
    ret ;
  }
  i M2TLIST_NEXT take out m2_recursive_output ;
  out i M2TLIST_S take vfs_write_string ;
}

fun m2_compile 2 {
  $files
  $outfile
  @files 1 param = ;
  @outfile 0 param = ;

  $ctx
  @ctx 1 SIZEOF_M2CTX calloc = ;
  $destination_file
  @destination_file outfile vfs_open = ;
  destination_file vfs_truncate ;
  $i
  @i 0 = ;
  while i files vector_size < {
    $name
    @name files i vector_at = ;
    $in
    @in name vfs_open = ;
    ctx M2CTX_GLOBAL_TOKEN take_addr ctx in ctx M2CTX_GLOBAL_TOKEN take name m2_read_all_tokens = ;
    in vfs_close ;
    @i i 1 + = ;
  }
  0 ctx M2CTX_GLOBAL_TOKEN take != "m2_compile: no or empty input file" assert_msg ;
  ctx M2CTX_GLOBAL_TOKEN take_addr ctx M2CTX_GLOBAL_TOKEN take m2_reverse_list = ;
  ctx m2_initialize_types ;
  $output_list
  @output_list ctx 0 m2_program = ;
  destination_file "\n# Core program\n" vfs_write_string ;
  output_list destination_file m2_recursive_output ;
  #destination_file "\n:ELF_data\n" vfs_write_string ;
  destination_file "\n# Program global variables\n" vfs_write_string ;
  ctx M2CTX_GLOBALS_LIST take destination_file m2_recursive_output ;
  destination_file "\n# Program strings\n" vfs_write_string ;
  ctx M2CTX_STRINGS_LIST take destination_file m2_recursive_output ;
  destination_file "\n:ELF_end\n" vfs_write_string ;
  destination_file vfs_close ;
  #"Compiled program:\n" 1 platform_log ;
  #outfile dump_file ;
  ctx free ;
}

fun m2_test 0 {
  $files
  @files 4 vector_init = ;
  files "/init/test_mes.c" strdup vector_push_back ;
  files "/ram/compiled.m1" m2_compile ;
  files free_vect_of_ptrs ;

  #"/ram/compiled.m1" dump_debug ;
}

fun m2_test_full_compilation 0 {
  $files
  @files 4 vector_init = ;
  files "/init/test_mes.c" strdup vector_push_back ;
  files "/ram/compiled.m1" m2_compile ;
  files free_vect_of_ptrs ;
  "/ram/compiled.m1" dump_file ;

  @files 4 vector_init = ;
  files "/disk1/mescc/x86_defs.m1" strdup vector_push_back ;
  files "/ram/compiled.m1" strdup vector_push_back ;
  files "/ram/assembled.hex2" m1_assemble ;
  files free_vect_of_ptrs ;

  @files 4 vector_init = ;
  files "/ram/assembled.hex2" strdup vector_push_back ;
  $data
  @data files hex2_link = ;

  "Executing code compiled with M2-Planet...\n" 1 platform_log ;
  $arg
  @arg "_main" = ;
  $res
  @res @arg 1 data \2 = ;
  "It returned " 1 platform_log ;
  res itoa 1 platform_log ;
  "\n" 1 platform_log ;

  data free ;
  files free_vect_of_ptrs ;
}
