#ifndef __STDIO_H
#define __STDIO_H

#include "asmc.h"
#include "stdlib.h"
#include "stdarg.h"
#include "assert.h"
#include "fcntl.h"
#include "unistd.h"

#define EOF (-1)

int fputc(int c, FILE *s) {
    if (s->fd == 0) {
        return EOF;
    } else if (s->fd == 1 || s->fd == 2) {
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
    if (fputs(s, stdout) != EOF) {
        if (fputc('\n', stdout) != EOF) {
            return 0;
        }
    }
    return EOF;
}

int getc(FILE *stream) {
    if (stream->ungetted) {
        stream->ungetted = 0;
        return stream->ungetbuf;
    }
    char buf;
    ssize_t res = read(stream->fd, &buf, 1);
    if (res) {
        return buf;
    } else {
        return EOF;
    }
}

int fgetc(FILE *stream) {
    return getc(stream);
}

int ungetc(int c, FILE *stream) {
    if (stream->ungetted) {
        return EOF;
    }
    stream->ungetted = 1;
    stream->ungetbuf = c;
    return c;
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

int _open_mode(const char *mode) {
    int oflag = 0;
    if (*mode == 'r') oflag = O_RDONLY;
    if (*mode == 'w') oflag = O_WRONLY | O_CREAT | O_TRUNC;
    if (!oflag) return 0;
    mode++;
    if (*mode == '\0') return oflag;
    if (*mode != 'b') return 0;
    mode++;
    if (*mode == '\0') return oflag;
    return 0;
}

FILE *fdopen(int fildes, const char *mode) {
    if (_open_mode(mode)) {
        FILE *ret = malloc(sizeof(FILE));
        ret->fd = fildes;
        ret->ungetbuf = 0;
        ret->ungetted = 0;
        return ret;
    } else {
        _force_assert(!"unknown file mode");
    }
}

FILE *fopen(const char *filename, const char *mode) {
    int oflag = _open_mode(mode);
    if (oflag) {
        int fildes = open(filename, oflag);
        FILE *ret = fdopen(fildes, mode);
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
