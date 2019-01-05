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

ifun cctx_emit 2

fun escape_char 2 {
  $from
  $to
  $ctx
  @from 2 param = ;
  @to 1 param = ;
  @ctx 0 param = ;

  $emit
  @emit to 0 == = ;
  $data
  @data 0 = ;
  $data_ptr
  @data_ptr @data = ;
  if emit {
    @to @data_ptr = ;
  }

  from ** **c 0 != "escape_char: unexpected null" assert_msg ;
  if from ** **c '\\' == {
    from from ** 1 + = ;
    $c
    @c from ** **c = ;
    c 0 != "escape_char: unexpected null" assert_msg ;
    $processed
    @processed 0 = ;
    if c '0' == {
      to ** 0 =c ;
      @processed 1 = ;
    }
    if c 'n' == {
      to ** '\n' =c ;
      @processed 1 = ;
    }
    if c 'r' == {
      to ** '\r' =c ;
      @processed 1 = ;
    }
    if c 't' == {
      to ** '\t' =c ;
      @processed 1 = ;
    }
    if c 'v' == {
      to ** '\v' =c ;
      @processed 1 = ;
    }
    if c 'f' == {
      to ** '\f' =c ;
      @processed 1 = ;
    }
    if c '\\' == {
      to ** '\\' =c ;
      @processed 1 = ;
    }
    if c '\'' == {
      to ** '\'' =c ;
      @processed 1 = ;
    }
    if c '\"' == {
      to ** '\"' =c ;
      @processed 1 = ;
    }
    processed "escape_char: unknown escape sequence" assert_msg ;
    from from ** 1 + = ;
    to to ** 1 + = ;
  } else {
    to ** from ** **c =c ;
    from from ** 1 + = ;
    to to ** 1 + = ;
  }

  if emit {
    data_ptr @data 1 + == "escape_char: error 1" assert_msg ;
    ctx data cctx_emit ;
  }
}

const TYPE_KIND_BASE 0
const TYPE_KIND_POINTER 1
const TYPE_KIND_FUNCTION 2
const TYPE_KIND_ARRAY 3
const TYPE_KIND_STRUCT 4
const TYPE_KIND_UNION 5
const TYPE_KIND_ENUM 6

const TYPE_KIND 0
const TYPE_BASE 4
const TYPE_SIZE 8
const TYPE_LENGTH 12
const TYPE_ARGS 16
const TYPE_ELLIPSIS 20
const TYPE_FIELDS_OFFS 24
const TYPE_FIELDS_TYPE_IDXS 28
const TYPE_FIELDS_NAMES 32
const SIZEOF_TYPE 36

fun type_init 0 {
  $type
  @type SIZEOF_TYPE malloc = ;
  type TYPE_ARGS take_addr 4 vector_init = ;
  type TYPE_FIELDS_OFFS take_addr 4 vector_init = ;
  type TYPE_FIELDS_TYPE_IDXS take_addr 4 vector_init = ;
  type TYPE_FIELDS_NAMES take_addr 4 vector_init = ;
  type ret ;
}

fun type_destroy 1 {
  $type
  @type 0 param = ;
  type TYPE_ARGS take vector_destroy ;
  type TYPE_FIELDS_OFFS take vector_destroy ;
  type TYPE_FIELDS_TYPE_IDXS take vector_destroy ;
  type TYPE_FIELDS_NAMES take free_vect_of_ptrs ;
  type free ;
}

fun type_dump 1 {
  $type
  @type 0 param = ;

  $kind
  @kind type TYPE_KIND take = ;
  $base
  @base type TYPE_BASE take = ;

  if kind TYPE_KIND_BASE == {
    "Base type #" 1 platform_log ;
    base itoa 1 platform_log ;
  }

  if kind TYPE_KIND_POINTER == {
    "Pointer type to #" 1 platform_log ;
    base itoa 1 platform_log ;
  }

  if kind TYPE_KIND_FUNCTION == {
    "Function type returning #" 1 platform_log ;
    base itoa 1 platform_log ;
    $args
    @args type TYPE_ARGS take = ;
    $ellipsis
    @ellipsis type TYPE_ELLIPSIS take = ;
    if args vector_size 0 == ellipsis ! && {
      " taking no argument" 1 platform_log ;
    } else {
      " taking arguments" 1 platform_log ;
      $i
      @i 0 = ;
      while i args vector_size < {
        " #" 1 platform_log ;
        args i vector_at itoa 1 platform_log ;
        @i i 1 + = ;
      }
      if ellipsis {
        " ..." 1 platform_log ;
      }
    }
  }

  if kind TYPE_KIND_ARRAY == {
    "Array type of #" 1 platform_log ;
    base itoa 1 platform_log ;
    $length
    @length type TYPE_LENGTH take = ;
    if length 0xffffffff == {
      " of unspecified length" 1 platform_log ;
    } else {
      " of length " 1 platform_log ;
      length itoa 1 platform_log ;
    }
  }

  if kind TYPE_KIND_STRUCT == {
    "Struct type with fields" 1 platform_log ;
    $i
    @i 0 = ;
    $names
    $type_idxs
    $offs
    @names type TYPE_FIELDS_NAMES take = ;
    @type_idxs type TYPE_FIELDS_TYPE_IDXS take = ;
    @offs type TYPE_FIELDS_OFFS take = ;
    while i names vector_size < {
      " " 1 platform_log ;
      $name
      @name names i vector_at = ;
      if name **c '\0' == {
        @name "<anonymous>" = ;
      }
      name 1 platform_log ;
      " (@" 1 platform_log ;
      offs i vector_at itoa 1 platform_log ;
      " #" 1 platform_log ;
      type_idxs i vector_at itoa 1 platform_log ;
      ")" 1 platform_log ;
      @i i 1 + = ;
    }
  }

  if kind TYPE_KIND_UNION == {
    "Union type with fields" 1 platform_log ;
    $i
    @i 0 = ;
    $names
    $type_idxs
    $offs
    @names type TYPE_FIELDS_NAMES take = ;
    @type_idxs type TYPE_FIELDS_TYPE_IDXS take = ;
    @offs type TYPE_FIELDS_OFFS take = ;
    while i names vector_size < {
      " " 1 platform_log ;
      $name
      @name names i vector_at = ;
      if name **c '\0' == {
        @name "<anonymous>" = ;
      }
      name 1 platform_log ;
      " (@" 1 platform_log ;
      offs i vector_at itoa 1 platform_log ;
      " #" 1 platform_log ;
      type_idxs i vector_at itoa 1 platform_log ;
      ")" 1 platform_log ;
      @i i 1 + = ;
    }
  }

  $size
  @size type TYPE_SIZE take = ;
  if size 0xffffffff == {
    ", of undertermined size" 1 platform_log ;
  } else {
    ", of size " 1 platform_log ;
    size itoa 1 platform_log ;
  }
}

fun type_get_idx 2 {
  $type
  $name
  @type 1 param = ;
  @name 0 param = ;

  type TYPE_KIND take TYPE_KIND_STRUCT == type TYPE_KIND take TYPE_KIND_UNION == || "type_get_idx: type is not a struct or a union" assert_msg ;

  $i
  @i 0 = ;
  $names
  @names type TYPE_FIELDS_NAMES take = ;
  while i names vector_size < {
    if name names i vector_at strcmp 0 == {
      i ret ;
    }
    @i i 1 + = ;
  }
  0xffffffff ret ;
}

const GLOBAL_TYPE_IDX 0
const GLOBAL_LOC 4
const SIZEOF_GLOBAL 8

fun global_init 0 {
  $global
  @global SIZEOF_GLOBAL malloc = ;
  global ret ;
}

fun global_destroy 1 {
  $global
  @global 0 param = ;
  global free ;
}

fun global_dump 1 {
  $global
  @global 0 param = ;
  "has type #" 1 platform_log ;
  global GLOBAL_TYPE_IDX take itoa 1 platform_log ;
  " and is stored at " 1 platform_log ;
  global GLOBAL_LOC take itoa 1 platform_log ;
}

const CCTX_ASTINT_GET_TOKEN 0
const CCTX_ASTINT_GET_TOKEN_OR_FAIL 4
const CCTX_ASTINT_GIVE_BACK_TOKEN 8
const CCTX_ASTINT_PARSE_TYPE 12
const CCTX_ASTINT_CTX 16
const SIZEOF_CCTX_ASTINT 20

ifun cctx_get_token 1
ifun cctx_give_back_token 1
ifun cctx_get_token_or_fail 1
ifun cctx_parse_type 1

fun cctx_astint_get_token 1 {
  $int
  @int 0 param = ;

  int CCTX_ASTINT_CTX take cctx_get_token ret ;
}

fun cctx_astint_get_token_or_fail 1 {
  $int
  @int 0 param = ;

  int CCTX_ASTINT_CTX take cctx_get_token_or_fail ret ;
}

fun cctx_astint_give_back_token 1 {
  $int
  @int 0 param = ;

  int CCTX_ASTINT_CTX take cctx_give_back_token ;
}

fun cctx_astint_parse_type 1 {
  $int
  @int 0 param = ;

  int CCTX_ASTINT_CTX take cctx_parse_type ret ;
}

fun cctx_astint_init 1 {
  $ctx
  @ctx 0 param = ;

  $int
  @int SIZEOF_CCTX_ASTINT malloc = ;
  int CCTX_ASTINT_GET_TOKEN take_addr @cctx_astint_get_token = ;
  int CCTX_ASTINT_GET_TOKEN_OR_FAIL take_addr @cctx_astint_get_token_or_fail = ;
  int CCTX_ASTINT_GIVE_BACK_TOKEN take_addr @cctx_astint_give_back_token = ;
  int CCTX_ASTINT_PARSE_TYPE take_addr @cctx_astint_parse_type = ;
  int CCTX_ASTINT_CTX take_addr ctx = ;
  int ret ;
}

fun cctx_astint_destroy 1 {
  $int
  @int 0 param = ;

  int free ;
}

const CCTX_TYPES 0
const CCTX_TYPENAMES 4
const CCTX_GLOBALS 8
const CCTX_TOKENS 12
const CCTX_TOKENS_POS 16
const CCTX_STAGE 20
const CCTX_CURRENT_LOC 24
const CCTX_LABEL_POS 28
const CCTX_LABEL_BUF 32
const CCTX_LABEL_NUM 36
const CCTX_STRUCTS 40
const CCTX_UNIONS 44
const CCTX_ENUM_CONSTS 48
const CCTX_HANDLES 52
const CCTX_VERBOSE 56
const CCTX_RUNTIME 60
const CCTX_ASTINT 64
const SIZEOF_CCTX 68

fun cctx_init_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TYPES take_addr 4 vector_init = ;
  ctx CCTX_TYPENAMES take_addr map_init = ;
  ctx CCTX_STRUCTS take_addr map_init = ;
  ctx CCTX_UNIONS take_addr map_init = ;
  ctx CCTX_ENUM_CONSTS take_addr map_init = ;
}

fun cctx_setup_handles 1 {
  $ctx
  @ctx 0 param = ;

  $handles
  @handles ctx CCTX_HANDLES take = ;

  handles @platform_write_char vector_push_back ;
  handles @platform_setjmp vector_push_back ;
  handles @platform_longjmp vector_push_back ;
  handles @malloc vector_push_back ;
  handles @calloc vector_push_back ;
  handles @free vector_push_back ;
  handles @realloc vector_push_back ;
  handles @itoa vector_push_back ;
}

fun cctx_setup_runtime 1 {
  $ctx
  @ctx 0 param = ;

  $fd
  @fd "/disk1/stdlib/int64.asm" vfs_open = ;
  ctx CCTX_RUNTIME take ASMCTX_VERBOSE take_addr 0 = ;
  ctx CCTX_RUNTIME take ASMCTX_DEBUG take_addr 0 = ;
  ctx CCTX_RUNTIME take fd asmctx_set_fd ;
  ctx CCTX_RUNTIME take asmctx_compile ;
  fd vfs_close ;
}

fun cctx_init 1 {
  $tokens
  @tokens 0 param = ;

  $ctx
  @ctx SIZEOF_CCTX malloc = ;
  ctx cctx_init_types ;
  ctx CCTX_GLOBALS take_addr map_init = ;
  ctx CCTX_TOKENS take_addr tokens = ;
  ctx CCTX_TOKENS_POS take_addr 0 = ;
  ctx CCTX_LABEL_NUM take_addr 0 = ;
  ctx CCTX_LABEL_BUF take_addr 32 malloc = ;
  ctx CCTX_LABEL_POS take_addr 4 vector_init = ;
  ctx CCTX_HANDLES take_addr 4 vector_init = ;
  ctx CCTX_VERBOSE take_addr 1 = ;
  ctx CCTX_RUNTIME take_addr asmctx_init = ;
  ctx CCTX_ASTINT take_addr ctx cctx_astint_init = ;

  ctx cctx_setup_handles ;
  #ctx cctx_setup_runtime ;

  ctx ret ;
}

fun cctx_destroy_types 1 {
  $ctx
  @ctx 0 param = ;

  $types
  @types ctx CCTX_TYPES take = ;
  $i
  @i 0 = ;
  while i types vector_size < {
    types i vector_at type_destroy ;
    @i i 1 + = ;
  }
  types vector_destroy ;

  $typenames
  @typenames ctx CCTX_TYPENAMES take = ;
  typenames map_destroy ;

  $structs
  @structs ctx CCTX_STRUCTS take = ;
  structs map_destroy ;

  $unions
  @unions ctx CCTX_UNIONS take = ;
  unions map_destroy ;

  ctx CCTX_ENUM_CONSTS take map_destroy ;
}

fun global_destroy_closure 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  value global_destroy ;
}

fun cctx_destroy 1 {
  $ctx
  @ctx 0 param = ;

  ctx cctx_destroy_types ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  globals @global_destroy_closure 0 map_foreach ;
  globals map_destroy ;

  ctx CCTX_LABEL_POS take vector_destroy ;
  ctx CCTX_LABEL_BUF take free ;
  ctx CCTX_HANDLES take vector_destroy ;
  ctx CCTX_RUNTIME take asmctx_destroy ;
  ctx CCTX_ASTINT take cctx_astint_destroy ;

  ctx free ;
}

fun cctx_reset_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx cctx_destroy_types ;
  ctx cctx_init_types ;
}

fun cctx_get_type 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  ctx CCTX_TYPES take type_idx vector_at ret ;
}

fun cctx_dump_types 1 {
  $ctx
  @ctx 0 param = ;

  $i
  @i 0 = ;
  $types
  @types ctx CCTX_TYPES take = ;
  while i types vector_size < {
    "#" 1 platform_log ;
    i itoa 1 platform_log ;
    ": " 1 platform_log ;
    types i vector_at type_dump ;
    "\n" 1 platform_log ;
    @i i 1 + = ;
  }
}

fun dump_typename_closure 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  "Typename " 1 platform_log ;
  key 1 platform_log ;
  ": #" 1 platform_log ;
  value itoa 1 platform_log ;
  "\n" 1 platform_log ;
}

fun cctx_dump_typenames 1 {
  $ctx
  @ctx 0 param = ;

  $typenames
  @typenames ctx CCTX_TYPENAMES take = ;
  typenames @dump_typename_closure 0 map_foreach ;
}

fun dump_global_closure 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  "Global " 1 platform_log ;
  key 1 platform_log ;
  ": " 1 platform_log ;
  value global_dump ;
  "\n" 1 platform_log ;
}

fun cctx_dump_globals 1 {
  $ctx
  @ctx 0 param = ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  globals @dump_global_closure 0 map_foreach ;
}

ifun cctx_type_compare 3

fun _cctx_type_compare 3 {
  $ctx
  $t1
  $t2
  @ctx 2 param = ;
  @t1 1 param = ;
  @t2 0 param = ;

  if t1 TYPE_KIND take t2 TYPE_KIND take != { 0 ret ; }
  if t1 TYPE_KIND take TYPE_KIND_BASE == {
    if t1 TYPE_BASE take t2 TYPE_BASE take != { 0 ret ; }
    1 ret ;
  }

  if t1 TYPE_KIND take TYPE_KIND_POINTER == {
    if ctx t1 TYPE_BASE take t2 TYPE_BASE take cctx_type_compare ! { 0 ret ; }
    1 ret ;
  }

  if t1 TYPE_KIND take TYPE_KIND_FUNCTION == {
    if ctx t1 TYPE_BASE take t2 TYPE_BASE take cctx_type_compare ! { 0 ret ; }
    if t1 TYPE_ELLIPSIS take t2 TYPE_ELLIPSIS take != { 0 ret ; }
    $args1
    $args2
    @args1 t1 TYPE_ARGS take = ;
    @args2 t2 TYPE_ARGS take = ;
    if args1 vector_size args2 vector_size != { 0 ret ; }
    $i
    @i 0 = ;
    while i args1 vector_size < {
      if ctx args1 i vector_at args2 i vector_at cctx_type_compare ! { 0 ret ; }
      @i i 1 + = ;
    }
    1 ret ;
  }

  if t1 TYPE_KIND take TYPE_KIND_ARRAY == {
    if ctx t1 TYPE_BASE take t2 TYPE_BASE take cctx_type_compare ! { 0 ret ; }
    if t1 TYPE_LENGTH take t2 TYPE_LENGTH take != { 0 ret ; }
    1 ret ;
  }

  # structs and unions are always different unless they have the same
  # type index, which has already been checked
  if t1 TYPE_KIND take TYPE_KIND_STRUCT == {
    0 ret ;
  }

  if t1 TYPE_KIND take TYPE_KIND_UNION == {
    0 ret ;
  }

  0 "_type_compare: not yet implemented" assert_msg ;
}

fun cctx_type_compare 3 {
  $ctx
  $ti1
  $ti2
  @ctx 2 param = ;
  @ti1 1 param = ;
  @ti2 0 param = ;

  if ti1 ti2 == { 1 ret ; }

  $t1
  $t2
  @t1 ctx CCTX_TYPES take ti1 vector_at = ;
  @t2 ctx CCTX_TYPES take ti2 vector_at = ;

  $res
  @res ctx t1 t2 _cctx_type_compare = ;
  if res {
    t1 TYPE_SIZE take t2 TYPE_SIZE take == "type_compare: type are equal, but have different size" assert_msg ;
  }
  res ret ;
}

fun cctx_add_type 2 {
  $ctx
  $type
  @ctx 1 param = ;
  @type 0 param = ;

  # Add the type to the list
  $types
  $idx
  @types ctx CCTX_TYPES take = ;
  @idx types vector_size = ;
  types type vector_push_back ;

  # Check if the new type already matches with another
  $i
  @i 0 = ;
  while i idx < {
    if ctx i idx cctx_type_compare {
      # Found a match, remove the new one and return the old one
      types vector_pop_back type_destroy ;
      i ret ;
    }
    @i i 1 + = ;
  }

  idx ret ;
}

fun cctx_get_pointer_type 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_POINTER = ;
  type TYPE_BASE take_addr type_idx = ;
  type TYPE_SIZE take_addr 4 = ;

  ctx type cctx_add_type ret ;
}

fun cctx_get_array_type 3 {
  $ctx
  $type_idx
  $length
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @length 0 param = ;

  $base_type
  @base_type ctx CCTX_TYPES take type_idx vector_at = ;
  base_type TYPE_SIZE take 0xffffffff != "cctx_get_array_type: base type is invalid size" assert_msg ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_ARRAY = ;
  type TYPE_BASE take_addr type_idx = ;
  type TYPE_LENGTH take_addr length = ;
  type TYPE_SIZE take_addr length base_type TYPE_SIZE take * = ;
  # -1 is used when length is not specified
  if length 0xffffffff == {
    type TYPE_SIZE take_addr 0xffffffff = ;
  }

  ctx type cctx_add_type ret ;
}

fun cctx_get_function_type 4 {
  $ctx
  $type_idx
  $args
  $ellipsis
  @ctx 3 param = ;
  @type_idx 2 param = ;
  @args 1 param = ;
  @ellipsis 0 param = ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_FUNCTION = ;
  type TYPE_BASE take_addr type_idx = ;
  type TYPE_SIZE take_addr 0xffffffff = ;
  type TYPE_ARGS take vector_destroy ;
  type TYPE_ARGS take_addr args = ;
  type TYPE_ELLIPSIS take_addr ellipsis = ;

  ctx type cctx_add_type ret ;
}

ifun cctx_type_footprint 2

fun cctx_construct_struct_type 3 {
  $ctx
  $type_idxs
  $names
  @ctx 2 param = ;
  @type_idxs 1 param = ;
  @names 0 param = ;

  type_idxs vector_size names vector_size == "cctx_construct_struct_type: inputs have different lengths" assert_msg ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_STRUCT = ;
  type TYPE_FIELDS_TYPE_IDXS take vector_destroy ;
  type TYPE_FIELDS_NAMES take vector_destroy ;
  type TYPE_FIELDS_TYPE_IDXS take_addr type_idxs = ;
  type TYPE_FIELDS_NAMES take_addr names = ;

  # Compute offsets and size
  $off
  @off 0 = ;
  $i
  @i 0 = ;
  $offs
  @offs type TYPE_FIELDS_OFFS take = ;
  while i names vector_size < {
    offs off vector_push_back ;
    $fp
    @fp ctx type_idxs i vector_at cctx_type_footprint = ;
    @off off fp + = ;
    @i i 1 + = ;
  }
  type TYPE_SIZE take_addr off = ;

  # Inherit labels from anonymous subtypes
  @i 0 = ;
  $orig_len
  @orig_len names vector_size = ;
  while i orig_len < {
    if names i vector_at **c '\0' == {
      $base_off
      @base_off offs i vector_at = ;
      $type_idx
      $type
      @type_idx type_idxs i vector_at = ;
      @type ctx type_idx cctx_get_type = ;
      type TYPE_KIND take TYPE_KIND_STRUCT == type TYPE_KIND take TYPE_KIND_UNION == || "cctx_construct_struct_type: anonymous field is not union or strucr" assert_msg ;
      $sub_type_idxs
      $sub_names
      $sub_offs
      @sub_type_idxs type TYPE_FIELDS_TYPE_IDXS take = ;
      @sub_names type TYPE_FIELDS_NAMES take = ;
      @sub_offs type TYPE_FIELDS_OFFS take = ;
      $j
      @j 0 = ;
      while j sub_names vector_size < {
        $sub_name
        @sub_name sub_names j vector_at = ;
        if sub_name **c '\0' != {
          names sub_name strdup vector_push_back ;
          type_idxs sub_type_idxs j vector_at vector_push_back ;
          offs sub_offs j vector_at base_off + vector_push_back ;
        }
        @j j 1 + = ;
      }
    }
    @i i 1 + = ;
  }

  type ret ;
}

fun cctx_get_incomplete_struct_type 1 {
  $ctx
  @ctx 0 param = ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_STRUCT = ;
  type TYPE_SIZE take_addr 0xffffffff = ;

  ctx type cctx_add_type ret ;
}

fun cctx_construct_union_type 3 {
  $ctx
  $type_idxs
  $names
  @ctx 2 param = ;
  @type_idxs 1 param = ;
  @names 0 param = ;

  type_idxs vector_size names vector_size == "cctx_construct_union_type: inputs have different lengths" assert_msg ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_UNION = ;
  type TYPE_FIELDS_TYPE_IDXS take vector_destroy ;
  type TYPE_FIELDS_NAMES take vector_destroy ;
  type TYPE_FIELDS_TYPE_IDXS take_addr type_idxs = ;
  type TYPE_FIELDS_NAMES take_addr names = ;

  # Compute size
  $size
  @size 0 = ;
  $i
  @i 0 = ;
  $offs
  @offs type TYPE_FIELDS_OFFS take = ;
  while i names vector_size < {
    offs 0 vector_push_back ;
    @size size ctx type_idxs i vector_at cctx_type_footprint max = ;
    @i i 1 + = ;
  }
  type TYPE_SIZE take_addr size = ;

  # Inherit labels from anonymous subtypes
  @i 0 = ;
  $orig_len
  @orig_len names vector_size = ;
  while i orig_len < {
    if names i vector_at **c '\0' == {
      $base_off
      @base_off offs i vector_at = ;
      $type_idx
      $type
      @type_idx type_idxs i vector_at = ;
      @type ctx type_idx cctx_get_type = ;
      type TYPE_KIND take TYPE_KIND_STRUCT == type TYPE_KIND take TYPE_KIND_UNION == || "cctx_construct_struct_type: anonymous field is not union or strucr" assert_msg ;
      $sub_type_idxs
      $sub_names
      $sub_offs
      @sub_type_idxs type TYPE_FIELDS_TYPE_IDXS take = ;
      @sub_names type TYPE_FIELDS_NAMES take = ;
      @sub_offs type TYPE_FIELDS_OFFS take = ;
      $j
      @j 0 = ;
      while j sub_names vector_size < {
        $sub_name
        @sub_name sub_names j vector_at = ;
        if sub_name **c '\0' != {
          names sub_name strdup vector_push_back ;
          type_idxs sub_type_idxs j vector_at vector_push_back ;
          offs sub_offs j vector_at base_off + vector_push_back ;
        }
        @j j 1 + = ;
      }
    }
    @i i 1 + = ;
  }

  type ret ;
}

fun cctx_get_incomplete_union_type 1 {
  $ctx
  @ctx 0 param = ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_UNION = ;
  type TYPE_SIZE take_addr 0xffffffff = ;

  ctx type cctx_add_type ret ;
}

const TYPE_VOID 0

const TYPE_FIRST_INTEGER 1
const TYPE_CHAR 1
const TYPE_SCHAR 2
const TYPE_UCHAR 3
const TYPE_SHORT 4
const TYPE_INT 5
const TYPE_LONG 6
const TYPE_USHORT 7
const TYPE_UINT 8
const TYPE_ULONG 9
const TYPE_BOOL 10
const TYPE_LAST_INTEGER 10

const TYPE_CHAR_ARRAY 11
const TYPE_VOID_PTR 12

fun is_integer_type 1 {
  $idx
  @idx 0 param = ;
  TYPE_FIRST_INTEGER idx <= TYPE_LAST_INTEGER idx >= && ret ;
}

fun cctx_create_basic_type 3 {
  $ctx
  $idx
  $size
  @ctx 2 param = ;
  @idx 1 param = ;
  @size 0 param = ;

  $types
  @types ctx CCTX_TYPES take = ;

  idx types vector_size == "cctx_create_basic_type: error 1" assert_msg ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_BASE = ;
  type TYPE_BASE take_addr idx = ;
  type TYPE_SIZE take_addr size = ;
  types type vector_push_back ;
}

fun cctx_create_basic_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx TYPE_VOID 0xffffffff cctx_create_basic_type ;
  ctx TYPE_CHAR 1 cctx_create_basic_type ;
  ctx TYPE_SCHAR 1 cctx_create_basic_type ;
  ctx TYPE_UCHAR 1 cctx_create_basic_type ;
  ctx TYPE_SHORT 2 cctx_create_basic_type ;
  ctx TYPE_INT 4 cctx_create_basic_type ;
  ctx TYPE_LONG 8 cctx_create_basic_type ;
  ctx TYPE_USHORT 2 cctx_create_basic_type ;
  ctx TYPE_UINT 4 cctx_create_basic_type ;
  ctx TYPE_ULONG 8 cctx_create_basic_type ;
  ctx TYPE_BOOL 4 cctx_create_basic_type ;

  ctx TYPE_CHAR 0xffffffff cctx_get_array_type TYPE_CHAR_ARRAY == "cctx_create_basic_types: error 1" assert_msg ;
  ctx TYPE_VOID cctx_get_pointer_type TYPE_VOID_PTR == "cctx_create_basic_types: error 2" assert_msg ;
}

fun cctx_has_global 2 {
  $ctx
  $name
  @ctx 1 param = ;
  @name 0 param = ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  globals name map_has ret ;
}

fun cctx_get_global 2 {
  $ctx
  $name
  @ctx 1 param = ;
  @name 0 param = ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  globals name map_has "cctx_get_global: global does not exist" name assert_msg_str ;
  $global
  @global globals name map_at = ;
  global ret ;
}

fun cctx_add_global 4 {
  $ctx
  $name
  $loc
  $type_idx
  @ctx 3 param = ;
  @name 2 param = ;
  @loc 1 param = ;
  @type_idx 0 param = ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  $present
  @present globals name map_has = ;
  $global
  if present {
    @global globals name map_at = ;
    ctx global GLOBAL_TYPE_IDX take type_idx cctx_type_compare "cctx_add_global: types do not match" assert_msg ;
  } else {
    ctx CCTX_STAGE take 0 == "cctx_add_global: error 1" assert_msg ;
    @global global_init = ;
    global GLOBAL_TYPE_IDX take_addr type_idx = ;
    global GLOBAL_LOC take_addr loc = ;
    globals name global map_set ;
  }

  if ctx CCTX_STAGE take 0 == {
    global GLOBAL_LOC take_addr 0xffffffff = ;
  } else {
    present "cctx_add_global: error 2" assert_msg ;
  }

  if ctx CCTX_STAGE take 1 == {
    if loc 0xffffffff != {
      global GLOBAL_LOC take 0xffffffff == "cctx_add_global: global is defined more than once" assert_msg ;
      global GLOBAL_LOC take_addr loc = ;
    }
  }

  if ctx CCTX_STAGE take 2 == {
    if loc 0xffffffff != {
      global GLOBAL_LOC take loc == "cctx_add_global: error 3" assert_msg ;
    }
  }
}

fun cctx_emit 2 {
  $ctx
  $byte
  @ctx 1 param = ;
  @byte 0 param = ;

  if ctx CCTX_STAGE take 2 == {
    ctx CCTX_CURRENT_LOC take byte =c ;
  }
  ctx CCTX_CURRENT_LOC take_addr ctx CCTX_CURRENT_LOC take 1 + = ;
}

fun cctx_emit16 2 {
  $ctx
  $word
  @ctx 1 param = ;
  @word 0 param = ;

  ctx word cctx_emit ;
  ctx word 8 >> cctx_emit ;
}

fun cctx_emit32 2 {
  $ctx
  $dword
  @ctx 1 param = ;
  @dword 0 param = ;

  ctx dword cctx_emit16 ;
  ctx dword 16 >> cctx_emit16 ;
}

fun cctx_emit_zeros 2 {
  $ctx
  $num
  @ctx 1 param = ;
  @num 0 param = ;

  $i
  @i 0 = ;
  while i num < {
    ctx 0 cctx_emit ;
    @i i 1 + = ;
  }
}

ifun cctx_gen_label 3
ifun cctx_fix_label 4
ifun cctx_gen_jump 3
ifun cctx_gen_label_jump 5

fun cctx_is_eof 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TOKENS_POS take ctx CCTX_TOKENS take vector_size == ret ;
}

fun cctx_get_token 1 {
  $ctx
  @ctx 0 param = ;

  if ctx CCTX_TOKENS_POS take ctx CCTX_TOKENS take vector_size == {
    0 ret ;
  } else {
    $tok
    @tok ctx CCTX_TOKENS take ctx CCTX_TOKENS_POS take vector_at = ;
    ctx CCTX_TOKENS_POS take_addr ctx CCTX_TOKENS_POS take 1 + = ;
    if ctx CCTX_VERBOSE take {
      " " 1 platform_log ;
      tok 1 platform_log ;
    }
    tok ret ;
  }
}

fun cctx_give_back_token 1 {
  $ctx
  @ctx 0 param = ;

  if ctx CCTX_VERBOSE take {
    " <gb>" 1 platform_log ;
  }
  ctx CCTX_TOKENS_POS take 0 > "cctx_give_back_token: error 1" assert_msg ;
  ctx CCTX_TOKENS_POS take_addr ctx CCTX_TOKENS_POS take 1 - = ;
}

fun cctx_save_token_pos 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TOKENS_POS take ret ;
}

fun cctx_restore_token_pos 2 {
  $ctx
  $pos
  @ctx 1 param = ;
  @pos 0 param = ;

  ctx CCTX_TOKENS_POS take_addr pos = ;
}

fun cctx_get_token_or_fail 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx cctx_get_token = ;
  tok 0 != "cctx_get_token_or_fail: unexpected end-of-file" assert_msg ;
  tok ret ;
}

fun cctx_go_to_matching 3 {
  $ctx
  $open
  $close
  @ctx 2 param = ;
  @open 1 param = ;
  @close 0 param = ;

  $level
  @level 1 = ;
  while level 0 > {
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    if tok open strcmp 0 == {
      @level level 1 + = ;
    }
    if tok close strcmp 0 == {
      @level level 1 - = ;
    }
  }
}

fun cctx_print_token_pos 1 {
  $ctx
  @ctx 0 param = ;

  "Token pos: " 1 platform_log ;
  ctx CCTX_TOKENS_POS take itoa 1 platform_log ;
  "\n" 1 platform_log ;
}

ifun cctx_parse_type 1
ifun cctx_parse_declarator 5

fun cctx_parse_struct 3 {
  $ctx
  $type_idxs_ptr
  $names_ptr
  @ctx 2 param = ;
  @type_idxs_ptr 1 param = ;
  @names_ptr 0 param = ;

  $type_idxs
  $names
  @type_idxs 4 vector_init = ;
  @names 4 vector_init = ;

  $cont
  @cont 1 = ;
  while cont {
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    if tok "}" strcmp 0 == {
      @cont 0 = ;
    } else {
      ctx cctx_give_back_token ;
      $type_idx
      @type_idx ctx cctx_parse_type = ;
      type_idx 0xffffffff != "cctx_parse_struct: type expected" assert_msg ;
      $cont2
      @cont2 1 = ;
      while cont2 {
        $actual_type_idx
        $name
        if ctx type_idx @actual_type_idx @name 0 cctx_parse_declarator ! {
          # If the declarator parsing fails, then we assume that this
          # is an annonymous struct or union, which for the moment we
          # just represent as having an empty name; names will be
          # fixed later, when the type is actually created
          @name "" = ;
          @actual_type_idx type_idx = ;
        }
        type_idxs actual_type_idx vector_push_back ;
        names name strdup vector_push_back ;
        @tok ctx cctx_get_token_or_fail = ;
        if tok ":" strcmp 0 == {
          @tok ctx cctx_get_token_or_fail = ;
          @tok ctx cctx_get_token_or_fail = ;
        }
        if tok ";" strcmp 0 == {
          @cont2 0 = ;
        } else {
          tok "," strcmp 0 == "cctx_parse_struct: comma expected" assert_msg ;
        }
      }
    }
  }

  type_idxs_ptr type_idxs = ;
  names_ptr names = ;
}

ifun ast_eval_compile 2

fun cctx_parse_ast1 2 {
  $ctx
  $term
  @ctx 1 param = ;
  @term 0 param = ;

  if ctx CCTX_VERBOSE take {
    " <pa1>" 1 platform_log ;
  }

  $res
  @res ctx CCTX_ASTINT take term ast_parse1 = ;

  if ctx CCTX_VERBOSE take {
    " </pa1>" 1 platform_log ;
  }

  res ret ;
}

fun cctx_parse_ast2 3 {
  $ctx
  $term1
  $term2
  @ctx 2 param = ;
  @term1 1 param = ;
  @term2 0 param = ;

  if ctx CCTX_VERBOSE take {
    " <pa2>" 1 platform_log ;
  }

  $res
  @res ctx CCTX_ASTINT take term1 term2 ast_parse2 = ;

  if ctx CCTX_VERBOSE take {
    " </pa2>" 1 platform_log ;
  }

  res ret ;
}

fun cctx_parse_ast3 4 {
  $ctx
  $term1
  $term2
  $term3
  @ctx 3 param = ;
  @term1 2 param = ;
  @term2 1 param = ;
  @term3 0 param = ;

  if ctx CCTX_VERBOSE take {
    " <pa3>" 1 platform_log ;
  }

  $res
  @res ctx CCTX_ASTINT take term1 term2 term3 ast_parse3 = ;

  if ctx CCTX_VERBOSE take {
    " </pa3>" 1 platform_log ;
  }

  res ret ;
}

fun cctx_parse_enum 1 {
  $ctx
  @ctx 0 param = ;

  $enum_consts
  @enum_consts ctx CCTX_ENUM_CONSTS take = ;

  $cont
  @cont 1 = ;
  $val
  @val 0 = ;
  while cont {
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    if tok "}" strcmp 0 == {
      @cont 0 = ;
    } else {
      $ident
      @ident tok = ;
      @tok ctx cctx_get_token_or_fail = ;
      if tok "=" strcmp 0 == {
        $ast
        @ast ctx "}" "," cctx_parse_ast2 = ;
        @val ctx ast ast_eval_compile = ;
        ast ast_destroy ;
        @tok ctx cctx_get_token_or_fail = ;
      }
      enum_consts ident map_has ! "cctx_parse_enum: constant is already defined" assert_msg ;
      enum_consts ident val map_set ;
      @val val 1 + = ;
      if tok "}" strcmp 0 == {
        @cont 0 = ;
      } else {
        tok "," strcmp 0 == "cctx_parse_enum: comma expected" assert_msg ;
      }
    }
  }
}

fun cctx_parse_type 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx cctx_get_token_or_fail = ;

  # Ignore constness
  if tok "const" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
  }

  if tok "void" strcmp 0 == { TYPE_VOID ret ; }
  if tok "_Bool" strcmp 0 == { TYPE_BOOL ret ; }
  if tok "char" strcmp 0 == { TYPE_CHAR ret ; }
  if tok "short" strcmp 0 == { TYPE_SHORT ret ; }
  if tok "int" strcmp 0 == { TYPE_INT ret ; }
  if tok "signed" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    if tok "char" strcmp 0 == { TYPE_SCHAR ret ; }
    if tok "short" strcmp 0 == { TYPE_SHORT ret ; }
    if tok "int" strcmp 0 == { TYPE_INT ret ; }
    if tok "long" strcmp 0 == {
      @tok ctx cctx_get_token_or_fail = ;
      if tok "int" strcmp 0 == { TYPE_LONG ret ; }
      if tok "long" strcmp 0 == {
        @tok ctx cctx_get_token_or_fail = ;
        if tok "int" strcmp 0 == { TYPE_LONG ret ; }
        ctx cctx_give_back_token ;
        TYPE_LONG ret ;
      }
      ctx cctx_give_back_token ;
      TYPE_LONG ret ;
    }
    ctx cctx_give_back_token ;
    TYPE_INT ret ;
  }
  if tok "unsigned" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    if tok "char" strcmp 0 == { TYPE_UCHAR ret ; }
    if tok "short" strcmp 0 == { TYPE_USHORT ret ; }
    if tok "int" strcmp 0 == { TYPE_UINT ret ; }
    if tok "long" strcmp 0 == {
      @tok ctx cctx_get_token_or_fail = ;
      if tok "int" strcmp 0 == { TYPE_ULONG ret ; }
      if tok "long" strcmp 0 == {
        @tok ctx cctx_get_token_or_fail = ;
        if tok "int" strcmp 0 == { TYPE_ULONG ret ; }
        ctx cctx_give_back_token ;
        TYPE_ULONG ret ;
      }
      ctx cctx_give_back_token ;
      TYPE_ULONG ret ;
    }
    ctx cctx_give_back_token ;
    TYPE_UINT ret ;
  }
  if tok "long" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    if tok "long" strcmp 0 == { TYPE_LONG ret ; }
    ctx cctx_give_back_token ;
    TYPE_LONG ret ;
  }

  if tok "struct" strcmp 0 == {
    $tag
    $type_idxs
    $names
    @tag 0 = ;
    @type_idxs 0 = ;
    @tok ctx cctx_get_token_or_fail = ;
    $structs
    @structs ctx CCTX_STRUCTS take = ;
    $type_idx
    if tok "{" strcmp 0 != {
      @tag tok = ;
      @tok ctx cctx_get_token_or_fail = ;
      if structs tag map_has {
        @type_idx structs tag map_at = ;
      } else {
        @type_idx ctx cctx_get_incomplete_struct_type = ;
        structs tag type_idx map_set ;
      }
    } else {
      @type_idx ctx cctx_get_incomplete_struct_type = ;
    }
    if tok "{" strcmp 0 == {
      ctx @type_idxs @names cctx_parse_struct ;
      $type
      @type ctx type_idx cctx_get_type = ;
      type TYPE_SIZE take 0xffffffff == "cctx_parse_type: cannot define a struct twice" assert_msg ;
      $newtype
      @newtype ctx type_idxs names cctx_construct_struct_type = ;
      type type_destroy ;
      ctx CCTX_TYPES take type_idx vector_at_addr newtype = ;
    } else {
      ctx cctx_give_back_token ;
      tag 0 != "cctx_parse_type: struct without neither tag nor definition" assert_msg ;
    }

    type_idx ret ;
  }

  if tok "union" strcmp 0 == {
    $tag
    $type_idxs
    $names
    @tag 0 = ;
    @type_idxs 0 = ;
    @tok ctx cctx_get_token_or_fail = ;
    $unions
    @unions ctx CCTX_UNIONS take = ;
    $type_idx
    if tok "{" strcmp 0 != {
      @tag tok = ;
      @tok ctx cctx_get_token_or_fail = ;
      if unions tag map_has {
        @type_idx unions tag map_at = ;
      } else {
        @type_idx ctx cctx_get_incomplete_union_type = ;
        unions tag type_idx map_set ;
      }
    } else {
      @type_idx ctx cctx_get_incomplete_union_type = ;
    }
    if tok "{" strcmp 0 == {
      ctx @type_idxs @names cctx_parse_struct ;
      $type
      @type ctx type_idx cctx_get_type = ;
      type TYPE_SIZE take 0xffffffff == "cctx_parse_type: cannot define a union twice" assert_msg ;
      $newtype
      @newtype ctx type_idxs names cctx_construct_union_type = ;
      type type_destroy ;
      ctx CCTX_TYPES take type_idx vector_at_addr newtype = ;
    } else {
      ctx cctx_give_back_token ;
      tag 0 != "cctx_parse_type: union without neither tag nor definition" assert_msg ;
    }

    type_idx ret ;
  }

  if tok "enum" strcmp 0 == {
    $tag
    @tok ctx cctx_get_token_or_fail = ;
    if tok "{" strcmp 0 != {
      @tag tok = ;
      @tok ctx cctx_get_token_or_fail = ;
    }
    if tok "{" strcmp 0 == {
      ctx cctx_parse_enum ;
    } else {
      ctx cctx_give_back_token ;
      tag 0 != "cctx_parse_type: enum without neither tag nor definition" assert_msg ;
    }

    TYPE_UINT ret ;
  }

  $typenames
  @typenames ctx CCTX_TYPENAMES take = ;
  if typenames tok map_has {
    $idx
    @idx typenames tok map_at = ;
    idx ret ;
  } else {
    ctx cctx_give_back_token ;
    0xffffffff ret ;
  }
}

fun _cctx_parse_function_arguments 3 {
  $ctx
  $ret_arg_names
  $ret_ellipsis
  @ctx 2 param = ;
  @ret_arg_names 1 param = ;
  @ret_ellipsis 0 param = ;

  ret_ellipsis 0 = ;

  $args
  @args 4 vector_init = ;
  while 1 {
    $type_idx
    @type_idx ctx cctx_parse_type = ;
    if type_idx 0xffffffff == {
      $tok
      @tok ctx cctx_get_token_or_fail = ;
      if tok "..." strcmp 0 == {
        ret_ellipsis 1 = ;
        @tok ctx cctx_get_token_or_fail = ;
      }
      tok ")" strcmp 0 == "_cctx_parse_function_arguments: ) or type expected" assert_msg ;
      args vector_size 0 == ret_ellipsis ** || "_cctx_parse_function_arguments: unexpected )" assert_msg ;
      args ret ;
    }
    $name
    $actual_type_idx
    if ctx type_idx @actual_type_idx @name 0 cctx_parse_declarator ! {
      @actual_type_idx type_idx = ;
    }
    args actual_type_idx vector_push_back ;
    if ret_arg_names 0 != {
      ret_arg_names name vector_push_back ;
    }
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    if tok ")" strcmp 0 == {
      args ret ;
    }
    tok "," strcmp 0 == "_cctx_parse_function_arguments: ) or , expected" assert_msg ;
  }
}

fun _cctx_parse_declarator 5 {
  $ctx
  $type_idx
  $ret_type_idx
  $ret_name
  $ret_arg_names
  @ctx 4 param = ;
  @type_idx 3 param = ;
  @ret_type_idx 2 param = ;
  @ret_name 1 param = ;
  @ret_arg_names 0 param = ;

  #"_cctx_parse_declarator: entering\n" 1 platform_log ;
  #ctx cctx_print_token_pos ;

  $tok
  @tok ctx cctx_get_token_or_fail = ;
  $processed
  @processed 0 = ;

  #"_cctx_parse_declarator: token is " 1 platform_log ;
  #tok 1 platform_log ;
  #"\n" 1 platform_log ;

  # Parse pointer declaration
  if tok "*" strcmp 0 == {
    @type_idx ctx type_idx cctx_get_pointer_type = ;
    if ctx type_idx ret_type_idx ret_name ret_arg_names _cctx_parse_declarator ! {
      ret_type_idx type_idx = ;
    }
    @processed 1 = ;
  }

  # Parse function declaration and grouping parantheses
  if tok "(" strcmp 0 == {
    # Here the first problem is decide whether this is a function or
    # grouping parenthesis; if immediately after there is a type or a
    # closing parenthesis, we are in the first case; otherwise, we are
    # in the second case.
    $pos
    @pos ctx cctx_save_token_pos = ;
    $type
    @type ctx cctx_parse_type = ;
    ctx pos cctx_restore_token_pos ;
    $is_funct
    @is_funct 0 = ;
    if type 0xffffffff != {
      @is_funct 1 = ;
    }
    @tok ctx cctx_get_token_or_fail = ;
    if tok ")" strcmp 0 == {
      @is_funct 1 = ;
    }

    # Restore the content of tok, so that the program does not get
    # captured in later branches
    @tok "(" = ;

    ctx cctx_give_back_token ;
    if is_funct {
      # Function parenthesis
      $args
      $ellipsis
      @args ctx ret_arg_names @ellipsis _cctx_parse_function_arguments = ;
      if ctx type_idx ret_type_idx ret_name 0 _cctx_parse_declarator {
        @type_idx ret_type_idx ** = ;
      }
      ret_type_idx ctx type_idx args ellipsis cctx_get_function_type = ;
    } else {
      # Grouping parenthesis
      $inside_pos
      $outside_pos
      $end_pos
      @inside_pos ctx cctx_save_token_pos = ;
      ctx "(" ")" cctx_go_to_matching ;
      @outside_pos ctx cctx_save_token_pos = ;
      if ctx type_idx ret_type_idx ret_name 0 _cctx_parse_declarator {
        @type_idx ret_type_idx ** = ;
      }
      @end_pos ctx cctx_save_token_pos = ;
      ctx inside_pos cctx_restore_token_pos ;
      ctx type_idx ret_type_idx ret_name ret_arg_names _cctx_parse_declarator "_cctx_parse_declarator: invalid syntax 1" assert_msg ;
      @tok ctx cctx_get_token_or_fail = ;
      tok ")" strcmp 0 == "_cctx_parse_declarator: error 1" assert_msg ;
      outside_pos ctx cctx_save_token_pos == "_cctx_parse_declarator: invalid syntax 2" assert_msg ;
      ctx end_pos cctx_restore_token_pos ;
    }
    @processed 1 = ;
  }

  # Parse array declaration
  if tok "[" strcmp 0 == {
    @tok ctx cctx_get_token_or_fail = ;
    $length
    if tok "]" strcmp 0 == {
      @length 0xffffffff = ;
    } else {
      ctx cctx_give_back_token ;
      $ast
      @ast ctx "]" cctx_parse_ast1 = ;
      @length ctx ast ast_eval_compile = ;
      ast ast_destroy ;
      @tok ctx cctx_get_token_or_fail = ;
    }
    tok "]" strcmp 0 == "_cctx_parse_declarator: expected ] after array subscript" assert_msg ;
    if ctx type_idx ret_type_idx ret_name 0 _cctx_parse_declarator {
      @type_idx ret_type_idx ** = ;
    }
    ret_type_idx ctx type_idx length cctx_get_array_type = ;
    @processed 1 = ;
  }

  # Parse the actual declarator identifier
  if tok is_valid_identifier {
    if ctx type_idx ret_type_idx ret_name ret_arg_names _cctx_parse_declarator ! {
      ret_type_idx type_idx = ;
    }
    ret_name ** 0 == "_cctx_parse_declarator: more than one identifier found" assert_msg ;
    ret_name tok = ;
    @processed 1 = ;
  }

  if processed ! {
    ctx cctx_give_back_token ;
    #"_cctx_parse_declarator: failed\n" 1 platform_log ;
    0 ret ;
  }

  #"_cctx_parse_declarator: success\n" 1 platform_log ;
  1 ret ;
}

fun cctx_parse_declarator 5 {
  $ctx
  $type_idx
  $ret_type_idx
  $ret_name
  $ret_arg_names
  @ctx 4 param = ;
  @type_idx 3 param = ;
  @ret_type_idx 2 param = ;
  @ret_name 1 param = ;
  @ret_arg_names 0 param = ;

  ret_name 0 = ;
  ctx type_idx ret_type_idx ret_name ret_arg_names _cctx_parse_declarator ret ;
}

fun cctx_type_footprint 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  $type
  @type ctx CCTX_TYPES take type_idx vector_at = ;
  $size
  @size type TYPE_SIZE take = ;
  size 0xffffffff != "cctx_type_footprint: type cannot be instantiated" assert_msg ;
  size 1 - 3 | 1 + ret ;
}

fun cctx_type_size 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  $type
  @type ctx CCTX_TYPES take type_idx vector_at = ;
  $size
  @size type TYPE_SIZE take = ;
  size 0xffffffff != "cctx_type_size: type cannot be instantiated" assert_msg ;
  size ret ;
}

const STACK_ELEM_NAME 0
const STACK_ELEM_TYPE_IDX 4
const STACK_ELEM_LOC 8
const SIZEOF_STACK_ELEM 12

fun stack_elem_init 0 {
  $elem
  @elem SIZEOF_STACK_ELEM malloc = ;
  elem ret ;
}

fun stack_elem_destroy 1 {
  $elem
  @elem 0 param = ;
  elem free ;
}

const LCTX_STACK 0
const LCTX_RETURN_TYPE_IDX 4
const LCTX_RETURN_LABEL 8
const LCTX_BREAK_LABEL 12
const LCTX_CONTINUE_LABEL 16
const LCTX_RETURNS_OBJ 20
const LCTX_GOTO_LABELS 24
const SIZEOF_LCTX 28

fun lctx_init 0 {
  $lctx
  @lctx SIZEOF_LCTX malloc = ;
  lctx LCTX_STACK take_addr 4 vector_init = ;
  lctx LCTX_GOTO_LABELS take_addr map_init = ;
  lctx ret ;
}

fun lctx_destroy 1 {
  $lctx
  @lctx 0 param = ;

  $stack
  @stack lctx LCTX_STACK take = ;
  $i
  @i 0 = ;
  while i stack vector_size < {
    stack i vector_at stack_elem_destroy ;
    @i i 1 + = ;
  }

  lctx LCTX_STACK take vector_destroy ;
  lctx LCTX_GOTO_LABELS take map_destroy ;
  lctx free ;
}

fun lctx_stack_pos 1 {
  $lctx
  @lctx 0 param = ;

  $stack
  @stack lctx LCTX_STACK take = ;
  stack stack vector_size 1 - vector_at STACK_ELEM_LOC take ret ;
}

fun lctx_gen_label 2 {
  $lctx
  $ctx
  @lctx 1 param = ;
  @ctx 0 param = ;

  ctx 0xffffffff 0xffffffff cctx_gen_label ret ;
}

fun lctx_fix_label 3 {
  $lctx
  $ctx
  $idx
  @lctx 2 param = ;
  @ctx 1 param = ;
  @idx 0 param = ;

  $loc
  $pos
  @loc ctx CCTX_CURRENT_LOC take = ;
  if lctx 0 != {
    @pos lctx lctx_stack_pos = ;
  } else {
    @pos 0 = ;
  }
  ctx idx loc pos cctx_fix_label ;
}

fun lctx_get_variable 2 {
  $lctx
  $name
  @lctx 1 param = ;
  @name 0 param = ;

  # Begin scanning the stack from the end, so that inner variables
  # mask outer ones
  $stack
  @stack lctx LCTX_STACK take = ;
  $i
  @i stack vector_size 1 - = ;
  while i 0 >= {
    $elem
    @elem stack i vector_at = ;
    if elem STACK_ELEM_NAME take name strcmp 0 == {
      elem ret ;
    }
    @i i 1 - = ;
  }

  0 ret ;
}

fun lctx_save_status 2 {
  $lctx
  $ctx
  @lctx 1 param = ;
  @ctx 0 param = ;
  lctx LCTX_STACK take vector_size ret ;
}

fun lctx_restore_status 3 {
  $lctx
  $ctx
  $status
  @lctx 2 param = ;
  @ctx 1 param = ;
  @status 0 param = ;

  $current_pos
  @current_pos lctx lctx_stack_pos = ;
  $stack
  @stack lctx LCTX_STACK take = ;
  status stack vector_size <= "lctx_restore_status: error 1" assert_msg ;
  $new_pos
  @new_pos stack status 1 - vector_at STACK_ELEM_LOC take = ;
  $rewind
  @rewind new_pos current_pos - = ;
  rewind 0 >= "lctx_restore_status: error 2" assert_msg ;

  # add esp, rewind
  ctx 0x81 cctx_emit ;
  ctx 0xc4 cctx_emit ;
  ctx rewind cctx_emit32 ;

  # Drop enough stack elements in excess
  while stack vector_size status > {
    $elem
    @elem stack vector_pop_back = ;
    elem stack_elem_destroy ;
  }
}

fun lctx_push_var 3 {
  $lctx
  $ctx
  $type_idx
  $name
  @lctx 3 param = ;
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @name 0 param = ;

  $footprint
  @footprint ctx type_idx cctx_type_footprint = ;
  $new_pos
  @new_pos lctx lctx_stack_pos footprint - = ;

  $elem
  @elem stack_elem_init = ;
  elem STACK_ELEM_NAME take_addr name = ;
  elem STACK_ELEM_TYPE_IDX take_addr type_idx = ;
  elem STACK_ELEM_LOC take_addr new_pos = ;
  lctx LCTX_STACK take elem vector_push_back ;

  # sub esp, footprint
  ctx 0x81 cctx_emit ;
  ctx 0xec cctx_emit ;
  ctx footprint cctx_emit32 ;
}

fun lctx_prime_stack 3 {
  $lctx
  $ctx
  $type_idx
  $arg_names
  @lctx 3 param = ;
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @arg_names 0 param = ;

  $type
  @type ctx type_idx cctx_get_type = ;
  type TYPE_KIND take TYPE_KIND_FUNCTION == "lctx_prime_stack: type is not a function" assert_msg ;
  $args
  @args type TYPE_ARGS take = ;
  args vector_size arg_names vector_size == "lctx_prime_stack: error 1" assert_msg ;
  $stack
  @stack lctx LCTX_STACK take = ;

  $return_type_idx
  @return_type_idx type TYPE_BASE take = ;
  $return_type
  @return_type ctx return_type_idx cctx_get_type = ;
  lctx LCTX_RETURNS_OBJ take_addr return_type TYPE_KIND take TYPE_KIND_STRUCT == return_type TYPE_KIND take TYPE_KIND_UNION == || = ;
  return_type_idx TYPE_VOID == return_type_idx is_integer_type || return_type TYPE_KIND take TYPE_KIND_POINTER == || return_type TYPE_KIND take TYPE_KIND_STRUCT == || return_type TYPE_KIND take TYPE_KIND_UNION == || "cctx_compile_function: return type must be void, integer, pointer, struct or union" assert_msg ;

  # Base footprint contains the saved EBP and return value; if the
  # function returns an object, it contains also the returned value
  # address
  $base_footprint
  @base_footprint 8 = ;
  if return_type TYPE_KIND take TYPE_KIND_UNION == return_type TYPE_KIND take TYPE_KIND_STRUCT == || {
    @base_footprint base_footprint 4 + = ;
  }

  $i
  @i 0 = ;
  $total_footprint
  @total_footprint 0 = ;
  while i args vector_size < {
    @total_footprint total_footprint ctx args i vector_at cctx_type_footprint + = ;
    @i i 1 + = ;
  }
  $loc
  @loc total_footprint base_footprint + = ;
  @i args vector_size 1 - = ;
  while i 0 >= {
    $this_type_idx
    @this_type_idx args i vector_at = ;
    $name
    @name arg_names i vector_at = ;
    name 0 != "lctx_prime_stack: name cannot be empty" assert_msg ;
    @loc loc ctx this_type_idx cctx_type_footprint - = ;
    $elem
    @elem stack_elem_init = ;
    elem STACK_ELEM_NAME take_addr name = ;
    elem STACK_ELEM_TYPE_IDX take_addr this_type_idx = ;
    elem STACK_ELEM_LOC take_addr loc = ;
    stack elem vector_push_back ;
    @i i 1 - = ;
  }
  loc base_footprint == "lctx_prime_stack: error 2" assert_msg ;

  # Add a fictious element to mark the beginning of local variables
  $elem
  @elem stack_elem_init = ;
  elem STACK_ELEM_NAME take_addr "" = ;
  elem STACK_ELEM_TYPE_IDX take_addr 0 = ;
  elem STACK_ELEM_LOC take_addr 0 = ;
  stack elem vector_push_back ;
}

fun lctx_gen_prologue 2 {
  $lctx
  $ctx
  @lctx 1 param = ;
  @ctx 0 param = ;

  # push ebp; mov ebp, esp
  ctx 0x55 cctx_emit ;
  ctx 0x89 cctx_emit ;
  ctx 0xe5 cctx_emit ;
}

fun lctx_gen_epilogue 2 {
  $lctx
  $ctx
  @lctx 1 param = ;
  @ctx 0 param = ;

  if lctx LCTX_RETURNS_OBJ take {
    # mov eax, [ebp+8]; pop ebp; ret 4
    ctx 0x8b cctx_emit ;
    ctx 0x45 cctx_emit ;
    ctx 0x08 cctx_emit ;
    ctx 0x5d cctx_emit ;
    ctx 0xc2 cctx_emit ;
    ctx 0x04 cctx_emit ;
    ctx 0x00 cctx_emit ;
  } else {
    # pop ebp; ret
    ctx 0x5d cctx_emit ;
    ctx 0xc3 cctx_emit ;
  }
}

fun cctx_write_label 2 {
  $ctx
  $idx
  @ctx 1 param = ;
  @idx 0 param = ;

  $buf
  @buf ctx CCTX_LABEL_BUF take = ;
  buf '.' =c ;
  buf 1 + 'L' =c ;
  idx itoa buf 2 + strcpy ;

  buf ret ;
}

fun cctx_gen_label 3 {
  $ctx
  $loc
  $pos
  @ctx 2 param = ;
  @loc 1 param = ;
  @pos 0 param = ;

  $label_pos
  @label_pos ctx CCTX_LABEL_POS take = ;
  $idx
  @idx ctx CCTX_LABEL_NUM take = ;
  $name
  @name ctx idx cctx_write_label = ;
  if ctx CCTX_STAGE take 0 == {
    idx label_pos vector_size == "cctx_gen_label: error 2" assert_msg ;
    label_pos pos vector_push_back ;
    ctx name loc TYPE_VOID cctx_add_global ;
  } else {
    idx label_pos vector_size < "cctx_gen_label: error 1" assert_msg ;
    if pos 0xffffffff != {
      label_pos idx vector_at pos == "cctx_gen_label: error 3" assert_msg ;
    }
    if ctx CCTX_STAGE take 2 == {
      # Check that in the end the label position has been set
      # (otherwise the label was never actually defined)
      label_pos idx vector_at 0xffffffff != "cctx_gen_label: label never defined" assert_msg ;
    }
    ctx name loc TYPE_VOID cctx_add_global ;
  }
  ctx CCTX_LABEL_NUM take_addr idx 1 + = ;
  idx ret ;
}

fun cctx_fix_label 4 {
  $ctx
  $idx
  $loc
  $pos
  @ctx 3 param = ;
  @idx 2 param = ;
  @loc 1 param = ;
  @pos 0 param = ;

  $label_pos
  @label_pos ctx CCTX_LABEL_POS take = ;
  $name
  @name ctx idx cctx_write_label = ;
  ctx name loc TYPE_VOID cctx_add_global ;
  if ctx CCTX_STAGE take 0 == {
    label_pos idx vector_at_addr pos = ;
  } else {
    label_pos idx vector_at pos == "cctx_fix_label: error 1" assert_msg ;
  }
}

const JUMP_TYPE_JMP 0
const JUMP_TYPE_CALL 1
const JUMP_TYPE_JZ 2
const JUMP_TYPE_JNZ 3

fun cctx_gen_jump_loc 3 {
  $ctx
  $target_loc
  $type
  @ctx 2 param = ;
  @target_loc 1 param = ;
  @type 0 param = ;

  if type JUMP_TYPE_JMP == {
    # jmp rel
    ctx 0xe9 cctx_emit ;
  } else {
    if type JUMP_TYPE_CALL == {
      # call rel
      ctx 0xe8 cctx_emit ;
    } else {
      if type JUMP_TYPE_JZ == {
        # jz rel
        ctx 0x0f cctx_emit ;
        ctx 0x84 cctx_emit ;
      } else {
        if type JUMP_TYPE_JNZ == {
          # jnz rel
          ctx 0x0f cctx_emit ;
          ctx 0x85 cctx_emit ;
        } else {
          0 "cctx_gen_dump: error 1" assert_msg ;
        }
      }
    }
  }

  $current_loc
  @current_loc ctx CCTX_CURRENT_LOC take 4 + = ;
  $rel
  @rel target_loc current_loc - = ;
  ctx rel cctx_emit32 ;
}

fun cctx_gen_jump 3 {
  $ctx
  $name
  $type
  @ctx 2 param = ;
  @name 1 param = ;
  @type 0 param = ;

  $global
  @global ctx name cctx_get_global = ;
  $target_loc
  @target_loc global GLOBAL_LOC take = ;

  ctx target_loc type cctx_gen_jump_loc ;
}

fun cctx_gen_label_jump 5 {
  $ctx
  $lctx
  $idx
  $type
  $rewind
  @ctx 4 param = ;
  @lctx 3 param = ;
  @idx 2 param = ;
  @type 1 param = ;
  @rewind 0 param = ;

  $current_pos
  if lctx 0 != {
    @current_pos lctx lctx_stack_pos = ;
  } else {
    @current_pos 0 = ;
  }
  $new_pos
  @new_pos ctx CCTX_LABEL_POS take idx vector_at = ;
  $pos_diff
  @pos_diff new_pos current_pos - = ;
  $name
  @name ctx idx cctx_write_label = ;

  # add esp, pos_diff; cctx_gen_jump
  if rewind {
    ctx 0x81 cctx_emit ;
    ctx 0xc4 cctx_emit ;
    ctx pos_diff cctx_emit32 ;
  }
  ctx name type cctx_gen_jump ;
}

fun cctx_get_label_addr 3 {
  $ctx
  $lctx
  $idx
  @ctx 2 param = ;
  @lctx 1 param = ;
  @idx 0 param = ;

  $name
  @name ctx idx cctx_write_label = ;
  $global
  @global ctx name cctx_get_global = ;
  global GLOBAL_LOC take ret ;
}

fun cctx_gen_string 3 {
  $ctx
  $lctx
  $name
  @ctx 2 param = ;
  @lctx 1 param = ;
  @name 0 param = ;

  $str_label
  $label
  @str_label lctx ctx lctx_gen_label = ;
  @label lctx ctx lctx_gen_label = ;
  ctx lctx label JUMP_TYPE_JMP 0 cctx_gen_label_jump ;
  lctx ctx str_label lctx_fix_label ;
  $from
  @from name 1 + = ;
  while from **c '\"' != {
    @from 0 ctx escape_char ;
  }
  from 1 + **c 0 == "cctx_gen_string: illegal string literal" assert_msg ;
  ctx 0 cctx_emit ;
  lctx ctx label lctx_fix_label ;
  str_label ret ;
}

ifun ast_eval_compile_ext 2

fun ast_eval_compile 2 {
  $ctx
  $ast
  @ctx 1 param = ;
  @ast 0 param = ;

  $value
  @value ast @ast_eval_compile_ext ctx ast_eval = ;
  value "ast_eval_compile: failed" assert_msg ;
  value ** ret ;
}

fun ast_eval_compile_ext 2 {
  $ctx
  $ast
  @ctx 1 param = ;
  @ast 0 param = ;

  $name
  @name ast AST_NAME take = ;

  # "ast_eval_compile_ext: " 1 platform_log ;
  # name 1 platform_log ;
  # "\n" 1 platform_log ;

  if ast AST_TYPE take 0 == {
    $value
    @value i64_init = ;
    # Operand
    if name is_valid_identifier {
      $enum_consts
      @enum_consts ctx CCTX_ENUM_CONSTS take = ;
      if enum_consts name map_has {
        enum_consts name map_at ret ;
      } else {
        $global
        @global ctx name cctx_get_global = ;
        $loc
        @loc global GLOBAL_LOC take = ;
        $type_idx
        @type_idx global GLOBAL_TYPE_IDX take = ;
        $type
        @type ctx type_idx cctx_get_type = ;
        if type TYPE_KIND take TYPE_KIND_ARRAY == type TYPE_KIND take TYPE_KIND_FUNCTION == || {
          value loc i64_from_u32 ;
        } else {
          ctx type_idx cctx_type_footprint 4 == "ast_eval_compile_ext: unsupported global" assert_msg ;
          value loc ** i64_from_u32 ;
        }
      }
    } else {
      if name **c '\"' == {
        $str_label
        @str_label ctx 0 name cctx_gen_string = ;
        value ctx 0 str_label cctx_get_label_addr i64_from_u32 ;
      } else {
        value name atoi_c i64_from_u32 ;
      }
    }
    value ret ;
  } else {
    # Operator: all operators are handler by generic code
    0 ret ;
  }

  0 "ast_eval_compile_ext: should not arrive here" assert_msg ;
}

ifun ast_eval_type 3

fun promote_integer_type 1 {
  $type
  @type 0 param = ;

  if type TYPE_BOOL ==
     type TYPE_CHAR == ||
     type TYPE_SCHAR == ||
     type TYPE_UCHAR == ||
     type TYPE_SHORT == ||
     type TYPE_INT == ||
     type TYPE_USHORT == || {
    TYPE_INT ret ;
  }

  if type TYPE_UINT == {
    TYPE_UINT ret ;
  }

  if type TYPE_LONG == {
    TYPE_LONG ret ;
  }

  if type TYPE_ULONG == {
    TYPE_ULONG ret ;
  }

  0 "promote_integer_type: not an integer type" assert_msg ;
}

fun ast_arith_conv 4 {
  $ast1
  $ast2
  $ctx
  $lctx
  @ast1 3 param = ;
  @ast2 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $type1
  $type2
  @type1 ast1 ctx lctx ast_eval_type = ;
  @type2 ast2 ctx lctx ast_eval_type = ;

  # As an exception to the standard, automatically convert every
  # pointer to an unsigned int
  if ctx type1 cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == {
    @type1 TYPE_UINT = ;
  }
  if ctx type2 cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == {
    @type2 TYPE_UINT = ;
  }

  @type1 type1 promote_integer_type = ;
  @type2 type2 promote_integer_type = ;

  if type1 type2 == {
    type1 ret ;
  }

  if type1 TYPE_UINT == type2 TYPE_INT == &&
     type2 TYPE_UINT == type1 TYPE_INT == && || {
    TYPE_UINT ret ;
  }

  if type1 TYPE_ULONG == type2 TYPE_LONG == &&
     type2 TYPE_ULONG == type1 TYPE_LONG == && || {
    TYPE_ULONG ret ;
  }

  if type1 TYPE_UINT == type2 TYPE_ULONG == &&
     type2 TYPE_UINT == type1 TYPE_ULONG == && || {
    TYPE_ULONG ret ;
  }

  if type1 TYPE_INT == type2 TYPE_LONG == &&
     type2 TYPE_INT == type1 TYPE_LONG == && || {
    TYPE_LONG ret ;
  }

  if type1 TYPE_INT == type2 TYPE_ULONG == &&
     type2 TYPE_INT == type1 TYPE_ULONG == && || {
    TYPE_ULONG ret ;
  }

  if type1 TYPE_UINT == type2 TYPE_LONG == &&
     type2 TYPE_UINT == type1 TYPE_LONG == && || {
    TYPE_LONG ret ;
  }

  0 "ast_arith_conv: error 1" type1 type2 assert_msg_int_int ;
}

fun i64_fits_in 2 {
  $i
  $type_idx
  @i 1 param = ;
  @type_idx 0 param = ;

  if type_idx TYPE_ULONG == { 1 ret ; }
  if type_idx TYPE_LONG == { i i64_to_upper32 0x80000000 & 0 == ret ; }
  if type_idx TYPE_UINT == { i i64_to_upper32 0 == ret ; }
  if type_idx TYPE_INT == { i i64_to_upper32 0 == i i64_to_32 0x80000000 & 0 == && ret ; }

  0 "i64_fits_in: unsupported type" assert_msg ;
}

fun ast_strtoll 1 {
  $ast
  @ast 0 param = ;

  $suffix
  $value
  @value ast AST_NAME take @suffix c_strtoll = ;
  ast AST_VALUE take_addr value = ;

  # Decode suffix
  $u_num
  $l_num
  @u_num 0 = ;
  @l_num 0 = ;
  while suffix **c '\0' != {
    $c
    @c suffix **c = ;
    if c 'u' == c 'U' == || {
      @u_num u_num 1 + = ;
    } else {
      if c 'l' == c 'L' == || {
        @l_num l_num 1 + = ;
      } else {
        0 "ast_strtoll: invalid suffix letter" assert_msg ;
      }
    }
    @suffix suffix 1 + = ;
  }
  0 u_num <= u_num 1 <= && "ast_strotoll: too many U suffixes" assert_msg ;
  0 l_num <= l_num 2 <= && "ast_strotoll: too many L suffixes" assert_msg ;

  # (Re)decode prefix
  $dec
  @dec ast AST_NAME take **c '0' != = ;

  # Ok, now we are ready to assign a type to the expression
  $type_idx
  if u_num 1 == {
    if l_num 1 <= {
       @type_idx TYPE_ULONG = ;
    } else {
      if value TYPE_UINT i64_fits_in {
        @type_idx TYPE_UINT = ;
      } else {
        @type_idx TYPE_ULONG = ;
      }
    }
  } else {
    if l_num 2 == {
      if dec {
        @type_idx TYPE_LONG = ;
      } else {
        if value TYPE_LONG i64_fits_in {
          @type_idx TYPE_LONG = ;
        } else {
          @type_idx TYPE_ULONG = ;
        }
      }
    } else {
      if l_num 1 == {
        if value TYPE_LONG i64_fits_in {
          @type_idx TYPE_LONG = ;
        } else {
          @type_idx TYPE_ULONG = ;
        }
      } else {
        if dec {
          if value TYPE_INT i64_fits_in {
            @type_idx TYPE_INT = ;
          } else {
            if value TYPE_LONG i64_fits_in {
              @type_idx TYPE_LONG = ;
            } else {
              @type_idx TYPE_ULONG = ;
            }
          }
        } else {
          if value TYPE_INT i64_fits_in {
            @type_idx TYPE_INT = ;
          } else {
            if value TYPE_UINT i64_fits_in {
              @type_idx TYPE_UINT = ;
            } else {
              if value TYPE_LONG i64_fits_in {
                @type_idx TYPE_LONG = ;
              } else {
                @type_idx TYPE_ULONG = ;
              }
            }
          }
        }
      }
    }
  }

  ast AST_TYPE_IDX take_addr type_idx = ;
}

fun ast_eval_type 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  if ast AST_TYPE_IDX take 0xffffffff != {
    ast AST_TYPE_IDX take ret ;
  }

  $name
  @name ast AST_NAME take = ;
  $type_idx
  $common_type_idx
  @common_type_idx 0xffffffff = ;
  if ast AST_TYPE take 0 == {
    # Operand
    if name is_valid_identifier {
      # Search among enum constants
      $enum_consts
      @enum_consts ctx CCTX_ENUM_CONSTS take = ;
      if enum_consts name map_has name "sizeof" strcmp 0 == || {
        @type_idx TYPE_INT = ;
      } else {
        # Search in local stack and among globals
        $elem
        @elem lctx name lctx_get_variable = ;
        if elem {
          @type_idx elem STACK_ELEM_TYPE_IDX take = ;
        } else {
          $global
          @global ctx name cctx_get_global = ;
          @type_idx global GLOBAL_TYPE_IDX take = ;
        }
      }
    } else {
      if name **c '\"' == {
        @type_idx TYPE_CHAR_ARRAY = ;
      } else {
        if name **c '\'' == {
          @type_idx TYPE_INT = ;
        } else {
          ast ast_strtoll ;
          @type_idx ast AST_TYPE_IDX take = ;
        }
      }
    }
  } else {
    # Operator
    $processed
    @processed 0 = ;

    $sum
    $subtract
    $assign
    @sum name "+" strcmp 0 == name "+=" strcmp 0 == || = ;
    @subtract name "-" strcmp 0 == name "-=" strcmp 0 == || = ;
    @assign name "+=" strcmp 0 == name "-=" strcmp 0 == || = ;

    if sum subtract ||
       processed ! && {
      $left_idx
      $right_idx
      @left_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      @right_idx ast AST_RIGHT take ctx lctx ast_eval_type = ;
      $left_ptr
      $right_ptr
      @left_ptr ctx left_idx cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == = ;
      @right_ptr ctx right_idx cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == = ;
      $left_size
      $right_size
      if left_ptr {
        @left_size ctx ctx left_idx cctx_get_type TYPE_BASE take cctx_type_size = ;
      }
      if right_ptr {
        @right_size ctx ctx right_idx cctx_get_type TYPE_BASE take cctx_type_size = ;
      }
      if sum {
        left_ptr right_ptr && ! "ast_eval_type: cannot take sum of two pointers" assert_msg ;
        if left_ptr {
          right_idx is_integer_type "ast_eval_type: cannot add pointer and non-integer" assert_msg ;
          @type_idx left_idx = ;
          @processed 1 = ;
        }
        if right_ptr {
          assign ! "ast_eval_type: right of sum-assign must be integer" assert_msg ;
          left_idx is_integer_type "ast_eval_type: cannot add pointer and non-integer" assert_msg ;
          @type_idx right_idx = ;
          @processed 1 = ;
        }
      } else {
        left_ptr ! right_ptr && ! "ast_eval_type: cannot take different of a non-pointer and a pointer" assert_msg ;
        if left_ptr {
          if right_ptr {
            assign ! "ast_eval_type: right of subtract-assign must be integer" assert_msg ;
            left_size right_size == "ast_eval_type: cannot take difference of pointers to types of different size" assert_msg ;
            @type_idx TYPE_INT = ;
          } else {
            right_idx is_integer_type "ast_eval_type: cannot subtract pointer and non-integer" assert_msg ;
            @type_idx left_idx = ;
          }
          @processed 1 = ;
        }
      }
    }

    if name "*" strcmp 0 ==
       name "/" strcmp 0 == ||
       name "%" strcmp 0 == ||
       name "+" strcmp 0 == ||
       name "-" strcmp 0 == ||
       name "&" strcmp 0 == ||
       name "^" strcmp 0 == ||
       name "|" strcmp 0 == ||
       name "*=" strcmp 0 == ||
       name "/=" strcmp 0 == ||
       name "%=" strcmp 0 == ||
       name "+=" strcmp 0 == ||
       name "-=" strcmp 0 == ||
       name "&=" strcmp 0 == ||
       name "^=" strcmp 0 == ||
       name "|=" strcmp 0 == ||
       processed ! && {
      @type_idx ast AST_LEFT take ast AST_RIGHT take ctx lctx ast_arith_conv = ;
      @common_type_idx type_idx = ;
      @processed 1 = ;
    }

    if name "<<" strcmp 0 ==
       name ">>" strcmp 0 == ||
       name "<<=" strcmp 0 == ||
       name ">>=" strcmp 0 == ||
       processed ! && {
      $type1
      $type2
      @type1 ast AST_LEFT take ctx lctx ast_eval_type = ;
      @type2 ast AST_RIGHT take ctx lctx ast_eval_type = ;
      @type1 type1 promote_integer_type = ;
      @type2 type2 promote_integer_type = ;
      @type_idx type1 = ;
      @common_type_idx type_idx = ;
      @processed 1 = ;
    }

    if name "+_PRE" strcmp 0 ==
       name "-_PRE" strcmp 0 == ||
       name "~_PRE" strcmp 0 == ||
       processed ! && {
      @type_idx ast AST_RIGHT take ctx lctx ast_eval_type promote_integer_type = ;
      @common_type_idx type_idx = ;
      @processed 1 = ;
    }

    if name "++_PRE" strcmp 0 ==
       name "++_POST" strcmp 0 == ||
       name "--_PRE" strcmp 0 == ||
       name "--_POST" strcmp 0 == ||
       processed ! && {
      $sub_type_idx
      if name "++_PRE" strcmp 0 == name "--_PRE" strcmp 0 == || {
        @sub_type_idx ast AST_RIGHT take ctx lctx ast_eval_type = ;
      } else {
        @sub_type_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      }
      if sub_type_idx is_integer_type {
        @type_idx sub_type_idx promote_integer_type = ;
      } else {
        ctx sub_type_idx cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == "ast_eval_type: argument must be integer or pointer" assert_msg ;
        @type_idx sub_type_idx = ;
      }
      @common_type_idx type_idx = ;
      @processed 1 = ;
    }

    if name "<" strcmp 0 ==
       name ">" strcmp 0 == ||
       name "<=" strcmp 0 == ||
       name ">=" strcmp 0 == ||
       name "==" strcmp 0 == ||
       name "!=" strcmp 0 == ||
       name "&&" strcmp 0 == ||
       name "||" strcmp 0 == ||
       processed ! && {
      $type1
      $type2
      @type1 ast AST_LEFT take ctx lctx ast_eval_type = ;
      @type2 ast AST_RIGHT take ctx lctx ast_eval_type = ;
      type1 is_integer_type ctx type1 cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == || "ast_eval_type: left is neither integer nor pointer" assert_msg ;
      type2 is_integer_type ctx type2 cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == || "ast_eval_type: left is neither integer nor pointer" assert_msg ;
      @type_idx TYPE_INT = ;
      @common_type_idx ast AST_LEFT take ast AST_RIGHT take ctx lctx ast_arith_conv = ;
      @processed 1 = ;
    }

    if name "!_PRE" strcmp 0 ==
       processed ! && {
      $type
      @type ast AST_RIGHT take ctx lctx ast_eval_type = ;
      type is_integer_type ctx type cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == || "ast_eval_type: operand is neither integer nor pointer" assert_msg ;
      @type_idx TYPE_INT = ;
      @common_type_idx type = ;
      if ctx type cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == {
        @common_type_idx TYPE_UINT = ;
      }
      @processed 1 = ;
    }

    if name "=" strcmp 0 == {
      @type_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      @processed 1 = ;
    }

    if name "(" strcmp 0 == {
      $fun_ptr_idx
      $fun_ptr_type
      $fun_idx
      $fun_type
      @fun_ptr_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      @fun_ptr_type ctx fun_ptr_idx cctx_get_type = ;
      fun_ptr_type TYPE_KIND take TYPE_KIND_POINTER == "ast_eval_type: left is not a pointer" assert_msg ;
      @fun_idx fun_ptr_type TYPE_BASE take = ;
      @fun_type ctx fun_idx cctx_get_type = ;
      fun_type TYPE_KIND take TYPE_KIND_FUNCTION == "ast_eval_type: left is not a pointer to function" assert_msg ;
      @type_idx fun_type TYPE_BASE take = ;
      @processed 1 = ;
    }

    if name "*_PRE" strcmp 0 == name "[" strcmp 0 == || {
      $ptr_idx
      $ptr_type
      $ptr_ast
      @ptr_ast ast AST_RIGHT take = ;
      if name "[" strcmp 0 == {
        @ptr_idx ptr_ast ctx lctx ast_eval_type = ;
        @ptr_type ctx ptr_idx cctx_get_type = ;
        if ptr_type TYPE_KIND take TYPE_KIND_POINTER != {
          @ptr_ast ast AST_LEFT take = ;
        }
      }
      @ptr_idx ptr_ast ctx lctx ast_eval_type = ;
      @ptr_type ctx ptr_idx cctx_get_type = ;
      ptr_type TYPE_KIND take TYPE_KIND_POINTER == "ast_eval_type: arg not a pointer" assert_msg ;
      @type_idx ptr_type TYPE_BASE take = ;
      @processed 1 = ;
    }

    if name "&_PRE" strcmp 0 == {
      $orig_idx
      @orig_idx ast AST_RIGHT take ctx lctx ast_eval_type = ;
      @type_idx ctx orig_idx cctx_get_pointer_type = ;
      @processed 1 = ;
    }

    if name "." strcmp 0 == {
      $struct_idx
      $struct_type
      @struct_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      @struct_type ctx struct_idx cctx_get_type = ;
      ast AST_RIGHT take AST_TYPE take 0 == "ast_eval_type: right is not a plain name" assert_msg ;
      $name
      @name ast AST_RIGHT take AST_NAME take = ;
      $field
      @field struct_type name type_get_idx = ;
      field 0xffffffff != "ast_eval_type: specified field does not exist" assert_msg ;
      @type_idx struct_type TYPE_FIELDS_TYPE_IDXS take field vector_at = ;
      @processed 1 = ;
    }

    if name "->" strcmp 0 == {
      $ptr_idx
      $ptr_type
      $struct_idx
      $struct_type
      @ptr_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      @ptr_type ctx ptr_idx cctx_get_type = ;
      ptr_type TYPE_KIND take TYPE_KIND_POINTER == "ast_eval_type: right is not a pointer" assert_msg ;
      @struct_idx ptr_type TYPE_BASE take = ;
      @struct_type ctx struct_idx cctx_get_type = ;
      ast AST_RIGHT take AST_TYPE take 0 == "ast_eval_type: right is not a plain name" assert_msg ;
      $name
      @name ast AST_RIGHT take AST_NAME take = ;
      $field
      @field struct_type name type_get_idx = ;
      field 0xffffffff != "ast_eval_type: specified field does not exist" assert_msg ;
      @type_idx struct_type TYPE_FIELDS_TYPE_IDXS take field vector_at = ;
      @processed 1 = ;
    }

    if name "?" strcmp 0 == {
      $processed2
      @processed2 0 = ;

      $type1
      $type2
      @type1 ast AST_CENTER take ctx lctx ast_eval_type = ;
      @type2 ast AST_RIGHT take ctx lctx ast_eval_type = ;

      if type1 is_integer_type type2 is_integer_type && {
        @type_idx ast AST_CENTER take ast AST_RIGHT take ctx lctx ast_arith_conv = ;
        @processed2 1 = ;
      }

      processed2 "ast_eval_type: not implemented form of ternary operator" assert_msg ;
      @processed 1 = ;
    }

    if name "(_PRE" strcmp 0 == {
      @type_idx ast AST_CAST_TYPE_IDX take = ;
      @processed 1 = ;
    }

    if name "sizeof_PRE" strcmp 0 == {
      @type_idx TYPE_INT = ;
      @processed 1 = ;
    }

    processed "ast_eval_type: not implemented" name assert_msg_str ;
  }

  # Process decaying
  $type
  @type ctx type_idx cctx_get_type = ;
  $orig_type_idx
  @orig_type_idx 0xffffffff = ;
  if type TYPE_KIND take TYPE_KIND_ARRAY == {
    @orig_type_idx type_idx = ;
    $base_idx
    @base_idx type TYPE_BASE take = ;
    @type_idx ctx base_idx cctx_get_pointer_type = ;
  }
  if type TYPE_KIND take TYPE_KIND_FUNCTION == {
    @orig_type_idx type_idx = ;
    @type_idx ctx type_idx cctx_get_pointer_type = ;
  }
  @type ctx type_idx cctx_get_type = ;

  # Sanity check
  type_idx TYPE_VOID == type TYPE_SIZE take 0xffffffff != || "ast_eval_type: invalid expression type" assert_msg ;

  ast AST_TYPE_IDX take_addr type_idx = ;
  ast AST_ORIG_TYPE_IDX take_addr orig_type_idx = ;
  ast AST_COMMON_TYPE_IDX take_addr common_type_idx = ;
  type_idx ret ;
}

ifun ast_push_value 3
ifun ast_push_value_ptr 3

fun ast_push_addr 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $name
  @name ast AST_NAME take = ;
  $type_idx
  @type_idx ast ctx lctx ast_eval_type = ;
  if ast AST_TYPE take 0 == {
    # Operand
    if name is_valid_identifier {
      # Search in local stack and among globals
      $elem
      @elem lctx name lctx_get_variable = ;
      if elem {
        # lea eax, [ebp+loc]; push eax
        ctx 0x8d cctx_emit ;
        ctx 0x85 cctx_emit ;
        ctx elem STACK_ELEM_LOC take cctx_emit32 ;
        ctx 0x50 cctx_emit ;
      } else {
        $global
        @global ctx name cctx_get_global = ;
        # push loc
        ctx 0x68 cctx_emit ;
        ctx global GLOBAL_LOC take cctx_emit32 ;
      }
    } else {
      if name **c '\"' == {
        $str_label
        @str_label ctx lctx name cctx_gen_string = ;
        # push str_label
        ctx 0x68 cctx_emit ;
        ctx ctx lctx str_label cctx_get_label_addr cctx_emit32 ;
      } else {
        0 "ast_push_addr: cannot take the address of an immediate" assert_msg ;
      }
    }
  } else {
    # Operator
    $processed
    @processed 0 = ;

    if name "*_PRE" strcmp 0 == {
      ast AST_RIGHT take ctx lctx ast_push_value ;
      @processed 1 = ;
    }

    if name "." strcmp 0 == {
      $struct_idx
      $struct_type
      @struct_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      @struct_type ctx struct_idx cctx_get_type = ;
      ast AST_RIGHT take AST_TYPE take 0 == "ast_push_addr: right is not a plain name" assert_msg ;
      $name
      @name ast AST_RIGHT take AST_NAME take = ;
      $field
      @field struct_type name type_get_idx = ;
      field 0xffffffff != "ast_push_addr: specified field does not exist" assert_msg ;
      $off
      @off struct_type TYPE_FIELDS_OFFS take field vector_at = ;

      # ast_push_addr; pop eax; add eax, off; push eax
      ast AST_LEFT take ctx lctx ast_push_addr ;
      ctx 0x58 cctx_emit ;
      ctx 0x05 cctx_emit ;
      ctx off cctx_emit32 ;
      ctx 0x50 cctx_emit ;

      @processed 1 = ;
    }

    if name "->" strcmp 0 == {
      $ptr_idx
      $ptr_type
      $struct_idx
      $struct_type
      @ptr_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      @ptr_type ctx ptr_idx cctx_get_type = ;
      ptr_type TYPE_KIND take TYPE_KIND_POINTER == "ast_push_addr: right is not a pointer" assert_msg ;
      @struct_idx ptr_type TYPE_BASE take = ;
      @struct_type ctx struct_idx cctx_get_type = ;
      ast AST_RIGHT take AST_TYPE take 0 == "ast_push_addr: right is not a plain name" assert_msg ;
      $name
      @name ast AST_RIGHT take AST_NAME take = ;
      $field
      @field struct_type name type_get_idx = ;
      field 0xffffffff != "ast_push_addr: specified field does not exist" assert_msg ;
      $off
      @off struct_type TYPE_FIELDS_OFFS take field vector_at = ;

      # ast_push_value; pop eax; add eax, off; push eax
      ast AST_LEFT take ctx lctx ast_push_value ;
      ctx 0x58 cctx_emit ;
      ctx 0x05 cctx_emit ;
      ctx off cctx_emit32 ;
      ctx 0x50 cctx_emit ;

      @processed 1 = ;
    }

    if name "[" strcmp 0 == {
      @processed ast ctx lctx ast_push_value_ptr = ;
    }

    processed "ast_push_addr: not implemented" assert_msg ;
  }
}

fun lctx_int_convert 4 {
  $lctx
  $ctx
  $from_idx
  $to_idx
  @lctx 3 param = ;
  @ctx 2 param = ;
  @from_idx 1 param = ;
  @to_idx 0 param = ;

  # Treat pointers as integers
  if ctx from_idx cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == {
    @from_idx TYPE_INT = ;
  }

  from_idx is_integer_type "lctx_int_convert: source is not an integer type" from_idx to_idx assert_msg_int_int ;
  to_idx is_integer_type "lctx_int_convert: target is not an integer type" from_idx to_idx assert_msg_int_int ;

  if ctx from_idx cctx_type_footprint 4 == {
    # pop eax
    ctx 0x58 cctx_emit ;
  } else {
    if ctx from_idx cctx_type_footprint 8 == {
      # pop eax; pop edx
      ctx 0x58 cctx_emit ;
      ctx 0x5a cctx_emit ;
    } else {
      0 "lctx_int_convert: error 1" assert_msg ;
    }
  }

  if from_idx TYPE_CHAR == from_idx TYPE_SCHAR == || {
    # movsx eax, al; cdq
    ctx 0x0f cctx_emit ;
    ctx 0xbe cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x99 cctx_emit ;
  } else {
    if from_idx TYPE_UCHAR == {
      # movzx eax, al; xor edx, edx
      ctx 0x0f cctx_emit ;
      ctx 0xb6 cctx_emit ;
      ctx 0xc0 cctx_emit ;
      ctx 0x31 cctx_emit ;
      ctx 0xd2 cctx_emit ;
    } else {
      if from_idx TYPE_SHORT == {
        # movsx eax, ax; cdq
        ctx 0x0f cctx_emit ;
        ctx 0xbf cctx_emit ;
        ctx 0xc0 cctx_emit ;
        ctx 0x99 cctx_emit ;
      } else {
        if from_idx TYPE_USHORT == {
          # movzx eax, ax; xor edx, edx
          ctx 0x0f cctx_emit ;
          ctx 0xb7 cctx_emit ;
          ctx 0xc0 cctx_emit ;
          ctx 0x31 cctx_emit ;
          ctx 0xd2 cctx_emit ;
        } else {
          if from_idx TYPE_INT == {
            # cdq
            ctx 0x99 cctx_emit ;
          } else {
            if from_idx TYPE_UINT == from_idx TYPE_BOOL == || {
              # xor edx, edx
              ctx 0x31 cctx_emit ;
              ctx 0xd2 cctx_emit ;
            } else {
              from_idx TYPE_LONG == from_idx TYPE_ULONG == || "lctx_int_convert: error 2" assert_msg ;
            }
          }
        }
      }
    }
  }

  if to_idx TYPE_BOOL == {
    # or eax, edx; setne al; movzx eax, al
    ctx 0x09 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0x95 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx 0x0f cctx_emit ;
    ctx 0xb6 cctx_emit ;
    ctx 0xc0 cctx_emit ;
  }

  if ctx to_idx cctx_type_footprint 4 == {
    # push eax
    ctx 0x50 cctx_emit ;
  } else {
    if ctx to_idx cctx_type_footprint 8 == {
      # push edx; push eax
      ctx 0x52 cctx_emit ;
      ctx 0x50 cctx_emit ;
    } else {
      0 "lctx_int_convert: error 3" assert_msg ;
    }
  }
}

fun lctx_convert_stack 4 {
  $lctx
  $ctx
  $from_idx
  $to_idx
  @lctx 3 param = ;
  @ctx 2 param = ;
  @from_idx 1 param = ;
  @to_idx 0 param = ;

  if ctx from_idx to_idx cctx_type_compare {
    ret ;
  }

  if from_idx is_integer_type to_idx is_integer_type && {
    lctx ctx from_idx to_idx lctx_int_convert ;
    ret ;
  }

  $from_type
  $to_type
  @from_type ctx from_idx cctx_get_type = ;
  @to_type ctx to_idx cctx_get_type = ;

  if from_type TYPE_KIND take TYPE_KIND_POINTER == to_type TYPE_KIND take TYPE_KIND_POINTER == && {
    # Permit any implicit conversion between any two pointers of any type
    ctx from_idx cctx_type_footprint 4 == "lctx_convert_stack: error 3" assert_msg ;
    ctx to_idx cctx_type_footprint 4 == "lctx_convert_stack: error 4" assert_msg ;
    ret ;
  }

  if from_idx is_integer_type to_type TYPE_KIND take TYPE_KIND_POINTER == && {
    # Permit any implicit converstion of integers to pointers
    ctx from_idx cctx_type_footprint 4 == "lctx_convert_stack: error 5" assert_msg ;
    ctx to_idx cctx_type_footprint 4 == "lctx_convert_stack: error 6" assert_msg ;
    ret ;
  }

  if from_type TYPE_KIND take TYPE_KIND_POINTER == to_idx is_integer_type && {
    # Permit any implicit conversion of pointers to integers
    ctx from_idx cctx_type_footprint 4 == "lctx_convert_stack: error 3" assert_msg ;
    ctx to_idx cctx_type_footprint 4 == "lctx_convert_stack: error 4" assert_msg ;
    ret ;
  }

  0 "lctx_convert_stack: not implemented" from_idx to_idx assert_msg_int_int ;
}

fun ast_push_value_logic 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $name
  @name ast AST_NAME take = ;
  $and
  @and name "&&" strcmp 0 == = ;
  and name "||" strcmp 0 == ^ "ast_push_value_logic: not a binary logic operator" assert_msg ;

  $type1
  $type2
  $type_idx
  @type1 ast AST_LEFT take ctx lctx ast_eval_type = ;
  @type2 ast AST_RIGHT take ctx lctx ast_eval_type = ;
  @type_idx ast ctx lctx ast_eval_type = ;

  # Evaluate first operand
  ast AST_LEFT take ctx lctx ast_push_value ;

  # Try short-circuit evaluation
  $end_lab
  @end_lab lctx ctx lctx_gen_label = ;
  # pop eax; test eax, eax; mov eax, ?; cctx_gen_label_jump
  ctx 0x58 cctx_emit ;
  ctx 0x85 cctx_emit ;
  ctx 0xc0 cctx_emit ;
  ctx 0xb8 cctx_emit ;
  if and {
    ctx 0 cctx_emit32 ;
    ctx lctx end_lab JUMP_TYPE_JZ 0 cctx_gen_label_jump ;
  } else {
    ctx 1 cctx_emit32 ;
    ctx lctx end_lab JUMP_TYPE_JNZ 0 cctx_gen_label_jump ;
  }

  # Evaluate second operand
  ast AST_RIGHT take ctx lctx ast_push_value ;

  # Reduce result to 0 or 1
  # pop eax; test eax, eax; mov eax, 0; setnz al
  ctx 0x58 cctx_emit ;
  ctx 0x85 cctx_emit ;
  ctx 0xc0 cctx_emit ;
  ctx 0xb8 cctx_emit ;
  ctx 0 cctx_emit32 ;
  ctx 0x0f cctx_emit ;
  ctx 0x95 cctx_emit ;
  ctx 0xc0 cctx_emit ;

  # Push result
  lctx ctx end_lab lctx_fix_label ;
  # push eax
  ctx 0x50 cctx_emit ;
}

fun ast_push_value_arith32 4 {
  $ctx
  $name
  $type_idx
  $is_prefix
  @ctx 3 param = ;
  @name 2 param = ;
  @type_idx 1 param = ;
  @is_prefix 0 param = ;

  # Pop right result and store in ECX
  # pop ecx
  ctx 0x59 cctx_emit ;

  # Pop left result and store in EAX
  if is_prefix ! {
    # pop eax
    ctx 0x58 cctx_emit ;
  }

  # Invoke the specific operation code
  $processed
  @processed 0 = ;

  if name "+" strcmp 0 == {
    # add eax, ecx
    ctx 0x01 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "-" strcmp 0 == {
    # sub eax, ecx
    ctx 0x29 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "&" strcmp 0 == {
    # and eax, ecx
    ctx 0x21 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "|" strcmp 0 == {
    # or eax, ecx
    ctx 0x09 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "^" strcmp 0 == {
    # xor eax, ecx
    ctx 0x01 cctx_emit ;
    ctx 0x31 cctx_emit ;
    @processed 1 = ;
  }

  if name "<<" strcmp 0 == {
    # shl eax, cl
    ctx 0xd3 cctx_emit ;
    ctx 0xe0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">>" strcmp 0 == type_idx TYPE_UINT == && {
    # shr eax, cl
    ctx 0xd3 cctx_emit ;
    ctx 0xe8 cctx_emit ;
    @processed 1 = ;
  }

  if name ">>" strcmp 0 == type_idx TYPE_INT == && {
    # sar eax, cl
    ctx 0xd3 cctx_emit ;
    ctx 0xf8 cctx_emit ;
    @processed 1 = ;
  }

  if name "+_PRE" strcmp 0 == {
    # mov eax, ecx
    ctx 0x89 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    @processed 1 = ;
  }

  if name "-_PRE" strcmp 0 == {
    # mov eax, ecx; neg eax
    ctx 0x89 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xd8 cctx_emit ;
    @processed 1 = ;
  }

  if name "~_PRE" strcmp 0 == {
    # mov eax, ecx; not eax
    ctx 0x89 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    @processed 1 = ;
  }

  if name "!_PRE" strcmp 0 == {
    # test ecx, ecx; mov eax, 0; sete al
    ctx 0x85 cctx_emit ;
    ctx 0xc9 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x94 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "*" strcmp 0 == {
    # imul ecx
    ctx 0xf7 cctx_emit ;
    ctx 0xe9 cctx_emit ;
    @processed 1 = ;
  }

  if name "/" strcmp 0 == type_idx TYPE_UINT == && {
    # xor edx, edx; div ecx
    ctx 0x31 cctx_emit ;
    ctx 0xd2 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xf1 cctx_emit ;
    @processed 1 = ;
  }

  if name "/" strcmp 0 == type_idx TYPE_INT == && {
    # cdq; idiv ecx
    ctx 0x99 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xf9 cctx_emit ;
    @processed 1 = ;
  }

  if name "%" strcmp 0 == type_idx TYPE_UINT == && {
    # xor edx, edx; div ecx; mov eax, edx
    ctx 0x31 cctx_emit ;
    ctx 0xd2 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xf1 cctx_emit ;
    ctx 0x89 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    @processed 1 = ;
  }

  if name "%" strcmp 0 == type_idx TYPE_INT == && {
    # cdq; idiv ecx; mov eax, edx
    ctx 0x99 cctx_emit ;
    ctx 0xf7 cctx_emit ;
    ctx 0xf9 cctx_emit ;
    ctx 0x89 cctx_emit ;
    ctx 0xd0 cctx_emit ;
    @processed 1 = ;
  }

  if name "==" strcmp 0 == {
    # cmp eax, ecx; mov eax, 0; sete al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x94 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "!=" strcmp 0 == {
    # cmp eax, ecx; mov eax, 0; setne al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x95 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "<" strcmp 0 == type_idx TYPE_UINT == && {
    # cmp eax, ecx; mov eax, 0; setb al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x92 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "<=" strcmp 0 == type_idx TYPE_UINT == && {
    # cmp eax, ecx; mov eax, 0; setbe al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x96 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">" strcmp 0 == type_idx TYPE_UINT == && {
    # cmp eax, ecx; mov eax, 0; seta al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x97 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">=" strcmp 0 == type_idx TYPE_UINT == && {
    # cmp eax, ecx; mov eax, 0; setae al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x93 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "<" strcmp 0 == type_idx TYPE_INT == && {
    # cmp eax, ecx; mov eax, 0; setl al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x9c cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name "<=" strcmp 0 == type_idx TYPE_INT == && {
    # cmp eax, ecx; mov eax, 0; setle al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x9e cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">" strcmp 0 == type_idx TYPE_INT == && {
    # cmp eax, ecx; mov eax, 0; setg al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x9f cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  if name ">=" strcmp 0 == type_idx TYPE_INT == && {
    # cmp eax, ecx; mov eax, 0; setge al
    ctx 0x39 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx 0xb8 cctx_emit ;
    ctx 0 cctx_emit32 ;
    ctx 0x0f cctx_emit ;
    ctx 0x9d cctx_emit ;
    ctx 0xc0 cctx_emit ;
    @processed 1 = ;
  }

  processed "ast_push_value_arith32: not implemented" name assert_msg_str ;

  # push eax
  ctx 0x50 cctx_emit ;
}

fun ast_push_value_arith64 4 {
  $ctx
  $name
  $type_idx
  $is_prefix
  @ctx 3 param = ;
  @name 2 param = ;
  @type_idx 1 param = ;
  @is_prefix 0 param = ;

  # Push arguments addresses on the stack, so that we can call i64_* routines
  if is_prefix {
    # lea edx, [esp]; push edx
    ctx 0x8d cctx_emit ;
    ctx 0x14 cctx_emit ;
    ctx 0x24 cctx_emit ;
    ctx 0x52 cctx_emit ;
  } else {
    # lea eax, [esp+8]; lea edx, [esp]; push eax; push edx
    ctx 0x8d cctx_emit ;
    ctx 0x44 cctx_emit ;
    ctx 0x24 cctx_emit ;
    ctx 0x08 cctx_emit ;
    ctx 0x8d cctx_emit ;
    ctx 0x14 cctx_emit ;
    ctx 0x24 cctx_emit ;
    ctx 0x50 cctx_emit ;
    ctx 0x52 cctx_emit ;
  }

  # Invoke the specific operation code
  $processed
  @processed 0 = ;

  if name "+" strcmp 0 == {
    ctx _i64_add JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "-" strcmp 0 == {
    ctx _i64_sub JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "&" strcmp 0 == {
    ctx _i64_and JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "|" strcmp 0 == {
    ctx _i64_or JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "^" strcmp 0 == {
    ctx _i64_xor JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "<<" strcmp 0 == {
    ctx _i64_shl JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name ">>" strcmp 0 == type_idx TYPE_ULONG == && {
    ctx _i64_shr JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name ">>" strcmp 0 == type_idx TYPE_LONG == && {
    ctx _i64_sar JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "+_PRE" strcmp 0 == {
    @processed 1 = ;
  }

  if name "-_PRE" strcmp 0 == {
    ctx _i64_neg JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "~_PRE" strcmp 0 == {
    ctx _i64_not JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "!_PRE" strcmp 0 == {
    ctx _i64_lnot JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "*" strcmp 0 == {
    ctx _i64_mul JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "/" strcmp 0 == type_idx TYPE_ULONG == && {
    ctx @i64_udiv JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "/" strcmp 0 == type_idx TYPE_LONG == && {
    ctx @i64_sdiv JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "%" strcmp 0 == type_idx TYPE_ULONG == && {
    ctx @i64_umod JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "%" strcmp 0 == type_idx TYPE_LONG == && {
    ctx @i64_smod JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "==" strcmp 0 == {
    ctx _i64_eq JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "!=" strcmp 0 == {
    ctx _i64_neq JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "<" strcmp 0 == type_idx TYPE_ULONG == && {
    ctx _i64_ul JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "<=" strcmp 0 == type_idx TYPE_ULONG == && {
    ctx _i64_ule JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name ">" strcmp 0 == type_idx TYPE_ULONG == && {
    ctx _i64_ug JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name ">=" strcmp 0 == type_idx TYPE_ULONG == && {
    ctx _i64_uge JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "<" strcmp 0 == type_idx TYPE_LONG == && {
    ctx _i64_l JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name "<=" strcmp 0 == type_idx TYPE_LONG == && {
    ctx _i64_le JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name ">" strcmp 0 == type_idx TYPE_LONG == && {
    ctx _i64_g JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  if name ">=" strcmp 0 == type_idx TYPE_LONG == && {
    ctx _i64_ge JUMP_TYPE_CALL cctx_gen_jump_loc ;
    @processed 1 = ;
  }

  processed "ast_push_value_arith64: not implemented" name assert_msg_str ;

  # Discard the addresses and possibly the second operand
  if is_prefix {
    # add esp, 4
    ctx 0x83 cctx_emit ;
    ctx 0xc4 cctx_emit ;
    ctx 0x04 cctx_emit ;
  } else {
    # add esp, 16
    ctx 0x83 cctx_emit ;
    ctx 0xc4 cctx_emit ;
    ctx 0x10 cctx_emit ;
  }
}

ifun cctx_gen_push_data 2
ifun cctx_gen_move_data 2

fun ast_push_value_arith 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $name
  @name ast AST_NAME take = ;
  $is_prefix
  $is_postfix
  @is_prefix name "+_PRE" strcmp 0 ==
             name "-_PRE" strcmp 0 == ||
             name "~_PRE" strcmp 0 == ||
             name "!_PRE" strcmp 0 == ||
             name "++_PRE" strcmp 0 == ||
             name "--_PRE" strcmp 0 == || = ;
  @is_postfix name "++_POST" strcmp 0 ==
              name "--_POST" strcmp 0 == || = ;

  $assign
  $incdec
  @assign name "*=" strcmp 0 ==
          name "/=" strcmp 0 == ||
          name "%=" strcmp 0 == ||
          name "+=" strcmp 0 == ||
          name "-=" strcmp 0 == ||
          name "&=" strcmp 0 == ||
          name "^=" strcmp 0 == ||
          name "|=" strcmp 0 == ||
          name "<<=" strcmp 0 == ||
          name ">>=" strcmp 0 == || = ;
  @incdec name "++_PRE" strcmp 0 ==
          name "--_PRE" strcmp 0 == ||
          name "++_POST" strcmp 0 == ||
          name "--_POST" strcmp 0 == || = ;

  @name name strdup = ;
  if assign {
    is_prefix ! "ast_push_value_arith: error 2" assert_msg ;
    name name strlen + 1 - '\0' =c ;
  }
  if incdec {
    name 1 + '\0' =c ;
    is_prefix is_postfix || "ast_push_value_arith: error 6" assert_msg ;
    is_prefix ! is_postfix ! || "ast_push_value_arith: error 7" assert_msg ;
    assign ! "ast_push_value_arith: error 8" assert_msg ;
  }
  if is_postfix {
    incdec "ast_push_value_arith: error 9" assert_msg ;
    assign ! "ast_push_value_arith: error 10" assert_msg ;
  }

  $type1
  $type2
  $type_idx
  $common_type_idx
  if is_prefix ! {
    @type1 ast AST_LEFT take ctx lctx ast_eval_type = ;
  }
  if is_postfix ! {
    @type2 ast AST_RIGHT take ctx lctx ast_eval_type = ;
  }
  if incdec {
    if is_prefix {
      @type1 type2 = ;
    } else {
      @type2 type1 = ;
    }
  }
  @type_idx ast ctx lctx ast_eval_type = ;
  @common_type_idx ast AST_COMMON_TYPE_IDX take = ;

  # Recursively evalute both operands
  if is_prefix ! {
    if assign incdec || {
      # See the comment for sum-assigning
      # ast_push_addr; mov eax, [esp], cctx_gen_push_data
      ast AST_LEFT take ctx lctx ast_push_addr ;
      ctx 0x8b cctx_emit ;
      ctx 0x04 cctx_emit ;
      ctx 0x24 cctx_emit ;
      ctx ctx type1 cctx_type_footprint cctx_gen_push_data ;
    } else {
      ast AST_LEFT take ctx lctx ast_push_value ;
    }
    lctx ctx type1 common_type_idx lctx_int_convert ;
  }
  if is_postfix ! {
    if incdec {
      # See the comment for sum-assigning
      # ast_push_addr; mov eax, [esp], cctx_gen_push_data
      ast AST_RIGHT take ctx lctx ast_push_addr ;
      ctx 0x8b cctx_emit ;
      ctx 0x04 cctx_emit ;
      ctx 0x24 cctx_emit ;
      ctx ctx type2 cctx_type_footprint cctx_gen_push_data ;
    } else {
      ast AST_RIGHT take ctx lctx ast_push_value ;
    }
    lctx ctx type2 common_type_idx lctx_int_convert ;
  }

  # If postincrement or postdecrement, put a further copy of the
  # operand on the stack, which will be returned in the end; so the
  # stack is: value to be returned, address to be assigned, operand
  if incdec is_postfix && {
    if ctx common_type_idx cctx_type_footprint 4 == {
      # pop eax; pop ecx; push eax; push ecx; push eax
      ctx 0x58 cctx_emit ;
      ctx 0x59 cctx_emit ;
      ctx 0x50 cctx_emit ;
      ctx 0x51 cctx_emit ;
      ctx 0x50 cctx_emit ;
    } else {
      # pop eax; pop edx; pop ecx; push edx; push eax; push ecx; push edx; push eax
      ctx 0x58 cctx_emit ;
      ctx 0x5a cctx_emit ;
      ctx 0x59 cctx_emit ;
      ctx 0x52 cctx_emit ;
      ctx 0x50 cctx_emit ;
      ctx 0x51 cctx_emit ;
      ctx 0x52 cctx_emit ;
      ctx 0x50 cctx_emit ;
    }
  }

  # If increment or decrement, then push 1 of the appropriate type
  if incdec {
    type1 type2 == "ast_push_value_arith: error 11" assert_msg ;
    # push 1
    ctx 0x6a cctx_emit ;
    ctx 0x01 cctx_emit ;
    lctx ctx TYPE_INT common_type_idx lctx_int_convert ;
  }

  # Incdec operators must not be considered as prefix, because we have
  # pushed a second operand on the stack
  if ctx common_type_idx cctx_type_footprint 4 == {
    ctx name common_type_idx is_prefix incdec ! && ast_push_value_arith32 ;
  } else {
    ctx common_type_idx cctx_type_footprint 8 == "ast_push_value_arith: error 1" assert_msg ;
    ctx name common_type_idx is_prefix incdec ! && ast_push_value_arith64 ;
  }

  if type_idx common_type_idx != {
    assign ! "ast_push_value_arith: error 3" assert_msg ;
    lctx ctx common_type_idx type_idx lctx_int_convert ;
  }

  # Do the assignment if needed
  if assign incdec || {
    ctx type1 cctx_type_size ctx type_idx cctx_type_size <= "ast_push_value_arith: error 5" assert_msg ;
    type_idx common_type_idx == "ast_push_value_arith: error 4" assert_msg ;

    # First remove the address from the stack (it is not on the top of
    # the stack, though)
    # pop eax
    ctx 0x58 cctx_emit ;
    if ctx type_idx cctx_type_footprint 8 == {
      # pop edx
      ctx 0x5a cctx_emit ;
    }
    # pop ecx
    ctx 0x59 cctx_emit ;
    if ctx type_idx cctx_type_footprint 8 == {
      # push edx
      ctx 0x52 cctx_emit ;
    }
    # push eax
    ctx 0x50 cctx_emit ;

    # Then do the assignment
    # mov eax, ecx; cctx_gen_move_data
    ctx 0x89 cctx_emit ;
    ctx 0xc8 cctx_emit ;
    ctx ctx type1 cctx_type_size cctx_gen_move_data ;
  }

  # If postincrement or postdecrement, remove the result of the
  # operation, because the copy of the operand already pushed on the
  # stack will be returned
  if incdec is_postfix && {
    # add esp, footprint
    ctx 0x81 cctx_emit ;
    ctx 0xc4 cctx_emit ;
    ctx ctx common_type_idx cctx_type_footprint cctx_emit32 ;
  }

  name free ;
}

fun cctx_gen_push_data 2 {
  $ctx
  $size
  @ctx 1 param = ;
  @size 0 param = ;

  size 4 % 0 == "cctx_gen_push_data: size is not multiple of 4" assert_msg ;

  $i
  @i size 4 - = ;
  while i 0 >= {
    # push [eax+off]
    ctx 0xff cctx_emit ;
    ctx 0xb0 cctx_emit ;
    ctx i cctx_emit32 ;
    @i i 4 - = ;
  }
}

fun cctx_gen_pop_data 2 {
  $ctx
  $size
  @ctx 1 param = ;
  @size 0 param = ;

  size 4 % 0 == "cctx_gen_pop_data: size is not multiple of 4" assert_msg ;

  $i
  @i 0 = ;
  while i size < {
    # pop [eax+off]
    ctx 0x8f cctx_emit ;
    ctx 0x80 cctx_emit ;
    ctx i cctx_emit32 ;
    @i i 4 + = ;
  }
}

fun cctx_gen_move_data 2 {
  $ctx
  $size
  @ctx 1 param = ;
  @size 0 param = ;

  if size 1 == {
    # mov dl, [esp]; mov [eax], dl
    ctx 0x8a cctx_emit ;
    ctx 0x14 cctx_emit ;
    ctx 0x24 cctx_emit ;
    ctx 0x88 cctx_emit ;
    ctx 0x10 cctx_emit ;
    ret ;
  }
  if size 2 == {
    # mov dx, [esp]; mov [eax], dx
    ctx 0x66 cctx_emit ;
    ctx 0x8b cctx_emit ;
    ctx 0x14 cctx_emit ;
    ctx 0x24 cctx_emit ;
    ctx 0x66 cctx_emit ;
    ctx 0x89 cctx_emit ;
    ctx 0x10 cctx_emit ;
    ret ;
  }

  size 4 % 0 == "cctx_gen_move_data: size is not multiple of 4" assert_msg ;

  $i
  @i 0 = ;
  while i size < {
    # mov edx, [esp+off]; mov [eax+off], edx
    ctx 0x8b cctx_emit ;
    ctx 0x94 cctx_emit ;
    ctx 0x24 cctx_emit ;
    ctx i cctx_emit32 ;
    ctx 0x89 cctx_emit ;
    ctx 0x90 cctx_emit ;
    ctx i cctx_emit32 ;
    @i i 4 + = ;
  }
}

fun cctx_gen_move_data_backward 2 {
  $ctx
  $size
  @ctx 1 param = ;
  @size 0 param = ;

  size 4 % 0 == "cctx_gen_move_data: size is not multiple of 4" assert_msg ;

  $i
  @i size 4 - = ;
  while i 0 >= {
    # mov edx, [esp+off]; mov [eax+off], edx
    ctx 0x8b cctx_emit ;
    ctx 0x94 cctx_emit ;
    ctx 0x24 cctx_emit ;
    ctx i cctx_emit32 ;
    ctx 0x89 cctx_emit ;
    ctx 0x90 cctx_emit ;
    ctx i cctx_emit32 ;
    @i i 4 - = ;
  }
}

fun cctx_default_promotion 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  if type_idx TYPE_CHAR ==
     type_idx TYPE_SCHAR == ||
     type_idx TYPE_SHORT == ||
     type_idx TYPE_INT == || {
    TYPE_INT ret ;
  }

  if type_idx TYPE_UCHAR ==
     type_idx TYPE_USHORT == ||
     type_idx TYPE_UINT == || {
    TYPE_UINT ret ;
  }

  type_idx ret ;
}

fun ast_gen_function_call 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $left
  $right
  @left ast AST_LEFT take = ;
  @right ast AST_RIGHT take = ;

  $type_idx
  @type_idx ast ctx lctx ast_eval_type = ;
  $fun_ptr_idx
  $fun_ptr_type
  $fun_idx
  $fun_type
  $return_type_idx
  $return_type
  @fun_ptr_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
  @fun_ptr_type ctx fun_ptr_idx cctx_get_type = ;
  fun_ptr_type TYPE_KIND take TYPE_KIND_POINTER == "ast_gen_function_call: left is not a pointer" assert_msg ;
  @fun_idx fun_ptr_type TYPE_BASE take = ;
  @fun_type ctx fun_idx cctx_get_type = ;
  fun_type TYPE_KIND take TYPE_KIND_FUNCTION == "ast_gen_function_call: left is not a pointer to function" assert_msg ;
  @return_type_idx fun_type TYPE_BASE take = ;
  @return_type ctx return_type_idx cctx_get_type = ;
  $args
  @args fun_type TYPE_ARGS take = ;

  # If the function will return an object, immediately allocate it
  $returns_obj
  @returns_obj return_type TYPE_KIND take TYPE_KIND_STRUCT == return_type TYPE_KIND take TYPE_KIND_UNION == || = ;
  if returns_obj {
    # sub esp, footprint
    ctx 0x81 cctx_emit ;
    ctx 0xec cctx_emit ;
    ctx ctx return_type_idx cctx_type_footprint cctx_emit32 ;
  }

  # Passed arguments are stored in reverse order
  $passed_args
  @passed_args 4 vector_init = ;
  if right AST_NAME take 0 != {
    $cont
    @cont 1 = ;
    while cont {
      if right AST_NAME take "," strcmp 0 == {
        passed_args right AST_RIGHT take vector_push_back ;
        @right right AST_LEFT take = ;
      } else {
        passed_args right vector_push_back ;
        @cont 0 = ;
      }
    }
  }

  # Push arguments on the stack, right to left
  $ellipsis
  @ellipsis fun_type TYPE_ELLIPSIS take = ;
  if ellipsis {
    passed_args vector_size args vector_size >= "ast_gen_function_call: too few arguments" assert_msg ;
  } else {
    passed_args vector_size args vector_size == "ast_gen_function_call: arguments number does not match" assert_msg ;
  }
  $i
  @i 0 = ;
  $rewind
  @rewind 0 = ;
  $excess_args
  @excess_args passed_args vector_size args vector_size - = ;
  while i passed_args vector_size < {
    $passed_arg
    @passed_arg passed_args i vector_at = ;
    passed_arg ctx lctx ast_push_value ;
    $from_type
    $to_type
    @from_type passed_arg ctx lctx ast_eval_type = ;
    if i excess_args < {
      @to_type ctx from_type cctx_default_promotion = ;
    } else {
      $arg
      @arg args args vector_size i excess_args - - 1 - vector_at = ;
      @to_type arg = ;
    }
    lctx ctx from_type to_type lctx_convert_stack ;
    @rewind rewind ctx to_type cctx_type_footprint + = ;
    @i i 1 + = ;
  }

  # If the function will return an object, push the returned value address
  if returns_obj {
    # lea eax, [esp+rewind]; push eax
    ctx 0x8d cctx_emit ;
    ctx 0x84 cctx_emit ;
    ctx 0x24 cctx_emit ;
    ctx rewind cctx_emit32 ;
    ctx 0x50 cctx_emit ;
  }

  # Call function
  # ast_push_value; pop eax; call eax
  left ctx lctx ast_push_value ;
  ctx 0x58 cctx_emit ;
  ctx 0xff cctx_emit ;
  ctx 0xd0 cctx_emit ;

  # Clean up stack
  # add esp, rewind
  ctx 0x81 cctx_emit ;
  ctx 0xc4 cctx_emit ;
  ctx rewind cctx_emit32 ;

  # Push result if there is one and it is not an object
  if type_idx TYPE_VOID != returns_obj ! && {
    $res_footprint
    @res_footprint ctx ast ctx lctx ast_eval_type cctx_type_footprint = ;
    res_footprint 4 == res_footprint 0 == || res_footprint 8 == || "ast_gen_function_call: return type is not scalar" assert_msg ;
    if res_footprint 4 >= {
      if res_footprint 8 == {
        # push edx
        ctx 0x52 cctx_emit ;
      }
      # push eax
      ctx 0x50 cctx_emit ;
    }
  }

  passed_args vector_destroy ;
}

fun ast_push_value_ptr 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $name
  @name ast AST_NAME take = ;

  $sum
  $subtract
  $assign
  @sum name "+" strcmp 0 == name "[" strcmp 0 == || name "+=" strcmp 0 == || = ;
  @subtract name "-" strcmp 0 == name "-=" strcmp 0 == || = ;
  @assign name "+=" strcmp 0 == name "-=" strcmp 0 == || = ;

  sum subtract || "ast_push_value_ptr: not a sum or a subtraction" assert_msg ;

  $processed
  @processed 0 = ;

  $left_idx
  $right_idx
  @left_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
  @right_idx ast AST_RIGHT take ctx lctx ast_eval_type = ;
  $left_ptr
  $right_ptr
  @left_ptr ctx left_idx cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == = ;
  @right_ptr ctx right_idx cctx_get_type TYPE_KIND take TYPE_KIND_POINTER == = ;
  $left_size
  $right_size
  if left_ptr {
    @left_size ctx ctx left_idx cctx_get_type TYPE_BASE take cctx_type_size = ;
  }
  if right_ptr {
    @right_size ctx ctx right_idx cctx_get_type TYPE_BASE take cctx_type_size = ;
  }

  if sum {
    left_ptr right_ptr && ! "ast_push_value_ptr: cannot take sum of two pointers" assert_msg ;
    if left_ptr {
      if assign {
        # When sum-assigning, push both the address and the value on
        # the stack: first we use the value to do the computation,
        # then the address to assign
        # ast_push_addr; mov eax, [esp]; push [eax]
        ast AST_LEFT take ctx lctx ast_push_addr ;
        ctx 0x8b cctx_emit ;
        ctx 0x04 cctx_emit ;
        ctx 0x24 cctx_emit ;
        ctx 0xff cctx_emit ;
        ctx 0x30 cctx_emit ;
      } else {
        # ast_push_value
        ast AST_LEFT take ctx lctx ast_push_value ;
      }
      # ast_push_value; lctx_convert_stack; push size
      ast AST_RIGHT take ctx lctx ast_push_value ;
      lctx ctx ast AST_RIGHT take ctx lctx ast_eval_type TYPE_UINT lctx_convert_stack ;
      ctx 0x68 cctx_emit ;
      ctx left_size cctx_emit32 ;
      @processed 1 = ;
    }
    if right_ptr {
      assign ! "ast_push_value_ptr: right of sum-assign must be integer" assert_msg ;
      # ast_push_value; ast_push_value; lctx_convert_stack; push size
      ast AST_RIGHT take ctx lctx ast_push_value ;
      ast AST_LEFT take ctx lctx ast_push_value ;
      lctx ctx ast AST_LEFT take ctx lctx ast_eval_type TYPE_UINT lctx_convert_stack ;
      ctx 0x68 cctx_emit ;
      ctx right_size cctx_emit32 ;
      @processed 1 = ;
    }
    if processed {
      # pop eax; pop edx; imul edx; pop ecx; add eax, ecx
      ctx 0x58 cctx_emit ;
      ctx 0x5a cctx_emit ;
      ctx 0xf7 cctx_emit ;
      ctx 0xea cctx_emit ;
      ctx 0x59 cctx_emit ;
      ctx 0x01 cctx_emit ;
      ctx 0xc8 cctx_emit ;
      if assign {
        # pop edx; mov [edx], eax
        ctx 0x5a cctx_emit ;
        ctx 0x89 cctx_emit ;
        ctx 0x02 cctx_emit ;
      }
      # push eax
      ctx 0x50 cctx_emit ;
    }
  } else {
    left_ptr ! right_ptr && ! "ast_push_value_ptr: cannot take different of a non-pointer and a pointer" assert_msg ;
    if left_ptr {
      if right_ptr {
        assign ! "ast_push_value_ptr: right of subtract-assign must be integer" assert_msg ;
        left_size right_size == "ast_push_value_ptr: cannot take difference of pointers to types of different size" assert_msg ;
        # push size; ast_push_value; ast_push_value
        ctx 0x68 cctx_emit ;
        ctx left_size cctx_emit32 ;
        ast AST_LEFT take ctx lctx ast_push_value ;
        ast AST_RIGHT take ctx lctx ast_push_value ;

        # pop edx; pop eax; sub eax, edx; pop ecx; cdq; idiv ecx; push eax
        ctx 0x5a cctx_emit ;
        ctx 0x58 cctx_emit ;
        ctx 0x29 cctx_emit ;
        ctx 0xd0 cctx_emit ;
        ctx 0x59 cctx_emit ;
        ctx 0x99 cctx_emit ;
        ctx 0xf7 cctx_emit ;
        ctx 0xf9 cctx_emit ;
        ctx 0x50 cctx_emit ;
      } else {
        if assign {
          # See the comment for sum-assigning
          # ast_push_addr; mov eax, [esp]; push [eax]
          ast AST_LEFT take ctx lctx ast_push_addr ;
          ctx 0x8b cctx_emit ;
          ctx 0x04 cctx_emit ;
          ctx 0x24 cctx_emit ;
          ctx 0xff cctx_emit ;
          ctx 0x30 cctx_emit ;
        } else {
          # ast_push_value
          ast AST_LEFT take ctx lctx ast_push_value ;
        }
        # ast_push_value; lctx_convert_stack; push size
        ast AST_RIGHT take ctx lctx ast_push_value ;
        lctx ctx ast AST_RIGHT take ctx lctx ast_eval_type TYPE_UINT lctx_convert_stack ;
        ctx 0x68 cctx_emit ;
        ctx left_size cctx_emit32 ;

        # pop eax; pop edx; imul edx; pop ecx; neg eax; add eax, ecx
        ctx 0x58 cctx_emit ;
        ctx 0x5a cctx_emit ;
        ctx 0xf7 cctx_emit ;
        ctx 0xea cctx_emit ;
        ctx 0x59 cctx_emit ;
        ctx 0xf7 cctx_emit ;
        ctx 0xd8 cctx_emit ;
        ctx 0x01 cctx_emit ;
        ctx 0xc8 cctx_emit ;
        if assign {
          # pop edx; mov [edx], eax
          ctx 0x5a cctx_emit ;
          ctx 0x89 cctx_emit ;
          ctx 0x02 cctx_emit ;
        }
        # push eax
        ctx 0x50 cctx_emit ;
      }
      @processed 1 = ;
    }
  }

  processed ret ;
}

fun ast_push_value 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  $name
  @name ast AST_NAME take = ;
  $type_idx
  @type_idx ast ctx lctx ast_eval_type = ;

  # In case of type decaying, return the address
  $orig_type_idx
  @orig_type_idx ast AST_ORIG_TYPE_IDX take = ;
  if orig_type_idx 0xffffffff != {
    $orig_type
    @orig_type ctx orig_type_idx cctx_get_type = ;
    $orig_kind
    @orig_kind orig_type TYPE_KIND take = ;
    if orig_kind TYPE_KIND_FUNCTION == orig_kind TYPE_KIND_ARRAY == || {
      ast ctx lctx ast_push_addr ;
      ret ;
    }
  }

  if ast AST_TYPE take 0 == {
    # Operand
    if name is_valid_identifier {
      $enum_consts
      @enum_consts ctx CCTX_ENUM_CONSTS take = ;
      if name "sizeof" strcmp 0 == {
        # push type_size
        ctx 0x68 cctx_emit ;
        ctx ctx ast AST_CAST_TYPE_IDX take cctx_type_size cctx_emit32 ;
      } else {
        if enum_consts name map_has {
          $value
          @value enum_consts name map_at = ;
          ctx 0x68 cctx_emit ;
          ctx value cctx_emit32 ;
        } else {
          # Push the address
          ast ctx lctx ast_push_addr ;
          # pop eax
          ctx 0x58 cctx_emit ;
          ctx ctx type_idx cctx_type_footprint cctx_gen_push_data ;
        }
      }
    } else {
      if name **c '\"' == {
        0 "ast_push_value: error 1" assert_msg ;
      } else {
        if name **c '\'' == {
          $data
          $from
          $to
          @data 0 = ;
          @from name 1 + = ;
          @to @data = ;
          @from @to 0 escape_char ;
          to @data 1 + == "ast_push_value: invalid character literal 1" assert_msg ;
          from **c '\'' == "ast_push_value: invalid character literal 2" assert_msg ;
          from 1 + **c 0 == "ast_push_value: invalid character literal 3" assert_msg ;
          $value
          @value i64_init = ;
          value data i64_from_32 ;
          ast AST_VALUE take_addr value = ;
        } else {
          # Value is already encoded in the AST
        }
      }

      if ctx type_idx cctx_type_footprint 8 == {
        # push upper32
        ctx 0x68 cctx_emit ;
        ctx ast AST_VALUE take i64_to_upper32 cctx_emit32 ;
      } else {
        ctx type_idx cctx_type_footprint 4 == "ast_push_value: error 2" assert_msg ;
      }

      # push lower32
      ctx 0x68 cctx_emit ;
      ctx ast AST_VALUE take i64_to_32 cctx_emit32 ;
    }
  } else {
    # Operator
    $processed
    @processed 0 = ;

    if name "+" strcmp 0 ==
       name "-" strcmp 0 == ||
       name "+=" strcmp 0 == ||
       name "-=" strcmp 0 == ||
       processed ! && {
      @processed ast ctx lctx ast_push_value_ptr = ;
    }

    if name "*" strcmp 0 ==
       name "/" strcmp 0 == ||
       name "%" strcmp 0 == ||
       name "+" strcmp 0 == ||
       name "-" strcmp 0 == ||
       name "&" strcmp 0 == ||
       name "^" strcmp 0 == ||
       name "|" strcmp 0 == ||
       name "<<" strcmp 0 == ||
       name ">>" strcmp 0 == ||
       name "*=" strcmp 0 == ||
       name "/=" strcmp 0 == ||
       name "%=" strcmp 0 == ||
       name "+=" strcmp 0 == ||
       name "-=" strcmp 0 == ||
       name "&=" strcmp 0 == ||
       name "^=" strcmp 0 == ||
       name "|=" strcmp 0 == ||
       name "<<=" strcmp 0 == ||
       name ">>=" strcmp 0 == ||
       name "<" strcmp 0 == ||
       name ">" strcmp 0 == ||
       name "<=" strcmp 0 == ||
       name ">=" strcmp 0 == ||
       name "==" strcmp 0 == ||
       name "!=" strcmp 0 == ||
       name "+_PRE" strcmp 0 == ||
       name "-_PRE" strcmp 0 == ||
       name "~_PRE" strcmp 0 == ||
       name "!_PRE" strcmp 0 == ||
       name "++_PRE" strcmp 0 == ||
       name "--_PRE" strcmp 0 == ||
       name "++_POST" strcmp 0 == ||
       name "--_POST" strcmp 0 == ||
       processed ! && {
      ast ctx lctx ast_push_value_arith ;
      @processed 1 = ;
    }

    if name "&&" strcmp 0 ==
       name "||" strcmp 0 == ||
       processed ! && {
      ast ctx lctx ast_push_value_logic ;
      @processed 1 = ;
    }

    if name "=" strcmp 0 == {
      ast AST_RIGHT take ctx lctx ast_push_value ;
      lctx ctx ast AST_RIGHT take ctx lctx ast_eval_type ast ctx lctx ast_eval_type lctx_convert_stack ;
      ast AST_LEFT take ctx lctx ast_push_addr ;

      # pop eax; cctx_gen_move_data
      ctx 0x58 cctx_emit ;
      ctx ctx ast ctx lctx ast_eval_type cctx_type_size cctx_gen_move_data ;

      @processed 1 = ;
    }

    if name "(" strcmp 0 == {
      ast ctx lctx ast_gen_function_call ;
      @processed 1 = ;
    }

    if name "*_PRE" strcmp 0 == name "[" strcmp 0 == || {
      # Push the address
      ast ctx lctx ast_push_addr ;
      # pop eax
      ctx 0x58 cctx_emit ;
      ctx ctx type_idx cctx_type_footprint cctx_gen_push_data ;
      @processed 1 = ;
    }

    if name "&_PRE" strcmp 0 == {
      ast AST_RIGHT take ctx lctx ast_push_addr ;
      @processed 1 = ;
    }

    if name "." strcmp 0 == {
      $struct_idx
      $struct_type
      $struct_size
      @struct_idx ast AST_LEFT take ctx lctx ast_eval_type = ;
      @struct_type ctx struct_idx cctx_get_type = ;
      @struct_size ctx struct_idx cctx_type_footprint = ;
      ast AST_RIGHT take AST_TYPE take 0 == "ast_push_value: right is not a plain name" assert_msg ;
      $name
      @name ast AST_RIGHT take AST_NAME take = ;
      $field
      @field struct_type name type_get_idx = ;
      field 0xffffffff != "ast_push_value: specified field does not exist" assert_msg ;
      $res_idx
      $res_size
      $off
      @res_idx ast ctx lctx ast_eval_type = ;
      @res_size ctx res_idx cctx_type_footprint = ;
      @off struct_type TYPE_FIELDS_OFFS take field vector_at = ;

      # ast_push_value; lea eax, [esp+struct_size-res_size]; add esp, off; cctx_gen_move_data_backward; mov esp, eax
      ast AST_LEFT take ctx lctx ast_push_value ;
      ctx 0x8d cctx_emit ;
      ctx 0x84 cctx_emit ;
      ctx 0x24 cctx_emit ;
      ctx struct_size res_size - cctx_emit32 ;
      ctx 0x81 cctx_emit ;
      ctx 0xc4 cctx_emit ;
      ctx off cctx_emit32 ;
      ctx res_size cctx_gen_move_data_backward ;
      ctx 0x89 cctx_emit ;
      ctx 0xc4 cctx_emit ;

      @processed 1 = ;
    }

    if name "->" strcmp 0 == {
      # Push the address
      ast ctx lctx ast_push_addr ;
      # pop eax
      ctx 0x58 cctx_emit ;
      ctx ctx type_idx cctx_type_footprint cctx_gen_push_data ;
      @processed 1 = ;
    }

    if name "?" strcmp 0 == {
      $else_lab
      $end_lab
      @else_lab lctx ctx lctx_gen_label = ;
      @end_lab lctx ctx lctx_gen_label = ;

      # Evaluate guard expression
      ast AST_LEFT take ctx lctx ast_push_value ;
      lctx ctx ast AST_LEFT take ctx lctx ast_eval_type TYPE_BOOL lctx_convert_stack ;

      # pop eax; test eax, eax; cctx_gen_label_jump
      ctx 0x58 cctx_emit ;
      ctx 0x85 cctx_emit ;
      ctx 0xc0 cctx_emit ;
      ctx lctx else_lab JUMP_TYPE_JZ 0 cctx_gen_label_jump ;

      # Evaluate center expression
      ast AST_CENTER take ctx lctx ast_push_value ;
      lctx ctx ast AST_CENTER take ctx lctx ast_eval_type type_idx lctx_convert_stack ;

      # cctx_gen_label_jump
      ctx lctx end_lab JUMP_TYPE_JMP 0 cctx_gen_label_jump ;

      # Evaluate right expression
      lctx ctx else_lab lctx_fix_label ;
      ast AST_RIGHT take ctx lctx ast_push_value ;
      lctx ctx ast AST_RIGHT take ctx lctx ast_eval_type type_idx lctx_convert_stack ;
      lctx ctx end_lab lctx_fix_label ;

      @processed 1 = ;
    }

    if name "(_PRE" strcmp 0 == {
      ast AST_RIGHT take ctx lctx ast_push_value ;
      if type_idx TYPE_VOID == {
        # Cast to void, discard the return value
        $right_type
        @right_type ast AST_RIGHT take ctx lctx ast_eval_type = ;
        if right_type TYPE_VOID != {
          # add esp, footprint
          ctx 0x81 cctx_emit ;
          ctx 0xc4 cctx_emit ;
          ctx ctx right_type cctx_type_footprint cctx_emit32 ;
        }
      } else {
        lctx ctx ast AST_RIGHT take ctx lctx ast_eval_type type_idx lctx_convert_stack ;
      }
      @processed 1 = ;
    }

    if name "sizeof_PRE" strcmp 0 == {
      # push type_size
      ctx 0x68 cctx_emit ;
      ctx ctx ast AST_RIGHT take ctx lctx ast_eval_type cctx_type_size cctx_emit32 ;
      @processed 1 = ;
    }

    processed "ast_push_value: not implemented" assert_msg ;
  }
}

fun ast_c_eval 3 {
  $ast
  $ctx
  $lctx
  @ast 2 param = ;
  @ctx 1 param = ;
  @lctx 0 param = ;

  # First push value
  ast ctx lctx ast_push_value ;

  # Then pop and discard it (if it is not void)
  $type_idx
  @type_idx ast ctx lctx ast_eval_type = ;
  if type_idx TYPE_VOID != {
    $footprint
    @footprint ctx type_idx cctx_type_footprint = ;

    # add esp, footprint
    ctx 0x81 cctx_emit ;
    ctx 0xc4 cctx_emit ;
    ctx footprint cctx_emit32 ;
  }
}

fun cctx_compile_expression 2 {
  $ctx
  $lctx
  $target_type_idx
  $end_tok
  @ctx 3 param = ;
  @lctx 2 param = ;
  @target_type_idx 1 param = ;
  @end_tok 0 param = ;

  $ast
  @ast ctx end_tok cctx_parse_ast1 = ;
  #ast ctx lctx ast_eval_type ;
  #ast ast_dump ;
  if target_type_idx TYPE_VOID == {
    ast ctx lctx ast_c_eval ;
  } else {
    ast ctx lctx ast_push_value ;
    lctx ctx ast ctx lctx ast_eval_type target_type_idx lctx_convert_stack ;
  }
  ast ast_destroy ;
}

ifun cctx_compile_statement_or_block 2

fun cctx_compile_statement 2 {
  $ctx
  $lctx
  @ctx 1 param = ;
  @lctx 0 param = ;

  $processed
  @processed 0 = ;
  $tok
  @tok ctx cctx_get_token_or_fail = ;

  # Check if we found the closing brace
  if tok "}" strcmp 0 == processed ! && {
    @processed 1 = ;
    0 ret ;
  }

  $expect_semicolon
  @expect_semicolon 0 = ;

  # Allow and ignore empty statements
  if tok ";" strcmp 0 == processed ! && {
    @expect_semicolon 0 = ;
    @processed 1 = ;
  }

  # Parse return
  if tok "return" strcmp 0 == processed ! && {
    $ret_type
    @ret_type lctx LCTX_RETURN_TYPE_IDX take = ;
    if ret_type TYPE_VOID != {
      ctx lctx ret_type ";" cctx_compile_expression ;
      if lctx LCTX_RETURNS_OBJ take {
        # mov eax, [ebp+8]; cctx_gen_move_data; add esp, size
        ctx 0x8b cctx_emit ;
        ctx 0x45 cctx_emit ;
        ctx 0x08 cctx_emit ;
        ctx ctx ret_type cctx_type_size cctx_gen_move_data ;
	ctx 0x81 cctx_emit ;
	ctx 0xc4 cctx_emit ;
	ctx ctx ret_type cctx_type_footprint cctx_emit32 ;
      } else {
        # pop eax
        ctx 0x58 cctx_emit ;
        if ctx ret_type cctx_type_footprint 8 == {
          # pop edx
          ctx 0x5a cctx_emit ;
        } else {
          ctx ret_type cctx_type_footprint 4 == "cctx_compile_statement: error 1" assert_msg ;
        }
      }
    }
    ctx lctx lctx LCTX_RETURN_LABEL take JUMP_TYPE_JMP 1 cctx_gen_label_jump ;
    @processed 1 = ;
    @expect_semicolon 1 = ;
  }

  # Parse break
  if tok "break" strcmp 0 == processed ! && {
    ctx lctx lctx LCTX_BREAK_LABEL take JUMP_TYPE_JMP 1 cctx_gen_label_jump ;
    @processed 1 = ;
    @expect_semicolon 1 = ;
  }

  # Parse continue
  if tok "continue" strcmp 0 == processed ! && {
    ctx lctx lctx LCTX_CONTINUE_LABEL take JUMP_TYPE_JMP 1 cctx_gen_label_jump ;
    @processed 1 = ;
    @expect_semicolon 1 = ;
  }

  # Parse if
  if tok "if" strcmp 0 == processed ! && {
    $else_lab
    $end_lab
    @else_lab lctx ctx lctx_gen_label = ;
    @end_lab lctx ctx lctx_gen_label = ;

    # Compile guard expression
    @tok ctx cctx_get_token_or_fail = ;
    tok "(" strcmp 0 == "cctx_compile_statement: ( expected" assert_msg ;
    ctx lctx TYPE_BOOL ")" cctx_compile_expression ;
    @tok ctx cctx_get_token_or_fail = ;
    tok ")" strcmp 0 == "cctx_compile_statement: ) expected" assert_msg ;

    # pop eax; test eax, eax; cctx_gen_label_jump
    ctx 0x58 cctx_emit ;
    ctx 0x85 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx lctx else_lab JUMP_TYPE_JZ 0 cctx_gen_label_jump ;

    # Compile body
    ctx lctx cctx_compile_statement_or_block ;

    # cctx_gen_label_jump
    ctx lctx end_lab JUMP_TYPE_JMP 0 cctx_gen_label_jump ;

    # Compile else
    lctx ctx else_lab lctx_fix_label ;
    @tok ctx cctx_get_token_or_fail = ;
    if tok "else" strcmp 0 == {
      ctx lctx cctx_compile_statement_or_block ;
    } else {
      ctx cctx_give_back_token ;
    }
    lctx ctx end_lab lctx_fix_label ;

    @processed 1 = ;
  }

  # Parse for
  if tok "for" strcmp 0 == processed ! && {
    # Set up labels
    $continue_lab
    $break_lab
    $restart_lab
    $body_lab
    @continue_lab lctx ctx lctx_gen_label = ;
    @break_lab lctx ctx lctx_gen_label = ;
    @restart_lab lctx ctx lctx_gen_label = ;
    @body_lab lctx ctx lctx_gen_label = ;

    # Compile initialization expression
    @tok ctx cctx_get_token_or_fail = ;
    tok "(" strcmp 0 == "cctx_compile_statement: ( expected after for" assert_msg ;
    ctx lctx TYPE_VOID ";" cctx_compile_expression ;
    @tok ctx cctx_get_token_or_fail = ;
    tok ";" strcmp 0 == "cctx_compile_statement: ; expected after for" assert_msg ;

    # Compile guard expression
    lctx ctx restart_lab lctx_fix_label ;
    ctx lctx TYPE_BOOL ";" cctx_compile_expression ;
    @tok ctx cctx_get_token_or_fail = ;
    tok ";" strcmp 0 == "cctx_compile_statement: second ; expected after for" assert_msg ;

    # pop eax; test eax, eax; cctx_gen_label_jump; cctx_gen_label_jump
    ctx 0x58 cctx_emit ;
    ctx 0x85 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx lctx break_lab JUMP_TYPE_JZ 0 cctx_gen_label_jump ;
    ctx lctx body_lab JUMP_TYPE_JMP 0 cctx_gen_label_jump ;

    # Compile iteration expression
    lctx ctx continue_lab lctx_fix_label ;
    ctx lctx TYPE_VOID ")" cctx_compile_expression ;
    @tok ctx cctx_get_token_or_fail = ;
    tok ")" strcmp 0 == "cctx_compile_statement: ) expected after for" assert_msg ;

    # cctx_gen_label_jump
    ctx lctx restart_lab JUMP_TYPE_JMP 0 cctx_gen_label_jump ;

    # Compile body
    $old_break_lab
    $old_continue_lab
    @old_break_lab lctx LCTX_BREAK_LABEL take = ;
    @old_continue_lab lctx LCTX_CONTINUE_LABEL take = ;
    lctx LCTX_BREAK_LABEL take_addr break_lab = ;
    lctx LCTX_CONTINUE_LABEL take_addr continue_lab = ;
    lctx ctx body_lab lctx_fix_label ;
    ctx lctx cctx_compile_statement_or_block ;
    lctx LCTX_BREAK_LABEL take_addr old_break_lab = ;
    lctx LCTX_CONTINUE_LABEL take_addr old_continue_lab = ;

    # cctx_gen_label_jump
    ctx lctx continue_lab JUMP_TYPE_JMP 0 cctx_gen_label_jump ;

    lctx ctx break_lab lctx_fix_label ;
    @processed 1 = ;
  }

  # Parse while
  if tok "while" strcmp 0 == processed ! && {
    # Set up labels
    $continue_lab
    $break_lab
    @continue_lab lctx ctx lctx_gen_label = ;
    @break_lab lctx ctx lctx_gen_label = ;

    # Compile guard expression
    lctx ctx continue_lab lctx_fix_label ;
    @tok ctx cctx_get_token_or_fail = ;
    tok "(" strcmp 0 == "cctx_compile_statement: ( expected after while" assert_msg ;
    ctx lctx TYPE_BOOL ")" cctx_compile_expression ;
    @tok ctx cctx_get_token_or_fail = ;
    tok ")" strcmp 0 == "cctx_compile_statement: ) expected after while" assert_msg ;

    # pop eax; test eax, eax; cctx_gen_label_jump
    ctx 0x58 cctx_emit ;
    ctx 0x85 cctx_emit ;
    ctx 0xc0 cctx_emit ;
    ctx lctx break_lab JUMP_TYPE_JZ 0 cctx_gen_label_jump ;

    # Compile body
    $old_break_lab
    $old_continue_lab
    @old_break_lab lctx LCTX_BREAK_LABEL take = ;
    @old_continue_lab lctx LCTX_CONTINUE_LABEL take = ;
    lctx LCTX_BREAK_LABEL take_addr break_lab = ;
    lctx LCTX_CONTINUE_LABEL take_addr continue_lab = ;
    ctx lctx cctx_compile_statement_or_block ;
    lctx LCTX_BREAK_LABEL take_addr old_break_lab = ;
    lctx LCTX_CONTINUE_LABEL take_addr old_continue_lab = ;

    # cctx_gen_label_jump
    ctx lctx continue_lab JUMP_TYPE_JMP 0 cctx_gen_label_jump ;

    lctx ctx break_lab lctx_fix_label ;
    @processed 1 = ;
  }

  # Parse goto
  if tok "goto" strcmp 0 == processed ! && {
    @tok ctx cctx_get_token_or_fail = ;
    $lab
    if lctx LCTX_GOTO_LABELS take tok map_has {
      @lab lctx LCTX_GOTO_LABELS take tok map_at = ;
    } else {
      @lab lctx ctx lctx_gen_label = ;
      lctx LCTX_GOTO_LABELS take tok lab map_set ;
    }
    # cctx_gen_label_jump
    ctx lctx lab JUMP_TYPE_JMP 1 cctx_gen_label_jump ;
    @processed 1 = ;
    @expect_semicolon 1 = ;
  }

  # Consider one more token to see if it is a goto label
  if processed ! {
    $tok2
    @tok2 ctx cctx_get_token_or_fail = ;
    if tok2 ":" strcmp 0 == {
      $lab
      if lctx LCTX_GOTO_LABELS take tok map_has {
        @lab lctx LCTX_GOTO_LABELS take tok map_at = ;
      } else {
        @lab lctx ctx lctx_gen_label = ;
        lctx LCTX_GOTO_LABELS take tok lab map_set ;
      }
      lctx ctx lab lctx_fix_label ;
      ctx lctx cctx_compile_statement_or_block ;
      @expect_semicolon 0 = ;
      @processed 1 = ;
    } else {
      ctx cctx_give_back_token ;
    }
  }

  if processed ! {
    ctx cctx_give_back_token ;

    # Try to parse a type, in which case we have a variable declaration
    $type_idx
    @type_idx ctx cctx_parse_type = ;
    if type_idx 0xffffffff != {
      # There is a type, so we have a variable declaration
      $cont
      @cont 1 = ;
      while cont {
        $actual_type_idx
        $name
        ctx type_idx @actual_type_idx @name 0 cctx_parse_declarator "cctx_compile_statement: error 1" assert_msg ;
        name 0 != "cctx_compile_statement: cannot instantiate variable without name" assert_msg ;
        lctx ctx actual_type_idx name lctx_push_var ;
        @tok ctx cctx_get_token_or_fail = ;
        if tok "=" strcmp 0 == {
          $right_ast
          $left_ast
          $ast
          @right_ast ctx ";" cctx_parse_ast1 = ;
          @left_ast ast_init = ;
          left_ast AST_TYPE take_addr 0 = ;
          left_ast AST_NAME take_addr name strdup = ;
          @ast ast_init = ;
          ast AST_TYPE take_addr 1 = ;
          ast AST_NAME take_addr "=" strdup = ;
          ast AST_RIGHT take_addr right_ast = ;
          ast AST_LEFT take_addr left_ast = ;
          ast ctx lctx ast_c_eval ;
          ast ast_destroy ;
        } else {
          ctx cctx_give_back_token ;
        }
        @tok ctx cctx_get_token_or_fail = ;
        if tok ";" strcmp 0 == {
          ctx cctx_give_back_token ;
          @cont 0 = ;
        } else {
          tok "," strcmp 0 == "cctx_compile_statement: comma expected" assert_msg ;
        }
      }
    } else {
      # No type, so this is an expression
      ctx lctx TYPE_VOID ";" cctx_compile_expression ;
    }
    @expect_semicolon 1 = ;
  }

  # Expect and consume the semicolon
  if expect_semicolon {
    @tok ctx cctx_get_token_or_fail = ;
    tok ";" strcmp 0 == "cctx_compile_statement: ; expected" assert_msg ;
  }

  1 ret ;
}

fun cctx_compile_block 2 {
  $ctx
  $lctx
  @ctx 1 param = ;
  @lctx 0 param = ;

  $saved_pos
  @saved_pos lctx ctx lctx_save_status = ;

  $cont
  @cont 1 = ;
  while cont {
    @cont ctx lctx cctx_compile_statement = ;
  }

  lctx ctx saved_pos lctx_restore_status ;
}

fun cctx_compile_statement_or_block 2 {
  $ctx
  $lctx
  @ctx 1 param = ;
  @lctx 0 param = ;

  $tok
  @tok ctx cctx_get_token_or_fail = ;
  if tok "{" strcmp 0 == {
    ctx lctx cctx_compile_block ;
  } else {
    ctx cctx_give_back_token ;
    ctx lctx cctx_compile_statement ;
  }
}

fun cctx_compile_function 3 {
  $ctx
  $type_idx
  $arg_names
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @arg_names 0 param = ;

  # Costruct the local context
  $lctx
  @lctx lctx_init = ;
  lctx LCTX_RETURN_LABEL take_addr lctx ctx lctx_gen_label = ;
  lctx LCTX_RETURN_TYPE_IDX take_addr ctx type_idx cctx_get_type TYPE_BASE take = ;

  lctx ctx type_idx arg_names lctx_prime_stack ;
  lctx ctx lctx_gen_prologue ;
  ctx lctx cctx_compile_block ;
  lctx ctx lctx LCTX_RETURN_LABEL take lctx_fix_label ;
  lctx ctx lctx_gen_epilogue ;

  lctx lctx_destroy ;
}

fun cctx_mangle_function_type 2 {
  $ctx
  $type_idx
  @ctx 1 param = ;
  @type_idx 0 param = ;

  $type
  @type ctx type_idx cctx_get_type = ;
  type TYPE_KIND take TYPE_KIND_FUNCTION == "cctx_mangle_function_type: not a function type" assert_msg ;
  $base_idx
  @base_idx type TYPE_BASE take = ;
  $args
  @args type TYPE_ARGS take = ;
  $new_args
  @new_args 4 vector_init = ;
  $ellipsis
  @ellipsis type TYPE_ELLIPSIS take = ;

  $i
  @i 0 = ;
  while i args vector_size < {
    $arg_idx
    @arg_idx args i vector_at = ;
    $arg_type
    @arg_type ctx arg_idx cctx_get_type = ;

    if arg_type TYPE_KIND take TYPE_KIND_ARRAY == {
      $arg_base
      @arg_base arg_type TYPE_BASE take = ;
      @arg_idx ctx arg_base cctx_get_pointer_type = ;
    }

    if arg_type TYPE_KIND take TYPE_KIND_FUNCTION == {
      @arg_idx ctx arg_idx cctx_get_pointer_type = ;
    }

    new_args arg_idx vector_push_back ;
    @i i 1 + = ;
  }

  ctx base_idx new_args ellipsis cctx_get_function_type ret ;
}

fun assign_with_size 3 {
  $loc
  $value
  $size
  @loc 2 param = ;
  @value 1 param = ;
  @size 0 param = ;

  if size 1 == {
    loc value ** =c ;
    ret ;
  }

  if size 2 == {
    loc value ** =c ;
    loc 1 + value ** 8 >> =c ;
    ret ;
  }

  if size 4 == {
    loc value ** = ;
    ret ;
  }

  if size 8 == {
    loc value ** = ;
    loc 4 + value 4 + ** = ;
    ret ;
  }

  0 "assign_with_size: invalid size" assert_msg ;
}

fun cctx_parse_initializer 3 {
  $ctx
  $type_idx
  $loc
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @loc 0 param = ;

  # Check that the type is complete
  ctx type_idx cctx_type_footprint ;
  $type
  @type ctx type_idx cctx_get_type = ;

  if type_idx is_integer_type type TYPE_KIND take TYPE_KIND_POINTER == || {
    $ast
    @ast ctx "," "}" ";" cctx_parse_ast3 = ;
    ctx ast ast_eval_compile ;
    ast ast_destroy ;
    $size
    @size ctx type_idx cctx_type_size = ;
    loc ast AST_VALUE take size assign_with_size ;
    ret ;
  }

  if type TYPE_KIND take TYPE_KIND_STRUCT == {
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    tok "{" strcmp 0 == "cctx_parse_initializer: { expected" assert_msg ;
    $i
    @i 0 = ;
    $offs
    @offs type TYPE_FIELDS_OFFS take = ;
    $type_idxs
    @type_idxs type TYPE_FIELDS_TYPE_IDXS take = ;
    while i offs vector_size < {
      @tok ctx cctx_get_token_or_fail = ;
      if tok "}" strcmp 0 == {
        @i offs vector_size = ;
      } else {
        ctx cctx_give_back_token ;
        ctx type_idxs i vector_at loc offs i vector_at + cctx_parse_initializer ;
        @tok ctx cctx_get_token_or_fail = ;
        if tok "}" strcmp 0 == {
          @i offs vector_size = ;
        } else {
          tok "," strcmp 0 == "cctx_parse_initializer: , or } expected" assert_msg ;
          @i i 1 + = ;
        }
      }
    }
    tok "}" strcmp 0 == "cctx_parse_initializer: initializer has too many entries" assert_msg ;
    ret ;
  }

  if type TYPE_KIND take TYPE_KIND_ARRAY == {
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    tok "{" strcmp 0 == "cctx_parse_initializer: { expected" assert_msg ;
    $i
    @i 0 = ;
    $len
    @len type TYPE_LENGTH take = ;
    $base_type_idx
    @base_type_idx type TYPE_BASE take = ;
    $base_size
    @base_size ctx base_type_idx cctx_type_size = ;
    while i len < {
      @tok ctx cctx_get_token_or_fail = ;
      if tok "}" strcmp 0 == {
        @i len = ;
      } else {
        ctx cctx_give_back_token ;
        ctx base_type_idx loc i base_size * + cctx_parse_initializer ;
        @tok ctx cctx_get_token_or_fail = ;
        if tok "}" strcmp 0 == {
          @i len = ;
        } else {
          tok "," strcmp 0 == "cctx_parse_initializer: , or } expected" assert_msg ;
          @i i 1 + = ;
        }
      }
    }
    tok "}" strcmp 0 == "cctx_parse_initializer: initializer has too many entries" assert_msg ;
    ret ;
  }

  0 "cctx_parse_initializer: not implemented" assert_msg ;
}

fun cctx_compile_line 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx cctx_get_token_or_fail = ;
  if tok "typedef" strcmp 0 == {
    $type_idx
    @type_idx ctx cctx_parse_type = ;
    type_idx 0xffffffff != "cctx_compile_line: type expected after typedef" assert_msg ;
    $cont
    @cont 1 = ;
    while cont {
      $actual_type_idx
      $name
      ctx type_idx @actual_type_idx @name 0 cctx_parse_declarator "cctx_compile_line: could not parse declarator after typedef" assert_msg ;
      name 0 != "cctx_compile_line: cannot define type without name" assert_msg ;
      $typenames
      @typenames ctx CCTX_TYPENAMES take = ;
      typenames name map_has ! "cctx_compile_line: type name already defined" assert_msg ;
      typenames name actual_type_idx map_set ;
      @tok ctx cctx_get_token_or_fail = ;
      if tok ";" strcmp 0 == {
        @cont 0 = ;
      } else {
        tok "," strcmp 0 == "cctx_compile_line: comma expected after typedef" assert_msg ;
      }
    }
    ret ;
  } else {
    ctx cctx_give_back_token ;
  }

  $extern
  $static
  @extern 0 = ;
  @static 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    @tok ctx cctx_get_token_or_fail = ;
    if tok "extern" strcmp 0 == {
      @extern 1 = ;
    } else {
      if tok "static" strcmp 0 == {
        @static 1 = ;
      } else {
        ctx cctx_give_back_token ;
        @cont 0 = ;
      }
    }
  }

  $type_idx
  @type_idx ctx cctx_parse_type = ;
  type_idx 0xffffffff != "cctx_compile: type expected" assert_msg ;
  @tok ctx cctx_get_token_or_fail = ;
  if tok ";" strcmp 0 == {
    @cont 0 = ;
  } else {
    ctx cctx_give_back_token ;
    @cont 1 = ;
  }
  while cont {
    $actual_type_idx
    $name
    $arg_names
    @arg_names 4 vector_init = ;
    ctx type_idx @actual_type_idx @name arg_names cctx_parse_declarator "cctx_compile_line: could not parse declarator" assert_msg ;
    $type
    @type ctx actual_type_idx cctx_get_type = ;
    name 0 != "cctx_compile_line: cannot instantiate variable without name" assert_msg ;
    if type TYPE_KIND take TYPE_KIND_FUNCTION == {
      # If it is a function, first mangle its parameters' types
      @actual_type_idx ctx actual_type_idx cctx_mangle_function_type = ;
      @type ctx actual_type_idx cctx_get_type = ;
      # Then check if it has a body
      @tok ctx cctx_get_token_or_fail = ;
      if tok "{" strcmp 0 == {
        # There is the body, register the global and compile the body
        ctx name ctx CCTX_CURRENT_LOC take actual_type_idx cctx_add_global ;
        ctx actual_type_idx arg_names cctx_compile_function ;
        @cont 0 = ;
      } else {
        # No body, register the global with a fictious location
        ctx cctx_give_back_token ;
        ctx name 0xffffffff actual_type_idx cctx_add_global ;
      }
    } else {
      if extern {
        ctx name 0xffffffff actual_type_idx cctx_add_global ;
      } else {
        # If it is anything else, register it and allocate its size
        $loc
        @loc ctx CCTX_CURRENT_LOC take = ;
        ctx name loc actual_type_idx cctx_add_global ;
        ctx ctx actual_type_idx cctx_type_footprint cctx_emit_zeros ;
        # Check if there is an initializer
        @tok ctx cctx_get_token_or_fail = ;
        if tok "=" strcmp 0 == {
          ctx actual_type_idx loc cctx_parse_initializer ;
        } else {
          ctx cctx_give_back_token ;
        }
      }
    }
    arg_names vector_destroy ;

    if cont {
      @tok ctx cctx_get_token_or_fail = ;
      if tok ";" strcmp 0 == {
        @cont 0 = ;
      } else {
        tok "," strcmp 0 == "cctx_compile_line: comma expected" assert_msg ;
      }
    }
  }
}

fun cctx_compile 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_STAGE take_addr 0 = ;
  $start_loc
  @start_loc 0 = ;
  $size
  while ctx CCTX_STAGE take 3 < {
    if ctx CCTX_VERBOSE take {
      "Compilation stage " 1 platform_log ;
      ctx CCTX_STAGE take 1 + itoa 1 platform_log ;
      "\n" 1 platform_log ;
    }
    ctx CCTX_CURRENT_LOC take_addr start_loc = ;
    ctx CCTX_TOKENS_POS take_addr 0 = ;
    ctx CCTX_LABEL_NUM take_addr 0 = ;
    ctx cctx_reset_types ;
    ctx cctx_create_basic_types ;
    ctx "__builtin_handles" ctx CCTX_HANDLES take vector_data TYPE_VOID_PTR cctx_add_global ;
    while ctx cctx_is_eof ! {
      ctx cctx_compile_line ;
    }
    if ctx CCTX_STAGE take 0 == {
      @size ctx CCTX_CURRENT_LOC take start_loc - = ;
      @start_loc size platform_allocate = ;
    } else {
      ctx CCTX_CURRENT_LOC take start_loc - size == "cctx_compile: error 1" assert_msg ;
    }
    ctx CCTX_STAGE take_addr ctx CCTX_STAGE take 1 + = ;
  }
  if ctx CCTX_VERBOSE take {
    "Compiled program has size " 1 platform_log ;
    size itoa 1 platform_log ;
    " and starts at " 1 platform_log ;
    start_loc itoa 1 platform_log ;
    "\n" 1 platform_log ;
    "Compiled dump:\n" 1 platform_log ;
    start_loc size dump_mem ;
    "\n" 1 platform_log ;
  }
}

fun parse_c 1 {
  $filename
  @filename 0 param = ;

  # Preprocessing
  $ctx
  @ctx ppctx_init = ;
  ctx filename ppctx_set_base_filename ;
  $tokens
  @tokens 4 vector_init = ;
  tokens ctx filename preproc_file ;
  @tokens tokens remove_whites = ;
  "Finished preprocessing\n" 1 platform_log ;
  #tokens print_token_list ;

  # Compilation
  $cctx
  @cctx tokens cctx_init = ;
  cctx cctx_compile ;

  # Debug output
  "TYPES TABLE\n" 1 platform_log ;
  cctx cctx_dump_types ;
  "TYPE NAMES TABLE\n" 1 platform_log ;
  cctx cctx_dump_typenames ;
  "GLOBALS TABLE\n" 1 platform_log ;
  cctx cctx_dump_globals ;

  # Try to execute the code
  "Executing compiled code...\n" 1 platform_log ;
  $main_global
  @main_global cctx "_start" cctx_get_global = ;
  $main_addr
  @main_addr main_global GLOBAL_LOC take = ;
  $arg
  @arg "_main" = ;
  $res
  @res @arg 1 main_addr \2 = ;
  "It returned " 1 platform_log ;
  res itoa 1 platform_log ;
  "\n" 1 platform_log ;

  # Cleanup
  tokens free_vect_of_ptrs ;
  cctx cctx_destroy ;
  ctx ppctx_destroy ;
}
