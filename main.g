
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

# Malloc
# Based on https://github.com/andrestc/linux-prog/blob/master/ch7/malloc.c
$head

fun take_size 1 {
  0 param ** ret ;
}

fun take_size_addr 1 {
  0 param ret ;
}

fun take_next 1 {
  0 param 4 + ** ret ;
}

fun take_next_addr 1 {
  0 param 4 + ret ;
}

fun take_prev 1 {
  0 param 8 + ** ret ;
}

fun take_prev_addr 1 {
  0 param 8 + ret ;
}

fun fl_remove 1 {
  $b
  @b 0 param = ;
  if b take_prev ! {
    if b take_next {
      @head b take_next = ;
    } else {
      @head 0 = ;
    }
  } else {
    b take_prev take_next_addr b take_next = ;
  }
  if b take_next {
    b take_next take_prev_addr b take_prev = ;
  }
}

fun fl_add 1 {
  $b
  @b 0 param = ;
  b take_next_addr 0 = ;
  b take_prev_addr 0 = ;
  if head ! head b > || {
    if head {
      head take_prev_addr b = ;
    }
    b take_next_addr head = ;
    @head b = ;
  } else {
    $curr
    @curr head = ;
    $cond
    @cond curr take_next = ;
    if cond {
      @cond curr take_next b < = ;
    }
    while cond {
      @curr curr take_next = ;
      @cond curr take_next = ;
      if cond {
        @cond curr take_next b < = ;
      }
    }
    b take_next_addr curr take_next = ;
    curr take_next_addr b = ;
  }
}

fun get_char_type 1 {
  $x
  @x 0 param = ;
  if x '\n' == { 1 ret ; }
  if x '\t' == x ' ' == || { 2 ret ; }
  if x '0' >= x '9' <= && x 'a' >= x 'z' <= && || x 'A' >= x 'Z' <= && || x '_' == || { 3 ret ; }
  4 ret ;
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

fun is_line_escape 1 {
  $first
  $second
  @first 0 param **c = ;
  @second 0 param 1 + **c = ;
  if first '\\' == second '\n' == && { 1 ret ; }
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
      @type c get_char_type = ;
      $enter_state
      @enter_state state = ;
      # Normal code
      if enter_state 0 == {
        @save_char 1 = ;
      }
      # C++ style comment
      if enter_state 1 == {
        if c '\n' == {
          token_buf ' ' =c ;
          @token_len 1 = ;
          @state 0 = ;
          @cont 0 = ;
          give_back_char ;
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
          token_buf ' ' =c ;
          @token_len 1 = ;
          @state 0 = ;
          @cont 0 = ;
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
            @token_type 0 = ;
          }
          if c '\'' == {
            @state 6 = ;
            @token_type 0 = ;
          }
          if c '\n' == {
            @cont 0 = ;
          }
        } else {
          if token_buf is_line_escape {
             @token_len 0 = ;
          } else {
            if token_type type == token_type 0 == || {
              @token_len token_len 1 + = ;
              if token_type 4 == {
                $done
                @done 0 = ;
                if token_buf is_c_comment {
                  @state 2 = ;
                  @done 1 = ;
                }
                if token_buf is_cpp_comment {
                  @state 1 = ;
                  @done 1 = ;
                }
                if token_buf is_valid_2_char_token {
                  @token_len token_len 1 + = ;
                  @cont 0 = ;
                  @done 1 = ;
                }
                if done ! {
                  give_back_char ;
                  @token_len 1 = ;
                  @cont 0 = ;
                }
              }
            } else {
              give_back_char ;
              @cont 0 = ;
            }
          }
        }
      }
      1 token_len + MAX_TOKEN_LEN <= assert ;
    }
  }
  if token_type 2 == {
    token_buf ' ' =c ;
    @token_len 1 = ;
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
      if tok **c '\n' == {
        "NL" 1 platform_log ;
      } else {
        tok 1 platform_log ;
      }
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
