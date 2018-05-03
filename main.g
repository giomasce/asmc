
const MAX_TOKEN_LEN 128
%token_buf MAX_TOKEN_LEN
$token_len

$fd_in
$read_char
$char_given_back

fun is_whitespace 1 {
  $x
  @x 0 param = ;
  x '\n' == x '\t' == x ' ' == || || ret ;
}

fun is_id_char 1 {
  $x
  @x 0 param = ;
  x '0' >= x '9' <= && x 'a' >= x 'z' <= && || x 'A' >= x 'Z' <= && || x '_' == || ret ;
}

fun give_back_char 0 {
  @char_given_back 1 = ;
}

fun get_char 0 {
  if char_given_back {
    @char_given_back 0 = ;
  } else {
    @read_char fd_in platform_read_char = ;
  }
  read_char ret
}

fun get_token 0 {
  $state
  @state 0 = ;
  $token_type
  @token_len 0 = ;
  $cont
  @cont 1 = ;
  while cont {
    $c
    @c get_char = ;
    @cont c 0xffffffff != = ;
    if cont {
      $save_char
      @save_char 0 = ;
      $type
      @type c is_id_char = ;
      if state 0 == {
        if c is_whitespace {
          if token_len 0 > {
            @cont 0 = ;
          }
        } else {
          @save_char 1 = ;
        }
      }
      if save_char {
        if token_len 0 == {
          token_buf token_len + c =c ;
          @token_len token_len 1 + = ;
          @token_type type = ;
        } else {
          if token_type type == {
            token_buf token_len + c =c ;
            @token_len token_len 1 + = ;
          } else {
            give_back_char ;
            @cont 0 = ;
          }
        }
      }
    }
  }
  token_buf token_len + 0 =c ;
  token_buf ret ;
}

fun parse_c 0 {
  $tok
  $cont
  @cont 1 = ;
  while cont {
    @tok get_token = ;
    @cont tok "" strcmp 0 != = ;
    if cont {
      tok 1 platform_log ;
      "#" 1 platform_log ;
    } else {
      "\nParsing finished\n" 1 platform_log ;
    }
  }
}

fun main 0 {
  "Hello, G!\n" 1 platform_log ;
  @fd_in "test.c" platform_open_file = ;
  parse_c ;
}
