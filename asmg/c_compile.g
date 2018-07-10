
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

const CCTX_TYPES 0
const CCTX_TYPENAMES 4
const CCTX_GLOBALS 8
const CCTX_TOKENS 12
const CCTX_TOKENS_POS 16
const CCTX_STAGE 20
const CCTX_CURRENT_LOC 24
const SIZEOF_CCTX 28

fun cctx_init_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx CCTX_TYPES take_addr 4 vector_init = ;
  ctx CCTX_TYPENAMES take_addr map_init = ;
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
}

fun cctx_destroy 1 {
  $ctx
  @ctx 0 param = ;

  ctx cctx_destroy_types ;

  $globals
  @globals ctx CCTX_GLOBALS take = ;
  $i
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

fun cctx_reset_types 1 {
  $ctx
  @ctx 0 param = ;

  ctx cctx_destroy_types ;
  ctx cctx_init_types ;
}

fun is_valid_identifier 1 {
  $ident
  @ident 0 param = ;

  #"is_valid_identifier for " 1 platform_log ;
  #ident 1 platform_log ;
  #"\n" 1 platform_log ;

  $len
  @len ident strlen = ;
  if len 0 == { 0 ret ; }
  $i
  @i 0 = ;
  while i len < {
    if ident i + **c get_char_type 3 != { 0 ret ; }
    @i i 1 + = ;
  }
  $first
  @first ident **c = ;
  if first '0' >= first '9' <= && { 0 ret ; }
  #"is_valid_identifier: return true\n" 1 platform_log ;
  1 ret ;
}

fun cctx_create_basic_types 1 {
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

fun cctx_add_type 2 {
  $ctx
  $type
  @ctx 1 param = ;
  @type 0 param = ;

  $types
  $idx
  @types ctx CCTX_TYPES take = ;
  @idx types vector_size = ;
  types type vector_push_back ;
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

fun cctx_get_function_type 3 {
  $ctx
  $type_idx
  $args
  @ctx 2 param = ;
  @type_idx 1 param = ;
  @args 0 param = ;

  $type
  @type type_init = ;
  type TYPE_KIND take_addr TYPE_KIND_FUNCTION = ;
  type TYPE_BASE take_addr type_idx = ;
  type TYPE_SIZE take_addr 0xffffffff = ;
  type TYPE_ARGS take vector_destroy ;
  type TYPE_ARGS take_addr args = ;

  ctx type cctx_add_type ret ;
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

  if ctx CCTX_STAGE take 0 == {
    globals name map_has ! "cctx_add_global: name already defined" assert_msg ;
    $global
    @global global_init = ;
    global GLOBAL_TYPE_IDX take_addr type_idx = ;
    global GLOBAL_LOC take_addr loc = ;
    globals name global map_set ;
  }
  if ctx CCTX_STAGE take 1 == {
    globals name map_has "cctx_add_global: error 1" assert_msg ;
    $global
    @global globals name map_at = ;
    global GLOBAL_TYPE_IDX take type_idx == "cctx_add_global: error 2" assert_msg ;
    #global GLOBAL_LOC take loc == "cctx_add_global: error 3" assert_msg ;
  }
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

fun cctx_emit 2 {
  $ctx
  $byte
  @ctx 1 param = ;
  @byte 0 param = ;

  if ctx CCTX_STAGE take 1 == {
    ctx CCTX_CURRENT_LOC take byte =c ;
  }
  ctx CCTX_CURRENT_LOC take_addr ctx CCTX_CURRENT_LOC take 1 + = ;
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
    ctx cctx_give_back_token ;
    0xffffffff ret ;
  }
}

ifun cctx_parse_declarator 4

fun _cctx_parse_function_arguments 1 {
  $ctx
  @ctx 0 param = ;

  $args
  @args 4 vector_init = ;
  while 1 {
    $type_idx
    @type_idx ctx cctx_parse_type = ;
    if type_idx 0xffffffff == {
      $tok
      @tok ctx cctx_get_token_or_fail = ;
      tok ")" strcmp 0 == "_cctx_parse_function_arguments: ) or type expected" assert_msg ;
      args vector_size 0 == "_cctx_parse_function_arguments: unexpected )" assert_msg ;
      args ret ;
    }
    $name
    $actual_type_idx
    if ctx type_idx @actual_type_idx @name cctx_parse_declarator ! {
      @actual_type_idx type_idx = ;
    }
    args actual_type_idx vector_push_back ;
    $tok
    @tok ctx cctx_get_token_or_fail = ;
    if tok ")" strcmp 0 == {
      args ret ;
    }
    tok "," strcmp 0 == "_cctx_parse_function_arguments: ) or , expected" assert_msg ;
  }
}

fun _cctx_parse_declarator 4 {
  $ctx
  $type_idx
  $ret_type_idx
  $ret_name
  @ctx 3 param = ;
  @type_idx 2 param = ;
  @ret_type_idx 1 param = ;
  @ret_name 0 param = ;

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
    if ctx type_idx ret_type_idx ret_name _cctx_parse_declarator ! {
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
      @args ctx _cctx_parse_function_arguments = ;
      if ctx type_idx ret_type_idx ret_name _cctx_parse_declarator {
        @type_idx ret_type_idx ** = ;
      }
      ret_type_idx ctx type_idx args cctx_get_function_type = ;
    } else {
      # Grouping parenthesis
      $inside_pos
      $outside_pos
      $end_pos
      @inside_pos ctx cctx_save_token_pos = ;
      ctx "(" ")" cctx_go_to_matching ;
      @outside_pos ctx cctx_save_token_pos = ;
      if ctx type_idx ret_type_idx ret_name _cctx_parse_declarator {
        @type_idx ret_type_idx ** = ;
      }
      @end_pos ctx cctx_save_token_pos = ;
      ctx inside_pos cctx_restore_token_pos ;
      ctx type_idx ret_type_idx ret_name _cctx_parse_declarator "_cctx_parse_declarator: invalid syntax 1" assert_msg ;
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
      # FIXME Implement proper formula parsing
      @length tok atoi = ;
      @tok ctx cctx_get_token_or_fail = ;
    }
    tok "]" strcmp 0 == "_cctx_parse_declarator: expected ] after array subscript" assert_msg ;
    if ctx type_idx ret_type_idx ret_name _cctx_parse_declarator {
      @type_idx ret_type_idx ** = ;
    }
    ret_type_idx ctx type_idx length cctx_get_array_type = ;
    @processed 1 = ;
  }

  # Parse the actual declarator identifier
  if tok is_valid_identifier {
    if ctx type_idx ret_type_idx ret_name _cctx_parse_declarator ! {
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

fun cctx_parse_declarator 4 {
  $ctx
  $type_idx
  $ret_type_idx
  $ret_name
  @ctx 3 param = ;
  @type_idx 2 param = ;
  @ret_type_idx 1 param = ;
  @ret_name 0 param = ;

  ret_name 0 = ;
  ctx type_idx ret_type_idx ret_name _cctx_parse_declarator ret ;
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

fun cctx_compile_line 1 {
  $ctx
  @ctx 0 param = ;

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

    # Register and allocate the global variable
    name 0 != "cctx_compile_line: cannot instantiate variable without name" assert_msg ;
    ctx name ctx CCTX_CURRENT_LOC take actual_type_idx cctx_add_global ;
    ctx ctx actual_type_idx cctx_type_footprint cctx_emit_zeros ;

    $tok
    @tok ctx cctx_get_token_or_fail = ;
    if tok ";" strcmp 0 == {
      @cont 0 = ;
    } else {
      tok "," strcmp 0 == "cctx_compile: comma expected" assert_msg ;
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
  while ctx CCTX_STAGE take 2 < {
    "Compilation stage " 1 platform_log ;
    ctx CCTX_STAGE take 1 + itoa 1 platform_log ;
    ctx CCTX_CURRENT_LOC take_addr start_loc = ;
    ctx CCTX_TOKENS_POS take_addr 0 = ;
    ctx cctx_reset_types ;
    ctx cctx_create_basic_types ;
    while ctx cctx_is_eof ! {
      ctx cctx_compile_line ;
    }
    "\n" 1 platform_log ;
    if ctx CCTX_STAGE take 0 == {
      @size ctx CCTX_CURRENT_LOC take start_loc - = ;
      @start_loc size platform_allocate = ;
    } else {
      ctx CCTX_CURRENT_LOC take start_loc - size == "cctx_compile: error 1" assert_msg ;
    }
    ctx CCTX_STAGE take_addr ctx CCTX_STAGE take 1 + = ;
  }
  "Compiled program has size " 1 platform_log ;
  size itoa 1 platform_log ;
  " and starts at " 1 platform_log ;
  start_loc itoa 1 platform_log ;
  "\n" 1 platform_log ;
  "Compiled dump:\n" 1 platform_log ;
  start_loc size dump_mem ;
  "\n" 1 platform_log ;
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
  cctx cctx_compile ;

  # Cleanup
  tokens free_vect_of_ptrs ;
  cctx cctx_destroy ;
  ctx ppctx_destroy ;
}
