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
    store i + ch = ;
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
    store i + ch = ;
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