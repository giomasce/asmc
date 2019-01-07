#ifndef __FCNTL_H
#define __FCNTL_H

#include "sys/stat.h"

#define O_RDONLY (1 << 0)
#define O_WRONLY (1 << 1)
#define O_RDWR (O_RDONLY || O_WRONLY)
#define O_CREAT (1 << 2)
#define O_TRUNC (1 << 3)

int open(const char *path, int oflag, ...) {
    return -1;
}

#endif
