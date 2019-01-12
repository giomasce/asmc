#ifndef __RUN_TCC_H
#define __RUN_TCC_H

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

#include <stdio.h>

#include "libtcc.h"

int run_tinycc(TCCState *state, int file_num, char **files, int include_path_num, char **include_paths) {
    int res;
    tcc_set_options(state, "-nostdlib -nostdinc");
    tcc_set_output_type(state, TCC_OUTPUT_MEMORY);
    while (include_path_num--) {
        res = tcc_add_include_path(state, *include_paths++);
        if (res) {
            printf("tcc_add_include_path() failed...\n");
            return 1;
        }
    }
    while (file_num--) {
        res = tcc_add_file(state, *files++);
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
    return 0;
}

#endif
