#ifndef __STDLIB_H
#define __STDLIB_H

#include "asmc_types.h"

void abort();
int abs(int j);
long int strtol( const char * s, char ** endptr, int base );
void *malloc(size_t size);
void free(void *ptr);

#include "asmc.h"
#include "errno.h"

void *malloc(size_t size) {
  return __handles->malloc(size);
}

void *calloc(size_t num, size_t size) {
  return __handles->calloc(num, size);
}

void free(void *ptr) {
  __handles->free(ptr);
}

void *realloc(void *ptr, size_t new_size) {
  return __handles->realloc(ptr, new_size);
}

void exit(int return_code) {
    __return_code = return_code;
    longjmp(__return_jump_buf, 1);
}

void abort() {
    __return_code = -1;
    __aborted = 1;
    __dump_stacktrace();
    longjmp(__return_jump_buf, 1);
}

// STUB
char *getenv(const char *name) {
    __unimplemented();
    return 0;
}

// STUB
int setenv(const char *envname, const char *envval, int overwrite) {
    __unimplemented();
    errno = ENOTIMPL;
    return -1;
}

// STUB
int mkstemp(char *template) {
    __unimplemented();
    errno = ENOTIMPL;
    return -1;
}

// From PDClib
int abs( int j )
{
    return ( j >= 0 ) ? j : -j;
}

#define RAND_MAX (1U << 31)

unsigned _seed;

// Very bad generator, but who cares
int rand() {
    _seed = (1103515245 * _seed + 12345) % RAND_MAX;
    return _seed;
}

void srand(unsigned seed) {
    _seed = seed;
}

// In line of principle a better RNG is mandated, but again who cares
long int random() {
    return rand();
}

void srandom(unsigned seed) {
    srand(seed);
}

#include "_qsort.h"
#include "_strtox.h"

#endif
