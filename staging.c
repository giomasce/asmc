
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
      return c != -1;
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
  }
}

int strlen(const char *s) {
  const char *s2 = s;
  while (*s2 != '\0') {
    s2++;
  }
  return s2 - s;
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
  assert(strlen(name) < MAX_SYMBOL_NAME_LEN);
  assert(find_symbol(name) == SYMBOL_TABLE_LEN);
  assert(symbol_num < SYMBOL_TABLE_LEN);
  strcpy(symbol_names[symbol_num], name);
  symbol_loc[symbol_num] = loc;
  symbol_num++;
}

void assemble_stdin() {
  while (1) {
    int finished = readline(0, input_buf, INPUT_BUF_LEN);
    trimstr(input_buf);
    int len = strlen(input_buf);
    if (input_buf[len-1] == ':') {
      input_buf[len-1] = '\0';
      add_symbol(input_buf, 0);
    } else {

    }
    if (finished) {
      return;
    }
  }
}
