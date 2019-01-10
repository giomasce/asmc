
// Allow the same code to be ran on the host machine, which is
// supposed to be x86_64
#ifdef __x86_64__

#define _GNU_SOURCE
#include <dlfcn.h>
//#define TCC_TARGET_I386
#define TCC_TARGET_X86_64 1
//#define CONFIG_TRIPLET "x86_64-linux-gnu"

#define ASMC_PREFIX "./diskfs"

int __get_handles() {
    return 0;
}

#else

#define TCC_TARGET_I386 1
// Need this, otherwise tcc does not believe it can run natively
#define __i386__ 1

#define ASMC_PREFIX "/disk1"

#endif

#ifndef LEVEL
#define LEVEL 0
#endif

#include <stdio.h>
#include <stdlib.h>

#include "libtcc.h"

void receive_error(void *ctx, const char *msg) {
    printf("Received error: '%s'\n", msg);
}

int recursively_compile() {
#if LEVEL == 10
    printf("Let's not get mad...\n");
    return 0;
#endif

    int res;
    TCCState *state = tcc_new();
    tcc_set_options(state, "-nostdlib -nostdinc");
    tcc_set_error_func(state, NULL, receive_error);
    tcc_set_output_type(state, TCC_OUTPUT_MEMORY);

    printf("I will now try to compile and execute tinycc recursively! (level %d)\n", LEVEL);

    char buf[1024];
    sprintf(buf, "%d", __get_handles());
    tcc_define_symbol(state, "__HANDLES", buf);
    sprintf(buf, "%d", LEVEL+1);
    tcc_define_symbol(state, "LEVEL", buf);

    res = tcc_add_include_path(state, ASMC_PREFIX);
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }
    res = tcc_add_include_path(state, ASMC_PREFIX "/stdlib");
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }
    res = tcc_add_include_path(state, ASMC_PREFIX "/tinycc");
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }
    res = tcc_add_include_path(state, ASMC_PREFIX "/tinycc-aux");
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }
    res = tcc_add_include_path(state, ASMC_PREFIX "/tinycc/softfloat");
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }
    res = tcc_add_include_path(state, ASMC_PREFIX "/tinycc/softfloat/include");
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }
    res = tcc_add_include_path(state, ASMC_PREFIX "/tinycc/softfloat/8086");
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }

    res = tcc_add_file(state, ASMC_PREFIX "/run_tcc.c");
    if (res) {
        printf("tcc_add_file() failed\n");
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

    int (*start)() = tcc_get_symbol(state, "_start");
    if (!start) {
        printf("tcc_get_symbol() failed\n");
        return 1;
    }
    printf("Recurring into the next tinycc...\n");
    int ret = start();
    printf("The program returned %d!\n", ret);
    free(program);

    tcc_delete(state);
    return 0;
}

int test_gauss() {
    int res;
    TCCState *state = tcc_new();
    tcc_set_options(state, "-nostdlib -nostdinc");
    tcc_set_error_func(state, NULL, receive_error);
    tcc_set_output_type(state, TCC_OUTPUT_MEMORY);

    printf("I will now compile and execute a small test program with tinycc!\n");

    char buf[1024];
    sprintf(buf, "%d", __get_handles());
    tcc_define_symbol(state, "__HANDLES", buf);

    res = tcc_add_include_path(state, ASMC_PREFIX);
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }
    res = tcc_add_include_path(state, ASMC_PREFIX "/stdlib");
    if (res) {
        printf("tcc_add_include_path() failed\n");
        return 1;
    }

    res = tcc_compile_string(state, "#include <stdio.h>\nint main(){} int gauss_sum(int max) { printf(\"Hello from inside!\\n\"); int sum = 0; for (int i = 0; i <= max; i++) sum += i; return sum; }");
    //res = tcc_add_file(state, "diskfs/test.c");
    if (res) {
        printf("tcc_compile_string() failed\n");
        return 1;
    }

    //tcc_output_file(state, "output.o");

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

    void (*init_stdlib)() = tcc_get_symbol(state, "__init_stdlib");
    if (init_stdlib) {
        printf("Initializing the standard library... ");
        init_stdlib();
        printf(" done!\n");
    }

    int (*gauss_sum)(int) = tcc_get_symbol(state, "gauss_sum");
    if (!gauss_sum) {
        printf("tcc_get_symbol() failed\n");
        return 1;
    }
    printf("Running the program...\n");
    int ret = gauss_sum(100);
    printf("The program returned %d!\n", ret);
    free(program);

    tcc_delete(state);
    return 0;
}

int main(int argc, char *argv[]) {
    if (test_gauss()) {
        printf("Gauss test failed...\n");
        return 1;
    }
    return recursively_compile();
}

//#if LEVEL == 0
#define USE_SOFTFLOAT 1
//#endif
#define ONE_SOURCE 1

#include "libtcc.c"
