#include "asmc.h"

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
