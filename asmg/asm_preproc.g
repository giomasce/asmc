
fun get_char_type 1 {
  $x
  @x 0 param = ;
  if x '\n' == { 1 ret ; }
  if x '\t' == x ' ' == || { 2 ret ; }
  if x '0' >= x '9' <= && x 'a' >= x 'z' <= && || x 'A' >= x 'Z' <= && || x '_' == || { 3 ret ; }
  4 ret ;
}

const ASMCTX_FDIN 0
const ASMCTX_READ_CHAR 4
const ASMCTX_CHAR_GIVEN_BACK 8
const ASMCTX_SYMBOLS 12
const ASMCTX_STAGE 16
const ASMCTX_CURRENT_LOC 20
const ASMCTX_READ_TOKEN 24
const ASMCTX_TOKEN_GIVEN_BACK 38
const SIZEOF_ASMCTX 32

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

fun emit_size 3 {
  $ctx
  $data
  $size
  @ctx 2 param = ;
  @data 1 param = ;
  @size 0 param = ;

  if size 1 == {
    ctx data asmctx_emit ;
  } else {
    if size 2 == {
      ctx data asmctx_emit16 ;
    } else {
      if size 3 == {
        ctx data asmctx_emit32 ;
      } else {
        0 "emit_size: invalid size" assert_msg ;
      }
    }
  }
}

fun emit_multibyte 2 {
  $ctx
  $data
  @ctx 1 param = ;
  @data 0 param = ;

  if data 0xff & 1 == {
    ctx data 8 >> asmctx_emit ;
    ret ;
  }
  if data 0xff & 2 == {
    ctx data 8 >> asmctx_emit16 ;
    ret ;
  }
  if data 0xff & 3 == {
    ctx data 8 >> asmctx_emit ;
    ctx data 16 >> asmctx_emit16 ;
    ret ;
  }
  0 "emit_multibyte: error 1" assert_msg ;
}

fun emit_string 2 {
  $ctx
  $str
  @ctx 1 param = ;
  @str 0 param = ;

  str **c '\'' == "emit_string: argument is not a string" assert_msg ;
  @str str 1 + = ;
  while str **c '\'' != {
    ctx str **c asmctx_emit ;
    @str str 1 + = ;
  }
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
    if syms name map_has {
      syms name map_at ret ;
    } else {
      "Undefined symbol: " 1 platform_log ;
      name 1 platform_log ;
      "\n" 1 platform_log ;
      0 "asmctx_add_symbol: symbol undefined" assert_msg ;
    }
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
  ptr ASMCTX_TOKEN_GIVEN_BACK take_addr 0 = ;
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

fun asmctx_give_back_token 1 {
  $ctx
  @ctx 0 param = ;
  ctx ASMCTX_TOKEN_GIVEN_BACK take ! "Token already given back" assert_msg ;
  ctx ASMCTX_TOKEN_GIVEN_BACK take_addr 1 = ;
}

fun asmctx_get_token 1 {
  $ctx
  @ctx 0 param = ;

  if ctx ASMCTX_TOKEN_GIVEN_BACK take {
    ctx ASMCTX_TOKEN_GIVEN_BACK take_addr 0 = ;
    ctx ASMCTX_READ_TOKEN take ret ;
  }

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
  ctx ASMCTX_READ_TOKEN take_addr token_buf = ;
  token_buf ret ;
}
