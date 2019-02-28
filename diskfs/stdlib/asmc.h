#ifndef __ASMC_H
#define __ASMC_H

#include "asmc_types.h"

struct __handles_t {
    void (*write)(char c);
    int (*platform_setjmp)(void *env);
    void (*platform_longjmp)(void *env, int status);
    void *(*malloc)(size_t size);
    void *(*calloc)(size_t num, size_t size);
    void (*free)(void *ptr);
    void *(*realloc)(void *ptr, size_t new_size);
    char *(*itoa)(unsigned int x);
    void (*dump_stacktrace)();
    int (*vfs_open)(const char *name);
    void (*vfs_close)(int fd);
    int (*vfs_read)(int fd);
    void (*vfs_write)(int c, int fd);
    void (*vfs_truncate)(int fd);
    int (*vfs_seek)(int whence, int offset, int fd);
};

struct __handles_t *__handles;

FILE __stdout = {1};
FILE *stdout;
FILE __stderr = {2};
FILE *stderr;

int main(int, char *[]);

#include "setjmp.h"

int __return_code;
int __aborted;
jmp_buf __return_jump_buf;

unsigned int __get_handles() {
    return (unsigned int) __handles;
}

void __init_stdlib() {
#ifdef __HANDLES
  __handles = (struct __handles_t*) __HANDLES;
#else
  __handles = &__builtin_handles;
#endif
  __aborted = 0;
  stdout = &__stdout;
  stderr = &__stderr;
}

// Nothing to do, for the moment
void __cleanup_stdlib() {
}

int fputs(const char *s, FILE *stream);
int fprintf(FILE* stream, const char * format, ...);

void __dump_stacktrace() {
    __handles->dump_stacktrace();
}

#ifdef __TINYC__
#define __unimplemented() fprintf(stderr, "Unimplemented call %s at %s:%d\n", __func__, __FILE__, __LINE__)
#else
void __unimplemented() {
    fputs("UNIMPLEMENTED CALL\n", stderr);
    __dump_stacktrace();
}
#endif

#include "stdio.h"

int _start(int argc, char *argv[]) {
  __init_stdlib();
  if (setjmp(__return_jump_buf) == 0) {
      __return_code = main(argc, argv);
  }
  if (__aborted) {
      fputs("ABORT\n", stderr);
  } else {
      __cleanup_stdlib();
  }
  return __return_code;
}

#endif
