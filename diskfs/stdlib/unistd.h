#ifndef __UNISTD_H
#define __UNISTD_H

#include "sys/stat.h"
#include "errno.h"

// STUB
int access(const char *path, int amode) {
    errno = ENOTIMPL;
    return -1;
}

// STUB
int isatty(int fildes) {
    errno = ENOTIMPL;
    return 0;
}

// STUB
ssize_t read(int fildes, void *buf, size_t nbyte) {
    errno = ENOTIMPL;
    return -1;
}

// STUB
char *getcwd(char *buf, size_t size) {
    errno = ENOTIMPL;
    return -1;
}

// STUB
int unlink(const char *path) {
    errno = ENOTIMPL;
    return -1;
}

// STUB
off_t lseek(int fildes, off_t offset, int whence) {
    errno = ENOTIMPL;
    return -1;
}

// STUB
int close(int fildes) {
    errno = ENOTIMPL;
    return -1;
}

// STUB
int ftruncate(int fildes, off_t length) {
    errno = ENOTIMPL;
    return -1;
}

#endif
