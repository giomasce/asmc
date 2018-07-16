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

const AST_TYPE 0             # 0 for operand, 1 for operator
const AST_NAME 4             # char*
const AST_LEFT 8             # AST*
const AST_RIGHT 12           # AST*
const AST_TYPE_IDX 16        # int
const AST_ORIG_TYPE_IDX 20   # int
const SIZEOF_AST 24

fun ast_init 0 {
  $ptr
  @ptr SIZEOF_AST malloc = ;
  ptr AST_TYPE take_addr 0 = ;
  ptr AST_NAME take_addr 0 = ;
  ptr AST_LEFT take_addr 0 = ;
  ptr AST_RIGHT take_addr 0 = ;
  ptr AST_TYPE_IDX take_addr 0xffffffff = ;
  ptr AST_ORIG_TYPE_IDX take_addr 0xffffffff = ;
  ptr ret ;
}

fun ast_destroy 1 {
  $ptr
  @ptr 0 param = ;
  ptr AST_NAME take free ;
  if ptr AST_LEFT take {
    ptr AST_LEFT take ast_destroy ;
  }
  if ptr AST_RIGHT take {
    ptr AST_RIGHT take ast_destroy ;
  }
  ptr free ;
}

fun ast_is_operator 1 {
  $str
  @str 0 param = ;
  str "++" strcmp 0 ==
    str "--" strcmp 0 == ||
    str "." strcmp 0 == ||
    str "->" strcmp 0 == ||
    str "+" strcmp 0 == ||
    str "-" strcmp 0 == ||
    str "!" strcmp 0 == ||
    str "~" strcmp 0 == ||
    str "*" strcmp 0 == ||
    str "&" strcmp 0 == ||
    str "sizeof" strcmp 0 == ||
    str "/" strcmp 0 == ||
    str "%" strcmp 0 == ||
    str "<<" strcmp 0 == ||
    str ">>" strcmp 0 == ||
    str "<" strcmp 0 == ||
    str "<=" strcmp 0 == ||
    str ">" strcmp 0 == ||
    str ">=" strcmp 0 == ||
    str "==" strcmp 0 == ||
    str "!=" strcmp 0 == ||
    str "^" strcmp 0 == ||
    str "|" strcmp 0 == ||
    str "&&" strcmp 0 == ||
    str "||" strcmp 0 == ||
    str "=" strcmp 0 == ||
    str "+=" strcmp 0 == ||
    str "-=" strcmp 0 == ||
    str "*=" strcmp 0 == ||
    str "/=" strcmp 0 == ||
    str "%=" strcmp 0 == ||
    str "<<=" strcmp 0 == ||
    str ">>=" strcmp 0 == ||
    str "&=" strcmp 0 == ||
    str "^=" strcmp 0 == ||
    str "|=" strcmp 0 == ||
    str "," strcmp 0 == ||
    ret ;
}

# See http://en.cppreference.com/w/c/language/operator_precedence
fun ast_get_priority 1 {
  $str
  @str 0 param = ;
  if str "++_POST" strcmp 0 == { 1 ret ; }
  if str "--_POST" strcmp 0 == { 1 ret ; }
  if str "(" strcmp 0 == { 1 ret ; }
  if str "[" strcmp 0 == { 1 ret ; }
  if str "." strcmp 0 == { 1 ret ; }
  if str "->" strcmp 0 == { 1 ret ; }
  if str "++_PRE" strcmp 0 == { 2 ret ; }
  if str "--_PRE" strcmp 0 == { 2 ret ; }
  if str "+_PRE" strcmp 0 == { 2 ret ; }
  if str "-_PRE" strcmp 0 == { 2 ret ; }
  if str "!" strcmp 0 == { 2 ret ; }
  if str "~" strcmp 0 == { 2 ret ; }
  if str "*_PRE" strcmp 0 == { 2 ret ; }
  if str "&_PRE" strcmp 0 == { 2 ret ; }
  if str "sizeof" strcmp 0 == { 2 ret ; }
  if str "*" strcmp 0 == { 3 ret ; }
  if str "/" strcmp 0 == { 3 ret ; }
  if str "%" strcmp 0 == { 3 ret ; }
  if str "+" strcmp 0 == { 4 ret ; }
  if str "-" strcmp 0 == { 4 ret ; }
  if str "<<" strcmp 0 == { 5 ret ; }
  if str ">>" strcmp 0 == { 5 ret ; }
  if str "<" strcmp 0 == { 6 ret ; }
  if str "<=" strcmp 0 == { 6 ret ; }
  if str ">" strcmp 0 == { 6 ret ; }
  if str ">=" strcmp 0 == { 6 ret ; }
  if str "==" strcmp 0 == { 7 ret ; }
  if str "!=" strcmp 0 == { 7 ret ; }
  if str "&" strcmp 0 == { 8 ret ; }
  if str "^" strcmp 0 == { 9 ret ; }
  if str "|" strcmp 0 == { 10 ret ; }
  if str "&&" strcmp 0 == { 11 ret ; }
  if str "||" strcmp 0 == { 12 ret ; }
  if str "=" strcmp 0 == { 14 ret ; }
  if str "+=" strcmp 0 == { 14 ret ; }
  if str "-=" strcmp 0 == { 14 ret ; }
  if str "*=" strcmp 0 == { 14 ret ; }
  if str "/=" strcmp 0 == { 14 ret ; }
  if str "%=" strcmp 0 == { 14 ret ; }
  if str "<<=" strcmp 0 == { 14 ret ; }
  if str ">>=" strcmp 0 == { 14 ret ; }
  if str "&=" strcmp 0 == { 14 ret ; }
  if str "^=" strcmp 0 == { 14 ret ; }
  if str "|=" strcmp 0 == { 14 ret ; }
  if str "," strcmp 0 == { 15 ret ; }
  if str " " strcmp 0 == { 100 ret ; }
  0 "Not an operator" assert_msg ;
}

# See http://en.cppreference.com/w/c/language/operator_precedence
# 0 is right-to-left
# 1 is left-to-right
fun ast_get_ass_direction 1 {
  $str
  @str 0 param = ;
  if str "++_POST" strcmp 0 == { 1 ret ; }
  if str "--_POST" strcmp 0 == { 1 ret ; }
  if str "(" strcmp 0 == { 1 ret ; }
  if str "[" strcmp 0 == { 1 ret ; }
  if str "." strcmp 0 == { 1 ret ; }
  if str "->" strcmp 0 == { 1 ret ; }
  if str "++_PRE" strcmp 0 == { 0 ret ; }
  if str "--_PRE" strcmp 0 == { 0 ret ; }
  if str "+_PRE" strcmp 0 == { 0 ret ; }
  if str "-_PRE" strcmp 0 == { 0 ret ; }
  if str "!" strcmp 0 == { 0 ret ; }
  if str "~" strcmp 0 == { 0 ret ; }
  if str "*_PRE" strcmp 0 == { 0 ret ; }
  if str "&_PRE" strcmp 0 == { 0 ret ; }
  if str "sizeof" strcmp 0 == { 0 ret ; }
  if str "*" strcmp 0 == { 1 ret ; }
  if str "/" strcmp 0 == { 1 ret ; }
  if str "%" strcmp 0 == { 1 ret ; }
  if str "+" strcmp 0 == { 1 ret ; }
  if str "-" strcmp 0 == { 1 ret ; }
  if str "<<" strcmp 0 == { 1 ret ; }
  if str ">>" strcmp 0 == { 1 ret ; }
  if str "<" strcmp 0 == { 1 ret ; }
  if str "<=" strcmp 0 == { 1 ret ; }
  if str ">" strcmp 0 == { 1 ret ; }
  if str ">=" strcmp 0 == { 1 ret ; }
  if str "==" strcmp 0 == { 1 ret ; }
  if str "!=" strcmp 0 == { 1 ret ; }
  if str "&" strcmp 0 == { 1 ret ; }
  if str "^" strcmp 0 == { 1 ret ; }
  if str "|" strcmp 0 == { 1 ret ; }
  if str "&&" strcmp 0 == { 1 ret ; }
  if str "||" strcmp 0 == { 1 ret ; }
  if str "=" strcmp 0 == { 0 ret ; }
  if str "+=" strcmp 0 == { 0 ret ; }
  if str "-=" strcmp 0 == { 0 ret ; }
  if str "*=" strcmp 0 == { 0 ret ; }
  if str "/=" strcmp 0 == { 0 ret ; }
  if str "%=" strcmp 0 == { 0 ret ; }
  if str "<<=" strcmp 0 == { 0 ret ; }
  if str ">>=" strcmp 0 == { 0 ret ; }
  if str "&=" strcmp 0 == { 0 ret ; }
  if str "^=" strcmp 0 == { 0 ret ; }
  if str "|=" strcmp 0 == { 0 ret ; }
  if str "," strcmp 0 == { 1 ret ; }
  if str " " strcmp 0 == { 0 ret ; }
  0 "Not an operator" assert_msg ;
}

fun ast_rewind_stack 2 {
  $operator_stack
  $operand_stack
  @operator_stack 1 param = ;
  @operand_stack 0 param = ;

  operand_stack vector_size operator_stack vector_size == "Stacks do not have the same size" assert_msg ;

  $cont
  @cont 1 = ;
  while operator_stack vector_size 2 >= cont && {
    $last_pri
    $nlast_pri
    $dir
    @last_pri operator_stack operator_stack vector_size 1 - vector_at ast_get_priority = ;
    @nlast_pri operator_stack operator_stack vector_size 2 - vector_at ast_get_priority = ;
    @dir operator_stack operator_stack vector_size 1 - vector_at ast_get_ass_direction = ;
    if last_pri nlast_pri > last_pri nlast_pri == dir && || {
      $ast
      @ast ast_init = ;
      $tmp
      @tmp operator_stack vector_pop_back = ;
      ast AST_TYPE take_addr 1 = ;
      ast AST_RIGHT take_addr operand_stack vector_pop_back = ;
      ast AST_LEFT take_addr operand_stack vector_pop_back = ;
      ast AST_NAME take_addr operator_stack vector_pop_back = ;
      operand_stack ast vector_push_back ;
      operator_stack tmp vector_push_back ;
    } else {
      @cont 0 = ;
    }
    operand_stack vector_size operator_stack vector_size == "Stacks do not have the same size" assert_msg ;
  }
}

fun ast_parse 3 {
  $intoks
  $iptr
  $end_tok
  @intoks 2 param = ;
  @iptr 1 param = ;
  @end_tok 0 param = ;

  $cont
  @cont 1 = ;
  $expect_operator
  @expect_operator 0 = ;
  $operator_stack
  @operator_stack 4 vector_init = ;
  $operand_stack
  @operand_stack 4 vector_init = ;
  while cont {
    $tok
    iptr iptr ** 1 + = ;
    @tok intoks iptr ** vector_at = ;
    if end_tok tok strcmp 0 == {
      @cont 0 = ;
    } else {
      if " " tok strcmp 0 != {
        $is_operator
        @is_operator tok ast_is_operator = ;
        #"Found: " 1 platform_log ;
        #tok 1 platform_log ;
        #if is_operator {
        #  " (operator)" 1 platform_log ;
        #} else {
        #  " (operand)" 1 platform_log ;
        #}
        #"\n" 1 platform_log ;
        if expect_operator {
          if is_operator {
            # Operator as we expect, push it in the operator stack.
            # If the operator is postfix, mangle it and push
            # a placeholder operand in the operand stack
            $is_postfix
            @is_postfix 0 = ;
            if tok "++" strcmp 0 == {
              @tok "++_POST" = ;
              @is_postfix 1 = ;
            }
            if tok "--" strcmp 0 == {
              @tok "--_POST" = ;
              @is_postfix 1 = ;
            }
            operator_stack tok strdup vector_push_back ;
            operator_stack operand_stack ast_rewind_stack ;
            if is_postfix {
              operand_stack ast_init vector_push_back ;
            } else {
              @expect_operator 0 = ;
            }
          } else {
            $ast
            # Here we treat the argument-separating comma as the
            # comma operator; this is not correct, in theory, because
            # it makes a((b,c),d) the same thing as a(b,c,d). However
            # we hope that no sane program relies on that.
            if tok "(" strcmp 0 == {
              $tok2
              iptr iptr ** 1 + = ;
              @tok2 intoks iptr ** vector_at = ;
              if tok2 ")" strcmp 0 == {
                # No arguments, push a placeholder
                @ast ast_init = ;
              } else {
                # Roll back token and parse arguments
                iptr iptr ** 1 - = ;
                @ast intoks iptr ")" ast_parse = ;
              }
              operator_stack tok strdup vector_push_back ;
              operator_stack operand_stack ast_rewind_stack ;
              operand_stack ast vector_push_back ;
            } else {
              if tok "[" strcmp 0 == {
                @ast intoks iptr "]" ast_parse = ;
                operator_stack tok strdup vector_push_back ;
                operator_stack operand_stack ast_rewind_stack ;
                operand_stack ast vector_push_back ;
              } else {
                # Operand instead of operator: error!
                0 "Operand instead of operator" assert_msg ;
              }
            }
          }
        } else {
          if is_operator {
            # Operator instead of operand, it must be a prefix.
            # Mangle it, push it in the operator stack
            # and push a placeholder operand in the operand stack
            $found
            @found 0 = ;
            if tok "++" strcmp 0 == {
              @tok "++_PRE" = ;
              @found 1 = ;
            }
            if tok "--" strcmp 0 == {
              @tok "--_PRE" = ;
              @found 1 = ;
            }
            if tok "+" strcmp 0 == {
              @tok "+_PRE" = ;
              @found 1 = ;
            }
            if tok "-" strcmp 0 == {
              @tok "-_PRE" = ;
              @found 1 = ;
            }
            if tok "*" strcmp 0 == {
              @tok "*_PRE" = ;
              @found 1 = ;
            }
            if tok "&" strcmp 0 == {
              @tok "&_PRE" = ;
              @found 1 = ;
            }
            found "Expect prefix operator" assert_msg ;
            operator_stack tok strdup vector_push_back ;
            operand_stack ast_init vector_push_back ;
          } else {
            $ast
            if tok "(" strcmp 0 == {
              @ast intoks iptr ")" ast_parse = ;
            } else {
              # Operand as we expect, push it in the operand stack
              @ast ast_init = ;
              ast AST_TYPE take_addr 0 = ;
              ast AST_NAME take_addr tok strdup = ;
            }
            operand_stack ast vector_push_back ;
            @expect_operator 1 = ;
          }
        }
        # Partially rewind the stack so that priority is decreasing
        if expect_operator ! {
          operator_stack operand_stack ast_rewind_stack ;
        }
      }
    }
  }

  expect_operator "Expect operand" assert_msg ;

  # Ad a final placeholder operator with the weakest possible priority,
  # in order to force the whole stack rewind
  $tmp
  @tmp " " strdup = ;
  operator_stack tmp vector_push_back ;
  operator_stack operand_stack ast_rewind_stack ;
  operand_stack vector_size 1 == "Internal error" assert_msg ;
  operator_stack vector_size 1 == "Internal error" assert_msg ;
  operator_stack vector_pop_back tmp == assert ;
  tmp free ;

  $res
  @res operand_stack vector_pop_back = ;

  operand_stack vector_destroy ;
  operator_stack vector_destroy ;

  res ret ;
}

fun ast_dump_int 2 {
  $ast
  $depth
  @ast 1 param = ;
  @depth 0 param = ;

  $i
  @i 0 = ;
  while i depth < {
    "  " 1 platform_log ;
    @i i 1 + = ;
  }
  if ast AST_TYPE take 0 == {
    if ast AST_NAME take 0 == {
      "Placeholder operand" 1 platform_log ;
    } else {
      "Operand of type #" 1 platform_log ;
      ast AST_TYPE_IDX take itoa 1 platform_log ;
      ": " 1 platform_log ;
      ast AST_NAME take 1 platform_log ;
    }
    "\n" 1 platform_log ;
  } else {
    "Operator of type #" 1 platform_log ;
    ast AST_TYPE_IDX take itoa 1 platform_log ;
    ": " 1 platform_log ;
    ast AST_NAME take 1 platform_log ;
    "\n" 1 platform_log ;
    ast AST_LEFT take depth 1 + ast_dump_int ;
    ast AST_RIGHT take depth 1 + ast_dump_int ;
  }
}

fun ast_dump 1 {
  0 param 0 ast_dump_int ;
}
