# This file is part of asmc, a bootstrapping OS with minimal seed
# Copyright (C) 2018 Giovanni Mascellani <gio@debian.org>
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

$fd_in
$read_char
$char_given_back

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
const PPCTX_BASE_PATH 4
const PPCTX_VERBOSE 8
const SIZEOF_PPCTX 12

fun ppctx_init 0 {
  $ptr
  @ptr SIZEOF_PPCTX malloc = ;
  ptr PPCTX_DEFINES take_addr map_init = ;
  ptr PPCTX_BASE_PATH take_addr 0 = ;
  ptr PPCTX_VERBOSE take_addr 1 = ;
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
  defs map_destroy ;
  ptr PPCTX_BASE_PATH take free ;
  ptr free ;
}

fun ppctx_define 3 {
  $ctx
  $key
  $value
  @ctx 2 param = ;
  @key 1 param = ;
  @value 0 param = ;

  $subst
  @subst subst_init = ;
  subst SUBST_REPLACEMENT take value strdup vector_push_back ;
  ctx PPCTX_DEFINES take key subst map_set ;
}

fun ppctx_set_base_filename 2 {
  $ctx
  $filename
  @ctx 1 param = ;
  @filename 0 param = ;

  @filename filename strdup = ;
  # Take the dirname
  $i
  @i filename strlen = ;
  filename **c '/' == "ppctx_set_base_filename: missing initial slash" assert_msg ;
  while filename i + **c '/' != {
    @i i 1 - = ;
  }
  filename i + 1 + 0 =c ;
  ctx PPCTX_BASE_PATH take_addr filename = ;
}

fun give_back_char 0 {
  @char_given_back 1 = ;
}

fun get_char 0 {
  if char_given_back {
    @char_given_back 0 = ;
  } else {
    @read_char fd_in vfs_read = ;
  }
  read_char ret
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
    @c '\r' = ;
    while c '\r' == {
      @c get_char = ;
    }
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
          @token_len 1 = ;
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
                if done ! {
                  token_buf token_len + 0 =c ;
                  if token_buf ast_is_operator token_buf "##" strcmp 0 == || token_buf ".." strcmp 0 == || token_buf "..." strcmp 0 == || ! {
                    @cont 0 = ;
                    @done 1 = ;
                    @token_len token_len 1 - = ;
                    give_back_char ;
                  }
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
  @fd_in 0 param vfs_open = ;
  fd_in 0 != "tokenize_file: could not open file" assert_msg ;
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
    } else {
      tok free ;
    }
  }
  fd_in vfs_close ;
  token_vect ret ;
}

fun discard_until_newline 2 {
  $tokens
  $iptr
  @iptr 0 param = ;
  @tokens 1 param = ;
  $cont
  @cont 1 = ;
  while cont {
    @cont tokens iptr ** vector_at "\n" strcmp 0 != = ;
    if cont {
      iptr iptr ** 1 + = ;
      iptr ** tokens vector_size < "discard_until_newline: stream end was found" assert_msg ;
    }
  }
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

fun discard_white_newline_tokens 2 {
  $tokens
  $iptr
  @iptr 0 param = ;
  @tokens 1 param = ;
  $cont
  @cont 1 = ;
  while cont {
    iptr iptr ** 1 + = ;
    iptr ** tokens vector_size < "discard_white_token: stream end was found" assert_msg ;
    $tok
    @tok tokens iptr ** vector_at = ;
    @cont tok " " strcmp 0 == tok "\n" strcmp 0 == || = ;
  }
}

# Check that the argument string has no " or \
fun check_string 1 {
  $s
  @s 0 param = ;

  while 1 {
    if s **c 0 == {
      ret ;
    }
    s **c '\"' == s **c '\\' == || ! "check_string: string is not valid" assert_msg ;
    @s s 1 + = ;
  }
}

fun process_token_stringify 2 {
  $ctx
  $toks
  @ctx 1 param = ;
  @toks 0 param = ;

  $res
  @res "\"" strdup = ;
  $i
  @i 0 = ;
  $begin
  @begin 1 = ;
  $whites
  @whites 0 = ;
  while i toks vector_size < {
    $tok
    @tok toks i vector_at = ;
    if tok " " strcmp 0 == tok "\n" strcmp 0 == || {
      if begin ! {
        @whites 1 = ;
      }
    } else {
      @begin 0 = ;
      if whites {
        @res res " " append_to_str = ;
      }
      tok check_string ;
      @res res tok append_to_str = ;
    }
    @i i 1 + = ;
  }
  @res res "\"" append_to_str = ;
  res ret ;
}

fun push_token 2 {
  $tokens
  $tok
  @tokens 1 param = ;
  @tok 0 param = ;

  $prev
  @prev tokens vector_pop_back = ;
  if prev "##" strcmp 0 == {
    if tok " " strcmp 0 == tok "\n" strcmp 0 == || ! {
      prev free ;
      @prev tokens vector_pop_back = ;
      @prev prev tok append_to_str = ;
    }
    tokens prev vector_push_back ;
    tok free ;
  } else {
    if tok "##" strcmp 0 == {
      while prev " " strcmp 0 == prev "\n" strcmp 0 == || {
        prev free ;
        @prev tokens vector_pop_back = ;
      }
    }
    tokens prev vector_push_back ;
    if tok "" strcmp 0 == {
      tok free ;
    } else {
      tokens tok vector_push_back ;
    }
  }
}

fun process_token_function 5 {
  $ctx
  $tokens
  $intoks
  $iptr
  $subst
  @ctx 4 param = ;
  @tokens 3 param = ;
  @intoks 2 param = ;
  @iptr 1 param = ;
  @subst 0 param = ;

  # First parse the inputs
  $args
  @args map_init = ;
  while args vector_size subst SUBST_PARAMETERS take vector_size < {
    $depth
    @depth 0 = ;
    $cont
    @cont 1 = ;
    $arg
    @arg 4 vector_init = ;
    $tok
    while cont {
      @tok intoks iptr ** vector_at = ;
      iptr iptr ** 1 + = ;
      iptr ** intoks vector_size < "process_token_function: end of stream found" assert_msg ;
      if tok "," strcmp 0 == tok ")" strcmp 0 == || depth 0 == && {
        @cont 0 = ;
      } else {
        if tok "(" strcmp 0 == {
          @depth depth 1 + = ;
        }
        if tok ")" strcmp 0 == {
          @depth depth 1 - = ;
        }
        arg tok vector_push_back ;
      }
    }
    $ident
    @ident subst SUBST_PARAMETERS take args map_size vector_at = ;
    args ident arg map_set ;
    if args vector_size subst SUBST_PARAMETERS take vector_size == {
      tok ")" strcmp 0 == "process_token_function: ) expected" assert_msg ;
    } else {
      tok "," strcmp 0 == "process_token_function: , expected" assert_msg ;
    }
  }
  iptr iptr ** 1 - = ;

  # Output tokens
  $i
  @i 0 = ;
  $repl
  @repl subst SUBST_REPLACEMENT take = ;
  while i repl vector_size < {
    $tok
    @tok repl i vector_at = ;
    if tok "#" strcmp 0 == {
      @i i 1 + = ;
      i repl vector_size < "process_token_function: invalid # usage" assert_msg ;
      @tok repl i vector_at = ;
      args tok map_has "process_token_function: # requires a parameter" assert_msg ;
      $newtok
      @newtok ctx args tok map_at process_token_stringify = ;
      tokens newtok push_token ;
    } else {
      if args tok map_has {
        $repl2
        @repl2 args tok map_at = ;
        $j
        @j 0 = ;
        # If the substitution is empty, push an empty token to trigger ## pasting
        if repl2 vector_size 0 == {
          tokens "" strdup push_token ;
        }
        while j repl2 vector_size < {
          @tok repl2 j vector_at = ;
          tokens tok strdup push_token ;
          @j j 1 + = ;
        }
      } else {
        tokens tok strdup push_token ;
      }
    }
    @i i 1 + = ;
  }

  # Free temporaries
  @i 0 = ;
  while i args map_size < {
    if args i map_has_idx {
      args i map_at_idx vector_destroy ;
    }
    @i i 1 + = ;
  }
  args map_destroy ;
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
    # "Expanding: " 1 platform_log ;
    # tok 1 platform_log ;
    # "\n" 1 platform_log ;
    $subst
    @subst ctx PPCTX_DEFINES take tok map_at = ;
    $repl
    @repl subst SUBST_REPLACEMENT take = ;
    if subst SUBST_IS_FUNCTION take {
      $saved_i
      @saved_i iptr ** = ;
      intoks iptr discard_white_newline_tokens ;
      @tok intoks iptr ** vector_at = ;
      if tok "(" strcmp 0 == {
        @changed 1 = ;
        iptr iptr ** 1 + = ;
        iptr ** intoks vector_size < "preproc_token: end of stream found" assert_msg ;
        ctx tokens intoks iptr subst process_token_function ;
      } else {
        # No actual substitution, roll back changes and push unchanged token
        iptr saved_i = ;
        @tok intoks iptr ** vector_at = ;
        tokens tok strdup vector_push_back ;
      }
    } else {
      @changed 1 = ;
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

fun print_token_list 1 {
  $tokens
  @tokens 0 param = ;

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
    # "---\n" 1 platform_log ;
    # intoks print_token_list ;
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
  if is_func {
    intoks iptr discard_white_tokens ;
    @tok intoks iptr ** vector_at = ;
    if tok ")" strcmp 0 != {
      $cont
      @cont 1 = ;
      while cont {
        tok is_valid_identifier "preproc_process_define: token is not an identifier" assert_msg ;
        subst SUBST_PARAMETERS take tok strdup vector_push_back ;
        intoks iptr discard_white_tokens ;
        @tok intoks iptr ** vector_at = ;
        if tok ")" strcmp 0 == {
          @cont 0 = ;
        } else {
          tok "," strcmp 0 == "preproc_process_define: , or ) expected" assert_msg ;
        }
        intoks iptr discard_white_tokens ;
        @tok intoks iptr ** vector_at = ;
      }
    } else {
      intoks iptr discard_white_tokens ;
      @tok intoks iptr ** vector_at = ;
    }
  } else {
    iptr iptr ** 1 - = ;
    intoks iptr discard_white_tokens ;
    @tok intoks iptr ** vector_at = ;
  }
  while tok "\n" strcmp 0 != {
    subst SUBST_REPLACEMENT take tok strdup vector_push_back ;
    iptr iptr ** 1 + = ;
    iptr ** intoks vector_size < "preproc_process_define: end of stream found" assert_msg ;
    @tok intoks iptr ** vector_at = ;
  }

  if ctx PPCTX_DEFINES take ident map_has {
    "Redefining " 1 platform_log ;
    ident 1 platform_log ;
    "\n" 1 platform_log ;
    $subst
    @subst ctx PPCTX_DEFINES take ident map_at = ;
    subst subst_destroy ;
    ctx PPCTX_DEFINES take ident map_erase ;
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

  # Search for the right include path
  $testfile
  @testfile filename strdup ctx PPCTX_BASE_PATH take prepend_to_str = ;
  $fd
  @fd testfile vfs_open = ;
  if fd ! {
    testfile free ;
    @testfile filename strdup "/disk1/stdlib/" prepend_to_str = ;
    @fd testfile vfs_open = ;
    fd "preproc_process_include: cannot find file" testfile assert_msg_str ;
    fd vfs_close ;
    filename free ;
    @filename testfile = ;
  } else {
    fd vfs_close ;
    filename free ;
    @filename testfile = ;
  }

  if ctx PPCTX_VERBOSE take {
    "Including file " 1 platform_log ;
    filename 1 platform_log ;
    "\n" 1 platform_log ;
  }
  tokens ctx filename preproc_file ;
  if ctx PPCTX_VERBOSE take {
    "Finished including file " 1 platform_log ;
    filename 1 platform_log ;
    "\n" 1 platform_log ;
  }
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
    if name is_valid_identifier {
      if defs name map_has {
        $subst
        @subst defs name map_at = ;
        $repl
        @repl subst SUBST_REPLACEMENT take = ;
        subst SUBST_IS_FUNCTION take ! "preproc_eval: not supported" assert_msg ;
        if repl vector_size 1 == repl 0 vector_at is_valid_identifier ! && {
          repl 0 vector_at atoi ret ;
        } else {
          $ast2
          $i
          @i 0 1 - = ;
          @ast2 repl @i ";;" ast_parse = ;
          $res
          @res ctx ast2 preproc_eval = ;
          ast2 ast_destroy ;
          res ret ;
        }
      } else {
        0 ret ;
      }
    } else {
      name atoi ret ;
    }
  } else {
    # Operator
    ast AST_TYPE take 1 == "preproc_eval: error 1" assert_msg ;

    if name "&&" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval && ret ;
    }

    if name "||" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval || ret ;
    }

    if name "&" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval & ret ;
    }

    if name "|" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval | ret ;
    }

    if name "==" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval == ret ;
    }

    if name "!=" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval != ret ;
    }

    if name ">=" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval >= ret ;
    }

    if name "<=" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval <= ret ;
    }

    if name ">" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval > ret ;
    }

    if name "<" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval < ret ;
    }

    if name "+" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval + ret ;
    }

    if name "-" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval - ret ;
    }

    if name "*" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval * ret ;
    }

    if name "/" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval / ret ;
    }

    if name "%" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval % ret ;
    }

    if name "^" strcmp 0 == {
      ctx ast AST_LEFT take preproc_eval ctx ast AST_RIGHT take preproc_eval ^ ret ;
    }

    if name "defined_PRE" strcmp 0 == {
      $child
      @child ast AST_RIGHT take = ;
      child AST_TYPE take 0 == "preproc_eval: not an identifier" assert_msg ;
      $ident
      @ident child AST_NAME take = ;
      defs ident map_has ret ;
    }

    if name "!_PRE" strcmp 0 == {
      ctx ast AST_RIGHT take preproc_eval ! ret ;
    }

    if name "-_PRE" strcmp 0 == {
      0 ctx ast AST_RIGHT take preproc_eval - ret ;
    }

    "Please implement " 1 platform_log ;
    name 1 platform_log ;
    "\n" 1 platform_log ;
    0 "preproc_eval: unsupported operation" assert_msg ;
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

  $ast
  @ast intoks iptr "\n" ast_parse = ;
  #ast ast_dump ;
  $value
  @value ctx ast preproc_eval ! ! = ;
  ast ast_destroy ;

  $state
  if_stack vector_size 1 > "preproc_process_elif: unmatched else" assert_msg ;
  @state if_stack vector_pop_back = ;
  @state state 1 + = ;
  if state 2 > {
    @state 2 = ;
  }
  if state 1 == value ! && {
    @state 0 = ;
  }
  if_stack state vector_push_back ;
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
  $value
  @value ctx ast preproc_eval ! ! = ;
  ast ast_destroy ;

  if_stack value vector_push_back ;
}

fun preproc_process_error 4 {
  $ctx
  $tokens
  $intoks
  $iptr
  @ctx 3 param = ;
  @tokens 2 param = ;
  @intoks 1 param = ;
  @iptr 0 param = ;

  intoks iptr discard_white_tokens ;

  $msg
  @msg intoks iptr ** vector_at = ;
  msg "\n" strcmp 0 != "preproc_process_error: newline found" assert_msg ;

  "#error with " 1 platform_log ;
  msg 1 platform_log ;
  "\n" 1 platform_log ;

  intoks iptr discard_white_tokens ;

  0 "preproc_process_error: dying because of error" assert_msg ;
}

fun preproc_process_warning 4 {
  $ctx
  $tokens
  $intoks
  $iptr
  @ctx 3 param = ;
  @tokens 2 param = ;
  @intoks 1 param = ;
  @iptr 0 param = ;

  intoks iptr discard_white_tokens ;

  $msg
  @msg intoks iptr ** vector_at = ;
  msg "\n" strcmp 0 != "preproc_process_warning: newline found" assert_msg ;

  "#warning with " 1 platform_log ;
  msg 1 platform_log ;
  "\n" 1 platform_log ;

  intoks iptr discard_white_tokens ;
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
      # "Processing " 1 platform_log ;
      # tok 1 platform_log ;
      # "\n" 1 platform_log ;
      $processed
      @processed 0 = ;
      if tok "include" strcmp 0 == processed ! && {
        if including {
          ctx tokens intoks @i preproc_process_include ;
        } else {
          intoks @i discard_until_newline ;
        }
        @processed 1 = ;
      }
      if tok "define" strcmp 0 == processed ! && {
        if including {
          ctx tokens intoks @i preproc_process_define ;
        } else {
          intoks @i discard_until_newline ;
        }
        @processed 1 = ;
      }
      if tok "undef" strcmp 0 == processed ! && {
        if including {
          ctx tokens intoks @i preproc_process_undef ;
        } else {
          intoks @i discard_until_newline ;
        }
        @processed 1 = ;
      }
      if tok "error" strcmp 0 == processed ! && {
        if including {
          ctx tokens intoks @i preproc_process_error ;
        } else {
          intoks @i discard_until_newline ;
        }
        @processed 1 = ;
      }
      if tok "warning" strcmp 0 == processed ! && {
        if including {
          ctx tokens intoks @i preproc_process_warning ;
        } else {
          intoks @i discard_until_newline ;
        }
        @processed 1 = ;
      }
      if tok "pragma" strcmp 0 == processed ! && {
        # pragma-s are silently discarded
        intoks @i discard_until_newline ;
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

fun remove_whites 1 {
  $intoks
  @intoks 0 param = ;

  $outtoks
  @outtoks 4 vector_init = ;
  $i
  @i 0 = ;
  while i intoks vector_size < {
    $tok
    @tok intoks i vector_at = ;
    if tok " " strcmp 0 == {
      tok free ;
    } else {
      if tok "\n" strcmp 0 == {
        tok free ;
      } else {
        outtoks tok vector_push_back ;
      }
    }
    @i i 1 + = ;
  }

  intoks vector_destroy ;
  outtoks ret ;
}
