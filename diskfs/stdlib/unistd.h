#ifndef __UNISTD_H
#define __UNISTD_H

#include "sys/stat.h"
#include "errno.h"

int access(const char *path, int amode) {
    errno = ENOTIMPL;
    return -1;
}

int isatty(int fildes) {
    errno = ENOTIMPL;
    return 0;
}

ssize_t read(int fildes, void *buf, size_t nbyte) {
    errno = ENOTIMPL;
    return -1;
}

char *getcwd(char *buf, size_t size) {
    errno = ENOTIMPL;
    return -1;
}

int unlink(const char *path) {
    errno = ENOTIMPL;
    return -1;
}

off_t lseek(int fildes, off_t offset, int whence) {
    errno = ENOTIMPL;
    return -1;
}

#endif
