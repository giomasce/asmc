#ifndef __ASMC_H
#define __ASMC_H

#define const
#define NULL 0

typedef int ssize_t;
typedef unsigned int size_t;

struct __handles_t {
  void (*platform_write_char)(int fd, char c);
};

struct __handles_t *__handles;

typedef struct {
  int fd;
} FILE;

FILE __stdout = {1};
FILE *stdout;
FILE __stderr = {1};
FILE *stderr;

#define EOF (0-1)

int fputc(int c, FILE *s) {
  __handles->platform_write_char(s->fd, c);
  return c;
}

#define putc fputc

int putchar(int c) {
  return fputc(c, stdout);
}

int fputs(const char *s, FILE *stream) {
  while (*s != 0) {
    if (fputc(*s, stream) == EOF) {
      return EOF;
    }
    s = s + 1;
  }
  return 0;
}

int puts(const char *s) {
  return fputs(s, stdout);
}

int main(int, char *[]);

void __init_stdlib() {
  __handles = &__builtin_handles;
  stdout = &__stdout;
  stderr = &__stderr;
}

int _start(int argc, char *argv[]) {
  __init_stdlib();
  return main(argc, argv);
}

#endif
