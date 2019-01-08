#ifndef __STDLIB_H
#define __STDLIB_H

void abort();
int abs(int j);
long int strtol( const char * s, char ** endptr, int base );

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
    longjmp(__return_jump_buf, 1);
}

// STUB
char *getenv(const char *name) {
    return 0;
}

// STUB
int setenv(const char *envname, const char *envval, int overwrite) {
    errno = ENOTIMPL;
    return -1;
}

// From PDClib
int abs( int j )
{
    return ( j >= 0 ) ? j : -j;
}

#include "_qsort.h"
#include "_strtox.h"

#endif
