
#include "platform.h"

int do_syscall(int syscall_num, int arg1, int arg2, int arg3);

#define SYS_exit 0x1
#define SYS_read 0x3
#define SYS_write 0x4
#define SYS_getpid 0x14
#define SYS_kill 0x25
#define SYS_open 0x5
#define SYS_lseek 0x13
#define SYS_brk 0x2d

#define SIGABRT 6

#define O_RDONLY 0
#define SEEK_SET 0

__attribute__((noreturn)) void platform_panic() {
  int pid = do_syscall(SYS_getpid, 0, 0, 0);
  do_syscall(SYS_kill, pid, SIGABRT, 0);
  __builtin_unreachable();
}

void platform_exit() {
  do_syscall(SYS_exit, 0, 0, 0);
  __builtin_unreachable();
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

char *itoa(int x);

void *platform_allocate(int size) {
  int current_brk = do_syscall(SYS_brk, 0, 0, 0);
  int new_brk = current_brk + size;
  new_brk = 1 + ((new_brk - 1) | 0xf);
  int returned_brk = do_syscall(SYS_brk, new_brk, 0, 0);
  if (returned_brk != new_brk) {
    platform_panic();
  }
  /*platform_log(2, "Allocate from ");
  platform_log(2, itoa(current_brk));
  platform_log(2, " to ");
  platform_log(2, itoa(new_brk));
  platform_log(2, "\n");*/
  return (void*) current_brk;
}
