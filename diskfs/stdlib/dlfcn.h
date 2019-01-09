#ifndef __DLFCN_H
#define __DLFCN_H

#include "asmc.h"

#define RTLD_LAZY       0x001
#define RTLD_NOW        0x002
#define RTLD_GLOBAL     0x100
#define RTLD_DEFAULT    NULL

void *dlopen(const char *filename, int flags) {
    printf("Fail to dlopen(\"%s\")\n", filename);
    return NULL;
}

void *dlsym(void *handle, const char *symbol) {
    printf("Fail to dlsym(\"%s\")\n", symbol);
    return NULL;
}

int dlclose(void *handle) {
    return 1;
}

#endif
