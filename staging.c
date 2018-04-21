
#include "platform.h"

#define INPUT_BUF_LEN 1024
#define MAX_SYMBOL_NAME_LEN 128
#define SYMBOL_TABLE_LEN 1024

char *get_input_buf();
char *get_symbol_names();
int *get_symbol_num();
int *get_symbol_loc();
char *get_current_section();
int *get_current_loc();
int *get_stage();

void assert(int cond);/* {
  if (!cond) {
    platform_panic();
  }
}*/

int readline(int fd, unsigned char *buf, int len);/* {
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
}*/

void trimstr(char *buf);/* {
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
}*/

void remove_spaces(char *buf);/* {
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
}*/

int strcmp(const char *s1, const char *s2);/* {
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
}*/

void strcpy(char *d, const char *s);/* {
  while (1) {
    *d = *s;
    if (*s == '\0') {
      return;
    }
    d++;
    s++;
  }
}*/

int strlen(const char *s);/* {
  const char *s2 = s;
  while (*s2 != '\0') {
    s2++;
  }
  return s2 - s;
}*/

int find_char(char *s, char c);/* {
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
}*/

int find_symbol(const char *name) {
  int i;
  for (i = 0; i < SYMBOL_TABLE_LEN; i++) {
    if (strcmp(name, get_symbol_names() + i * MAX_SYMBOL_NAME_LEN) == 0) {
      break;
    }
  }
  return i;
}

void add_symbol(const char *name, int loc) {
  int len = strlen(name);
  assert(len > 0);
  assert(len < MAX_SYMBOL_NAME_LEN);
  int stage = *get_stage();
  if (stage == 0) {
    int symbol_num = *get_symbol_num();
    assert(find_symbol(name) == SYMBOL_TABLE_LEN);
    assert(symbol_num < SYMBOL_TABLE_LEN);
    strcpy(get_symbol_names() + symbol_num * MAX_SYMBOL_NAME_LEN, name);
    get_symbol_loc()[symbol_num] = loc;
    *get_symbol_num() = symbol_num + 1;
  } else if (stage == 1) {
    int idx = find_symbol(name);
    assert(idx < SYMBOL_TABLE_LEN);
    assert(get_symbol_loc()[idx] == loc);
  } else {
    platform_panic();
  }
}

int decode_reg32(char *reg) {
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

int decode_reg8(char *reg) {
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

int decode_number_or_symbol(const char *operand, unsigned int *num, int force_symbol) {
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

int decode_operand(char *operand, int *is_direct, int *reg, int *disp, int *is8, int *is32) {
  remove_spaces(operand);
  *is8 = 0;
  *is32 = 0;
  if (operand[0] == 'B' && operand[1] == 'Y' && operand[2] == 'T' && operand[3] == 'E') {
    operand += 4;
    *is8 = 1;
  }
  if (operand[0] == 'D' && operand[1] == 'W' && operand[2] == 'O' && operand[3] == 'R' && operand[4] == 'D') {
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

void emit(char c) {
  int stage = *get_stage();
  if (stage == 1) {
    platform_write_char(1, c);
  }
  (*get_current_loc())++;
}

void emit32(int x) {
  emit(x);
  emit(x >> 8);
  emit(x >> 16);
  emit(x >> 24);
}

int process_bss_line(char *opcode, char *data) {
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
    for (i = 0; i < 4 * val; i++) {
      emit(0);
    }
  } else {
    return 0;
  }
  return 1;
}

int emit_modrm(int mod, int reg, int rm) {
  assert(mod == mod & 0x3);
  assert(reg == reg & 0x7);
  assert(rm == rm & 0x7);
  emit((mod << 6) + (reg << 3) + rm);
  // The only two supported mode are a direct register, or an indirect
  // register + disp32
  assert(mod == 2 || mod == 3);
  // In the particular case of ESP used as indirect base, a SIB is
  // needed
  if (mod == 2 && rm == 4) {
    emit(0x24);
  }
}

enum {
  OP_PUSH,
  OP_POP,
  OP_ADD,
  OP_SUB,
  OP_MOV,
  OP_CMP,
  OP_AND,
  OP_OR,
  OP_JMP,
  OP_CALL,
  OP_JZ,
  OP_JNZ,
};

void process_jmp_like(int op, char *data) {
  int is_direct, reg, disp, is8, is32;
  int res = decode_operand(data, &is_direct, &reg, &disp, &is8, &is32);
  if (res) {
    assert(!is8);
    // r/m32
    int opcode;
    int ext;
    if (op == OP_JMP) {
      opcode = 0xff;
      ext = 4;
    } else if (op == OP_CALL) {
      opcode = 0xff;
      ext = 2;
    } else {
      platform_panic();
    }
    if (is_direct) {
      emit(opcode);
      emit_modrm(3, ext, reg);
    } else {
      emit(opcode);
      emit_modrm(2, ext, reg);
      emit32(disp);
    }
  } else {
    // rel32
    int opcode;
    int opcode2;
    int has_opcode2 = 0;
    if (op == OP_JMP) {
      opcode = 0xe9;
    } else if (op == OP_CALL) {
      opcode = 0xe8;
    } else if (op == OP_JZ) {
      opcode = 0x0f;
      opcode2 = 0x84;
      has_opcode2 = 1;
    } else if (op == OP_JNZ) {
      opcode = 0x0f;
      opcode2 = 0x85;
      has_opcode2 = 1;
    } else {
      platform_panic();
    }
    int rel;
    int res = decode_number_or_symbol(data, &rel, 0);
    if (!res) {
      platform_panic();
    }
    int current_loc = *get_current_loc();
    rel = rel - current_loc - (has_opcode2 ? 6 : 5);
    emit(opcode);
    if (has_opcode2) {
      emit(opcode2);
    }
    emit32(rel);
  }
}

void process_push_like(int op, char *data) {
  int is_direct, reg, disp, is8, is32;
  int res = decode_operand(data, &is_direct, &reg, &disp, &is8, &is32);
  if (res) {
    assert(!is8);
    if (is_direct) {
      int opcode;
      if (op == OP_PUSH) {
        opcode = 0x50;
      } else if (op == OP_POP) {
        opcode = 0x58;
      } else {
        platform_panic();
      }
      emit(opcode + reg);
    } else {
      int opcode;
      int reg;
      if (op == OP_PUSH) {
        opcode = 0xff;
        reg = 6;
      } else if (op == OP_POP) {
        opcode = 0x8f;
        reg = 0;
      } else {
        platform_panic();
      }
      emit(opcode);
      emit_modrm(2, reg, reg);
      emit32(disp);
    }
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

void process_add_like(int op, char *data) {
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
        int opcode;
        if (op == OP_ADD) {
          opcode = 0x02;
        } else if (op == OP_SUB) {
          opcode = 0x2a;
        } else if (op == OP_MOV) {
          opcode = 0x8a;
        } else if (op == OP_CMP) {
          opcode = 0x3a;
        } else if (op == OP_AND) {
          opcode = 0x22;
        } else if (op == OP_OR) {
          opcode = 0x0a;
        } else {
          platform_panic();
        }
        if (src_is_direct) {
          emit(opcode);
          emit_modrm(3, dest_reg, src_reg);
        } else {
          emit(opcode);
          emit_modrm(2, dest_reg, src_reg);
          emit32(src_disp);
        }
      } else {
        // r32, r/m32
        int opcode;
        if (op == OP_ADD) {
          opcode = 0x03;
        } else if (op == OP_SUB) {
          opcode = 0x2b;
        } else if (op == OP_MOV) {
          opcode = 0x8b;
        } else if (op == OP_CMP) {
          opcode = 0x3b;
        } else if (op == OP_AND) {
          opcode = 0x23;
        } else if (op == OP_OR) {
          opcode = 0x0b;
        } else {
          platform_panic();
        }
        if (src_is_direct) {
          emit(opcode);
          emit_modrm(3, dest_reg, src_reg);
        } else {
          emit(opcode);
          emit_modrm(2, dest_reg, src_reg);
          emit32(src_disp);
        }
      }
    } else {
      if (src_is_direct) {
        if (is8) {
          // r/m8, r8
          int opcode;
          if (op == OP_ADD) {
            opcode = 0x00;
          } else if (op == OP_SUB) {
            opcode = 0x28;
          } else if (op == OP_MOV) {
            opcode = 0x88;
          } else if (op == OP_CMP) {
            opcode = 0x38;
          } else if (op == OP_AND) {
            opcode = 0x20;
          } else if (op == OP_OR) {
            opcode = 0x08;
          } else {
            platform_panic();
          }
          emit(opcode);
          emit_modrm(2, src_reg, dest_reg);
          emit32(dest_disp);
        } else {
          // r/m32, r32
          int opcode;
          if (op == OP_ADD) {
            opcode = 0x01;
          } else if (op == OP_SUB) {
            opcode = 0x29;
          } else if (op == OP_MOV) {
            opcode = 0x89;
          } else if (op == OP_CMP) {
            opcode = 0x39;
          } else if (op == OP_AND) {
            opcode = 0x21;
          } else if (op == OP_OR) {
            opcode = 0x09;
          } else {
            platform_panic();
          }
          emit(opcode);
          emit_modrm(2, src_reg, dest_reg);
          emit32(dest_disp);
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
        int opcode;
        int reg;
        if (op == OP_ADD) {
          opcode = 0x80;
          reg = 0;
        } else if (op == OP_SUB) {
          opcode = 0x80;
          reg = 5;
        } else if (op == OP_MOV) {
          opcode = 0xc6;
          reg = 0;
        } else if (op == OP_CMP) {
          opcode = 0x80;
          reg = 7;
        } else if (op == OP_AND) {
          opcode = 0x80;
          reg = 4;
        } else if (op == OP_OR) {
          opcode = 0x80;
          reg = 1;
        } else {
          platform_panic();
        }
        if (dest_is_direct) {
          emit(opcode);
          emit_modrm(3, reg, dest_reg);
          emit(imm);
        } else {
          emit(opcode);
          emit_modrm(2, reg, dest_reg);
          emit32(dest_disp);
          emit(imm);
        }
      } else {
        // r/m32, imm32
        int opcode;
        int reg;
        if (op == OP_ADD) {
          opcode = 0x81;
          reg = 0;
        } else if (op == OP_SUB) {
          opcode = 0x81;
          reg = 5;
        } else if (op == OP_MOV) {
          opcode = 0xc7;
          reg = 0;
        } else if (op == OP_CMP) {
          opcode = 0x81;
          reg = 7;
        } else if (op == OP_AND) {
          opcode = 0x81;
          reg = 4;
        } else if (op == OP_OR) {
          opcode = 0x81;
          reg = 1;
        } else {
          platform_panic();
        }
        if (dest_is_direct) {
          emit(opcode);
          emit_modrm(3, reg, dest_reg);
          emit32(imm);
        } else {
          emit(opcode);
          emit_modrm(2, reg, dest_reg);
          emit32(dest_disp);
          emit32(imm);
        }
      }
    } else {
      platform_panic();
    }
  }
}

void process_int(char *data) {
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

int process_text_line(char *opcode, char *data) {
  if (strcmp(opcode, "call") == 0) {
    process_jmp_like(OP_CALL, data);
  } else if (strcmp(opcode, "jmp") == 0) {
    process_jmp_like(OP_JMP, data);
  } else if (strcmp(opcode, "ret") == 0) {
    assert(strcmp(data, "") == 0);
    emit(0xc3);
  } else if (strcmp(opcode, "push") == 0) {
    process_push_like(OP_PUSH, data);
  } else if (strcmp(opcode, "pop") == 0) {
    process_push_like(OP_POP, data);
  } else if (strcmp(opcode, "add") == 0) {
    process_add_like(OP_ADD, data);
  } else if (strcmp(opcode, "sub") == 0) {
    process_add_like(OP_SUB, data);
  } else if (strcmp(opcode, "and") == 0) {
    process_add_like(OP_AND, data);
  } else if (strcmp(opcode, "or") == 0) {
    process_add_like(OP_OR, data);
  } else if (strcmp(opcode, "mov") == 0) {
    process_add_like(OP_MOV, data);
  } else if (strcmp(opcode, "cmp") == 0) {
    process_add_like(OP_CMP, data);
  } else if (strcmp(opcode, "jz") == 0) {
    process_jmp_like(OP_JZ, data);
  } else if (strcmp(opcode, "jnz") == 0) {
    process_jmp_like(OP_JNZ, data);
  } else if (strcmp(opcode, "int") == 0) {
    process_int(data);
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
    data_len = 0;
  } else {
    opcode[opcode_len] = '\0';
    data = line + opcode_len + 1;
    trimstr(data);
    data_len = strlen(data);
  }

  if (strcmp(opcode, "section") == 0) {
    assert(data_len > 0);
    assert(data_len < MAX_SYMBOL_NAME_LEN);
    strcpy(get_current_section(), data);
  } else if (strcmp(opcode, "global") == 0) {
  } else if (strcmp(opcode, "align") == 0) {
  } else if (strcmp(opcode, "extern") == 0) {
    add_symbol(data, 0);
  } else {
    int processed = 0;
    if (strcmp(get_current_section(), ".bss") == 0) {
      processed = process_bss_line(opcode, data);
    } else if (strcmp(get_current_section(), ".text") == 0) {
      processed = process_text_line(opcode, data);
    }
    if (!processed) {
      int data_space_pos = find_char(data, ' ');
      if (data_space_pos >= 0) {
        data[data_space_pos] = '\0';
        if (strcmp(data, "equ") == 0) {
          int val;
          int res = decode_number_or_symbol(data + data_space_pos + 1, &val, 0);
          if (res) {
            add_symbol(opcode, val);
          } else {
            platform_panic();
          }
        } else {
          platform_panic();
        }
      } else {
        platform_panic();
      }
    }
  }
}

void assemble_file() {
  int fd_in = platform_open_file("asmc.asm");
  for (*get_stage() = 0; *get_stage() < 2; (*get_stage())++) {
    platform_reset_file(fd_in);
    *get_current_loc() = 0;
    while (1) {
      char *input_buf = get_input_buf();
      int finished = readline(fd_in, input_buf, INPUT_BUF_LEN);
      /*platform_log(2, "Decoding line: ");
      platform_log(2, input_buf);
      platform_log(2, "\n");*/
      trimstr(input_buf);
      int len = strlen(input_buf);
      if (finished && len == 0) {
        break;
      }
      if (len == 0 || input_buf[0] == ';') {
        continue;
      }
      if (input_buf[len-1] == ':') {
        input_buf[len-1] = '\0';
        add_symbol(input_buf, *get_current_loc());
      } else {
        process_line(input_buf);
      }
    }
  }
}
