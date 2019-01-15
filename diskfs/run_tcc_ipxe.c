
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
    {ASMC_PREFIX "/run_ipxe.c", IPXE_TEMP "/run_ipxe.o"},
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
    {IPXE_PREFIX "/core/interface.c", IPXE_TEMP "/interface.o"},
    {IPXE_PREFIX "/core/device.c", IPXE_TEMP "/device.o"},
    {IPXE_PREFIX "/drivers/bus/pci.c", IPXE_TEMP "/pci.o"},
    {IPXE_PREFIX "/arch/x86/core/pcidirect.c", IPXE_TEMP "/pcidirect.o"},
    {IPXE_PREFIX "/core/debug.c", IPXE_TEMP "/debug.o"},
    {IPXE_PREFIX "/core/timer.c", IPXE_TEMP "/timer.o"},
    {IPXE_PREFIX "/arch/x86/core/rdtsc_timer.c", IPXE_TEMP "/rdtsc_timer.o"},
    {IPXE_PREFIX "/arch/x86/core/pit8254.c", IPXE_TEMP "/pit8254.o"},
    {IPXE_PREFIX "/arch/x86/core/cpuid.c", IPXE_TEMP "/cpuid.o"},
    {IPXE_PREFIX "/arch/x86/interface/pcbios/acpi_timer.c", IPXE_TEMP "/acpi_timer.o"},
    {IPXE_PREFIX "/core/acpi.c", IPXE_TEMP "/acpi.o"},
    {IPXE_PREFIX "/arch/x86/interface/pcbios/rsdp.c", IPXE_TEMP "/rsdp.o"},
    {IPXE_PREFIX "/core/string.c", IPXE_TEMP "/string.o"},
    {IPXE_PREFIX "/core/ctype.c", IPXE_TEMP "/ctype.o"},
};

#include "ipxe_handover.h"

int table_comp(void *t1, void *t2) {
    table_sect *s1 = t1;
    table_sect *s2 = t2;
    return strcmp(s1->name, s2->name);
}

char *memdup(void *data, size_t len) {
    char *ret = malloc(len);
    memcpy(ret, data, len);
    return ret;
}

char *memappend(char *dest, size_t dest_size, char *src, size_t src_size) {
    dest = realloc(dest, dest_size + src_size);
    memcpy(dest + dest_size, src, src_size);
    return dest;
}

// This function manually performs the linker script trick used by
// iPXE to support linking-time tables, which the tcc linker is not
// powerful enough to do for us
void prepare_tables(TCCState *state, ipxe_handover *ih) {
    int i;
    table_sect *subsects = malloc(sizeof(table_sect) * state->nb_sections);
    int subsects_num = 0;
    for (i = 1; i < state->nb_sections; i++) {
        char *name = state->sections[i]->name;
        if (strncmp(name, ".tbl.", 5) == 0) {
            subsects[subsects_num].name = strdup(name + 5);
            subsects[subsects_num].data = (char*) state->sections[i]->sh_addr;
            subsects[subsects_num].len = state->sections[i]->data_offset;
            subsects_num++;
        }
    }

    // Funny cast to acquiesce tcc warning about incompatible pointers
    qsort(subsects, subsects_num, sizeof(table_sect), (int (*)(const void *, const void *))table_comp);

    /*printf("Subsections:\n");
    for (i = 0; i < subsects_num; i++) {
        printf(" * %s (addr: %x, size: %d)\n", subsects[i].name, subsects[i].data, subsects[i].len);
    }*/

    table_sect *sects = malloc(sizeof(table_sect) * subsects_num);
    int sects_num = 0;
    for (i = 0; i < subsects_num; i++) {
        char *subsect_name = subsects[i].name;
        char *dot_pos = strchr(subsect_name, '.');
        assert(dot_pos);
        size_t name_len = dot_pos - subsect_name;
        // We also check the dot in order not to be fooled by prefixes
        if (sects_num == 0 || strncmp(subsect_name, sects[sects_num-1].name, name_len + 1) != 0) {
            // New section
            sects[sects_num].name = subsects[i].name;
            sects[sects_num].name[name_len+1] = '\0';
            sects[sects_num].data = memappend(NULL, 0, subsects[i].data, subsects[i].len);
            sects[sects_num].len = subsects[i].len;
            sects_num++;
        } else {
            // Continuing previous section
            sects[sects_num-1].data = memappend(sects[sects_num-1].data, sects[sects_num-1].len,
                                                subsects[i].data, subsects[i].len);
            sects[sects_num-1].len += subsects[i].len;
            free(subsects[i].name);
        }
    }
    free(subsects);

    printf("Sections:\n");
    for (i = 0; i < sects_num; i++) {
        // Finally cut away the dot
        sects[i].name[strlen(sects[i].name)-1] = '\0';
        printf(" * %s (addr: %x, size: %d)\n", sects[i].name, sects[i].data, sects[i].len);
    }

    ih->sects_num = sects_num;
    ih->sects = sects;
}

void free_handover(ipxe_handover *ih) {
    int i;
    for (i = 0; i < ih->sects_num; i++) {
        free(ih->sects[i].name);
        free(ih->sects[i].data);
    }
    free(ih->sects);
}

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
    int (*main_symb)(ipxe_handover*) = tcc_get_symbol(state, "pre_main");
    if (!main_symb) {
        printf("tcc_get_symbol() failed...\n");
        return 1;
    }
    ipxe_handover ih;
    prepare_tables(state, &ih);

    printf("Jumping into iPXE!\n");
    res = main_symb(&ih);
    free_handover(&ih);
    tcc_delete(state);

    return res;
}

#include "libtcc.c"
