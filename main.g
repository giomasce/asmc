
const MAX_TOKEN_LEN 128
%token_buf MAX_TOKEN_LEN
$token_len

$fd_in
$read_char
$char_given_back

fun assert 1 {
  if 0 param ! {
    platform_panic ;
  }
}

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

fun is_valid_2_char_token 1 {
  $first
  $second
  @first 0 param **c = ;
  @second 0 param 1 + **c = ;
  if first '=' == second '=' == && { 1 ret ; }
  if first '!' == second '=' == && { 1 ret ; }
  if first '<' == second '=' == && { 1 ret ; }
  if first '>' == second '=' == && { 1 ret ; }
  if first '<' == second '<' == && { 1 ret ; }
  if first '>' == second '>' == && { 1 ret ; }
  if first '&' == second '&' == && { 1 ret ; }
  if first '|' == second '|' == && { 1 ret ; }
  0 ret ;
}

fun is_c_comment 1 {
  $first
  $second
  @first 0 param **c = ;
  @second 0 param 1 + **c = ;
  if first '/' == second '*' == && { 1 ret ; }
  0 ret ;
}

fun is_cpp_comment 1 {
  $first
  $second
  @first 0 param **c = ;
  @second 0 param 1 + **c = ;
  if first '/' == second '/' == && { 1 ret ; }
  0 ret ;
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
      $enter_state
      @enter_state state = ;
      # Normal code
      if enter_state 0 == {
        if c is_whitespace {
          if token_len 0 > {
            @cont 0 = ;
          }
        } else {
          @save_char 1 = ;
        }
      }
      # C++ style comment
      if enter_state 1 == {
        if c '\n' == {
          @state 0 = ;
          if token_len 0 > {
            @cont 0 = ;
          }
        }
      }
      # C style comment
      if enter_state 2 == {
        if c '*' == {
          @state 3 = ;
        }
      }
      # C style comment after star
      if enter_state 3 == {
        if c '/' == {
          @state 0 = ;
          if token_len 0 > {
            @cont 0 = ;
          }
        }
        if c '*' != {
          @state 2 = ;
        }
      }
      # String
      if enter_state 4 == {
        @save_char 1 = ;
        if c '\\' == {
          @state 5 = ;
        }
        if c '"' == {
          @state 0 = ;
          @cont 0 = ;
        }
      }
      # String after backslash
      if enter_state 5 == {
        @save_char 1 = ;
        @state 4 = ;
      }
      # Character
      if enter_state 6 == {
        @save_char 1 = ;
        if c '\\' == {
           @state 7 = ;
        }
        if c '\'' == {
          @state 0 = ;
          @cont 0 = ;
        }
      }
      # Character after backslash
      if enter_state 7 == {
        @save_char 1 = ;
        @state 6 = ;
      }
      token_buf token_len + c =c ;
      if save_char {
        if token_len 0 == {
          @token_len token_len 1 + = ;
          @token_type type = ;
          if c '"' == {
            @state 4 = ;
            @token_type 2 = ;
          }
          if c '\'' == {
            @state 6 = ;
            @token_type 2 = ;
          }
        } else {
          if token_type type == token_type 2 == || {
            if token_type 1 == token_type 2 == || {
              @token_len token_len 1 + = ;
            } else {
              if token_buf is_c_comment {
                @token_len 0 = ;
                @state 2 = ;
              }
              if token_buf is_cpp_comment {
                @token_len 0 = ;
                @state 1 = ;
              }
              if token_buf is_valid_2_char_token {
                @token_len token_len 1 + = ;
              } else {
                give_back_char ;
              }
              @cont 0 = ;
            }
          } else {
            give_back_char ;
            @cont 0 = ;
          }
        }
      }
      1 token_len + MAX_TOKEN_LEN <= assert ;
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
