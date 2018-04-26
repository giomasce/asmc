
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

#define TOK_CALL_OPEN ((char) 0x80)
#define TOK_CALL_CLOSED ((char) 0x81)
#define TOK_SHL ((char) 0x82)
#define TOK_SHR ((char) 0x83)
#define TOK_LE ((char) 0x84)
#define TOK_GE ((char) 0x85)
#define TOK_EQ ((char) 0x86)
#define TOK_INEQ ((char) 0x87)
#define TOK_AND ((char) 0x88)
#define TOK_OR ((char) 0x89)
#define TOK_DEREF ((char) 0x8a)
#define TOK_ADDR ((char) 0x8b)

#define MAX_ID_LEN 128
#define STACK_LEN 1024

int block_depth;
int stack_depth;
int current_loc;

char stack_vars[MAX_ID_LEN * STACK_LEN];

void push_var(char *var_name) {
  int len = strlen(var_name);
  assert(len > 0);
  assert(len < MAX_ID_LEN);
  assert(stack_depth < STACK_LEN);
  strcpy(stack_vars + stack_depth * MAX_ID_LEN, var_name);
  stack_depth++;
}

void pop_var() {
  stack_depth--;
}

void pop_to_depth(int depth) {
  stack_depth = depth;
}

void emit(char x) {
  fwrite(&x, 1, 1, stdout);
  current_loc++;
}

void emit32(int x) {
  emit(x);
  emit(x >> 8);
  emit(x >> 16);
  emit(x >> 24);
}

int find_in_stack(char *var_name) {
  int i;
  for (i = 0; i < stack_depth; i++) {
    if (strcmp(var_name, stack_vars + (stack_depth - 1 - i) * MAX_ID_LEN) == 0) {
      return i;
    }
  }
  return -1;
}

int is_whitespace(char x) {
  return x == ' ' || x == '\t' || x == '\n';
}

int is_id(char x) {
  return ('a' <= x && x <= 'z') || ('A' <= x && x <= 'Z') || ('0' <= x && x <= '9') || x == '_';
}

void remove_spaces(char *begin, char *end) {
  char *read_buf = begin;
  while (read_buf != end) {
    if (*read_buf == '\0') {
      *begin = '\0';
      return;
    }
    if (is_whitespace(*read_buf)) {
      read_buf++;
    } else {
      *begin = *read_buf;
      begin++;
      read_buf++;
    }
  }
  if (begin != end) {
    *begin = '\0';
  }
}

int find_char(char *s, char *e, char c) {
  char *s2 = s;
  while (1) {
    if (s2 == e) {
      return -1;
    }
    if (*s2 == c) {
      return s2 - s;
    }
    if (*s2 == '\0') {
      return -1;
    }
    s2++;
  }
}

int find_char_back(char *s, char *e, char c) {
  char *s2 = e;
  while (1) {
    s2--;
    if (*s2 == c) {
      return s2 - s;
    }
    if (s2 == s) {
      return -1;
    }
  }
}

char *isstrpref(char *s1, char *s2) {
  while (1) {
    if (*s1 == '\0') {
      return s2;
    }
    if (*s1 != *s2) {
      return 0;
    }
    s1++;
    s2++;
  }
}

void trimstr(char *buf) {
  char *write_buf = buf;
  char *read_buf = buf;
  while (is_whitespace(*read_buf)) {
    read_buf++;
  }
  while (*read_buf != '\0') {
    *write_buf = *read_buf;
    write_buf++;
    read_buf++;
  }
  *write_buf = '\0';
  write_buf--;
  while (write_buf >= buf && is_whitespace(*write_buf)) {
    *write_buf = '\0';
    write_buf--;
  }
}

void fix_operands(char *begin, char *end) {
  while (begin + 1 < end) {
    if (*begin == '<' && *(begin+1) == '<') { *begin = TOK_SHL; *(begin+1) = ' '; }
    if (*begin == '>' && *(begin+1) == '>') { *begin = TOK_SHR; *(begin+1) = ' '; }
    if (*begin == '<' && *(begin+1) == '=') { *begin = TOK_LE; *(begin+1) = ' '; }
    if (*begin == '>' && *(begin+1) == '=') { *begin = TOK_GE; *(begin+1) = ' '; }
    if (*begin == '=' && *(begin+1) == '=') { *begin = TOK_EQ; *(begin+1) = ' '; }
    if (*begin == '!' && *(begin+1) == '=') { *begin = TOK_INEQ; *(begin+1) = ' '; }
    if (*begin == '&' && *(begin+1) == '&') { *begin = TOK_AND; *(begin+1) = ' '; }
    if (*begin == '|' && *(begin+1) == '|') { *begin = TOK_OR; *(begin+1) = ' '; }
    begin++;
  }
}

void print(char *begin, char *end) {
  while (begin < end) {
    if (*begin == '\0') {
      break;
    }
    putchar(*begin);
    begin++;
  }
}

void fix_strings(char *begin, char *end) {
  int mode = 0;
  while (begin < end) {
    assert((unsigned char) *begin < 0x80);
    if (mode == 0) {
      if (*begin == '\'') {
        mode = 1;
      } else if (*begin == '"') {
        mode = 2;
      } else if (begin + 1 < end && *begin == '/' && *(begin+1) == '/') {
        mode = 3;
        *begin = ' ';
        begin++;
        *begin = ' ';
      } else if (begin + 1 < end && *begin == '/' && *(begin+1) == '*') {
        mode = 4;
        *begin = ' ';
        begin++;
        *begin = ' ';
      } else if (*begin == '#') {
        mode = 3;
        *begin = ' ';
      } else {
        if (is_whitespace(*begin)) {
          *begin = ' ';
        }
      }
    } else if (mode == 1) {
      if (*begin == '\'') {
        mode = 0;
      } else if (*begin == '\\') {
        assert(begin + 1 < end);
        *begin = *begin + 0x80;
        begin++;
        *begin = *begin + 0x80;
      } else {
        assert(*begin >= 0x20);
        *begin = *begin + 0x80;
      }
    } else if (mode == 2) {
      if (*begin == '"') {
        mode = 0;
      } else if (*begin == '\\') {
        assert(begin + 1 < end);
        *begin = *begin + 0x80;
        begin++;
        *begin = *begin + 0x80;
      } else {
        assert(*begin >= 0x20);
        *begin = *begin + 0x80;
      }
    } else if (mode == 3) {
      if (*begin == '\n') {
        mode = 0;
        *begin = ' ';
      } else {
        *begin = ' ';
      }
    } else if (mode == 4) {
      if (begin + 1 < end && *begin == '*' && *(begin+1) == '/') {
        mode = 0;
        *begin = ' ';
        begin++;
        *begin = ' ';
      } else {
        *begin = ' ';
      }
    }
    begin++;
  }
}

char *find_matching(char open, char closed, char *begin, char *end) {
  int depth = 0;
  while (begin < end) {
    if (*begin == open) {
      depth++;
    } else if (*begin == closed) {
      depth--;
    }
    if (depth == 0) {
      return begin;
    }
    begin++;
  }
  return 0;
}

char *find_id(char *s) {
  while (s != 0) {
    if (!is_id(*s)) {
      break;
    }
    s++;
  }
  return s;
}

int strncmp2(char *b1, char *e1, char *b2) {
  int len = strlen(b2);
  return e1 - b1 == len && strncmp(b1, b2, len) == 0;
}

char *interpret_type(char *decl) {
  int state = 0;
  char *name_begin;
  char *name_end;
  while (1) {
    if (*decl == '\0') {
      break;
    } else if (is_whitespace(*decl)) {
      decl++;
    } else if (*decl == '*') {
      decl++;
      if (state == 1) {
        state = 2;
      } else {
        assert(0);
      }
    } else if (*decl == '[') {
      if (state == 3) {
        // TODO
      } else {
        assert(0);
      }
    } else if (is_id(*decl)) {
      char *id_end = find_id(decl);
      int type_found = 0;
      if (strncmp2(decl, id_end, "unsigned")) {
        decl = id_end;
        type_found = 1;
      } else if (strncmp2(decl, id_end, "char")) {
        decl = id_end;
        type_found = 1;
      } else if (strncmp2(decl, id_end, "int")) {
        decl = id_end;
        type_found = 1;
      } else if (strncmp2(decl, id_end, "void")) {
        decl = id_end;
        type_found = 1;
      } else {
        // This is the declared name
        if (state == 1 || state == 2) {
          state = 3;
          name_begin = decl;
          name_end = id_end;
          decl = id_end;
        } else {
          assert(0);
        }
      }
      if (type_found) {
        if (state == 0 || state == 1) {
          state = 1;
        } else {
          assert(0);
        }
      }
    } else {
      assert(0);
    }
  }
  assert(state == 3);
  name_end = '\0';
  return name_begin;
}

int parse_expr(char *begin, char *end, char pivot, int dir) {

}

int eval_expr(char *begin, char *end, int addr) {

}

void compile_expression(char *exp) {
  remove_spaces(exp, 0);
  char *end = exp + strlen(exp);
  fprintf(stderr, "Expression: %s\n", exp);
  eval_expr(exp, end, 0);
}

void compile_statement(char *begin, char *end) {
  *end = '\0';
  trimstr(begin);
  if (*begin == '\0') {
    return;
  }
  char *first_id_end = find_id(begin);
  int is_return = 0;
  int has_decl = 0;
  if (strncmp2(begin, first_id_end, "return")) {
    is_return = 1;
  } else if (strncmp2(begin, first_id_end, "unsigned")) {
    has_decl = 1;
  } else if (strncmp2(begin, first_id_end, "char")) {
    has_decl = 1;
  } else if (strncmp2(begin, first_id_end, "int")) {
    has_decl = 1;
  } else if (strncmp2(begin, first_id_end, "void")) {
    has_decl = 1;
  }
  int equal_pos;
  if (has_decl) {
    equal_pos = find_char(begin, 0, '=');
  }

  if (has_decl) {
    if (equal_pos == -1) {
      fprintf(stderr, "Declaration: %s\n", begin);
      char *name = interpret_type(begin);
      fprintf(stderr, "  declared name is: %s\n", name);
      push_var(name);
      emit(0x83);  // sub esp, 4
      emit(0xec);
      emit(0x04);
    } else {
      begin[equal_pos] = '\0';
      fprintf(stderr, "Declaration: %s\n", begin);
      char *name = interpret_type(begin);
      fprintf(stderr, "  declared name is: %s\n", name);
      push_var(name);
      emit(0x83);  // sub esp, 4
      emit(0xec);
      emit(0x04);
      begin[equal_pos] = '=';
      char *initializer = begin + equal_pos + 1;
      trimstr(initializer);
      fprintf(stderr, "  initialized to: %s\n", initializer);
      compile_expression(initializer);
    }
  } else if (is_return) {
    if (*first_id_end == '\0') {
      fprintf(stderr, "Empty return statement\n");
    } else {
      fprintf(stderr, "Return statement: %s\n", first_id_end);
      compile_expression(first_id_end);
    }
  } else {
    fprintf(stderr, "Statement: %s\n", begin);
    compile_expression(begin);
  }
}

void compile_block_with_head(char *def_begin, char *block_begin, char *block_end);

void compile_block(char *begin, char *end) {
  block_depth++;
  int saved_stack_depth = stack_depth;
  while (1) {
    int semicolon_pos = find_char(begin, end, ';');
    int brace_pos = find_char(begin, end, '{');
    if (semicolon_pos == -1 && brace_pos == -1) {
      *end = '\0';
      trimstr(begin);
      assert(*begin == '\0');
      break;
    } else {
      if (semicolon_pos == -1) {
        semicolon_pos = brace_pos + 1;
      }
      if (brace_pos == -1) {
        brace_pos = semicolon_pos + 1;
      }
      if (semicolon_pos < brace_pos) {
        compile_statement(begin, begin + semicolon_pos);
        begin = begin + semicolon_pos + 1;
      } else {
        char *res = find_matching('{', '}', begin+brace_pos, end);
        compile_block_with_head(begin, begin+brace_pos, res);
        begin = res + 1;
      }
    }
  }
  int exit_stack_depth = stack_depth;
  pop_to_depth(saved_stack_depth);
  emit(0x81);  // add esp, ..
  emit(0xc4);
  emit32(4 * (exit_stack_depth - saved_stack_depth));
  block_depth--;
}

void compile_block_with_head(char *def_begin, char *block_begin, char *block_end) {
  *block_begin = '\0';
  trimstr(def_begin);
  //remove_spaces(def_begin, 0);
  if (strcmp(def_begin, "enum") == 0) {
    return;
  }

  int param_num = 0;
  if (block_depth == 1) {
    // This is a function
    remove_spaces(def_begin, 0);
    int open_pos = find_char(def_begin, block_begin, '(');
    assert(open_pos != -1);
    int closed_pos = find_char(def_begin, block_begin, ')');
    assert(closed_pos != -1);
    assert(def_begin[closed_pos+1] == '\0');
    def_begin[open_pos] = '\0';
    def_begin[closed_pos] = '\0';
    fprintf(stderr, "Beginning of a function with name %s\n", def_begin);

    assert(stack_depth == 0);
    char *params_begin = def_begin + open_pos + 1;
    char *params_end = def_begin + closed_pos;
    while (1) {
      int pos = find_char_back(params_begin, params_end, ',');
      if (pos != -1) {
        params_begin[pos] = '\0';
        push_var(params_begin + pos + 1);
        param_num++;
        fprintf(stderr, "  with parameter %s\n", params_begin + pos + 1);
        params_end = params_begin + pos;
      } else {
        push_var(params_begin);
        param_num++;
        fprintf(stderr, "  with parameter %s\n", params_begin);
        break;
      }
    }
    push_var("__ret");
  } else {
    fprintf(stderr, "Begin of block: %s\n", def_begin);
  }

  compile_block(block_begin+1, block_end-1);

  if (block_depth == 1) {
    pop_var();
    emit(0xc3);  // ret
    int i;
    for (i = 0; i < param_num; i++) {
      pop_var();
    }
    assert(stack_depth == 0);
  }

  fprintf(stderr, "End of block\n");
}

int main() {
  int fd = open("test.c", O_RDONLY);
  int len = lseek(fd, 0, SEEK_END);
  lseek(fd, 0, SEEK_SET);
  char *src = mmap(0, len, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);

  fix_strings(src, src+len);
  fix_operands(src, src+len);
  //remove_spaces(src, src+len);
  //print(src, src+len);

  block_depth = 0;
  stack_depth = 0;
  current_loc = 0x100000;
  compile_block(src, src+len);
  assert(block_depth == 0);
  assert(stack_depth == 0);

  return 0;
}
