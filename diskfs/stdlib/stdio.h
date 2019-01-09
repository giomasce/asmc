#ifndef __STDIO_H
#define __STDIO_H

#include "asmc.h"
#include "stdlib.h"
#include "stdarg.h"
#include "assert.h"

#define EOF (-1)

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

int getc(FILE *stream) {
    // File reading has not been implemented so far
    return EOF;
}

int ungetc(int c, FILE *stream) {
    // File reading has not been implemented so far
    return EOF;
}

char *itoa(unsigned int x) {
  return __handles->itoa(x);
}

int fflush(FILE *stream) {
    // Our FILE has no buffer, so there is nothing to flush
    return 0;
}

size_t fwrite(const void *buffer, size_t size, size_t count, FILE *stream) {
    const char *buf = buffer;
    size *= count;
    while (size--) {
        fputc(*buf++, stream);
    }
}

FILE *fdopen(int fildes, const char *mode) {
    if (*mode == 'r' && *(mode+1) == 0) {
        FILE *ret = malloc(sizeof(FILE));
        ret->fd = fildes;
        return ret;
    } else {
        _force_assert(!"can only open file in read mode");
    }
}

int fclose(FILE *stream) {
    if (stream == stdout || stream == stderr) {
        // Nothing to do here...
    } else {
        // FIXME: pass close to underlying fd
        free(stream);
    }
}

#include "_printf.h"
#include "_scanf.h"

#define SEEK_CUR 0
#define SEEK_END 1
#define SEEK_SET 2

#endif
