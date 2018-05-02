
const MAX_TOKEN_LEN 128
%token_buf MAX_TOKEN_LEN
$token_len

$fd_in

fun is_whitespace 1 {
  $x
  &x 0 param = ;
  x '\n' == x '\t' == x ' ' == || || ret ;
}

fun get_token 0 {
  $state
  &state 0 = ;
  &token_len 0 = ;
  $cont
  &cont 1 = ;
  while cont {
    $c
    &c fd_in platform_read_char = ;
    &cont c 0xffffffff != = ;
    if cont {
      $save_char
      &save_char 0 = ;
      $ok
      &ok state 0 == = ;
      if ok {
        $isw
        &isw c is_whitespace = ;
        if isw {
          &ok token_len 0 > = ;
          if ok {
            &cont 0 = ;
          }
        } else {
          &save_char 1 = ;
        }
      }
      if save_char {
        token_buf token_len + c =c ;
        &token_len token_len 1 + = ;
      }
    }
  }
  token_buf token_len + 0 =c ;
  token_buf ret ;
}

fun parse_c 0 {
  $tok
  $cont
  &cont 1 = ;
  while cont {
    &tok get_token = ;
    &cont tok "" strcmp 0 != = ;
    if cont {
      "Token received: " 1 platform_log ;
      tok 1 platform_log ;
      "\n" 1 platform_log ;
    } else {
      "Parsing finished\n" 1 platform_log ;
    }
  }
}

fun main 0 {
  "Hello, G!\n" 1 platform_log ;
  &fd_in "test.c" platform_open_file = ;
  parse_c ;
}
