#ifndef __ASMC_TYPES_H
#define __ASMC_TYPES_H

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

#endif
