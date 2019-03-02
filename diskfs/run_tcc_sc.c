
#include "run_tcc.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#define USE_SOFTFLOAT 1
#define ONE_SOURCE 1
#include "tcc.h"

// Silence some internal tcc warnings
#undef free
#undef malloc
#undef realloc
#undef strdup

#define SC_PREFIX ASMC_PREFIX "/sc/src"
#define SC_TEMP "/ram/sc"

const char *includes[] = {
    ASMC_PREFIX,
    ASMC_PREFIX "/stdlib",
};

const char *sources[][2] = {
    {SC_PREFIX "/sch3.c", SC_TEMP "/sch3.o"},
};

char *sch3_argv[] = {
    "sch3",
    "/disk1/sch3.scm",
};

int main(int argc, char *argv[]) {
    printf("Here is where we compile single_cream!\n");

    int res;
    TCCState *state;

    // First compile all files
    for (int j = 0; j < sizeof(sources) / sizeof(sources[0]); j++) {
        state = tcc_new();
        tcc_set_options(state, "-nostdinc -nostdlib");
        tcc_set_output_type(state, TCC_OUTPUT_OBJ);
        char buf[1024];
        sprintf(buf, "%d", __get_handles());
        tcc_define_symbol(state, "__HANDLES", buf);
        for (int i = 0; i < sizeof(includes) / sizeof(includes[0]); i++) {
            res = tcc_add_include_path(state, includes[i]);
            if (res) {
                printf("tcc_add_include_path() failed...\n");
                return 1;
            }
        }
        res = tcc_add_file(state, sources[j][0]);
        if (res) {
            printf("tcc_add_file() failed...\n");
            return 1;
        }
        res = tcc_output_file(state, sources[j][1]);
        if (res) {
            printf("tcc_output_file() failed...\n");
            return 1;
        }
        tcc_delete(state);
    }

    // Then link everything together
    state = tcc_new();
    tcc_set_options(state, "-nostdinc -nostdlib");
    tcc_set_output_type(state, TCC_OUTPUT_MEMORY);
    for (int i = 0; i < sizeof(sources) / sizeof(sources[0]); i++) {
        res = tcc_add_file(state, sources[i][1]);
        if (res) {
            printf("tcc_add_file() failed...\n");
            return 1;
        }
    }
    res = tcc_relocate(state, TCC_RELOCATE_AUTO);
    if (res) {
        printf("tcc_relocate() failed...\n");
        return 1;
    }
    int (*start)(int, char *[]) = tcc_get_symbol(state, "_start");
    if (!start) {
        printf("tcc_get_symbol() failed...\n");
        return 1;
    }

    printf("Jumping into single_cream!\n");
    res = start(sizeof(sch3_argv)/sizeof(sch3_argv[0]), sch3_argv);
    printf("single_cream returned %d!\n", res);
    tcc_delete(state);

    return res;
}

#include "libtcc.c"
