#ifndef __ASMC_H
#define __ASMC_H

// Remove some language features that are not supported by the
// compiler

// const is just a correctness checker, which can just be removed; we
// assume that the program is correct instead of verifying it. Inline
// is useless, because the compiler does not have a linking phase
#define const
#define inline

// Same for static assertions: we assume they are correct; since the
// compiler does not support empty statements, we replace the static
// assertion with "int", making the statement into an empty
// declaration
#define _Static_assert(cond, msg) int

// Ignore GCC __attribute__ constructs
#define __attribute__(x)

#define NULL ((void*)0)

typedef int ssize_t;
typedef unsigned int size_t;

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
