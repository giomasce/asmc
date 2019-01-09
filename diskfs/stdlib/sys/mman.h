#ifndef __SYS_MMAN_H
#define __SYS_MMAN_H

#include "asmc_types.h"
#include "errno.h"

#define PROT_NONE 0
#define PROT_EXEC (1 << 0)
#define PROT_READ (1 << 1)
#define PROT_WRITE (1 << 2)

#define MAP_FAILED NULL

int mprotect(void *addr, size_t len, int prot) {
    if (prot == PROT_READ | PROT_WRITE | PROT_EXEC) {
        // There is no protection, so all memory is automatically rwx
        return 0;
    } else {
        errno = ENOTIMPL;
        return -1;
    }
}

// STUB
void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off) {
    __unimplemented();
    return MAP_FAILED;
}

#endif
