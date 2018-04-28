
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
#define TOK_NE ((char) 0x87)
#define TOK_AND ((char) 0x88)
#define TOK_OR ((char) 0x89)
#define TOK_DEREF ((char) 0x8a)
#define TOK_ADDR ((char) 0x8b)

#define TOKS_CALL_OPEN "\x80"
#define TOKS_AND "\x88"
#define TOKS_OR "\x89"
#define TOKS_EQ_NE "\x86\x87"
#define TOKS_LE_GE "\x84\x85"
#define TOKS_SHL_SHR "\x82\x83"
#define TOKS_DEREF_ADDR "\x8a\x8b"

#define MAX_ID_LEN 128
#define STACK_LEN 1024
#define SYMBOL_TABLE_LEN 1024

int block_depth;
int stack_depth;
int current_loc;
int ret_depth;
int char_op;
int symbol_num;
int stage;

char stack_vars[MAX_ID_LEN * STACK_LEN];
char symbol_names[MAX_ID_LEN * SYMBOL_TABLE_LEN];
int symbol_locs[SYMBOL_TABLE_LEN];

char *find_matching_rev(char open, char closed, char *begin, char *end) {
  int depth = 0;
  end--;
  while (begin >= end) {
    if (*end == closed) {
      depth++;
    } else if (*end == open) {
      depth--;
    }
    if (depth == 0) {
      return end;
    }
    end--;
  }
  return 0;
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

int strncmp2(char *b1, char *e1, char *b2) {
  int len = strlen(b2);
  return e1 - b1 == len && strncmp(b1, b2, len) == 0;
}

int find_symbol(char *name) {
  int i;
  for (i = 0; i < symbol_num; i++) {
    if (strcmp(name, symbol_names + i * MAX_ID_LEN) == 0) {
      break;
    }
  }
  if (i == symbol_num) {
    i = SYMBOL_TABLE_LEN;
  }
  return i;
}

int find_symbol2(char *begin, char *end) {
  int i;
  for (i = 0; i < symbol_num; i++) {
    if (strncmp2(begin, end, symbol_names + i * MAX_ID_LEN)) {
      break;
    }
  }
  if (i == symbol_num) {
    i = SYMBOL_TABLE_LEN;
  }
  return i;
}

void add_symbol(char *name, int loc) {
  int len = strlen(name);
  assert(len > 0);
  assert(len < MAX_ID_LEN);
  if (stage == 0) {
    assert(find_symbol(name) == SYMBOL_TABLE_LEN);
    assert(symbol_num < SYMBOL_TABLE_LEN);
    symbol_locs[symbol_num] = loc;
    strcpy(symbol_names + symbol_num * MAX_ID_LEN, name);
    symbol_num = symbol_num + 1;
  } else if (stage == 1) {
    int idx = find_symbol(name);
    assert(idx < symbol_num);
    assert(symbol_locs[idx] == loc);
  } else {
    assert(0);
  }
}

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

int find_in_stack(char *var_name) {
  int i;
  for (i = 0; i < stack_depth; i++) {
    if (strcmp(var_name, stack_vars + (stack_depth - 1 - i) * MAX_ID_LEN) == 0) {
      return i;
    }
  }
  return -1;
}

int find_in_stack2(char* begin, char *end) {
  int i;
  for (i = 0; i < stack_depth; i++) {
    if (strncmp2(begin, end, stack_vars + (stack_depth - 1 - i) * MAX_ID_LEN)) {
      return i;
    }
  }
  return -1;
}

void emit(char x) {
  if (stage == 1) {
    fwrite(&x, 1, 1, stdout);
  }
  current_loc++;
}

void emit32(int x) {
  emit(x);
  emit(x >> 8);
  emit(x >> 16);
  emit(x >> 24);
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

void fix_operations(char *exp) {
  int prev_is_id = 0;
  while (*exp != '\0') {
    if (*(exp+1) != '\0') {
      if (*exp == '<' && *(exp+1) == '<') { *exp = TOK_SHL; *(exp+1) = ' '; }
      if (*exp == '>' && *(exp+1) == '>') { *exp = TOK_SHR; *(exp+1) = ' '; }
      if (*exp == '<' && *(exp+1) == '=') { *exp = TOK_LE; *(exp+1) = ' '; }
      if (*exp == '>' && *(exp+1) == '=') { *exp = TOK_GE; *(exp+1) = ' '; }
      if (*exp == '=' && *(exp+1) == '=') { *exp = TOK_EQ; *(exp+1) = ' '; }
      if (*exp == '!' && *(exp+1) == '=') { *exp = TOK_NE; *(exp+1) = ' '; }
      if (*exp == '&' && *(exp+1) == '&') { *exp = TOK_AND; *(exp+1) = ' '; }
      if (*exp == '|' && *(exp+1) == '|') { *exp = TOK_OR; *(exp+1) = ' '; }
    }
    if (prev_is_id) {
      if (*exp == '*') { *exp = TOK_DEREF; }
      if (*exp == '&') { *exp = TOK_ADDR; }
      if (*exp == '(') {
        char *match = find_matching('(', ')', exp, exp+strlen(exp));
        assert(match != 0);
        *exp = TOK_CALL_OPEN;
        *match = TOK_CALL_CLOSED;
      }
    }
    if (is_id(*exp) || *exp == ')') {
      prev_is_id = 1;
    } else {
      prev_is_id = 0;
    }
    exp++;
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

char *find_id(char *s) {
  while (s != 0) {
    if (!is_id(*s)) {
      break;
    }
    s++;
  }
  return s;
}

int decode_number(char *begin, char *end, unsigned int *num) {
  *num = 0;
  int is_decimal = 1;
  int digit_seen = 0;
  if (*begin == '0' && *begin == 'x') {
    begin += 2;
    is_decimal = 0;
  }
  while (1) {
    if (begin == end) {
      if (digit_seen) {
        return 1;
      } else {
        return 0;
      }
    }
    digit_seen = 1;
    if (is_decimal) {
      *num *= 10;
    } else {
      *num *= 16;
    }
    if ('0' <= *begin && *begin <= '9') {
      *num += *begin - '0';
    } else if (!is_decimal && 'a' <= *begin && *begin <= 'f') {
      *num += *begin - 'a' + 10;
    } else {
      return 0;
    }
    begin++;
  }
}

void eval_expr(char *begin, char *end, int addr);

void run_eval_expr(char *begin, char *op, char *end, int addr) {
  if (*op == '=') {
    eval_expr(op+1, end, 0);
    eval_expr(begin, op, 1);
    emit(0x58);  // pop eax
    pop_var();
    emit(0x59);  // pop ecx
    pop_var();
    emit(0x89);  // mov [eax], ecx
    emit(0x08);
    push_var("__temp");
    if (addr) {
      emit(0x50);  // push eax
    } else {
      emit(0x51);  // push ecx
    }
  } else if (*op == TOK_CALL_OPEN) {
    assert(!addr);
    char *match = find_matching(TOK_CALL_OPEN, TOK_CALL_CLOSED, op, end);
    assert(match != 0);
    char *params_begin = op + 1;
    char *params_end = end - 1;
    assert(params_end == match);
    int param_num = 0;
    while (1) {
      if (params_begin == params_end) {
        break;
      }
      int pos = find_char_back(params_begin, params_end, ',');
      if (pos != -1) {
        eval_expr(params_begin + pos + 1, params_end, 0);
        params_end = params_begin + pos;
        param_num++;
      } else {
        eval_expr(params_begin, params_end, 0);
        param_num++;
        break;
      }
    }
    eval_expr(begin, op, 1);
    pop_var();
    emit(0x58);  // pop eax
    emit(0xff);  // call eax
    emit(0xd0);
    emit(0x81);  // add esp, ...
    emit(0xc4);
    emit32(4 * param_num);
    for (int i = 0; i < param_num; i++) {
      pop_var();
    }
    push_var("__temp");
    emit(0x50);  // push eax
  } else if (*op == TOK_DEREF) {
    assert(begin == op);
    eval_expr(op+1, end, 0);
    pop_var();
    emit(0x58);  // pop eax
    if (!addr) {
      emit(0xb8);  // mov eax, [eax]
      emit(0x00);
    }
    push_var("__temp");
    emit(0x50);  // push eax
  } else if (*op == TOK_ADDR) {
    assert(!addr);
    assert(begin == op);
    eval_expr(op+1, end, 1);
  } else if (*op == '!' || *op == '~') {
    assert(!addr);
    assert(begin == op);
    eval_expr(op+1, end, 0);
    pop_var();
    emit(0x58);  // pop eax
    if (*op == '!') {
      emit(0x83);  // cmp eax, 0
      emit(0xf8);
      emit(0x00);
      emit(0x74);  // je 0x9
      emit(0x04);
      emit(0x31);  // xor eax, eax
      emit(0xc0);
      emit(0xeb);  // jmp 0xe
      emit(0x05);
      emit(0xb8);  // mov eax, 1
      emit32(1);
    } else if (*op == '~') {
      emit(0xf7);  // not eax
      emit(0xd0);
    } else {
      assert(0);
    }
    emit(0x50);  // push eax
    push_var("__temp");
  } else {
    assert(!addr);
    eval_expr(op+1, end, 0);
    eval_expr(begin, op, 0);
    emit(0x58);  // pop eax
    pop_var();
    emit(0x59);  // pop ecx
    pop_var();
    if (*op == '+') {
      emit(0x01);  // add eax, ecx
      emit(0xc8);
    } else if (*op == '-') {
      emit(0x29);  // sub eax, ecx
      emit(0xc8);
    } else if (*op == '*') {
      emit(0xf7);  // imul ecx
      emit(0xe9);
    } else if (*op == '/') {
      emit(0x31);  // xor edx, edx
      emit(0xd2);
      emit(0xf7);  // idiv ecx
      emit(0xf9);
    } else if (*op == '%') {
      emit(0x31);  // xor edx, edx
      emit(0xd2);
      emit(0xf7);  // idiv ecx
      emit(0xf9);
      emit(0x89);  // mov eax, edx
      emit(0xd0);
    } else if (*op == TOK_SHL) {
      emit(0xd3);  // shl eax, cl
      emit(0xe0);
    } else if (*op == TOK_SHR) {
      emit(0xd3);  // shr eax, cl
      emit(0xe8);
    } else if (*op == '&') {
      emit(0x21);  // and eax, ecx
      emit(0xc8);
    } else if (*op == '|') {
      emit(0x09);  // or eax, ecx
      emit(0xc8);
    } else if (*op == TOK_AND) {
      emit(0x83);  // cmp eax, 0
      emit(0xf8);
      emit(0x00);
      emit(0x74);  // je 0x11
      emit(0x0c);
      emit(0x83);  // cmp ecx, 0
      emit(0xf9);
      emit(0x00);
      emit(0x74);  // je 0x11
      emit(0x07);
      emit(0xb8);  // mov eax, 1
      emit32(1);
      emit(0xeb);  // jmp 0x13
      emit(0x02);
      emit(0x31);  // xor eax, eax
      emit(0xc0);
    } else if (*op == TOK_OR) {
      emit(0x83);  // cmp eax, 0
      emit(0xf8);
      emit(0x00);
      emit(0x75);  // jne 0xe
      emit(0x09);
      emit(0x83);  // cmp ecx, 0
      emit(0xf9);
      emit(0x00);
      emit(0x75);  // jne 0xe
      emit(0x04);
      emit(0x31);  // xor eax, eax
      emit(0xc0);
      emit(0xeb);  // jmp 0x13
      emit(0x05);
      emit(0xb8);  // mov eax, 1
      emit32(1);
    } else {
      emit(0x39);  // cmp eax, ecx
      emit(0xc8);
      if (*op == TOK_EQ) {
        emit(0x74);  // je 0x8
        emit(0x04);
      } else if (*op == TOK_NE) {
        emit(0x75);  // jne 0x8
        emit(0x04);
      } else if (*op == '<') {
        emit(0x7c);  // jl 0x8
        emit(0x04);
      } else if (*op == TOK_LE) {
        emit(0x7e);  // jle 0x8
        emit(0x04);
      } else if (*op == '>') {
        emit(0x7f);  // jg 0x8
        emit(0x04);
      } else if (*op == TOK_GE) {
        emit(0x7d);  // jge 0x8
        emit(0x04);
      } else {
        assert(0);
      }
      emit(0x31);  // xor eax, eax
      emit(0xc0);
      emit(0xeb);  // jmp 0xd
      emit(0x05);
      emit(0xb8);  // mov eax, 1
      emit32(1);
    }
    push_var("__temp");
    emit(0x50);  // push eax
  }
}

int is_in(char x, char *set) {
  while (1) {
    if (*set == '\0') {
      return 0;
    }
    if (x == *set) {
      return 1;
    }
    set++;
  }
}

int parse_expr(char *begin, char *end, char *pivots, int dir, int addr) {
  if (dir == 0) {
    char *p = begin;
    while (p < end) {
      if (is_in(*p, pivots)) {
        run_eval_expr(begin, p, end, addr);
        return 1;
      } else if (*p == '(') {
        p = find_matching('(', ')', p, end);
        assert(p != 0);
      } else if (*p == '[') {
        p = find_matching('[', ']', p, end);
        assert(p != 0);
      }
      p++;
    }
  } else {
    char *p = end-1;
    while (p >= begin) {
      if (is_in(*p, pivots)) {
        run_eval_expr(begin, p, end, addr);
        return 1;
      } else if (*p == ')') {
        p = find_matching_rev('(', ')', begin, p+1);
        assert(p != 0);
      } else if (*p == ']') {
        p = find_matching_rev('[', ']', begin, p+1);
        assert(p != 0);
      }
      p--;
    }
  }
  return 0;
}

void eval_expr(char *begin, char *end, int addr) {
  if (*begin == '(') {
    char *match = find_matching('(', ')', begin, end);
    if (match == end-1) {
      eval_expr(begin+1, end-1, addr);
    }
  } else if (is_id(*begin) && find_id(begin) == end) {
    if ('0' <= *begin && *begin <= '9') {
      assert(!addr);
      int val;
      int res = decode_number(begin, end, &val);
      assert(res);
      emit(0x68);  // push val
      emit32(val);
      push_var("__temp");
    } else {
      int pos = find_in_stack2(begin, end);
      if (pos != -1) {
        if (addr) {
          emit(0x89);  // mov eax, esp
          emit(0xe0);
          emit(0x05);  // add eax, pos
          emit32(4 * pos);
          emit(0x50);  // push eax
          push_var("__temp");
        } else {
          emit(0x8b);  // mov eax, [esp+pos]
          emit(0x84);
          emit(0x24);
          emit32(4 * pos);
          emit(0x50);  // push eax
          push_var("__temp");
        }
      } else {
        int var_addr = 0;
        if (stage == 1) {
          pos = find_symbol2(begin, end);
          assert(pos != SYMBOL_TABLE_LEN);
          var_addr = symbol_locs[pos];
        }
        if (addr) {
          emit(0x68);  // push addr
          emit32(var_addr);
          push_var("__temp");
        } else {
          emit(0xb8);  // mov eax, addr
          emit32(var_addr);
          emit(0xff);  // push DWORD [eax]
          emit(0x30);
          push_var("__temp");
        }
      }
    }
  } else {
    if (parse_expr(begin, end, "=", 0, addr)) {
    } else if (parse_expr(begin, end, TOKS_OR, 1, addr)) {
    } else if (parse_expr(begin, end, TOKS_AND, 1, addr)) {
    } else if (parse_expr(begin, end, "|", 1, addr)) {
    } else if (parse_expr(begin, end, "&", 1, addr)) {
    } else if (parse_expr(begin, end, TOKS_EQ_NE, 1, addr)) {
    } else if (parse_expr(begin, end, TOKS_LE_GE "<>", 1, addr)) {
    } else if (parse_expr(begin, end, TOKS_SHL_SHR, 1, addr)) {
    } else if (parse_expr(begin, end, "+-", 1, addr)) {
    } else if (parse_expr(begin, end, "*/%", 1, addr)) {
    } else if (parse_expr(begin, end, "!~" TOKS_DEREF_ADDR, 0, addr)) {
    } else if (parse_expr(begin, end, TOKS_CALL_OPEN, 1, addr)) {
    } else {
      assert(0);
    }
  }
}

void compile_expression(char *exp) {
  fix_operations(exp);
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
  char *p;
  if (p = isstrpref("return", begin)) {
    assert(block_depth > 1);
    if (*p == '\0') {
      fprintf(stderr, "Empty return statement\n");
    } else {
      p++;
      fprintf(stderr, "Return statement: %s\n", p);
      compile_expression(p);
      emit(0x58);  // pop eax
      pop_var();
    }
    int exit_stack_depth = stack_depth;
    emit(0x81);  // add esp, ..
    emit(0xc4);
    emit32(4 * (exit_stack_depth - ret_depth));
    emit(0xc3);  // ret
  } else if (p = isstrpref("int", begin)) {
    fprintf(stderr, "Declaration: %s\n", begin);
    char *name = p + 1;
    trimstr(name);
    fprintf(stderr, "  declared name is: %s\n", name);
    if (block_depth == 1) {
      fprintf(stderr, "  this is a top level declaration\n");
      add_symbol(name, current_loc);
      emit32(0);
    } else {
      push_var(name);
      emit(0x83);  // sub esp, 4
      emit(0xec);
      emit(0x04);
    }
  } else {
    assert(block_depth > 1);
    char_op = 0;
    if (p = isstrpref("char", begin)) {
      char_op = 1;
      begin = p + 1;
    }
    fprintf(stderr, "Statement: %s\n", begin);
    compile_expression(begin);
    emit(0x83);  // add esp, 4
    emit(0xc4);
    emit(0x04);
    pop_var();
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
  if (block_depth != 1) {
    int exit_stack_depth = stack_depth;
    pop_to_depth(saved_stack_depth);
    emit(0x81);  // add esp, ..
    emit(0xc4);
    emit32(4 * (exit_stack_depth - saved_stack_depth));
  }
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
    add_symbol(def_begin, current_loc);

    assert(stack_depth == 0);
    char *params_begin = def_begin + open_pos + 1;
    char *params_end = def_begin + closed_pos;
    while (1) {
      if (params_begin == params_end) {
        break;
      }
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
    ret_depth = stack_depth;
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
  symbol_num = 0;
  for (stage = 0; stage < 2; stage++) {
    int fd = open("test.c", O_RDONLY);
    int len = lseek(fd, 0, SEEK_END);
    lseek(fd, 0, SEEK_SET);
    char *src = mmap(0, len, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);

    fix_strings(src, src+len);
    //remove_spaces(src, src+len);
    //print(src, src+len);

    block_depth = 0;
    stack_depth = 0;
    current_loc = 0x100000;
    compile_block(src, src+len);
    assert(block_depth == 0);
    assert(stack_depth == 0);
  }

  return 0;
}
