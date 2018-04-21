
int do_syscall(int syscall_num, int arg1, int arg2, int arg3);

#define SYS_exit 0x1
#define SYS_read 0x3
#define SYS_write 0x4
#define SYS_getpid 0x14
#define SYS_kill 0x25
#define SYS_open 0x5
#define SYS_lseek 0x13

#define SIGABRT 6

#define O_RDONLY 0
#define SEEK_SET 0

void platform_panic() {
  int pid = do_syscall(SYS_getpid, 0, 0, 0);
  do_syscall(SYS_kill, pid, SIGABRT, 0);
}

void platform_exit() {
  do_syscall(SYS_exit, 0, 0, 0);
}

int platform_open_file(char *fname) {
  int ret = do_syscall(SYS_open, (int) fname, O_RDONLY, 0);
  if (ret < 0) {
    platform_panic();
  }
  return ret;
}

int platform_reset_file(int fd) {
  int res = do_syscall(SYS_lseek, fd, 0, SEEK_SET);
  if (res < 0) {
    platform_panic();
  }
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

void platform_log(int fd, char *s) {
  while (*s != '\0') {
    platform_write_char(fd, *s);
    s++;
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

int stage;

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
  if (stage == 0) {
    assert(find_symbol(name) == SYMBOL_TABLE_LEN);
    assert(symbol_num < SYMBOL_TABLE_LEN);
    strcpy(symbol_names[symbol_num], name);
    symbol_loc[symbol_num] = loc;
    symbol_num++;
  } else if (stage == 1) {
    int idx = find_symbol(name);
    assert(idx < SYMBOL_TABLE_LEN);
    assert(symbol_loc[idx] == loc);
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

int decode_number(char *operand, unsigned int *num) {
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

int decode_operand(char *operand, int *is_direct, int *reg, int *disp) {
  remove_spaces(operand);
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
          *reg = decode_reg(operand);
          return *reg != -1;
        }
      }
    } else {
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
  if (stage == 1) {
    platform_write_char(1, c);
  }
  current_loc++;
}

void emit32(int x) {
  emit(x);
  emit(x >> 8);
  emit(x >> 16);
  emit(x >> 24);
}

void process_bss_line(char *opcode, char *data) {
  if (strcmp(opcode, "resb") == 0) {
    int val;
    int res = decode_number(data, &val);
    if (!res) {
      platform_panic();
    }
    int i;
    for (i = 0; i < val; i++) {
      emit(0);
    }
  } else {
    platform_panic();
  }
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
  OP_JMP,
  OP_CALL,
  OP_JZ,
  OP_JNZ,
};

void process_jmp_like(int op, char *data) {
  int is_direct, reg, disp;
  int res = decode_operand(data, &is_direct, &reg, &disp);
  if (res) {
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
    int res = decode_number(data, &rel);
    if (!res) {
      if (stage == 0) {
        rel = 0;
      } else {
        int idx = find_symbol(data);
        if (idx < SYMBOL_TABLE_LEN) {
          // Here 5 or 6 is the length of the instruction we are going to emit
          rel = symbol_loc[idx] - current_loc - (has_opcode2 ? 6 : 5);
        } else {
          platform_panic();
        }
      }
    }
    emit(opcode);
    if (has_opcode2) {
      emit(opcode2);
    }
    emit32(rel);
  }
}

void process_push_like(int op, char *data) {
  int is_direct, reg, disp;
  int res = decode_operand(data, &is_direct, &reg, &disp);
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
      emit_modrm(2, reg, reg);
      emit32(disp);
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
  int dest_is_direct, dest_reg, dest_disp;
  int src_is_direct, src_reg, src_disp;
  int dest_res = decode_operand(dest, &dest_is_direct, &dest_reg, &dest_disp);
  if (!dest_res) {
    platform_panic();
  }
  int src_res = decode_operand(src, &src_is_direct, &src_reg, &src_disp);
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
        emit_modrm(3, dest_reg, src_reg);
      } else {
        emit(opcode);
        emit_modrm(2, dest_reg, src_reg);
        emit32(src_disp);
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
        emit_modrm(2, src_reg, dest_reg);
        emit32(dest_disp);
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
        emit_modrm(3, reg, dest_reg);
        emit32(imm);
      } else {
        emit(opcode);
        emit_modrm(2, reg, dest_reg);
        emit32(dest_disp);
        emit32(imm);
      }
    } else {
      platform_panic();
    }
  }
}

void process_int(char *data) {
  int imm;
  int res = decode_number(data, &imm);
  if (!res) {
    platform_panic();
  }
  if (res < 0 || res >= 0x100) {
    platform_panic();
  }
  emit(0xcd);
  emit(imm);
}

void process_text_line(char *opcode, char *data) {
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
    platform_panic();
  }
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
    strcpy(current_section, data);
  } else if (strcmp(opcode, "global") == 0) {
  } else if (strcmp(opcode, "extern") == 0) {
    add_symbol(data, 0);
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

void assemble_file() {
  int fd_in = platform_open_file("asmc.asm");
  for (stage = 0; stage < 2; stage++) {
    platform_reset_file(fd_in);
    current_loc = 0;
    while (1) {
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
        add_symbol(input_buf, current_loc);
      } else {
        process_line(input_buf);
      }
    }
  }
}
