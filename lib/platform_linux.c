
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

#include "platform.h"

__attribute__((noreturn)) void platform_panic() {
  abort();
}

void platform_exit() {
  exit(0);
}

int platform_open_file(char *fname) {
  int ret = open(fname, O_RDONLY);
  if (ret < 0) {
    platform_panic();
  }
  return ret;
}

int platform_reset_file(int fd) {
  int res = lseek(fd, 0, SEEK_SET);
  if (res < 0) {
    platform_panic();
  }
}

int platform_read_char(int fd) {
  int buf = 0;
  int ret = read(fd, &buf, 1);
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
  int ret = write(fd, &buf, 1);
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

void *platform_allocate(int size) {
  return malloc(size);
}
