#ifndef __ASMC_H
#define __ASMC_H

#define const
#define NULL 0

typedef int ssize_t;
typedef unsigned int size_t;

struct __handles_t {
  void (*platform_write_char)(int fd, char c);
  void *(*malloc)(size_t size);
  void *(*calloc)(size_t num, size_t size);
  void (*free)(void *ptr);
  void *(*realloc)(void *ptr, size_t new_size);
};

struct __handles_t *__handles;

typedef struct {
  int fd;
} FILE;

FILE __stdout = {1};
FILE *stdout;
FILE __stderr = {1};
FILE *stderr;

int main(int, char *[]);

void __init_stdlib() {
  __handles = &__builtin_handles;
  stdout = &__stdout;
  stderr = &__stderr;
}

int _start(int argc, char *argv[]) {
  __init_stdlib();
  return main(argc, argv);
}

#endif
