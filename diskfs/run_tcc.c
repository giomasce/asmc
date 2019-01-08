
// Allow the same code to be ran on the host machine, which is
// supposed to be x86_64
#ifdef __x86_64__

#define _GNU_SOURCE
#include <dlfcn.h>
#define TCC_TARGET_X86_64 1
#define CONFIG_TRIPLET "x86_64-linux-gnu"

#else

#define TCC_TARGET_I386 1
// Need this, otherwise tcc does not believe it can run natively
#define __i386__ 1

#endif

#include <stdio.h>
#include <stdlib.h>

void receive_error(void *ctx, const char *msg) {
    printf("Received error: '%s'\n", msg);
}

#include "libtcc.h"

int main(int argc, char *argv[]) {
    int res;
    TCCState *state = tcc_new();
    tcc_set_options(state, "-nostdlib -nostdinc");
    tcc_set_error_func(state, NULL, receive_error);
    tcc_set_output_type(state, TCC_OUTPUT_MEMORY);
    res = tcc_compile_string(state, "int main() { return 1234; }");
    if (res) {
        printf("tcc_compile_string() failed\n");
        return 1;
    }
    int size = tcc_relocate(state, NULL);
    if (size == -1) {
        printf("first tcc_relocate() failed\n");
        return 1;
    }
    void *program = malloc(size);
    res = tcc_relocate(state, program);
    if (res == -1) {
        printf("second tcc_relocate() failed\n");
        return 1;
    }
    int (*main_symbol)(int, char**) = tcc_get_symbol(state, "main");
    if (!main_symbol) {
        printf("tcc_get_symbol() failed\n");
        return 1;
    }
    int ret = main_symbol(0, 0);
    //int ret = tcc_run(state, 0, 0);
    printf("Returned %d\n", ret);
    //tcc_output_file(state, "tcc.out");
    free(program);
    tcc_delete(state);
    return 0;
}

#define USE_SOFTFLOAT 1
#define ONE_SOURCE 1

#include "libtcc.c"
