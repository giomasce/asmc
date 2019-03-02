#ifndef __UNISTD_H
#define __UNISTD_H

#include "asmc.h"
#include "sys/stat.h"
#include "errno.h"

// STUB
int access(const char *path, int amode) {
    __unimplemented();
    errno = ENOTIMPL;
    return -1;
}

// STUB
int isatty(int fildes) {
    __unimplemented();
    errno = ENOTIMPL;
    return 0;
}

ssize_t read(int fildes, void *buf, size_t nbyte) {
    if (fildes == 1 || fildes == 2) {
        return 0;
    }
    if (nbyte == 0) {
        return 0;
    }
    int c;
    if (fildes == 0) {
        c = __handles->kbd_getc();
        // Loop back character to console
        __handles->write(c);
    } else {
        c = __handles->vfs_read(fildes);
    }
    if (c < 0) {
        return 0;
    } else {
        _force_assert(0 <= c && c < 256);
        *(char*)buf = (char) c;
        return 1;
    }
}

// STUB
char *getcwd(char *buf, size_t size) {
    __unimplemented();
    errno = ENOTIMPL;
    return NULL;
}

// Just ignore unlink
int unlink(const char *path) {
    return 0;
}

off_t lseek(int fildes, off_t offset, int whence) {
    //printf("seeking at %d from %d\n", offset, whence);
    return __handles->vfs_seek(whence, offset, fildes);
}

int close(int fildes) {
    __handles->vfs_close(fildes);
    return 0;
}

// STUB
int ftruncate(int fildes, off_t length) {
    __unimplemented();
    errno = ENOTIMPL;
    return -1;
}

#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

#endif
