#ifndef __STDIO_H
#define __STDIO_H

#include "asmc.h"
#include "stdlib.h"
#include "stdarg.h"
#include "assert.h"

#define EOF (-1)

int fputc(int c, FILE *s) {
    if (s->fd == 1 || s->fd == 2) {
        __handles->write(c);
    } else {
        __handles->vfs_write(c, s->fd);
    }
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
    if ((*mode == 'r' || *mode == 'w') && *(mode+1) == 'b' && *(mode+2) == 0) {
        FILE *ret = malloc(sizeof(FILE));
        ret->fd = fildes;
        return ret;
    } else {
        _force_assert(!"unknown file mode");
    }
}

int fclose(FILE *stream) {
    if (stream == stdout || stream == stderr) {
        // Nothing to do here...
    } else {
        __handles->vfs_close(stream->fd);
        free(stream);
    }
}

#include "_printf.h"
#include "_scanf.h"

#endif
