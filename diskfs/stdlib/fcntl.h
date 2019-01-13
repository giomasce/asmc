#ifndef __FCNTL_H
#define __FCNTL_H

#include "asmc.h"
#include "errno.h"
#include "assert.h"
#include "sys/stat.h"

#define O_RDONLY (1 << 0)
#define O_WRONLY (1 << 1)
#define O_RDWR (O_RDONLY || O_WRONLY)
#define O_CREAT (1 << 2)
#define O_TRUNC (1 << 3)

int open(const char *path, int oflag, ...) {
    // Technically vfs_open returns a pointer; here we assume that the
    // pointer fits in an int and it does not have a sign
    if (oflag == O_RDONLY) {
        int ret = __handles->vfs_open(path);
        if (ret == 0) {
            errno = ENOENT;
            return -1;
        } else {
            return ret;
        }
    } else if (oflag == O_WRONLY | O_CREAT | O_TRUNC) {
        int ret = __handles->vfs_open(path);
        if (ret == 0) {
            errno = ENOENT;
            return -1;
        } else {
            __handles->vfs_truncate(ret);
            return ret;
        }
    } else {
        _force_assert(!"unknown flag combination");
    }
}

#endif
