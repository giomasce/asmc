
const AST_TYPE 0      # 0 for operand, 1 for operator
const AST_NAME 4      # char*
const AST_LEFT 8      # AST*
const AST_RIGHT 12    # AST*
const SIZEOF_AST 16

fun ast_init 0 {
  $ptr
  @ptr SIZEOF_AST malloc = ;
  ptr AST_TYPE take_addr 0 = ;
  ptr AST_NAME take_addr 0 = ;
  ptr AST_LEFT take_addr 0 = ;
  ptr AST_RIGHT take_addr 0 = ;
  ptr ret ;
}

fun ast_destroy 1 {
  $ptr
  @ptr 0 param = ;
  ptr AST_NAME take free ;
  ptr AST_LEFT take ast_destroy ;
  ptr AST_RIGHT take ast_destroy ;
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
    ret ;
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
        "Found: " 1 platform_log ;
        tok 1 platform_log ;
        if is_operator {
          " (operator)" 1 platform_log ;
        } else {
          " (operand)" 1 platform_log ;
        }
        "\n" 1 platform_log ;
      }
    }
  }

  0 ret ;
}
