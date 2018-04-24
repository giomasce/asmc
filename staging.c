
#include "platform.h"

#define INPUT_BUF_LEN 1024
#define MAX_SYMBOL_NAME_LEN 128
#define SYMBOL_TABLE_LEN 1024

typedef void (*opcode_func)(int, char*);

char *get_input_buf();
char *get_symbol_names();
int *get_symbol_num();
int *get_symbol_loc();
int *get_current_loc();
int *get_stage();

char *get_opcode_names();
opcode_func *get_opcode_funcs();
int *get_rm32_opcode();
int *get_imm32_opcode();
int *get_rm8r8_opcode();
int *get_rm32r32_opcode();
int *get_r8rm8_opcode();
int *get_r32rm32_opcode();
int *get_rm8imm8_opcode();
int *get_rm32imm32_opcode();

int line;

void assert(int cond);
void assert2(int cond) {
  if (!cond) {
    platform_panic();
  }
}

int readline(int fd, unsigned char *buf, int len);
int readline2(int fd, unsigned char *buf, int len) {
  while (len > 0) {
    int c = platform_read_char(fd);
    if (c == '\n' || c == -1) {
      *buf = '\0';
      return c == -1;
    } else {
      *buf = (unsigned char) c;
    }
    buf++;
    len--;
  }
  platform_panic();
}

void trimstr(char *buf);
void trimstr2(char *buf) {
  char *write_buf = buf;
  char *read_buf = buf;
  while (*read_buf == ' ' || *read_buf == '\t') {
    read_buf++;
  }
  while (*read_buf != '\0') {
    *write_buf = *read_buf;
    write_buf++;
    read_buf++;
  }
  *write_buf = '\0';
  write_buf--;
  while (write_buf >= buf && (*write_buf == ' ' || *write_buf == '\t')) {
    *write_buf = '\0';
    write_buf--;
  }
}

void remove_spaces(char *buf);
void remove_spaces2(char *buf) {
  char *read_buf = buf;
  while (1) {
    if (*read_buf == '\0') {
      *buf = '\0';
      return;
    }
    if (*read_buf == ' ' || *read_buf == '\t') {
      read_buf++;
    } else {
      *buf = *read_buf;
      buf++;
      read_buf++;
    }
  }
}

int strcmp(const char *s1, const char *s2);
int strcmp2(const char *s1, const char *s2) {
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

int isstrpref(const char *s1, const char *s2);
int isstrpref2(const char *s1, const char *s2) {
  while (1) {
    if (*s1 == '\0') {
      return 1;
    }
    if (*s1 != *s2) {
      return 0;
    }
    s1++;
    s2++;
  }
}

void strcpy(char *d, const char *s);
void strcpy2(char *d, const char *s) {
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
int strlen2(const char *s) {
  const char *s2 = s;
  while (*s2 != '\0') {
    s2++;
  }
  return s2 - s;
}

int find_char(char *s, char c);
int find_char2(char *s, char c) {
  char *s2 = s;
  while (1) {
    if (*s2 == c) {
      return s2 - s;
    }
    if (*s2 == '\0') {
      return -1;
    }
    s2++;
  }
}

int find_symbol(const char *name);
int find_symbol2(const char *name) {
  int i;
  for (i = 0; i < *get_symbol_num(); i++) {
    if (strcmp(name, get_symbol_names() + i * MAX_SYMBOL_NAME_LEN) == 0) {
      break;
    }
  }
  if (i == *get_symbol_num()) {
    i = SYMBOL_TABLE_LEN;
  }
  return i;
}

void add_symbol(const char *name, int loc);
void add_symbol2(const char *name, int loc) {
  int len = strlen(name);
  assert(len > 0);
  assert(len < MAX_SYMBOL_NAME_LEN);
  int stage = *get_stage();
  if (stage == 0) {
    int symbol_num = *get_symbol_num();
    assert(find_symbol(name) == SYMBOL_TABLE_LEN);
    assert(symbol_num < SYMBOL_TABLE_LEN);
    get_symbol_loc()[symbol_num] = loc;
    strcpy(get_symbol_names() + symbol_num * MAX_SYMBOL_NAME_LEN, name);
    *get_symbol_num() = symbol_num + 1;
  } else if (stage == 1) {
    int idx = find_symbol(name);
    assert(idx < *get_symbol_num());
    assert(get_symbol_loc()[idx] == loc);
  } else {
    platform_panic();
  }
}

int decode_reg32(char *reg);
int decode_reg322(char *reg) {
  if (strcmp(reg, "eax") == 0) {
    return 0;
  } else if (strcmp(reg, "ecx") == 0) {
    return 1;
  } else if (strcmp(reg, "edx") == 0) {
    return 2;
  } else if (strcmp(reg, "ebx") == 0) {
    return 3;
  } else if (strcmp(reg, "esp") == 0) {
    return 4;
  } else if (strcmp(reg, "ebp") == 0) {
    return 5;
  } else if (strcmp(reg, "esi") == 0) {
    return 6;
  } else if (strcmp(reg, "edi") == 0) {
    return 7;
  } else {
    return -1;
  }
}

int decode_reg8(char *reg);
int decode_reg82(char *reg) {
  if (strcmp(reg, "al") == 0) {
    return 0;
  } else if (strcmp(reg, "cl") == 0) {
    return 1;
  } else if (strcmp(reg, "dl") == 0) {
    return 2;
  } else if (strcmp(reg, "bl") == 0) {
    return 3;
  } else if (strcmp(reg, "ah") == 0) {
    return 4;
  } else if (strcmp(reg, "ch") == 0) {
    return 5;
  } else if (strcmp(reg, "dh") == 0) {
    return 6;
  } else if (strcmp(reg, "bh") == 0) {
    return 7;
  } else {
    return -1;
  }
}

int decode_number(const char *operand, unsigned int *num);
int decode_number2(const char *operand, unsigned int *num) {
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

int decode_number_or_symbol(const char *operand, unsigned int *num, int force_symbol);
int decode_number_or_symbol2(const char *operand, unsigned int *num, int force_symbol) {
  int res = decode_number(operand, num);
  if (res) {
    return 1;
  }
  int stage = *get_stage();
  if (stage == 1 || force_symbol) {
    int idx = find_symbol(operand);
    if (idx < SYMBOL_TABLE_LEN) {
      *num = get_symbol_loc()[idx];
      return 1;
    } else {
      return 0;
    }
  } else if (stage == 0) {
    *num = 0;
    return 1;
  } else {
    platform_panic();
  }
}

int decode_operand(char *operand, int *is_direct, int *reg, int *disp, int *is8, int *is32);
int decode_operand2(char *operand, int *is_direct, int *reg, int *disp, int *is8, int *is32) {
  remove_spaces(operand);
  *is8 = 0;
  *is32 = 0;
  if (isstrpref("BYTE", operand)) {
    operand += 4;
    *is8 = 1;
  }
  if (isstrpref("DWORD", operand)) {
    operand += 5;
    *is32 = 1;
  }
  assert(!*is8 || !*is32);
  if (operand[0] == '[') {
    *is_direct = 0;
    operand++;
    int plus_pos = find_char(operand, '+');
    if (plus_pos == -1) {
      *disp = 0;
      int closed_pos = find_char(operand, ']');
      if (closed_pos == -1) {
        return 0;
      } else {
        if (operand[closed_pos+1] != '\0') {
          return 0;
        } else {
          operand[closed_pos] = '\0';
          *reg = decode_reg32(operand);
          return *reg != -1;
        }
      }
    } else {
      operand[plus_pos] = '\0';
      *reg = decode_reg32(operand);
      if (*reg == -1) {
        return 0;
      } else {
        operand = operand + plus_pos + 1;
        int closed_pos = find_char(operand, ']');
        if (closed_pos == -1) {
          return 0;
        } else {
          if (operand[closed_pos+1] != '\0') {
            return 0;
          } else {
            operand[closed_pos] = '\0';
            return decode_number_or_symbol(operand, disp, 0);
          }
        }
      }
    }
  } else {
    *is_direct = 1;
    if (*is32 || *is8) {
      return 0;
    }
    *reg = decode_reg32(operand);
    if (*reg != -1) {
      *is32 = 1;
      assert(!*is8);
      return 1;
    } else {
      *reg = decode_reg8(operand);
      if (*reg != -1) {
        *is8 = 1;
        assert(!*is32);
        return 1;
      } else {
        return 0;
      }
    }
  }
}

void emit(char c);
void emit2(char c) {
  int stage = *get_stage();
  if (stage == 1) {
    platform_write_char(1, c);
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

int process_bss_line(char *opcode, char *data);
int process_bss_line2(char *opcode, char *data) {
  if (strcmp(opcode, "resb") == 0) {
    int val;
    int res = decode_number_or_symbol(data, &val, 1);
    if (!res) {
      platform_panic();
    }
    int i;
    for (i = 0; i < val; i++) {
      emit(0);
    }
  } else if (strcmp(opcode, "resd") == 0) {
    int val;
    int res = decode_number_or_symbol(data, &val, 1);
    if (!res) {
      platform_panic();
    }
    int i;
    for (i = 0; i < val; i++) {
      emit32(0);
    }
  } else {
    return 0;
  }
  return 1;
}

int process_data_line(char *opcode, char *data);
int process_data_line2(char *opcode, char *data) {
  if (strcmp(opcode, "db") == 0) {
    if (data[0] == '\'') {
      int len = strlen(data);
      assert(len >= 2);
      assert(data[len-1] == '\'');
      data[len-1] = '\0';
      data++;
      for ( ; *data != '\0'; data++) {
        emit(*data);
      }
    } else {
      int val;
      int res = decode_number_or_symbol(data, &val, 0);
      if (!res) {
        platform_panic();
      }
      emit(val);
    }
  } else if (strcmp(opcode, "dd") == 0) {
    int val;
    int res = decode_number_or_symbol(data, &val, 0);
    if (!res) {
      platform_panic();
    }
    emit32(val);
  } else {
    return 0;
  }
  return 1;
}

int emit_modrm(int mod, int reg, int rm);
int emit_modrm2(int mod, int reg, int rm) {
  assert(mod == mod & 0x3);
  assert(reg == reg & 0x7);
  assert(rm == rm & 0x7);
  // The only two supported mode are a direct register, or an indirect
  // register + disp32
  assert(mod == 2 || mod == 3);
  emit((mod << 6) + (reg << 3) + rm);
  // In the particular case of ESP used as indirect base, a SIB is
  // needed
  if (mod == 2 && rm == 4) {
    emit(0x24);
  }
}

enum {
  OP_PUSH = 0,
  OP_POP,
  OP_ADD,
  OP_SUB,
  OP_MOV,
  OP_CMP,
  OP_AND,
  OP_OR,
  OP_JMP,
  OP_CALL,
  OP_JE,
  OP_JNE,
  OP_JA,
  OP_JNA,
  OP_JAE,
  OP_JNAE,
  OP_JB,
  OP_JNB,
  OP_JBE,
  OP_JNBE,
  OP_JG,
  OP_JNG,
  OP_JGE,
  OP_JNGE,
  OP_JL,
  OP_JNL,
  OP_JLE,
  OP_JNLE,
  OP_MUL,
  OP_IMUL,
  OP_INT,
  OP_RET,
};

void emit_helper(int opcode_data, int is_direct, int reg, int rm, int disp);
void emit_helper2(int opcode_data, int is_direct, int reg, int rm, int disp) {
  int opcode = opcode_data & 0xff;
  int opcode2 = (opcode_data >> 8) & 0xff;
  int has_opcode2 = opcode_data & 0xff0000;
  if (reg == -1) {
    reg = opcode2;
  }
  int mod;
  if (is_direct) {
    mod = 3;
  } else {
    mod = 2;
  }
  int has_modrm = (rm != -1);

  assert(opcode != 0xf0);

  emit(opcode);
  if (has_opcode2) {
    emit(opcode2);
  }
  if (has_modrm) {
    emit_modrm(mod, reg, rm);
  }
  if (!is_direct) {
    emit32(disp);
  }
}

void process_jmp_like(int op, char *data);
void process_jmp_like2(int op, char *data) {
  int is_direct, reg, disp, is8, is32;
  int res = decode_operand(data, &is_direct, &reg, &disp, &is8, &is32);
  if (res) {
    assert(!is8);
    // r/m32
    int opcode_data = get_rm32_opcode()[op];
    emit_helper(opcode_data, is_direct, -1, reg, disp);
  } else {
    // rel32
    int opcode_data = get_imm32_opcode()[op];
    emit_helper(opcode_data, 1, -1, -1, 0);
    int rel;
    int res = decode_number_or_symbol(data, &rel, 0);
    if (!res) {
      platform_panic();
    }
    int current_loc = *get_current_loc();
    rel = rel - current_loc - 4;
    emit32(rel);
  }
}

void process_push_like(int op, char *data);
void process_push_like2(int op, char *data) {
  int is_direct, reg, disp, is8, is32;
  int res = decode_operand(data, &is_direct, &reg, &disp, &is8, &is32);
  if (res) {
    assert(!is8);
    // r/m32
    int opcode_data = get_rm32_opcode()[op];
    emit_helper(opcode_data, is_direct, -1, reg, disp);
  } else {
    assert(op == OP_PUSH);
    int imm;
    int res = decode_number_or_symbol(data, &imm, 0);
    if (res) {
      emit(0x68);
      emit32(imm);
    } else {
      platform_panic();
    }
  }
}

void process_add_like(int op, char *data);
void process_add_like2(int op, char *data) {
  int comma_pos = find_char(data, ',');
  if (comma_pos == -1) {
    platform_panic();
  }
  data[comma_pos] = '\0';
  char *dest = data;
  char *src = data + comma_pos + 1;
  int dest_is_direct, dest_reg, dest_disp, dest_is8, dest_is32;
  int src_is_direct, src_reg, src_disp, src_is8, src_is32;
  int dest_res = decode_operand(dest, &dest_is_direct, &dest_reg, &dest_disp, &dest_is8, &dest_is32);
  if (!dest_res) {
    platform_panic();
  }
  int src_res = decode_operand(src, &src_is_direct, &src_reg, &src_disp, &src_is8, &src_is32);
  if (src_res) {
    // First we decide whether this is an 8 or 32 bits operation
    int is8 = dest_is8 || src_is8;
    int is32 = dest_is32 || src_is32;
    assert(is8 || is32);
    assert(!is8 || !is32);
    if (dest_is_direct) {
      if (is8) {
        // r8, r/m8
        int opcode_data = get_r8rm8_opcode()[op];
        emit_helper(opcode_data, src_is_direct, dest_reg, src_reg, src_disp);
      } else {
        // r32, r/m32
        int opcode_data = get_r32rm32_opcode()[op];
        emit_helper(opcode_data, src_is_direct, dest_reg, src_reg, src_disp);
      }
    } else {
      if (src_is_direct) {
        if (is8) {
          // r/m8, r8
          int opcode_data = get_rm8r8_opcode()[op];
          emit_helper(opcode_data, 0, src_reg, dest_reg, dest_disp);
        } else {
          // r/m32, r32
          int opcode_data = get_rm32r32_opcode()[op];
          emit_helper(opcode_data, 0, src_reg, dest_reg, dest_disp);
        }
      } else {
        platform_panic();
      }
    }
  } else {
    assert(dest_is8 || dest_is32);
    int imm;
    int res = decode_number_or_symbol(src, &imm, 0);
    if (res) {
      if (dest_is8) {
        // r/m8, imm8
        int opcode_data = get_rm8imm8_opcode()[op];
        emit_helper(opcode_data, dest_is_direct, -1, dest_reg, dest_disp);
        emit(imm);
      } else {
        // r/m32, imm32
        int opcode_data = get_rm32imm32_opcode()[op];
        emit_helper(opcode_data, dest_is_direct, -1, dest_reg, dest_disp);
        emit32(imm);
      }
    } else {
      platform_panic();
    }
  }
}

void process_int(int op, char *data);
void process_int2(int op, char *data) {
  assert(op == OP_INT);
  int imm;
  int res = decode_number_or_symbol(data, &imm, 0);
  if (!res) {
    platform_panic();
  }
  if (res < 0 || res >= 0x100) {
    platform_panic();
  }
  emit(0xcd);
  emit(imm);
}

void process_ret(int op, char *data);
void process_ret2(int op, char *data) {
  assert(op == OP_RET);
  assert(data[0] == '\0');
  emit(0xc3);
}

int process_text_line(char *opcode, char *data);
int process_text_line2(char *opcode, char *data) {
  char *names = get_opcode_names();
  int idx = 0;
  while (1) {
    if (*names == '\0') {
      return 0;
    }
    if (strcmp(names, opcode) == 0) {
      get_opcode_funcs()[idx](idx, data);
      return 1;
    }
    int len = strlen(names);
    names += len + 1;
    idx++;
  }
}

int process_directive_line(char *opcode, char *data);
int process_directive_line2(char *opcode, char *data) {
  if (strcmp(opcode, "section") == 0) {
  } else if (strcmp(opcode, "global") == 0) {
  } else if (strcmp(opcode, "align") == 0) {
  } else if (strcmp(opcode, "extern") == 0) {
    add_symbol(data, 0);
  } else {
    return 0;
  }
  return 1;
}

int process_equ_line(char *opcode, char *data);
int process_equ_line2(char *opcode, char *data) {
  int data_space_pos = find_char(data, ' ');
  if (data_space_pos >= 0) {
    data[data_space_pos] = '\0';
    if (strcmp(data, "equ") == 0) {
      char *val_str = data + data_space_pos + 1;
      trimstr(val_str);
      int val;
      int res = decode_number_or_symbol(val_str, &val, 0);
      if (res) {
        add_symbol(opcode, val);
      } else {
        platform_panic();
      }
    } else {
      return 0;
    }
  } else {
    return 0;
  }
  return 1;
}

void process_line(char *line) {
  char *opcode = line;
  int opcode_len = find_char(line, ' ');
  char *data;
  int data_len;
  if (opcode_len == -1) {
    data = line + strlen(line);
  } else {
    opcode[opcode_len] = '\0';
    data = line + opcode_len + 1;
    trimstr(data);
  }

  int processed = 0;
  if (!processed) {
    processed = process_directive_line(opcode, data);
  }
  if (!processed) {
    processed = process_bss_line(opcode, data);
  }
  if (!processed) {
    processed = process_text_line(opcode, data);
  }
  if (!processed) {
    processed = process_data_line(opcode, data);
  }
  if (!processed) {
    processed = process_equ_line(opcode, data);
  }
  if (!processed) {
    platform_panic();
  }
}

void assemble_file() {
  *get_symbol_num() = 0;
  int fd_in = platform_open_file("full.asm");
  for (*get_stage() = 0; *get_stage() < 2; (*get_stage())++) {
    platform_reset_file(fd_in);
    line = 0;
    *get_current_loc() = 0x100000;
    while (1) {
      char *input_buf = get_input_buf();
      int finished = readline(fd_in, input_buf, INPUT_BUF_LEN);
      if (1) {
        platform_log(2, "Decoding line: ");
        platform_log(2, input_buf);
        platform_log(2, "\n");
      }
      int semicolon_pos = find_char(input_buf, ';');
      if (semicolon_pos != -1) {
        input_buf[semicolon_pos] = '\0';
      }
      trimstr(input_buf);
      int len = strlen(input_buf);
      if (finished && len == 0) {
        break;
      }
      if (len == 0) {
        line++;
        continue;
      }
      if (input_buf[len-1] == ':') {
        input_buf[len-1] = '\0';
        add_symbol(input_buf, *get_current_loc());
      } else {
        process_line(input_buf);
      }
      line++;
    }
  }
}
