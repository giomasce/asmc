
#include "run_tcc.h"

#include <stdio.h>
#include <stdlib.h>

#define IPXE_PREFIX ASMC_PREFIX "/ipxe/src"
#define IPXE_TEMP "/ram/ipxe"

const char *includes[] = {
    IPXE_PREFIX,
    IPXE_PREFIX "/include",
    IPXE_PREFIX "/arch/x86/include",
    IPXE_PREFIX "/arch/i386/include",
    IPXE_PREFIX "/arch/i386/include/pcbios",
};

const char *sources[][2] = {
    {IPXE_PREFIX "/core/main.c", IPXE_TEMP "/main.o"},
    {IPXE_PREFIX "/core/init.c", IPXE_TEMP "/init.o"},
    {IPXE_PREFIX "/core/vsprintf.c", IPXE_TEMP "/vsprintf.o"},
    {IPXE_PREFIX "/core/console.c", IPXE_TEMP "/console.o"},
    {IPXE_PREFIX "/arch/x86/interface/pcbios/bios_nap.c", IPXE_TEMP "/bios_nap.o"},
    {IPXE_PREFIX "/core/process.c", IPXE_TEMP "/process.o"},
    {IPXE_PREFIX "/core/refcnt.c", IPXE_TEMP "/refcnt.o"},
    {IPXE_PREFIX "/core/list.c", IPXE_TEMP "/list.o"},
    {IPXE_PREFIX "/core/malloc.c", IPXE_TEMP "/malloc.o"},
    {IPXE_PREFIX "/arch/x86/core/x86_string.c", IPXE_TEMP "/x86_string.o"},
    {IPXE_PREFIX "/core/serial.c", IPXE_TEMP "/serial.o"},
    {IPXE_PREFIX "/core/uart.c", IPXE_TEMP "/uart.o"},
    {IPXE_PREFIX "/arch/x86/core/x86_uart.c", IPXE_TEMP "/x86_uart.o"},
};

int main(int argc, char *argv[]) {
    printf("Here is where we compile iPXE!\n");

    int res;
    TCCState *state;

    // First compile all files
    for (int j = 0; j < sizeof(sources) / sizeof(sources[0]); j++) {
        state = tcc_new();
        tcc_set_options(state, "-nostdinc -nostdlib -include " IPXE_PREFIX "/include/compiler.h");
        tcc_set_output_type(state, TCC_OUTPUT_OBJ);
        tcc_define_symbol(state, "ARCH", "i386");
        tcc_define_symbol(state, "PLATFORM", "pcbios");
        tcc_define_symbol(state, "SECUREBOOT", "0");
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
    //res = tcc_output_file(state, IPXE_TEMP "/ipxe.o");
    res = tcc_relocate(state, TCC_RELOCATE_AUTO);
    if (res) {
        printf("tcc_relocate() failed...\n");
        return 1;
    }
    int (*main_symb)() = tcc_get_symbol(state, "main");
    if (!main_symb) {
        printf("tcc_get_symbol() failed...\n");
        return 1;
    }
    printf("Jumping into iPXE!\n");
    res = main_symb();
    tcc_delete(state);

    return res;
}

// Include the actual tinycc compiler
#define USE_SOFTFLOAT 1
#define ONE_SOURCE 1

#include "libtcc.c"
