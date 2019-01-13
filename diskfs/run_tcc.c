
#include "run_tcc.h"

#include <stdio.h>
#include <stdlib.h>

#ifndef LEVEL
#define LEVEL 0
#endif

// Uncomment this to have fun with compilation recursion!
//#define JUST_FOR_FUN

int recursively_compile() {
#if LEVEL == 10
    printf("Let's not get mad, stopping recursion...\n");
    return 0;
#endif

    const char *includes[7];
    includes[0] = ASMC_PREFIX;
    includes[1] = ASMC_PREFIX "/stdlib";
    includes[2] = ASMC_PREFIX "/tinycc-aux";
    includes[3] = ASMC_PREFIX "/tinycc";
    includes[4] = ASMC_PREFIX "/tinycc/softfloat";
    includes[5] = ASMC_PREFIX "/tinycc/softfloat/include";
    includes[6] = ASMC_PREFIX "/tinycc/softfloat/8086";
    const char *files[1];

#if LEVEL == 1 && !defined(JUST_FOR_FUN)
    files[0] = ASMC_PREFIX "/run_tcc_ipxe.c";
    printf("I will now try to compile and execute tinycc, diverting to iPXE! (level %d)\n", LEVEL);
#else
    files[0] = ASMC_PREFIX "/run_tcc.c";
    printf("I will now try to compile and execute tinycc recursively! (level %d)\n", LEVEL);
#endif

    TCCState *state = tcc_new();
    char buf[1024];
    sprintf(buf, "%d", __get_handles());
    tcc_define_symbol(state, "__HANDLES", buf);
    sprintf(buf, "%d", LEVEL+1);
    tcc_define_symbol(state, "LEVEL", buf);

    if (run_tinycc(state, sizeof(files) / sizeof(files[0]), files,
                   sizeof(includes) / sizeof(includes[0]), includes)) {
        "tinycc invocation failed...\n";
        return 1;
    }

    int (*start)() = tcc_get_symbol(state, "_start");
    if (!start) {
        printf("tcc_get_symbol() failed\n");
        return 1;
    }
    printf("Entering tinycc...\n");
    int ret = start();
    printf("The program returned %d!\n", ret);

    tcc_delete(state);
    return 0;
}

int main(int argc, char *argv[]) {
    if (recursively_compile()) {
        printf("Recursive compilation failed...\n");
        return 1;
    }
    return 0;
}

// Include the actual tinycc compiler
#define USE_SOFTFLOAT 1
#define ONE_SOURCE 1

#include "libtcc.c"
