
$fd_in
$read_char
$char_given_back

const SUBST_IS_FUNCTION 0   # bool
const SUBST_PARAMETERS 4    # vector of char*
const SUBST_REPLACEMENT 8   # vector of char*
const SIZEOF_SUBST 12

fun subst_init 0 {
  $ptr
  @ptr SIZEOF_SUBST malloc = ;
  ptr SUBST_IS_FUNCTION take_addr 0 = ;
  ptr SUBST_PARAMETERS take_addr 4 vector_init = ;
  ptr SUBST_REPLACEMENT take_addr 4 vector_init = ;
  ptr ret ;
}

fun subst_destroy 1 {
  $ptr
  @ptr 0 param = ;
  ptr SUBST_PARAMETERS take free_vect_of_ptrs ;
  ptr SUBST_REPLACEMENT take free_vect_of_ptrs ;
  ptr free ;
}

const PPCTX_DEFINES 0
const SIZEOF_PPCTX 4

fun ppctx_init 0 {
  $ptr
  @ptr SIZEOF_PPCTX malloc = ;
  ptr PPCTX_DEFINES take_addr map_init = ;
  ptr ret ;
}

fun ppctx_destroy 1 {
  $ptr
  @ptr 0 param = ;
  $defs
  @defs ptr PPCTX_DEFINES take = ;
  $i
  @i 0 = ;
  while i defs map_size < {
    if defs i map_has_idx {
      defs i map_at_idx subst_destroy ;
    }
    @i i 1 + = ;
  }
  defs free ;
  ptr free ;
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
  if first '+' == second '+' == && { 1 ret ; }
  if first '-' == second '-' == && { 1 ret ; }
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

fun tokenize_file 1 {
  @fd_in 0 param platform_open_file = ;
  $tok
  $cont
  @cont 1 = ;
  $token_vect
  @token_vect 4 vector_init = ;
  while cont {
    @tok get_token = ;
    @cont tok "" strcmp 0 != = ;
    if cont {
      token_vect tok vector_push_back ;
    }
  }
  token_vect ret ;
}

fun discard_white_tokens 2 {
  $tokens
  $iptr
  @iptr 0 param = ;
  @tokens 1 param = ;
  $cont
  @cont 1 = ;
  while cont {
    iptr iptr ** 1 + = ;
    iptr ** tokens vector_size < "discard_white_token: stream end was found" assert_msg ;
    @cont tokens iptr ** vector_at " " strcmp 0 == = ;
  }
}

fun process_token 4 {
  $ctx
  $tokens
  $intoks
  $iptr
  @iptr 0 param = ;
  @intoks 1 param = ;
  @tokens 2 param = ;
  @ctx 3 param = ;
  $tok
  @tok intoks iptr ** vector_at = ;

  # Search the token in the context defines
  $changed
  @changed 0 = ;
  if ctx PPCTX_DEFINES take tok map_has {
    @changed 1 = ;
    #"Expanding: " 1 platform_log ;
    #tok 1 platform_log ;
    #"\n" 1 platform_log ;
    $subst
    @subst ctx PPCTX_DEFINES take tok map_at = ;
    $repl
    @repl subst SUBST_REPLACEMENT take = ;
    if subst SUBST_IS_FUNCTION take {
      # TODO
      0 "Not implemented yet" assert_msg ;
    } else {
      $j
      @j 0 = ;
      while j repl vector_size < {
        tokens repl j vector_at strdup vector_push_back ;
        @j j 1 + = ;
      }
    }
  } else {
    tokens tok strdup vector_push_back ;
  }
  changed ret ;
}

fun preproc_replace_int 3 {
  $ctx
  $intoks
  $outtoks
  @ctx 2 param = ;
  @intoks 1 param = ;
  @outtoks 0 param = ;

  $changed
  @changed 0 = ;
  $i
  @i 0 = ;
  while i intoks vector_size < {
    @changed changed ctx outtoks intoks @i process_token || = ;
    @i i 1 + = ;
  }

  changed ret ;
}

fun preproc_replace 2 {
  $ctx
  $intoks
  @ctx 1 param = ;
  @intoks 0 param = ;

  $changed
  @changed 1 = ;
  @intoks intoks dup_vect_of_ptrs = ;
  while changed {
    $outtoks
    @outtoks 4 vector_init = ;
    @changed ctx intoks outtoks preproc_replace_int = ;
    intoks free_vect_of_ptrs ;
    @intoks outtoks = ;
  }

  intoks ret ;
}

fun preproc_expand 3 {
  $ctx
  $intoks
  $outtoks
  @ctx 2 param = ;
  @intoks 1 param = ;
  @outtoks 0 param = ;
  $replaced
  @replaced ctx intoks preproc_replace = ;
  $i
  @i 0 = ;
  while i replaced vector_size < {
    outtoks replaced i vector_at vector_push_back ;
    @i i 1 + = ;
  }
  replaced vector_destroy ;
}

fun preproc_process_define 4 {
  $ctx
  $tokens
  $intoks
  $iptr
  @ctx 3 param = ;
  @tokens 2 param = ;
  @intoks 1 param = ;
  @iptr 0 param = ;

  intoks iptr discard_white_tokens ;

  $ident
  @ident intoks iptr ** vector_at = ;
  ident "\n" strcmp 0 != "preproc_process_define: newline found" assert_msg ;
  iptr iptr ** 1 + = ;
  iptr ** intoks vector_size < "preproc_process_define: end of stream found" assert_msg ;

  $tok
  @tok intoks iptr ** vector_at = ;
  $is_func
  @is_func tok "(" strcmp 0 == = ;

  $subst
  @subst subst_init = ;
  subst SUBST_IS_FUNCTION take_addr is_func = ;
  subst SUBST_PARAMETERS take_addr 4 vector_init = ;
  subst SUBST_REPLACEMENT take_addr 4 vector_init = ;
  if is_func {
    # TODO
    0 assert ;
  } else {
    while tok "\n" strcmp 0 != {
      subst SUBST_REPLACEMENT take tok strdup vector_push_back ;
      iptr iptr ** 1 + = ;
      iptr ** intoks vector_size < "preproc_process_define: end of stream found" assert_msg ;
      @tok intoks iptr ** vector_at = ;
    }
  }

  if ctx PPCTX_DEFINES take ident map_has {
    $subst
    @subst ctx PPCTX_DEFINES take tok map_at = ;
    subst subst_destroy ;
    ctx PPCTX_DEFINES take tok map_erase ;
  }
  ctx PPCTX_DEFINES take ident subst map_set ;
}

fun preproc_process_undef 4 {
  $ctx
  $tokens
  $intoks
  $iptr
  @ctx 3 param = ;
  @tokens 2 param = ;
  @intoks 1 param = ;
  @iptr 0 param = ;

  intoks iptr discard_white_tokens ;

  $tok
  @tok intoks iptr ** vector_at = ;

  # If this definition is known, erase it
  if ctx PPCTX_DEFINES take tok map_has {
    $subst
    @subst ctx PPCTX_DEFINES take tok map_at = ;
    subst subst_destroy ;
    ctx PPCTX_DEFINES take tok map_erase ;
  }

  intoks iptr discard_white_tokens ;
}

ifun preproc_file 3

fun preproc_process_include 4 {
  $ctx
  $tokens
  $intoks
  $iptr
  @ctx 3 param = ;
  @tokens 2 param = ;
  @intoks 1 param = ;
  @iptr 0 param = ;

  intoks iptr discard_white_tokens ;

  $tok
  @tok intoks iptr ** vector_at = ;
  $filename
  @filename "" strdup = ;
  if tok "<" strcmp 0 == {
    iptr iptr ** 1 + = ;
    @tok intoks iptr ** vector_at = ;
    while tok ">" strcmp 0 != {
      @filename filename tok append_to_str = ;
      iptr iptr ** 1 + = ;
      @tok intoks iptr ** vector_at = ;
    }
  } else {
    tok **c '"' == "preproc_process_include: syntax error in inclusion directive" assert_msg ;
    filename free ;
    @filename tok 1 + strdup = ;
    filename filename strlen 1 - + '\0' =c ;
  }
  "Including file " 1 platform_log ;
  filename 1 platform_log ;
  "\n" 1 platform_log ;
  tokens ctx filename preproc_file ;
  filename free ;

  intoks iptr discard_white_tokens ;
}

fun preproc_eval 2 {
  $ctx
  $ast
  @ctx 1 param = ;
  @ast 0 param = ;

  $defs
  @defs ctx PPCTX_DEFINES take = ;
  $name
  @name ast AST_NAME take = ;

  if ast AST_TYPE take 0 == {
    # Operand
    if defs name map_has {
      # TODO
    } else {
      0 ret ;
    }
  } else {
    # Operator
    ast AST_TYPE take 1 == assert ;
    # TODO
  }
}

fun preproc_process_endif 5 {
  $ctx
  $tokens
  $intoks
  $iptr
  $if_stack
  @ctx 4 param = ;
  @tokens 3 param = ;
  @intoks 2 param = ;
  @iptr 1 param = ;
  @if_stack 0 param = ;

  if_stack vector_size 1 > "preproc_process_endif: unmatched endif" assert_msg ;
  if_stack vector_pop_back ;

  intoks iptr discard_white_tokens ;
}

fun preproc_process_else 5 {
  $ctx
  $tokens
  $intoks
  $iptr
  $if_stack
  @ctx 4 param = ;
  @tokens 3 param = ;
  @intoks 2 param = ;
  @iptr 1 param = ;
  @if_stack 0 param = ;

  $state
  if_stack vector_size 1 > "preproc_process_endif: unmatched else" assert_msg ;
  @state if_stack vector_pop_back = ;
  @state state 1 + = ;
  if state 2 > {
    @state 2 = ;
  }
  if_stack state vector_push_back ;

  intoks iptr discard_white_tokens ;
}

fun preproc_process_ifdef 5 {
  $ctx
  $tokens
  $intoks
  $iptr
  $if_stack
  @ctx 4 param = ;
  @tokens 3 param = ;
  @intoks 2 param = ;
  @iptr 1 param = ;
  @if_stack 0 param = ;

  intoks iptr discard_white_tokens ;

  $ident
  @ident intoks iptr ** vector_at = ;
  ident "\n" strcmp 0 != "preproc_process_ifdef: newline found" assert_msg ;

  if ctx PPCTX_DEFINES take ident map_has {
    if_stack 1 vector_push_back ;
  } else {
    if_stack 0 vector_push_back ;
  }

  intoks iptr discard_white_tokens ;
}

fun preproc_process_ifndef 5 {
  $ctx
  $tokens
  $intoks
  $iptr
  $if_stack
  @ctx 4 param = ;
  @tokens 3 param = ;
  @intoks 2 param = ;
  @iptr 1 param = ;
  @if_stack 0 param = ;

  intoks iptr discard_white_tokens ;

  $ident
  @ident intoks iptr ** vector_at = ;
  ident "\n" strcmp 0 != "preproc_process_ifndef: newline found" assert_msg ;

  if ctx PPCTX_DEFINES take ident map_has {
    if_stack 0 vector_push_back ;
  } else {
    if_stack 1 vector_push_back ;
  }

  intoks iptr discard_white_tokens ;
}

fun preproc_process_elif 5 {
  $ctx
  $tokens
  $intoks
  $iptr
  $if_stack
  @ctx 4 param = ;
  @tokens 3 param = ;
  @intoks 2 param = ;
  @iptr 1 param = ;
  @if_stack 0 param = ;

  0 "preproc_process_elif: not implemented" assert_msg ;
}

fun preproc_process_if 5 {
  $ctx
  $tokens
  $intoks
  $iptr
  $if_stack
  @ctx 4 param = ;
  @tokens 3 param = ;
  @intoks 2 param = ;
  @iptr 1 param = ;
  @if_stack 0 param = ;

  $ast
  @ast intoks iptr "\n" ast_parse = ;
  #ast ast_dump ;
  ctx ast preproc_eval ;

  # FIXME
  if_stack 0 vector_push_back ;

  0 "preproc_process_if: not implemented" assert_msg ;
}

fun is_including 1 {
  $if_stack
  @if_stack 0 param = ;

  $i
  @i 0 = ;
  while i if_stack vector_size < {
    if if_stack i vector_at 1 != {
      0 ret ;
    }
    @i i 1 + = ;
  }
  1 ret ;
}

fun preproc_file 3 {
  $ctx
  $filename
  $tokens
  @ctx 1 param = ;
  @filename 0 param = ;
  @tokens 2 param = ;
  $intoks
  @intoks filename tokenize_file = ;
  # All incoming tokens are accumulated in ready_toks; before each
  # preprocessor directive is processed (and at the end of the file),
  # tokens in ready_tokens are expanded and flushed; this is probably
  # not the correct algorithm, but it should work for sane programs.
  $ready_toks
  @ready_toks 4 vector_init = ;
  $i
  @i 0 = ;
  $at_newline
  @at_newline 1 = ;
  # For each #if stack level, we store 0 if no if has matched yet, 1
  # if we are including and 2 if we have already matched
  $if_stack
  @if_stack 4 vector_init = ;
  if_stack 1 vector_push_back ;
  $including
  @including if_stack is_including = ;
  while i intoks vector_size < {
    $tok
    @tok intoks i vector_at = ;
    if tok "#" strcmp 0 == at_newline && {
      ctx ready_toks tokens preproc_expand ;
      ready_toks vector_clear ;
      intoks @i discard_white_tokens ;
      @tok intoks i vector_at = ;
      $processed
      @processed 0 = ;
      if tok "include" strcmp 0 == processed ! && {
        if including {
          ctx tokens intoks @i preproc_process_include ;
        }
        @processed 1 = ;
      }
      if tok "define" strcmp 0 == processed ! && {
        if including {
          ctx tokens intoks @i preproc_process_define ;
        }
        @processed 1 = ;
      }
      if tok "undef" strcmp 0 == processed ! && {
        if including {
          ctx tokens intoks @i preproc_process_undef ;
        }
        @processed 1 = ;
      }
      if tok "if" strcmp 0 == processed ! && {
        ctx tokens intoks @i if_stack preproc_process_if ;
        @including if_stack is_including = ;
        @processed 1 = ;
      }
      if tok "endif" strcmp 0 == processed ! && {
        ctx tokens intoks @i if_stack preproc_process_endif ;
        @including if_stack is_including = ;
        @processed 1 = ;
      }
      if tok "elif" strcmp 0 == processed ! && {
        ctx tokens intoks @i if_stack preproc_process_elif ;
        @including if_stack is_including = ;
        @processed 1 = ;
      }
      if tok "else" strcmp 0 == processed ! && {
        ctx tokens intoks @i if_stack preproc_process_else ;
        @including if_stack is_including = ;
        @processed 1 = ;
      }
      if tok "ifdef" strcmp 0 == processed ! && {
        ctx tokens intoks @i if_stack preproc_process_ifdef ;
        @including if_stack is_including = ;
        @processed 1 = ;
      }
      if tok "ifndef" strcmp 0 == processed ! && {
        ctx tokens intoks @i if_stack preproc_process_ifndef ;
        @including if_stack is_including = ;
        @processed 1 = ;
      }
      if processed ! {
        0 "preproc_file: invalid preprocessor directive" assert_msg ;
      }
      intoks i vector_at "\n" strcmp 0 == "preproc_file: error 1" assert_msg ;
    } else {
      if including {
        ready_toks tok vector_push_back ;
        #ctx tokens intoks @i process_token ;
      }
    }
    @tok intoks i vector_at = ;
    @at_newline tok "\n" strcmp 0 == = ;
    @i i 1 + = ;
  }
  ctx ready_toks tokens preproc_expand ;
  ready_toks vector_clear ;
  ready_toks vector_destroy ;
  if_stack vector_size 1 == "preproc_file: some #if was not closed" assert_msg ;
  if_stack vector_destroy ;
  intoks free_vect_of_ptrs ;
}

fun parse_c 1 {
  $ctx
  @ctx ppctx_init = ;
  $tokens
  @tokens 4 vector_init = ;
  tokens ctx 0 param preproc_file ;
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
  tokens free_vect_of_ptrs ;
  ctx ppctx_destroy ;
}
