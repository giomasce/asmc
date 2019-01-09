#ifndef __SYS_STAT_H
#define __SYS_STAT_H

#include "asmc.h"
#include "errno.h"
#include "sys/types.h"

#define S_IRWXU 0700
#define S_IRUSR 0400
#define S_IWUSR 0200
#define S_IXUSR 0100
#define S_IRWXG 0070
#define S_IRGRP 0040
#define S_IWGRP 0020
#define S_IXGRP 0010
#define S_IRWXO 0007
#define S_IROTH 0004
#define S_IWOTH 0002
#define S_IXOTH 0001
#define S_ISUID 04000
#define S_ISGID 02000
#define S_ISVTX 01000

// STUB
int chmod(const char *path, mode_t mode) {
    __unimplemented();
    errno = ENOTIMPL;
    return -1;
}

#endif
