#ifndef __ASMC_H
#define __ASMC_H

#include "asmc_types.h"

struct __handles_t {
  void (*platform_write_char)(int fd, char c);
  int (*platform_setjmp)(void *env);
  void (*platform_longjmp)(void *env, int status);
  void *(*malloc)(size_t size);
  void *(*calloc)(size_t num, size_t size);
  void (*free)(void *ptr);
  void *(*realloc)(void *ptr, size_t new_size);
  char *(*itoa)(unsigned int x);
};

struct __handles_t *__handles;

typedef struct {
  int fd;
} FILE;

FILE __stdout = {1};
FILE *stdout;
FILE __stderr = {2};
FILE *stderr;

int main(int, char *[]);

#include "setjmp.h"

int __return_code;
int __aborted;
jmp_buf __return_jump_buf;

void __init_stdlib() {
  __handles = &__builtin_handles;
  __aborted = 0;
  stdout = &__stdout;
  stderr = &__stderr;
}

// Nothing to do, for the moment
void __cleanup_stdlib() {
}

int fputs(const char *s, FILE *stream);

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
