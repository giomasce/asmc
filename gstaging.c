
#include <stdio.h>

#include "platform.h"

#define MAX_TOKEN_LEN 128
#define STACK_LEN 1024
#define SYMBOL_TABLE_LEN 1024
#define WRITE_LABEL_BUF_LEN 128

#define TEMP_VAR "__temp"

char write_label_buf[WRITE_LABEL_BUF_LEN];

int atoi(char*);
int sprintf(char *str, const char *format, ...);
int find_symbol(const char *name, int *loc, int *arity);
void add_symbol(const char *name, int loc, int arity);
void add_symbol_wrapper(const char *name, int loc, int arity);
int *get_symbol_num();
int *get_stage();
int *get_label_num();
char *get_stack_vars();
int *get_block_depth();
int *get_stack_depth();
int *get_temp_depth();
int *get_token_given_back();
int *get_token_len();
char *get_token_buf();
char *get_buf2();
int *get_read_fd();
int *get_emit_fd();
int *get_current_loc();
int decode_number(const char *operand, unsigned int *num);
int strcmp(const char *s1, const char *s2);
void strcpy(char *d, const char *s);
int strlen(const char *s);
void init_symbols();
void init_g_compiler();

void assert(int cond);
void assert(int cond) {
  if (!cond) {
    platform_panic();
  }
}

void emit(char c);
void emit2(char c) {
  if (*get_stage() == 1) {
    platform_write_char(*get_emit_fd(), c);
  }
  (*get_current_loc())++;
}

void emit32(int x);
void emit322(int x) {
  emit(x);
  emit(x >> 8);
  emit(x >> 16);
  emit(x >> 24);
}

void emit_str(char *x, int len);
void emit_str2(char *x, int len) {
  while (len > 0) {
    emit(*x);
    x++;
    len--;
  }
}

int gen_label();
int gen_label2() {
  return (*get_label_num())++;
}

char *write_label(int id);
char *write_label2(int id) {
  sprintf(write_label_buf, ".%d", id);
  return write_label_buf;
}

int get_symbol(char *name, int *arity);
int get_symbol2(char *name, int *arity) {
  if (*get_stage() == 1 || arity != 0) {
    int loc;
    int res = find_symbol(name, &loc, arity);
    assert(res);
    return loc;
  } else {
    return 0;
  }
}

void push_var(char *var_name, int temp);
void push_var2(char *var_name, int temp) {
  int len = strlen(var_name);
  assert(len > 0);
  assert(len < MAX_TOKEN_LEN);
  assert(*get_stack_depth() < STACK_LEN);
  strcpy(get_stack_vars() + *get_stack_depth() * MAX_TOKEN_LEN, var_name);
  (*get_stack_depth())++;
  if (temp) {
    (*get_temp_depth())++;
  } else {
    assert(*get_temp_depth() == 0);
  }
}

void pop_var(int temp);
void pop_var2(int temp) {
  assert(*get_stack_depth() > 0);
  (*get_stack_depth())--;
  if (temp) {
    assert(*get_temp_depth() > 0);
    (*get_temp_depth())--;
  }
}

int pop_temps();
int pop_temps2() {
  while (*get_temp_depth() > 0) {
    pop_var(1);
  }
}

int find_in_stack(char *var_name);
int find_in_stack2(char *var_name) {
  int i;
  for (i = 0; i < *get_stack_depth(); i++) {
    if (strcmp(var_name, get_stack_vars() + (*get_stack_depth() - 1 - i) * MAX_TOKEN_LEN) == 0) {
      return i;
    }
  }
  return -1;
}

int is_whitespace(char x);
int is_whitespace2(char x) {
  return x == ' ' || x == '\t' || x == '\n';
}

char *get_token();
char *get_token2() {
  if (*get_token_given_back()) {
    *get_token_given_back() = 0;
    return get_token_buf();
  }
  int x;
  *get_token_len() = 0;
  int state = 0;
  while (1) {
    x = platform_read_char(*get_read_fd());
    if (x == -1) {
      break;
    }
    int save_char = 0;
    if (state == 0) {
      if (is_whitespace(x)) {
        if (*get_token_len() > 0) {
          break;
        }
      } else if ((char) x == '#') {
        state = 1;
      } else {
        if ((char) x == '"') {
          state = 2;
        }
        save_char = 1;
      }
    } else if (state == 1) {
      if ((char) x == '\n') {
        state = 0;
        if (*get_token_len() > 0) {
          break;
        }
      }
    } else if (state == 2) {
      if ((char) x == '"') {
        state = 0;
      } else if ((char) x == '\\') {
        state = 3;
      }
      save_char = 1;
    } else if (state == 3) {
      state = 2;
      save_char = 1;
    } else {
      assert(0);
    }
    if (save_char) {
      get_token_buf()[(*get_token_len())++] = (char) x;
    }
  }
  get_token_buf()[*get_token_len()] = '\0';
  return get_token_buf();
}

void give_back_token();
void give_back_token2() {
  assert(!*get_token_given_back());
  *get_token_given_back() = 1;
}

char escaped(char x);
char escaped2(char x) {
  if (x == 'n') { return '\n'; }
  if (x == 't') { return '\t'; }
  if (x == '0') { return '\0'; }
  if (x == '\\') { return '\\'; }
  if (x == '\'') { return '\''; }
  if (x == '"') { return '"'; }
  return 0;
}

void emit_escaped_string(char *s);
void emit_escaped_string2(char *s) {
  assert(*s == '"');
  s++;
  while (1) {
    assert(*s != 0);
    if (*s == '"') {
      s++;
      assert(*s == 0);
      return;
    }
    if (*s == '\\') {
      s++;
      assert(*s != 0);
      emit(escaped(*s));
    } else {
      emit(*s);
    }
    s++;
  }
}

int decode_number_or_char(const char *operand, unsigned int *num);
int decode_number_or_char2(const char *operand, unsigned int *num) {
  if (*operand == '\'') {
    if (operand[1] == '\\') {
      *num = escaped(operand[2]);
      assert(operand[3] == 0);
    } else {
      *num = operand[1];
      assert(operand[2] == 0);
    }
    return 1;
  } else {
    return decode_number(operand, num);
  }
}

int compute_rel(int addr);
int compute_rel2(int addr) {
  return addr - *get_current_loc() - 4;
}

void push_expr(char *tok, int want_addr);
void push_expr2(char *tok, int want_addr) {
  // Try to interpret as a number
  int val;
  if (decode_number_or_char(tok, &val)) {
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
    int arity;
    int loc = get_symbol(tok, &arity);
    if (arity == -2) {
      assert(!want_addr);
    }
    if (want_addr || arity == -2) {
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
        emit32(compute_rel(loc));
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

void parse_block();
void parse_block2() {
  (*get_block_depth())++;
  int saved_stack_depth = *get_stack_depth();
  char *tok = get_token();
  assert(strcmp(tok, "{") == 0);
  while (1) {
    char *tok = get_token();
    //fprintf(stderr, "Parsing token %s\n", tok);
    assert(*tok != '\0');
    if (strcmp(tok, "}") == 0) {
      break;
    } else if (strcmp(tok, ";") == 0) {
      emit_str("\x81\xc4", 2);  // add esp, ...
      emit32(4 * *get_temp_depth());
      pop_temps();
    } else if (strcmp(tok, "ret") == 0) {
      if (*get_temp_depth() > 0) {
        emit(0x58);  // pop eax
        pop_var(1);
      }
      emit_str("\x81\xc4", 2);  // add esp, ..
      emit32(4 * *get_stack_depth());
      emit_str("\x5d\xc3", 2);  // pop ebp; ret
    } else if (strcmp(tok, "if") == 0) {
      char *cond = get_token();
      assert(strcmp(cond, "}") != 0);
      push_expr(cond, 0);
      int else_lab = gen_label();
      pop_var(1);
      emit_str("\x58\x83\xF8\x00\x0F\x84", 6);  // pop eax; cmp eax, 0; je rel
      emit32(compute_rel(get_symbol(write_label(else_lab), 0)));
      parse_block();
      char *else_tok = get_token();
      if (strcmp(else_tok, "else") == 0) {
        int fi_lab = gen_label();
        emit(0xe9);  // jmp rel
        emit32(compute_rel(get_symbol(write_label(fi_lab), 0)));
        add_symbol_wrapper(write_label(else_lab), *get_current_loc(), -1);
        parse_block();
        add_symbol_wrapper(write_label(fi_lab), *get_current_loc(), -1);
      } else {
        add_symbol_wrapper(write_label(else_lab), *get_current_loc(), -1);
        give_back_token();
      }
    } else if (strcmp(tok, "while") == 0) {
      char *cond = get_token();
      assert(strcmp(cond, "}") != 0);
      int restart_lab = gen_label();
      int end_lab = gen_label();
      add_symbol_wrapper(write_label(restart_lab), *get_current_loc(), -1);
      push_expr(cond, 0);
      pop_var(1);
      emit_str("\x58\x83\xF8\x00\x0F\x84", 6);  // pop eax; cmp eax, 0; je rel
      emit32(compute_rel(get_symbol(write_label(end_lab), 0)));
      parse_block();
      emit(0xe9);  // jmp rel
      emit32(compute_rel(get_symbol(write_label(restart_lab), 0)));
      add_symbol_wrapper(write_label(end_lab), *get_current_loc(), -1);
    } else if (*tok == '$') {
      char *name = tok + 1;
      assert(*name != '\0');
      push_var(name, 0);
      emit_str("\x83\xec\x04", 3);  // sub esp, 4
    } else if (*tok == '"') {
      int str_lab = gen_label();
      int jmp_lab = gen_label();
      emit(0xe9);  // jmp rel
      emit32(compute_rel(get_symbol(write_label(jmp_lab), 0)));
      add_symbol_wrapper(write_label(str_lab), *get_current_loc(), -1);
      emit_escaped_string(tok);
      add_symbol_wrapper(write_label(jmp_lab), *get_current_loc(), -1);
      push_var(TEMP_VAR, 1);
      emit(0x68);  // push val
      emit32(get_symbol(write_label(str_lab), 0));
    } else {
      // Check if we want the address
      int want_addr = 0;
      if (*tok == '&') {
        tok++;
        want_addr = 1;
      }
      push_expr(tok, want_addr);
    }
    //fprintf(stderr, "Stack depth: %d; temp depth: %d; block depth: %d\n", *get_stack_depth(), *get_temp_depth(), *get_block_depth());
  }
  emit_str("\x81\xc4", 2);  // add esp, ..
  assert(*get_stack_depth() >= saved_stack_depth);
  emit32(4 * (*get_stack_depth() - saved_stack_depth));
  *get_stack_depth() = saved_stack_depth;
  (*get_block_depth())--;
}

int decode_number_or_symbol(char *str) {
  int val;
  int res = decode_number_or_char(str, &val);
  if (res) {
    return val;
  }
  int arity;
  return get_symbol(str, &arity);
}

void parse() {
  while (1) {
    char *tok = get_token();
    if (*tok == 0) {
      break;
    }
    if (strcmp(tok, "fun") == 0) {
      char *name = get_token();
      strcpy(get_buf2(), name);
      name = get_buf2();
      char *arity_str = get_token();
      int arity = atoi(arity_str);
      add_symbol_wrapper(name, *get_current_loc(), arity);
      emit_str("\x55\x89\xe5", 3);  // push ebp; mov ebp, esp
      parse_block();
      emit_str("\x5d\xc3", 2);  // pop ebp; ret
    } else if (strcmp(tok, "const") == 0) {
      char *name = get_token();
      strcpy(get_buf2(), name);
      name = get_buf2();
      char *val_str = get_token();
      int val = decode_number_or_symbol(val_str);
      add_symbol_wrapper(name, val, -2);
    } else if (*tok == '$') {
      char *name = tok + 1;
      assert(*name != '\0');
      add_symbol_wrapper(name, *get_current_loc(), -1);
      emit32(0);
    } else if (*tok == '%') {
      char *name = tok + 1;
      add_symbol_wrapper(name, *get_current_loc(), -1);
      char *len_str = get_token();
      int len = decode_number_or_symbol(len_str);
      while (len > 0) {
        emit(0);
        len--;
      }
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
  add_symbol_wrapper("=", *get_current_loc(), 2);
  emit_str("\x8B\x44\x24\x04\x8B\x4C\x24\x08\x89\x01\xC3", 11);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  8b 44 85 08             mov    eax,DWORD PTR [ebp+eax*4+0x8]
    8:  c3                      ret
   */
  add_symbol_wrapper("param", *get_current_loc(), 1);
  emit_str("\x8B\x44\x24\x04\x8B\x44\x85\x08\xC3", 9);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  03 44 24 08             add    eax,DWORD PTR [esp+0x8]
    8:  c3                      ret
  */
  add_symbol_wrapper("+", *get_current_loc(), 2);
  emit_str("\x8B\x44\x24\x04\x03\x44\x24\x08\xC3", 9);

  /*
    0:  8b 44 24 04             mov    eax,DWORD PTR [esp+0x4]
    4:  2b 44 24 08             sub    eax,DWORD PTR [esp+0x8]
    8:  c3                      ret
  */
  add_symbol_wrapper("-", *get_current_loc(), 2);
  emit_str("\x8B\x44\x24\x04\x2b\x44\x24\x08\xC3", 9);
}

int main() {
  init_symbols();
  init_g_compiler();
  *get_emit_fd() = 1;
  *get_read_fd() = platform_open_file("test.g");
  *get_block_depth() = 0;
  *get_stack_depth() = 0;
  *get_symbol_num() = 0;

  for (*get_stage() = 0; *get_stage() < 2; (*get_stage())++) {
    platform_reset_file(*get_read_fd());
    *get_label_num() = 0;
    *get_current_loc() = 0x100000;
    emit_preamble();
    parse();
    assert(*get_block_depth() == 0);
    assert(*get_stack_depth() == 0);
  }

  return 0;
}
