#ifndef __ASMC_TYPES_H
#define __ASMC_TYPES_H

#ifdef __ASMC_COMP__
// Remove some language features that are not supported by the
// compiler

// const is just a correctness checker, which can just be removed; we
// assume that the program is correct instead of verifying it. Inline
// is useless, because the compiler does not have a linking phase
#define const
#define inline

// Ignore GCC __attribute__ constructs
#define __attribute__(x)
#endif

#ifdef __TINYC__
#include "tinycc/lib/libtcc1.c"
#endif

#define NULL ((void*)0)

typedef int ssize_t;
typedef unsigned int size_t;

// tinycc expects a very early definition of memmove, otherwise it
// fails (probably because it tries to define it internally, but then
// the two definitions clash)
void * memmove( void * s1, const void * s2, size_t n );

typedef struct {
  int fd;
} FILE;

#endif
