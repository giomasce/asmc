
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
const SIZEOF_TYPE 20

fun type_init 0 {
  $type
  @type SIZEOF_TYPE malloc = ;
  type TYPE_ARGS take_addr 4 vector_init = ;
  type ret ;
}

fun type_destroy 1 {
  $type
  @type 0 param = ;
  type TYPE_ARGS take vector_destroy ;
  type free ;
}

const GLOBAL_TYPE 0
const SIZEOF_GLOBAL 4

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

const CCTX_TYPES 0
const CCTX_TYPENAMES 4
const CCTX_GLOBALS 8
const CCTX_TOKENS 12
const CCTX_TOKENS_POS 16
const SIZEOF_CCTX 20

fun cctx_init 1 {
  $tokens
  @tokens 0 param = ;

  $ctx
  @ctx SIZEOF_CCTX malloc = ;
  ctx CCTX_TYPES take_addr 4 vector_init = ;
  ctx CCTX_TYPENAMES take_addr map_init = ;
  ctx CCTX_GLOBALS take_addr map_init = ;
  ctx CCTX_TOKENS take_addr tokens = ;
  ctx CCTX_TOKENS_POS take_addr 0 = ;
  ctx ret ;
}

fun cctx_destroy 1 {
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

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  @i 0 = ;
  while i globals map_size < {
    if globals i map_has_idx {
      globals i map_at_idx global_destroy ;
    }
    @i i 1 + = ;
  }
  globals map_destroy ;

  ctx free ;
}

fun cctx_init_data 1 {
  $ctx
  @ctx 0 param = ;

  $types
  $typenames
  @types ctx CCTX_TYPES take = ;
  @typenames ctx CCTX_TYPENAMES take = ;

  $type
  $idx
  @idx 0 = ;

  # int
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_BASE = ;
  type TYPE_BASE take_addr idx = ;
  type TYPE_SIZE take_addr 4 = ;
  types type vector_push_back ;
  typenames "int" idx map_set ;

  @idx idx 1 + = ;

  # short
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_BASE = ;
  type TYPE_BASE take_addr idx = ;
  type TYPE_SIZE take_addr 2 = ;
  types type vector_push_back ;
  typenames "short" idx map_set ;

  @idx idx 1 + = ;

  # char
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_BASE = ;
  type TYPE_BASE take_addr idx = ;
  type TYPE_SIZE take_addr 1 = ;
  types type vector_push_back ;
  typenames "char" idx map_set ;

  @idx idx 1 + = ;

  # uint
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_BASE = ;
  type TYPE_BASE take_addr idx = ;
  type TYPE_SIZE take_addr 4 = ;
  types type vector_push_back ;
  typenames "uint" idx map_set ;

  @idx idx 1 + = ;

  # ushort
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_BASE = ;
  type TYPE_BASE take_addr idx = ;
  type TYPE_SIZE take_addr 2 = ;
  types type vector_push_back ;
  typenames "ushort" idx map_set ;

  @idx idx 1 + = ;

  # uchar
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_BASE = ;
  type TYPE_BASE take_addr idx = ;
  type TYPE_SIZE take_addr 1 = ;
  types type vector_push_back ;
  typenames "uchar" idx map_set ;

  @idx idx 1 + = ;
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
    if t1 TYPE_BASE take t2 TYPE_BASE take != { 0 ret ; }
    1 ret ;
  }
  if t1 TYPE_KIND take TYPE_KIND_FUNCTION == {
    if t1 TYPE_BASE take t2 TYPE_BASE take != { 0 ret ; }
    if t1 TYPE_LENGTH take t2 TYPE_LENGTH take != { 0 ret ; }
    $length
    @length t1 TYPE_LENGTH take = ;
    $args1
    $args2
    @args1 t1 TYPE_ARGS take = ;
    @args2 t2 TYPE_ARGS take = ;
    $i
    @i 0 = ;
    while i length < {
      if ctx args1 i vector_at args2 i vector_at cctx_type_compare ! { 0 ret ; }
      @i i 1 + = ;
    }
    1 ret ;
  }
  if t1 TYPE_KIND take TYPE_KIND_ARRAY == {
    if t1 TYPE_BASE take t2 TYPE_BASE take != { 0 ret ; }
    if t1 TYPE_LENGTH take t2 TYPE_LENGTH take != { 0 ret ; }
    1 ret ;
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
    tok ret ;
  }
}

fun cctx_give_back_token 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TOKENS_POS take 0 > "cctx_give_back_token: error 1" assert_msg ;
  ctx CCTX_TOKENS_POS take_addr ctx CCTX_TOKENS_POS take 1 - = ;
}

fun cctx_get_token_or_fail 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx cctx_get_token = ;
  tok 0 != "cctx_get_token_or_fail: unexpected end-of-file" assert_msg ;
  tok ret ;
}

fun cctx_parse_type 1 {
  $ctx
  @ctx 0 param = ;

  $tok
  @tok ctx cctx_get_token_or_fail = ;

  $typenames
  @typenames ctx CCTX_TYPENAMES take = ;
  if typenames tok map_has {
    $idx
    @idx typenames tok map_at = ;
    idx ret ;
  } else {
    0xffffffff ret ;
  }
}

fun cctx_parse_declarator 2 {
  $ctx
  $type_idx
  $ret_type_idx
  $ret_name
  @ctx 3 param = ;
  @type_idx 2 param = ;
  @ret_type_idx 1 param = ;
  @ret_name 0 param = ;

  $tok
  @tok ctx cctx_get_token_or_fail = ;
  ret_name tok = ;
  ret_type_idx type_idx = ;

  1 ret ;
}

fun cctx_compile 1 {
  $ctx
  @ctx 0 param = ;

  $i
  @i 0 = ;
  while ctx cctx_is_eof ! {
    $type_idx
    @type_idx ctx cctx_parse_type = ;
    type_idx 0xffffffff != "cctx_compile: type expected" assert_msg ;
    $cont
    @cont 1 = ;
    while cont {
      $actual_type_idx
      $name
      $res
      @res ctx type_idx @actual_type_idx @name cctx_parse_declarator = ;

      # Allocate the global variable
      

      $tok
      @tok ctx cctx_get_token_or_fail = ;
      if tok ";" strcmp 0 == {
        @cont 0 = ;
      } else {
        tok "," strcmp 0 == "cctx_compile: comma expected" assert_msg ;
      }
    }
  }
}

fun test 0 {
  $v
  @v 4 malloc = ;
  v 2 + 0x4c =c ;
  v free ;
}

fun parse_c 1 {
  # Preprocessing
  $ctx
  @ctx ppctx_init = ;
  $tokens
  @tokens 4 vector_init = ;
  tokens ctx 0 param preproc_file ;
  @tokens tokens remove_whites = ;
  "Finished preprocessing\n" 1 platform_log ;
  $i
  @i 0 = ;
  while i tokens vector_size < {
    $tok
    @tok tokens i vector_at = ;
    if tok **c '\n' == {
      "NL" 1 platform_log ;
    } else {
      tok 1 platform_log ;
    }
    "#" 1 platform_log ;
    @i i 1 + = ;
  }
  "\n" 1 platform_log ;

  # Compilation
  $cctx
  @cctx tokens cctx_init = ;
  cctx cctx_init_data ;
  cctx cctx_compile ;

  # Cleanup
  tokens free_vect_of_ptrs ;
  cctx cctx_destroy ;
  ctx ppctx_destroy ;
}
