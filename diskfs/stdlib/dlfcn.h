#ifndef __DLFCN_H
#define __DLFCN_H

#define RTLD_LAZY       0x001
#define RTLD_NOW        0x002
#define RTLD_GLOBAL     0x100
#define RTLD_DEFAULT    NULL

// STUB
void *dlopen(const char *filename, int flags) {
    return NULL;
}

// STUB
void *dlsym(void *handle, const char *symbol) {
    return NULL;
}

// STUB
int dlclose(void *handle) {
    return 1;
}

#endif
