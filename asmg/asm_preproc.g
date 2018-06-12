
fun get_char_type 1 {
  $x
  @x 0 param = ;
  if x '\n' == { 1 ret ; }
  if x '\t' == x ' ' == || { 2 ret ; }
  if x '0' >= x '9' <= && x 'a' >= x 'z' <= && || x 'A' >= x 'Z' <= && || x '_' == || { 3 ret ; }
  4 ret ;
}

# 0 -> indirect (all fields set), 1 -> register (REG and SIZE set), 2 -> immediate (OFFSET set)
const OPERAND_TYPE 0
# 0 -> unknown, 1 -> 8 bits, 2 -> 16 bits, 3 -> 32 bits
const OPERAND_SIZE 4
const OPERAND_REG 8
const OPERAND_OFFSET 12
const OPERAND_SEGMENT 16
const OPERAND_SCALE 20
const OPERAND_INDEX_REG 24
const SIZEOF_OPERAND 28

const ASMCTX_FDIN 0
const ASMCTX_READ_CHAR 4
const ASMCTX_CHAR_GIVEN_BACK 8
const ASMCTX_SYMBOLS 12
const ASMCTX_STAGE 16
const ASMCTX_CURRENT_LOC 20
const SIZEOF_ASMCTX 24

fun asmctx_init 0 {
  $ptr
  @ptr SIZEOF_ASMCTX malloc = ;
  ptr ASMCTX_SYMBOLS take_addr map_init = ;
  ptr ret ;
}

fun asmctx_destroy 1 {
  $ptr
  @ptr 0 param = ;
  ptr ASMCTX_SYMBOLS take map_destroy ;
  ptr free ;
}

fun asmctx_emit 2 {
  $ctx
  $byte
  @ctx 1 param = ;
  @byte 0 param = ;

  if ctx ASMCTX_STAGE take 2 == {
    ctx ASMCTX_CURRENT_LOC take byte =c ;
  }
  ctx ASMCTX_CURRENT_LOC take_addr ctx ASMCTX_CURRENT_LOC take 1 + = ;
}

fun asmctx_emit16 2 {
  $ctx
  $word
  @ctx 1 param = ;
  @word 0 param = ;

  ctx word asmctx_emit ;
  ctx word 8 >> asmctx_emit ;
}

fun asmctx_emit32 2 {
  $ctx
  $dword
  @ctx 1 param = ;
  @dword 0 param = ;

  ctx dword asmctx_emit16 ;
  ctx dword 16 >> asmctx_emit16 ;
}

fun asmctx_add_symbol 3 {
  $ctx
  $name
  $value
  @ctx 2 param = ;
  @name 1 param = ;
  @value 0 param = ;

  $syms
  @syms ctx ASMCTX_SYMBOLS take = ;

  if ctx ASMCTX_STAGE take 1 == {
    syms name map_has ! "asmctx_add_symbol: symbol already defined" assert_msg ;
    syms name value map_set ;
  }
  if ctx ASMCTX_STAGE take 2 == {
    syms name map_has "asmctx_add_symbol: error 1" assert_msg ;
    syms name map_at value == "asmctx_add_symbol: error 2" assert_msg ;
  }
}

fun asmctx_get_symbol 2 {
  $ctx
  $name
  @ctx 1 param = ;
  @name 0 param = ;

  $syms
  @syms ctx ASMCTX_SYMBOLS take = ;

  if ctx ASMCTX_STAGE take 2 == {
    syms name map_has "asmctx_add_symbol: symbol undefined" assert_msg ;
    syms name map_at ret ;
  } else {
    0 ret ;
  }
}

fun asmctx_set_fd 2 {
  $ptr
  $fd
  @ptr 1 param = ;
  @fd 0 param = ;
  ptr ASMCTX_CHAR_GIVEN_BACK take_addr 0 = ;
  ptr ASMCTX_FDIN take_addr fd = ;
}

# fun asmctx_set_starting_loc 2 {
#   $ptr
#   $loc
#   @ptr 1 param = ;
#   @loc 0 param = ;
#   ptr ASMCTX_CURRENT_LOC take_addr loc = ;
# }

fun asmctx_give_back_char 1 {
  $ctx
  @ctx 0 param = ;
  ctx ASMCTX_CHAR_GIVEN_BACK take ! "Character already given back" assert_msg ;
  ctx ASMCTX_CHAR_GIVEN_BACK take_addr 1 = ;
}

fun asmctx_get_char 1 {
  $ctx
  @ctx 0 param = ;
  if ctx ASMCTX_CHAR_GIVEN_BACK take {
    ctx ASMCTX_CHAR_GIVEN_BACK take_addr 0 = ;
  } else {
    ctx ASMCTX_READ_CHAR take_addr ctx ASMCTX_FDIN take platform_read_char = ;
  }
  ctx ASMCTX_READ_CHAR take ret ;
}

fun asmctx_get_token 1 {
  $ctx
  @ctx 0 param = ;
  $token_buf
  $token_buf_len
  @token_buf_len 32 = ;
  @token_buf token_buf_len malloc = ;
  $state
  @state 0 = ;
  $token_type
  $token_len
  @token_len 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    $c
    @c ctx asmctx_get_char = ;
    @cont c 0xffffffff != = ;
    if cont {
      $save_char
      @save_char 0 = ;
      $type
      @type c get_char_type = ;
      $enter_state
      @enter_state state = ;
      # Normal code
      if enter_state 0 == {
        @save_char 1 = ;
      }
      # Comment
      if enter_state 1 == {
        if c '\n' == {
          token_buf '\n' =c ;
          @token_len 1 = ;
          @state 0 = ;
          @cont 0 = ;
        }
      }
      # String
      if enter_state 2 == {
        @save_char 1 = ;
        #if c '\\' == {
        #  @state 3 = ;
        #}
        if c '\'' == {
          @state 0 = ;
          @cont 0 = ;
        }
      }
      # String after backslash
      if enter_state 3 == {
        @save_char 1 = ;
        @state 2 = ;
      }
      token_buf token_len + c =c ;
      if save_char {
        if token_len 0 == {
          if type 2 != {
            @token_len token_len 1 + = ;
            @token_type type = ;
            if c '\'' == {
              @state 2 = ;
              @token_type 0 = ;
            }
            if c ';' == {
              @state 1 = ;
              @token_type 0 = ;
            }
            if token_type 1 == {
              @cont 0 = ;
            }
            if token_type 4 == {
              @cont 0 = ;
            }
          }
        } else {
          if token_type type == token_type 0 == || {
            @token_len token_len 1 + = ;
          } else {
            ctx asmctx_give_back_char ;
            @cont 0 = ;
          }
        }
      }
      if token_len 1 + token_buf_len >= {
        @token_buf_len token_buf_len 2 * = ;
        @token_buf token_buf_len token_buf realloc = ;
      }
    }
  }
  if token_type 2 == {
    token_buf ' ' =c ;
    @token_len 1 = ;
  }
  token_buf token_len + 0 =c ;
  token_buf ret ;
}

fun asmctx_parse_operand 1 {
  $ctx
  @ctx 0 param = ;
  $op
  @op SIZEOF_OPERAND malloc = ;

  $tok
  @tok ctx asmctx_get_token = ;

  # Find the size prefix
  op OPERAND_SIZE take_addr 0 = ;
  if tok "byte" strcmp 0 == {
    op OPERAND_SIZE take_addr 1 = ;
  } else {
    if tok "word" strcmp 0 == {
      op OPERAND_SIZE take_addr 2 = ;
    } else {
      if tok "dword" strcmp 0 == {
        op OPERAND_SIZE take_addr 3 = ;
      }
    }
  }
  if op OPERAND_SIZE take 0 != {
    @tok ctx asmctx_get_token = ;
  }

  # Is it direct or indirect?
  if tok **c '[' == {
    op OPERAND_TYPE take_addr 0 = ;
    
  } else {
    op OPERAND_SIZE take 0 == "Cannot specify the size of a direct operand" assert_msg ;
    $reg
    @reg tok parse_register = ;
    if reg 0xffffffff != {
      op OPERAND_TYPE take_addr 1 = ;
      op OPERAND_REG take_addr reg 0x0f & = ;
      op OPERAND_SIZE take_addr reg 4 >> = ;
    } else {
      op OPERAND_TYPE take_addr 2 = ;
      $syms
      @syms ctx ASMCTX_SYMBOLS take = ;
      if syms tok map_has {
        op OPERAND_OFFSET take_addr syms tok map_at = ;
      } else {
        $endptr
        op OPERAND_OFFSET take_addr tok @endptr 0 strtol = ;
        endptr **c 0 == "asmctx_parse_operand: illegal direct operand" assert_msg ;
      }
    }
  }

  op ret ;
}

fun asmctx_parse_line 1 {
  $ctx
  @ctx 0 param = ;
  $tok
  @tok ctx asmctx_get_token = ;
  while tok "\n" strcmp 0 == {
    tok free ;
    @tok ctx asmctx_get_token = ;
  }
  if tok "" strcmp 0 == {
    tok free ;
    0 ret ;
  }
  $opcode_map
  @opcode_map get_opcode_map = ;
  if opcode_map tok map_has {
    $opcode
    @opcode opcode_map tok map_at = ;
    $i
    @i 0 = ;
    $op
    while i opcode OPCODE_ARG_NUM take 1 - < {
      tok free ;
      @op ctx asmctx_parse_operand = ;
      
      op free ;
      @tok ctx asmctx_get_token = ;
      tok "," strcmp 0 == "parse_asm_line: expected comma" assert_msg ;
      tok free ;
      @i i 1 + = ;
    }
    @op ctx asmctx_parse_operand = ;
    
    op free ;
  } else {
    $label
    @label tok = ;
    @tok ctx asmctx_get_token = ;
    tok ":" strcmp 0 == "parse_asm_line: wrong syntax after label" assert_msg ;
    tok free ;
    ctx label ctx ASMCTX_CURRENT_LOC take asmctx_add_symbol ;
    label free ;
  }
  @tok ctx asmctx_get_token = ;
  tok "\n" strcmp 0 == "parse_asm_line: expected line terminator" assert_msg ;
  tok free ;
  1 ret ;
}

fun asmctx_compile 1 {
  $ctx
  @ctx 0 param = ;

  ctx ASMCTX_STAGE take_addr 0 = ;
  $start_loc
  @start_loc 0 = ;
  $size
  while ctx ASMCTX_STAGE take 3 < {
    ctx ASMCTX_FDIN take platform_reset_file ;
    ctx ASMCTX_CURRENT_LOC take_addr start_loc = ;
    $cont
    @cont 1 = ;
    while cont {
      @cont ctx asmctx_parse_line = ;
    }
    if ctx ASMCTX_STAGE take 0 == {
      @size ctx ASMCTX_CURRENT_LOC take start_loc - = ;
      @start_loc size malloc = ;
    } else {
      ctx ASMCTX_CURRENT_LOC take start_loc - size == "asmctx_compile: error 1" assert_msg ;
    }
    ctx ASMCTX_STAGE take_addr ctx ASMCTX_STAGE take 1 + = ;
  }
  "Assembled program has size " 1 platform_log ;
  size itoa 1 platform_log ;
  " and starts at " 1 platform_log ;
  start_loc itoa 1 platform_log ;
  "\n" 1 platform_log ;
}

fun parse_asm 1 {
  $filename
  @filename 0 param = ;
  $ctx
  @ctx asmctx_init = ;
  $cont
  @cont 1 = ;
  ctx filename platform_open_file asmctx_set_fd ;
  ctx asmctx_compile ;
  #while cont {
    #$tok
    #@tok ctx asmctx_get_token = ;
    #@cont tok **c 0 != = ;
    #if tok **c '\n' == {
    #  "NL" 1 platform_log ;
    #} else {
    #  tok 1 platform_log ;
    #}
    #"#" 1 platform_log ;
    #tok free ;
    @cont ctx asmctx_parse_line = ;
  #}
  #"\n" 1 platform_log ;
  ctx asmctx_destroy ;
}
