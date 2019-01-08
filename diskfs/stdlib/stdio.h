#ifndef __STDIO_H
#define __STDIO_H

#include "asmc.h"
#include "stdlib.h"
#include "stdarg.h"

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

char *itoa(unsigned int x) {
  return __handles->itoa(x);
}

int sscanf(const char *buffer, const char *format, ...) {
    abort();
}

int fflush(FILE *stream) {
    // Our FILE has no buffer, so there is nothing to flush
    return 0;
}

size_t fwrite(const void *buffer, size_t size, size_t count, FILE *stream) {
    abort();
}

FILE *fdopen(int fildes, const char *mode) {
    abort();
}

int fclose(FILE *stream) {
    abort();
}

#include "_printf.h"

#define SEEK_CUR 0
#define SEEK_END 1
#define SEEK_SET 2

#endif
