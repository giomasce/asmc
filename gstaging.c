
#include "platform.h"

#define MAX_TOKEN_LEN 128
#define STACK_LEN 1024
#define SYMBOL_TABLE_LEN 1024

#define TEMP_VAR "__temp"

int read_fd;

int token_len;
char token_buf[MAX_TOKEN_LEN];

int block_depth;
int stack_depth;
int temp_depth;
int current_loc;
int ret_depth;
int symbol_num;
int stage;
int label_num;

char stack_vars[MAX_TOKEN_LEN * STACK_LEN];

char symbol_names[MAX_TOKEN_LEN * SYMBOL_TABLE_LEN];
int symbol_locs[SYMBOL_TABLE_LEN];
int symbol_arities[SYMBOL_TABLE_LEN];

int atoi(char*);

void assert(int cond);
void assert(int cond) {
  if (!cond) {
    platform_panic();
  }
}

void strcpy(char *d, const char *s);
void strcpy(char *d, const char *s) {
  while (1) {
    *d = *s;
    if (*s == '\0') {
      return;
    }
    d++;
    s++;
  }
}

int strlen(const char *s);
int strlen(const char *s) {
  const char *s2 = s;
  while (*s2 != '\0') {
    s2++;
  }
  return s2 - s;
}

int strcmp(const char *s1, const char *s2);
int strcmp(const char *s1, const char *s2) {
  while (1) {
    if (*s1 < *s2) {
      return -1;
    }
    if (*s1 > *s2) {
      return 1;
    }
    if (*s1 == '\0') {
      return 0;
    }
    s1++;
    s2++;
  }
}

void emit(char c);
void emit(char c) {
  if (stage == 1) {
    platform_write_char(1, c);
  }
  current_loc++;
}

void emit32(int x);
void emit32(int x) {
  emit(x);
  emit(x >> 8);
  emit(x >> 16);
  emit(x >> 24);
}

void emit_str(char *x, int len) {
  while (len > 0) {
    emit(*x);
    x++;
    len--;
  }
}

int find_symbol(char *name) {
  int i;
  for (i = 0; i < symbol_num; i++) {
    if (strcmp(name, symbol_names + i * MAX_TOKEN_LEN) == 0) {
      break;
    }
  }
  if (i == symbol_num) {
    i = SYMBOL_TABLE_LEN;
  }
  return i;
}

void add_symbol(char *name, int loc, int arity) {
  int len = strlen(name);
  assert(len > 0);
  assert(len < MAX_TOKEN_LEN);
  if (stage == 0) {
    assert(find_symbol(name) == SYMBOL_TABLE_LEN);
    assert(symbol_num < SYMBOL_TABLE_LEN);
    symbol_locs[symbol_num] = loc;
    symbol_arities[symbol_num] = arity;
    strcpy(symbol_names + symbol_num * MAX_TOKEN_LEN, name);
    symbol_num = symbol_num + 1;
  } else if (stage == 1) {
    int idx = find_symbol(name);
    assert(idx < symbol_num);
    assert(symbol_locs[idx] == loc);
    assert(symbol_arities[idx] == arity);
  } else {
    assert(0);
  }
}

void push_var(char *var_name, int temp) {
  int len = strlen(var_name);
  assert(len > 0);
  assert(len < MAX_TOKEN_LEN);
  assert(stack_depth < STACK_LEN);
  strcpy(stack_vars + stack_depth * MAX_TOKEN_LEN, var_name);
  stack_depth++;
  if (temp) {
    temp_depth++;
  } else {
    assert(temp_depth == 0);
  }
}

void pop_var(int temp) {
  assert(stack_depth > 0);
  stack_depth--;
  if (temp) {
    assert(temp_depth > 0);
    temp_depth--;
  }
}

int pop_temps() {
  while (temp_depth > 0) {
    pop_var(1);
  }
}

int find_in_stack(char *var_name) {
  int i;
  for (i = 0; i < stack_depth; i++) {
    if (strcmp(var_name, stack_vars + (stack_depth - 1 - i) * MAX_TOKEN_LEN) == 0) {
      return i;
    }
  }
  return -1;
}

int is_whitespace(char x) {
  return x == ' ' || x == '\t' || x == '\n';
}

char *get_token() {
  int x;
  token_len = 0;
  while (1) {
    x = platform_read_char(read_fd);
    if (x == -1 || is_whitespace(x) && token_len > 0) {
      break;
    }
    if (!is_whitespace(x)) {
      token_buf[token_len++] = (char) x;
    }
  }
  token_buf[token_len] = '\0';
  return token_buf;
}

void expect(char *x) {
  char *tok = get_token();
  assert(strcmp(tok, x) == 0);
}

int decode_number(const char *operand, unsigned int *num);
int decode_number(const char *operand, unsigned int *num) {
  *num = 0;
  int is_decimal = 1;
  int digit_seen = 0;
  if (operand[0] == '0' && operand[1] == 'x') {
    operand += 2;
    is_decimal = 0;
  }
  while (1) {
    if (operand[0] == '\0') {
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
    if ('0' <= operand[0] && operand[0] <= '9') {
      *num += operand[0] - '0';
    } else if (!is_decimal && 'a' <= operand[0] && operand[0] <= 'f') {
      *num += operand[0] - 'a' + 10;
    } else {
      return 0;
    }
    operand++;
  }
}

void push_expr(char *tok, int want_addr) {
  // Try to interpret as a number
  int val;
  if (decode_number(tok, &val)) {
    assert(!want_addr);
    push_var(TEMP_VAR, 1);
    emit(0x68);  // push val
    emit32(val);
    return;
  }
  // Look for the name in the stack
  int pos = find_in_stack(tok);
  if (pos != -1) {
    if (want_addr) {
      push_var(TEMP_VAR, 1);
      emit_str("\x8d\x84\x24", 3);  // lea eax, [esp+pos]
      emit32(4 * pos);
      emit(0x50);  // push eax
    } else {
      push_var(TEMP_VAR, 1);
      emit_str("\xff\xb4\x24", 3);  // push [esp+pos]
      emit32(4 * pos);
    }
  } else {
    pos = find_symbol(tok);
    assert(pos != SYMBOL_TABLE_LEN);
    int loc = symbol_locs[pos];
    int arity = symbol_arities[pos];
    if (want_addr) {
      push_var(TEMP_VAR, 1);
      emit(0x68);  // push loc
      emit32(loc);
    } else {
      if (arity == -1) {
        push_var(TEMP_VAR, 1);
        emit(0xb8);  // mov eax, loc
        emit32(loc);
        emit_str("\xff\x30", 2);  // push [eax]
      } else {
        emit(0xe8);  // call rel
        int rel = loc - 4 - current_loc;
        emit32(rel);
        emit_str("\x81\xc4", 2);  // add esp, ...
        emit32(4 * arity);
        while (arity > 0) {
          pop_var(1);
          arity--;
        }
        push_var(TEMP_VAR, 1);
        emit(0x50);  // push eax
      }
    }
  }
}

void parse_block() {
  block_depth++;
  int saved_stack_depth = stack_depth;
  expect("{");
  while (1) {
    char *tok = get_token();
    assert(*tok != '\0');
    if (strcmp(tok, "}") == 0) {
      break;
    } else if (strcmp(tok, ";") == 0) {
      emit_str("\x81\xc4", 2);  // add esp, ...
      emit32(4 * temp_depth);
      pop_temps();
    } else if (strcmp(tok, "ret") == 0) {
      if (temp_depth > 0) {
        emit(0x58);  // pop eax
        pop_var(1);
      }
      emit_str("\x81\xc4", 2);  // add esp, ..
      emit32(4 * stack_depth);
      emit_str("\x5d\xc3", 2);  // pop ebp; ret
    } else if (*tok == '$') {
      char *name = tok + 1;
      push_var(name, 0);
      emit_str("\x83\xec\x04", 3);  // sub esp, 4
    } else {
      // Check if we want the address
      int want_addr = 0;
      if (*tok == '&') {
        tok++;
        want_addr = 1;
      }
      push_expr(tok, want_addr);
    }
  }
  emit_str("\x81\xc4", 2);  // add esp, ..
  assert(stack_depth >= saved_stack_depth);
  emit32(4 * (stack_depth - saved_stack_depth));
  stack_depth = saved_stack_depth;
  block_depth--;
}

void parse() {
  while (1) {
    char *tok = get_token();
    if (*tok == 0) {
      break;
    }
    if (strcmp(tok, "fun") == 0) {
      char *arity_str = get_token();
      int arity = atoi(arity_str);
      char *name = get_token();
      add_symbol(name, current_loc, arity);
      emit_str("\x55\x89\xe5", 3);  // push ebp; mov ebp, esp
      parse_block();
      emit_str("\x5d\xc3", 2);  // pop ebp; ret
    } else {
      assert(0);
    }
  }
}

void emit_preamble() {
  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  8b 4c 24 08             mov    ecx,DWORD PTR [esp+0x8]
    8:  89 01                   mov    DWORD PTR [ecx],eax
    a:  c3                      ret
  */
  add_symbol("=", current_loc, 2);
  emit_str("\x8B\x44\x24\x04\x8B\x4C\x24\x08\x89\x01\xC3", 11);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  8b 44 85 08             mov    eax,DWORD PTR [ebp+eax*4+0x8]
    8:  c3                      ret
   */
  add_symbol("param", current_loc, 1);
  emit_str("\x8B\x44\x24\x04\x8B\x44\x85\x08\xC3", 9);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  03 44 24 08             add    eax,DWORD PTR [esp+0x8]
    8:  c3                      ret
  */
  add_symbol("+", current_loc, 2);
  emit_str("\x8B\x44\x24\x04\x03\x44\x24\x08\xC3", 9);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  2b 44 24 08             sub    eax,DWORD PTR [esp+0x8]
    8:  c3                      ret
  */
  add_symbol("-", current_loc, 2);
  emit_str("\x8B\x44\x24\x04\x2b\x44\x24\x08\xC3", 9);
}

int main() {
  read_fd = platform_open_file("test.g");
  block_depth = 0;
  stack_depth = 0;
  symbol_num = 0;

  for (stage = 0; stage < 2; stage++) {
    platform_reset_file(read_fd);
    label_num = 0;
    current_loc = 0x100000;
    emit_preamble();
    parse();
    assert(block_depth == 0);
    assert(stack_depth == 0);
  }

  return 0;
}
