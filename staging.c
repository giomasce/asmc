
int do_syscall(int syscall_num, int arg1, int arg2, int arg3);

#define SYS_exit 0x1
#define SYS_read 0x3
#define SYS_write 0x4
#define SYS_getpid 0x14
#define SYS_kill 0x25

#define SIGABRT 6

void platform_panic() {
  int pid = do_syscall(SYS_getpid, 0, 0, 0);
  do_syscall(SYS_kill, pid, SIGABRT, 0);
}

void platform_exit() {
  do_syscall(SYS_exit, 0, 0, 0);
}

int platform_read_char(int fd) {
  int buf = 0;
  int ret = do_syscall(SYS_read, fd, (int) &buf, 1);
  if (ret == 0) {
    return -1;
  }
  if (ret != 1) {
    platform_panic();
  }
  return buf;
}

void platform_write_char(int fd, int c) {
  int buf = c;
  int ret = do_syscall(SYS_write, fd, (int) &buf, 1);
  if (ret != 1) {
    platform_panic();
  }
}

#define INPUT_BUF_LEN 1024
#define MAX_SYMBOL_NAME_LEN 128
#define SYMBOL_TABLE_LEN 1024

unsigned char input_buf[INPUT_BUF_LEN];

unsigned char symbol_names[SYMBOL_TABLE_LEN][MAX_SYMBOL_NAME_LEN];
int symbol_loc[SYMBOL_TABLE_LEN];
int symbol_num;

char current_section[MAX_SYMBOL_NAME_LEN];
int current_loc;

void assert(int cond) {
  if (!cond) {
    platform_panic();
  }
}

int readline(int fd, unsigned char *buf, int len) {
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

void trimstr(char *buf) {
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

void remove_spaces(char *buf) {
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

int strlen(const char *s) {
  const char *s2 = s;
  while (*s2 != '\0') {
    s2++;
  }
  return s2 - s;
}

int find_char(char *s, char c) {
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

int find_symbol(unsigned char *name) {
  int i;
  for (i = 0; i < SYMBOL_TABLE_LEN; i++) {
    if (strcmp(name, symbol_names[i]) == 0) {
      break;
    }
  }
  return i;
}

void add_symbol(unsigned char *name, int loc) {
  int len = strlen(name);
  assert(len > 0);
  assert(len < MAX_SYMBOL_NAME_LEN);
  assert(find_symbol(name) == SYMBOL_TABLE_LEN);
  assert(symbol_num < SYMBOL_TABLE_LEN);
  strcpy(symbol_names[symbol_num], name);
  symbol_loc[symbol_num] = loc;
  symbol_num++;
}

void process_bss_line(char *opcode, char *data) {
  if (strcmp(opcode, "resb") == 0) {
  } else {
    platform_panic();
  }
}

int decode_reg(char *reg) {
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

int decode_number(char *operand, int *num) {
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
      *num += operand[0] - 'a';
    } else {
      return 0;
    }
    operand++;
  }
}

int decode_operand(char *operand, int *is_direct, int *reg, int *has_disp, int *disp) {
  remove_spaces(operand);
  if (operand[0] == '[') {
    *is_direct = 0;
    operand++;
    int plus_pos = find_char(operand, '+');
    if (plus_pos == -1) {
      *has_disp = 0;
      int closed_pos = find_char(operand, ']');
      if (closed_pos == -1) {
        return 0;
      } else {
        if (operand[closed_pos+1] != '\0') {
          return 0;
        } else {
          operand[closed_pos] = '\0';
          *reg = decode_reg(operand);
          return *reg != -1;
        }
      }
    } else {
      *has_disp = 1;
      operand[plus_pos] = '\0';
      *reg = decode_reg(operand);
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
            return decode_number(operand, disp);
          }
        }
      }
    }
  } else {
    *is_direct = 1;
    *reg = decode_reg(operand);
    return *reg != -1;
  }
}

void emit(char c) {
  platform_write_char(1, c);
  current_loc++;
}

void emit32(int x) {
  emit(x);
  emit(x >> 8);
  emit(x >> 16);
  emit(x >> 24);
}

int assemble_modrm(int mod, int reg, int rm) {
  assert(mod == mod & 0x3);
  assert(reg == reg & 0x7);
  assert(rm == rm & 0x7);
  return (mod << 6) + (reg << 3) + rm;
}

enum {
  OP_PUSH,
  OP_POP,
  OP_ADD,
  OP_SUB,
  OP_MOV,
  OP_CMP,
};

void process_push_like(int op, char *data) {
  int is_direct, reg, has_disp, disp;
  int res = decode_operand(data, &is_direct, &reg, &has_disp, &disp);
  if (res) {
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
      // FIXME: sometimes we need to generate a SIB
      emit(assemble_modrm(has_disp ? 2 : 0, reg, reg));
      if (has_disp) {
        emit32(disp);
      }
    }
  } else {
    assert(op == OP_PUSH);
    int imm;
    int res = decode_number(data, &imm);
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
  int dest_is_direct, dest_reg, dest_has_disp, dest_disp;
  int src_is_direct, src_reg, src_has_disp, src_disp;
  int dest_res = decode_operand(dest, &dest_is_direct, &dest_reg, &dest_has_disp, &dest_disp);
  if (!dest_res) {
    platform_panic();
  }
  int src_res = decode_operand(src, &src_is_direct, &src_reg, &src_has_disp, &src_disp);
  if (src_res) {
    if (dest_is_direct) {
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
      } else {
        platform_panic();
      }
      if (src_is_direct) {
        emit(opcode);
        emit(assemble_modrm(3, dest_reg, src_reg));
      } else {
        emit(opcode);
        emit(assemble_modrm(src_has_disp ? 2 : 0, dest_reg, src_reg));
        if (src_has_disp) {
          emit32(src_disp);
        }
      }
    } else {
      if (src_is_direct) {
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
        } else {
          platform_panic();
        }
        emit(opcode);
        emit(assemble_modrm(dest_has_disp ? 2 : 0, src_reg, dest_reg));
        if (dest_has_disp) {
          emit32(dest_disp);
        }
      } else {
        platform_panic();
      }
    }
  } else {
    int imm;
    int res = decode_number(src, &imm);
    if (res) {
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
      } else {
        platform_panic();
      }
      if (dest_is_direct) {
        emit(opcode);
        emit(assemble_modrm(3, reg, dest_reg));
        emit32(imm);
      } else {
        emit(opcode);
        emit(assemble_modrm(dest_has_disp ? 2 : 0, reg, dest_reg));
        if (dest_has_disp) {
          emit32(dest_disp);
        }
        emit32(imm);
      }
    } else {
      platform_panic();
    }
  }
}

void process_text_line(char *opcode, char *data) {
  if (strcmp(opcode, "call") == 0) {
  } else if (strcmp(opcode, "ret") == 0) {
  } else if (strcmp(opcode, "jmp") == 0) {
  } else if (strcmp(opcode, "push") == 0) {
    process_push_like(OP_PUSH, data);
  } else if (strcmp(opcode, "pop") == 0) {
    process_push_like(OP_POP, data);
  } else if (strcmp(opcode, "add") == 0) {
    process_add_like(OP_ADD, data);
  } else if (strcmp(opcode, "sub") == 0) {
    process_add_like(OP_SUB, data);
  } else if (strcmp(opcode, "mov") == 0) {
    process_add_like(OP_MOV, data);
  } else if (strcmp(opcode, "cmp") == 0) {
    process_add_like(OP_CMP, data);
  } else if (strcmp(opcode, "jz") == 0) {
  } else {
    platform_panic();
  }
}

void process_line(char *line) {
  char *opcode = line;
  int opcode_len = find_char(line, ' ');
  opcode[opcode_len] = '\0';
  char *data = line + opcode_len + 1;
  trimstr(data);
  int data_len = strlen(data);

  if (strcmp(opcode, "section") == 0) {
    assert(data_len > 0);
    assert(data_len < MAX_SYMBOL_NAME_LEN);
    strcpy(current_section, data);
  } else if (strcmp(opcode, "global") == 0) {
  } else if (strcmp(opcode, "extern") == 0) {
  } else {
    if (strcmp(current_section, ".bss") == 0) {
      process_bss_line(opcode, data);
    } else if (strcmp(current_section, ".text") == 0) {
      process_text_line(opcode, data);
    } else {
      platform_panic();
    }
  }
}

void assemble_stdin() {
  while (1) {
    int finished = readline(0, input_buf, INPUT_BUF_LEN);
    trimstr(input_buf);
    int len = strlen(input_buf);
    if (finished && len == 0) {
      return;
    }
    if (len == 0 || input_buf[0] == ';') {
      continue;
    }
    if (input_buf[len-1] == ':') {
      input_buf[len-1] = '\0';
      add_symbol(input_buf, current_loc);
    } else {
      process_line(input_buf);
    }
  }
}
