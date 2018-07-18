# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
# https://gitlab.com/giomasce/asmc

# This file was ported from M1-macro.c, distributed with MES,
# which has the following copyright notices:
# Copyright (C) 2016 Jeremiah Orians
# Copyright (C) 2017 Jan Nieuwenhuizen <janneke@gnu.org>

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

const M1_MAX_STRING 4096

const M1TOKEN_TYPE_MACRO 1
const M1TOKEN_TYPE_STR 2

const M1TOKEN_NEXT 0
const M1TOKEN_TYPE 4
const M1TOKEN_TEXT 8
const M1TOKEN_EXPR 12
const SIZEOF_M1TOKEN 16

const M1CTX_SOURCE_FD 0
const M1CTX_DEST_FD 4
const SIZEOF_M1CTX 8

fun m1_new_token 0 {
  $p
  @p SIZEOF_M1TOKEN 1 calloc = ;
  p ret ;
}

fun m1_reverse_list 1 {
  $head
  @head 0 param = ;

  $root
  @root 0 = ;
  while head 0 != {
    $next
    @next head M1TOKEN_NEXT take = ;
    head M1TOKEN_NEXT take_addr root = ;
    @root head = ;
    @head next = ;
  }
  root ret ;
}

fun m1_purge_line_comment 1 {
  $ctx
  @ctx 0 param = ;

  $fd
  @fd ctx M1CTX_SOURCE_FD take = ;

  $c
  @c fd vfs_read = ;
  while c '\n' != c '\r' != && {
    @c fd vfs_read = ;
  }
}

fun m1_store_atom 2 {
  $ctx
  $c
  @ctx 1 param = ;
  @c 0 param = ;

  $fd
  @fd ctx M1CTX_SOURCE_FD take = ;

  $store
  @store 1 M1_MAX_STRING 1 + calloc = ;
  $ch
  @ch c = ;
  $i
  @i 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    store i + ch =c ;
    @ch fd vfs_read = ;
    @i i 1 + = ;
    @cont ch 9 != ch 10 != && ch 32 != && i M1_MAX_STRING <= && = ;
  }
  store ret ;
}

fun m1_store_string 2 {
  $ctx
  $c
  @ctx 1 param = ;
  @c 0 param = ;

  $fd
  @fd ctx M1CTX_SOURCE_FD take = ;

  $store
  @store 1 M1_MAX_STRING 1 + calloc = ;
  $ch
  @ch c = ;
  $i
  @i 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    store i + ch =c ;
    @i i 1 + = ;
    @ch fd vfs_read = ;
    ch 0xffffffff != "m1_store_string: unmatched !" assert_msg ;
    M1_MAX_STRING i != "m1_store_string: max string size exceeded" assert_msg ;
    @cont c ch != = ;
  }
  store ret ;  
}

fun m1_tokenize_line 2 {
  $ctx
  $head
  @ctx 1 param = ;
  @head 0 param = ;

  $fd
  @fd ctx M1CTX_SOURCE_FD take = ;

  $c
  $p
  while 1 {
    @c fd vfs_read = ;
    if 35 c == 59 c == || {
      ctx m1_purge_line_comment ;
    } else {
      if 9 c == 10 c == || 32 c == || ! {
        if 0xffffffff c == {
	  head ret ;
	}
	@p m1_new_token = ;
	if 34 c == 39 c == || {
	  p M1TOKEN_TEXT take_addr ctx c m1_store_string = ;
	  p M1TOKEN_TYPE take_addr M1TOKEN_TYPE_STR = ;
	} else {
	  p M1TOKEN_TEXT take_addr ctx c m1_store_atom = ;
	}
	p M1TOKEN_NEXT take_addr head = ;
	@head p = ;
      }
    }
  }
}

fun m1_set_expression 4 {
  $ctx
  $p
  $c
  $exp
  @ctx 3 param = ;
  @p 2 param = ;
  @c 1 param = ;
  @exp 0 param = ;

  $i
  @i p = ;
  while i 0 != {
    if i M1TOKEN_TYPE take M1TOKEN_TYPE_MACRO & ! {
      if i M1TOKEN_TEXT take c strcmp 0 == {
        i M1TOKEN_EXPR take_addr exp = ;
      }
    }
    @i i M1TOKEN_NEXT take = ;
  }
}

fun m1_identify_macros 2 {
  $ctx
  $p
  @ctx 1 param = ;
  @p 0 param = ;

  $i
  @i p = ;
  while i 0 != {
    if i M1TOKEN_TEXT take "DEFINE" strcmp 0 == {
      i M1TOKEN_TYPE take_addr M1TOKEN_TYPE_MACRO = ;
      i M1TOKEN_TEXT take_addr i M1TOKEN_NEXT take M1TOKEN_TEXT take = ;
      if i M1TOKEN_NEXT take M1TOKEN_NEXT take M1TOKEN_TYPE take M1TOKEN_TYPE_STR & {
        i M1TOKEN_EXPR take_addr i M1TOKEN_NEXT take M1TOKEN_NEXT take M1TOKEN_TEXT take 1 + = ;
      } else {
        i M1TOKEN_EXPR take_addr i M1TOKEN_NEXT take M1TOKEN_NEXT take M1TOKEN_TEXT take = ;
      }
      i M1TOKEN_NEXT take_addr i M1TOKEN_NEXT take M1TOKEN_NEXT take M1TOKEN_NEXT take = ;
    }
    @i i M1TOKEN_NEXT take = ;
  }
}

fun m1_line_macro 2 {
  $ctx
  $p
  @ctx 1 param = ;
  @p 0 param = ;

  $i
  @i p = ;
  while i 0 != {
    if i M1TOKEN_TYPE take M1TOKEN_TYPE_MACRO & {
      ctx i M1TOKEN_NEXT take i M1TOKEN_TEXT take i M1TOKEN_EXPR take m1_set_expression ;
    }
    @i i M1TOKEN_NEXT take = ;
  }
}

fun m1_hexify_string 2 {
  $ctx
  $p
  @ctx 1 param = ;
  @p 0 param = ;

  $table
  @table "0123456789ABCDEF" = ;
  $i
  @i p M1TOKEN_TEXT take 1 + strlen 4 / 1 + 8 * = ;
  $d
  @d 1 M1_MAX_STRING calloc = ;
  p M1TOKEN_EXPR take_addr d = ;

  while 0 i < {
    @i i 1 - = ;
    d i + 0x30 =c ;
  }

  while i M1_MAX_STRING < {
    if 0 p M1TOKEN_TEXT take i + 1 + **c == {
      @i M1_MAX_STRING = ;
    } else {
      d 2 i * + table p M1TOKEN_TEXT take i 1 + + **c 16 / + **c =c ;
      d 2 i * 1 + + table p M1TOKEN_TEXT take i 1 + + **c 16 % + **c =c ;
      @i i 1 + = ;
    }
  }
}

fun m1_process_string 2 {
  $ctx
  $p
  @ctx 1 param = ;
  @p 0 param = ;

  $i
  @i p = ;
  while i 0 != {
    if i M1TOKEN_TYPE take M1TOKEN_TYPE_STR & {
      if '\'' i M1TOKEN_TEXT take **c == {
        i M1TOKEN_EXPR take_addr i M1TOKEN_TEXT take 1 + = ;
      } else {
        if '\"' i M1TOKEN_TEXT take **c == {
	  ctx i m1_hexify_string ;
	}
      }
    }
    @i i M1TOKEN_NEXT take = ;
  }
}

fun m1_preserve_other 2 {
  $ctx
  $p
  @ctx 1 param = ;
  @p 0 param = ;

  $i
  @i p = ;
  while i 0 != {
    if i M1TOKEN_EXPR take 0 == i M1TOKEN_TYPE take M1TOKEN_TYPE_MACRO & ! && {
      $c
      @c i M1TOKEN_TEXT take **c = ;
      if c '!' == c '@' == || c '$' == || c '%' == || c '&' == || c ':' == || {
        i M1TOKEN_EXPR take_addr i M1TOKEN_TEXT take = ;
      } else {
        0 "m1_preserve_other: invalid other" assert_msg ;
      }
    }
    @i i M1TOKEN_NEXT take = ;
  }
}

fun m1_bound_values 4 {
  $disp
  $num
  $low
  $high
  @disp 3 param = ;
  @num 2 param = ;
  @low 1 param = ;
  @high 0 param = ;

  high disp < disp low < || ! "m1_bound_values: displacement does not fit" assert_msg ;
}

fun m1_range_check 2 {
  $disp
  $num
  @disp 1 param = ;
  @num 0 param = ;

  if 4 num == {
   ret ;
  }
  if 3 num == {
    disp num 0 8388608 - 16777216 m1_bound_values ;
    ret ;
  }
  if 2 num == {
    disp num 0 32768 - 65535 m1_bound_values ;
    ret ;
  }
  if 1 num == {
    disp num 0 128 - 255 m1_bound_values ;
    ret ;
  }
  0 "m1_range_check: invalid byte number" assert_msg ;
}

fun m1_reverse_bit_order 1 {
  $c
  @c 0 param = ;

  if c 0 == {
    ret ;
  }
  if c 1 + **c 0 == {
    ret ;
  }
  $hold
  @hold c **c = ;
  c c 1 + **c =c ;
  c 1 + hold =c ;
  c 2 + m1_reverse_bit_order ;
}

fun m1_little_endian 1 {
  $start
  @start 0 param = ;

  $end
  @end start = ;
  $c
  @c start = ;
  while 0 end **c != {
    @end end 1 + = ;
  }
  $hold
  @end end 1 - = ;
  while start end < {
    @hold start **c = ;
    start end **c =c ;
    end hold =c ;
    @end end 1 - = ;
    @start start 1 + = ;
  }
  c m1_reverse_bit_order ;
}

fun m1_hex2char 1 {
  $c
  @c 0 param = ;

  if c 0 >= c 9 <= && {
    c 48 + ret ;
  }
  if c 10 >= c 15 <= && {
    c 55 + ret ;
  }
  0 1 - ret ;
}

fun m1_char2hex 1 {
  $c
  @c 0 param = ;

  if c '0' >= c '9' <= && {
    c 48 - ret ;
  }
  if c 'a' >= c 'f' <= && {
    c 87 - ret ;
  }
  if c 'A' >= c 'F' <= && {
    c 55 - ret ;
  }
  0 1 - ret ;
}

fun m1_char2dec 1 {
  $c
  @c 0 param = ;

  if c '0' >= c '9' <= && {
    c 48 - ret ;
  }
  0 1 - ret ;
}

fun m1_stringify 5 {
  $s
  $digits
  $divisor
  $value
  $shift
  @s 4 param = ;
  @digits 3 param = ;
  @divisor 2 param = ;
  @value 1 param = ;
  @shift 0 param = ;

  $i
  @i value = ;
  if digits 1 > {
    @i s 1 + digits 1 - divisor value shift m1_stringify = ;
  }
  s i divisor 1 - & m1_hex2char =c ;
  i shift >> ret ;
}

fun m1_express_number 2 {
  $value
  $c
  @value 1 param = ;
  @c 0 param = ;

  $ch
  @ch 42 1 calloc = ;
  $size
  $num
  $shift
  $processed
  @processed 0 = ;
  if '!' c == {
    @num 1 = ;
    @value value 0xff & = ;
    @processed 1 = ;
  }
  if '@' c == {
    @num 2 = ;
    @value value 0xffff & = ;
    @processed 1 = ;
  }
  if '%' c == {
    @num 4 = ;
    @value value 0xffffffff & = ;
    @processed 1 = ;
  }
  processed "m1_express_number: invalid character" assert_msg ;

  value num m1_range_check ;

  @size num 2 * = ;
  @shift 4 = ;
  ch size 16 value shift m1_stringify ;
  ch m1_little_endian ;
  ch ret ;
}

fun m1_numerate_string 1 {
  $a
  @a 0 param = ;

  $count
  @count 0 = ;
  $index
  $negative
  if 0 a **c == {
    0 ret ;
  }
  if a **c '0' == a 1 + **c 'x' == && {
    if a 2 + **c '-' == {
      @negative 1 = ;
      @index 3 = ;
    } else {
      @negative 0 = ;
      @index 2 = ;
    }
    while 0 a index + **c != {
      if a index + **c m1_char2hex 0 1 - == {
        0 ret ;
      }
      @count count 16 * a index + **c m1_char2hex + = ;
      @index index 1 + = ;
    }
  } else {
    if a **c '-' == {
      @negative 1 = ;
      @index 1 = ;
    } else {
      @negative 0 = ;
      @index 0 = ;
    }
    while 0 a index + **c != {
      if a index + **c m1_char2dec 0 1 - == {
        0 ret ;
      }
      @count count 10 * a index + **c m1_char2dec + = ;
      @index index 1 + = ;
    }
  }
  if negative {
    @count 0 count - = ;
  }
  count ret ;
}

fun m1_eval_immediates 1 {
  $p
  @p 0 param = ;

  $i
  @i p = ;
  while i 0 != {
    if i M1TOKEN_EXPR take 0 == i M1TOKEN_TYPE take M1TOKEN_TYPE_MACRO & ! && {
      $value
      @value i M1TOKEN_TEXT take 1 + m1_numerate_string = ;
      if '0' i M1TOKEN_TEXT take 1 + **c == 0 value != || {
        i M1TOKEN_EXPR take_addr value i M1TOKEN_TEXT take **c m1_express_number = ;
      }
    }
    @i i M1TOKEN_NEXT take = ;
  }
}

fun m1_print_hex 2 {
  $ctx
  $p
  @ctx 1 param = ;
  @p 0 param = ;

  $i
  @i p = ;
  while i 0 != {
    if i M1TOKEN_TYPE take M1TOKEN_TYPE_MACRO ^ {
      ctx M1CTX_DEST_FD take '\n' vfs_write ;
      ctx M1CTX_DEST_FD take i M1TOKEN_EXPR take vfs_write_string ;
    }
    @i i M1TOKEN_NEXT take = ;
  }
  ctx M1CTX_DEST_FD take '\n' vfs_write ;
}

fun m1_dealloc_list 1 {
  $head
  @head 0 param = ;
  ret ;

  $i
  @i head = ;
  while i 0 != {
    $tok
    @tok i = ;
    @i i M1TOKEN_NEXT take = ;
    tok M1TOKEN_TEXT take free ;
    tok M1TOKEN_EXPR take free ;
    tok free ;
  }
}

fun m1_assemble 2 {
  $files
  $outfile
  @files 1 param = ;
  @outfile 0 param = ;

  $ctx
  @ctx SIZEOF_M1CTX malloc = ;
  $head
  @head 0 = ;
  ctx M1CTX_DEST_FD take_addr outfile vfs_open = ;
  ctx M1CTX_DEST_FD take vfs_truncate ;
  $i
  @i 0 = ;
  while i files vector_size < {
    $name
    @name files i vector_at = ;
    ctx M1CTX_SOURCE_FD take_addr name vfs_open = ;
    @head ctx head m1_tokenize_line = ;
    ctx M1CTX_SOURCE_FD take vfs_close ;
    @i i 1 + = ;
  }
  head 0 != "m1_assemble: empty content" assert_msg ;
  @head head m1_reverse_list = ;
  ctx head m1_identify_macros ;
  ctx head m1_line_macro ;
  ctx head m1_process_string ;
  head m1_eval_immediates ;
  ctx head m1_preserve_other ;
  ctx head m1_print_hex ;
  ctx M1CTX_DEST_FD take vfs_close ;
  head m1_dealloc_list ;
  ctx free ;
  "Assembled dump:\n" 1 platform_log ;
  outfile dump_file ;
  "\n" 1 platform_log ;
}

fun m1_test 0 {
  $files
  @files 4 vector_init = ;
  files "/init/test.m1" strdup vector_push_back ;
  files "/ram/assembled" m1_assemble ;
  files free_vect_of_ptrs ;
}
