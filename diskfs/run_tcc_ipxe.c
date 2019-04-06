
#include "run_tcc.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "coros.h"

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
    ASMC_PREFIX,
    IPXE_PREFIX,
    IPXE_PREFIX "/include",
    IPXE_PREFIX "/arch/x86/include",
    IPXE_PREFIX "/arch/i386/include",
    IPXE_PREFIX "/arch/i386/include/pcbios",
};

const char *sources[][2] = {
    {ASMC_PREFIX "/run_ipxe.c", IPXE_TEMP "/run_ipxe.o"},
    {ASMC_PREFIX "/tinycc/lib/libtcc1.c", IPXE_TEMP "/libtcc1.o"},

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
    {IPXE_PREFIX "/drivers/net/intel.c", IPXE_TEMP "/intel.o"},
    {IPXE_PREFIX "/drivers/nvs/nvs.c", IPXE_TEMP "/nvs.o"},
    {IPXE_PREFIX "/core/iobuf.c", IPXE_TEMP "/iobuf.o"},
    {IPXE_PREFIX "/net/netdevice.c", IPXE_TEMP "/netdevice.o"},
    {IPXE_PREFIX "/core/settings.c", IPXE_TEMP "/settings.o"},
    {IPXE_PREFIX "/net/ethernet.c", IPXE_TEMP "/ethernet.o"},
    {IPXE_PREFIX "/core/uri.c", IPXE_TEMP "/uri.o"},
    {IPXE_PREFIX "/core/base16.c", IPXE_TEMP "/base16.o"},
    {IPXE_PREFIX "/core/base64.c", IPXE_TEMP "/base64.o"},
    {IPXE_PREFIX "/net/socket.c", IPXE_TEMP "/socket.o"},
    {IPXE_PREFIX "/core/basename.c", IPXE_TEMP "/basename.o"},
    {IPXE_PREFIX "/core/uuid.c", IPXE_TEMP "/uuid.o"},
    {IPXE_PREFIX "/core/random.c", IPXE_TEMP "/random.o"},
    {IPXE_PREFIX "/core/asprintf.c", IPXE_TEMP "/asprintf.o"},
    {IPXE_PREFIX "/arch/x86/interface/pcbios/rtc_time.c", IPXE_TEMP "/rtc_time.o"},
    {IPXE_PREFIX "/core/time.c", IPXE_TEMP "/time.o"},
    {IPXE_PREFIX "/net/nullnet.c", IPXE_TEMP "/nullnet.o"},
    {IPXE_PREFIX "/net/retry.c", IPXE_TEMP "/retry.o"},
    {IPXE_PREFIX "/core/fault.c", IPXE_TEMP "/fault.o"},
    {IPXE_PREFIX "/core/params.c", IPXE_TEMP "/params.o"},
    {IPXE_PREFIX "/net/netdev_settings.c", IPXE_TEMP "/netdev_settings.o"},
    {IPXE_PREFIX "/core/errno.c", IPXE_TEMP "/errno.o"},
    {IPXE_PREFIX "/net/udp/dhcp.c", IPXE_TEMP "/dhcp.o"},
    {IPXE_PREFIX "/net/dhcppkt.c", IPXE_TEMP "/dhcppkt.o"},
    {IPXE_PREFIX "/net/dhcpopts.c", IPXE_TEMP "/dhcpopts.o"},
    {IPXE_PREFIX "/net/udp.c", IPXE_TEMP "/udp.o"},
    {IPXE_PREFIX "/net/tcpip.c", IPXE_TEMP "/tcpip.o"},
    {IPXE_PREFIX "/net/ipv4.c", IPXE_TEMP "/ipv4.o"},
    {IPXE_PREFIX "/net/icmpv4.c", IPXE_TEMP "/icmpv4.o"},
    {IPXE_PREFIX "/net/fragment.c", IPXE_TEMP "/fragment.o"},
    {IPXE_PREFIX "/net/neighbour.c", IPXE_TEMP "/neighbour.o"},
    {IPXE_PREFIX "/net/arp.c", IPXE_TEMP "/arp.o"},
    {IPXE_PREFIX "/net/icmp.c", IPXE_TEMP "/icmp.o"},
    {IPXE_PREFIX "/crypto/crc32.c", IPXE_TEMP "/crc32.o"},
    {IPXE_PREFIX "/core/xfer.c", IPXE_TEMP "/xfer.o"},
    {IPXE_PREFIX "/core/open.c", IPXE_TEMP "/open.o"},
    {IPXE_PREFIX "/core/resolv.c", IPXE_TEMP "/resolv.o"},
    {IPXE_PREFIX "/net/ping.c", IPXE_TEMP "/ping.o"},
    {IPXE_PREFIX "/net/tcp.c", IPXE_TEMP "/tcp.o"},
    {IPXE_PREFIX "/core/cwuri.c", IPXE_TEMP "/cwuri.o"},
    {IPXE_PREFIX "/core/pending.c", IPXE_TEMP "/pending.o"},
    {IPXE_PREFIX "/interface/smbios/smbios_settings.c", IPXE_TEMP "/smbios_settings.o"},
    {IPXE_PREFIX "/interface/smbios/smbios.c", IPXE_TEMP "/smbios.o"},
    {IPXE_PREFIX "/arch/x86/interface/pcbios/bios_smbios.c", IPXE_TEMP "/bios_smbios.o"},
    {IPXE_PREFIX "/usr/ifmgmt.c", IPXE_TEMP "/ifmgmt.o"},
    {IPXE_PREFIX "/core/job.c", IPXE_TEMP "/job.o"},
    {IPXE_PREFIX "/core/monojob.c", IPXE_TEMP "/monojob.o"},
    {IPXE_PREFIX "/arch/x86/interface/pcbios/acpipwr.c", IPXE_TEMP "/acpipwr.o"},
    {IPXE_PREFIX "/drivers/net/virtio-net.c", IPXE_TEMP "/virtio-net.o"},
    {IPXE_PREFIX "/drivers/bus/virtio-pci.c", IPXE_TEMP "/virtio-pci.o"},
    {IPXE_PREFIX "/drivers/bus/virtio-ring.c", IPXE_TEMP "/virtio-ring.o"},
    {IPXE_PREFIX "/drivers/bus/pciextra.c", IPXE_TEMP "/pciextra.o"},
    /* {IPXE_PREFIX "/usr/autoboot.c", IPXE_TEMP "/autoboot.o"}, */
    /* {IPXE_PREFIX "/usr/prompt.c", IPXE_TEMP "/prompt.o"}, */
    /* {IPXE_PREFIX "/usr/route.c", IPXE_TEMP "/route.o"}, */
    /* {IPXE_PREFIX "/usr/route_ipv4.c", IPXE_TEMP "/route_ipv4.o"}, */
    /* {IPXE_PREFIX "/usr/imgmgmt.c", IPXE_TEMP "/imgmgmt.o"}, */
    /* {IPXE_PREFIX "/hci/shell.c", IPXE_TEMP "/shell.o"}, */
    /* {IPXE_PREFIX "/hci/readline.c", IPXE_TEMP "/readline.o"}, */
    /* {IPXE_PREFIX "/hci/editstring.c", IPXE_TEMP "/editstring.o"}, */
    /* {IPXE_PREFIX "/core/getkey.c", IPXE_TEMP "/getkey.o"}, */
    /* {IPXE_PREFIX "/core/exec.c", IPXE_TEMP "/exec.o"}, */
    /* {IPXE_PREFIX "/core/parseopt.c", IPXE_TEMP "/parseopt.o"}, */
    /* {IPXE_PREFIX "/core/getopt.c", IPXE_TEMP "/getopt.o"}, */
    /* {IPXE_PREFIX "/core/image.c", IPXE_TEMP "/image.o"}, */
    /* {IPXE_PREFIX "/core/downloader.c", IPXE_TEMP "/downloader.o"}, */
    /* {IPXE_PREFIX "/core/xferbuf.c", IPXE_TEMP "/xferbuf.o"}, */
    /* {IPXE_PREFIX "/core/menu.c", IPXE_TEMP "/menu.o"}, */
    /* {IPXE_PREFIX "/core/null_sanboot.c", IPXE_TEMP "/null_sanboot.o"}, */
    /* {IPXE_PREFIX "/core/sanboot.c", IPXE_TEMP "/sanboot.o"}, */
    /* {IPXE_PREFIX "/drivers/block/ata.c", IPXE_TEMP "/ata.o"}, */
    /* {IPXE_PREFIX "/core/blockdev.c", IPXE_TEMP "/blockdev.o"}, */
    /* {IPXE_PREFIX "/core/edd.c", IPXE_TEMP "/edd.o"}, */
    /* {IPXE_PREFIX "/core/quiesce.c", IPXE_TEMP "/quiesce.o"}, */
    {IPXE_PREFIX "/net/tcp/http.c", IPXE_TEMP "/http.o"},
    {IPXE_PREFIX "/net/tcp/httpcore.c", IPXE_TEMP "/httpcore.o"},
    {IPXE_PREFIX "/net/tcp/httpconn.c", IPXE_TEMP "/httpconn.o"},
    {IPXE_PREFIX "/core/pool.c", IPXE_TEMP "/pool.o"},
    {IPXE_PREFIX "/core/blockdev.c", IPXE_TEMP "/blockdev.o"},
    {IPXE_PREFIX "/core/linebuf.c", IPXE_TEMP "/linebuf.o"},
    {IPXE_PREFIX "/core/xferbuf.c", IPXE_TEMP "/xferbuf.o"},
    {IPXE_PREFIX "/usr/imgmgmt.c", IPXE_TEMP "/imgmgmt.o"},
    {IPXE_PREFIX "/core/image.c", IPXE_TEMP "/image.o"},
    {IPXE_PREFIX "/core/downloader.c", IPXE_TEMP "/downloader.o"},
    {IPXE_PREFIX "/net/udp/dns.c", IPXE_TEMP "/dns.o"},
};

#include "ipxe_handover.h"
#include "ipxe_asmc_structs.h"

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
        /* if (strcmp(sects[i].name, "timers") == 0) { */
        /*     printf("%s\n", *(char**)sects[i].data); */
        /* } */
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

ipxe_handover ih;

void push_to_ipxe(void *msg) {
    ipxe_list_push(&ih, &ih.to_ipxe, msg);
}

void *pop_from_ipxe() {
    return ipxe_list_pop(&ih, &ih.from_ipxe);
}

int main(int argc, char *argv[]) {
    printf("Here is where we compile iPXE!\n");

    int res;
    TCCState *state;

    // First compile all files
    for (int j = 0; j < sizeof(sources) / sizeof(sources[0]); j++) {
        printf("Compiling %s to %s...", sources[j][0], sources[j][1]);
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
        printf(" done!\n");
    }

    // Then link everything together
    printf("Linking IPXE...");
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
    printf(" done!\n");
    void (*main_symb)(void*) = tcc_get_symbol(state, "pre_main");
    if (!main_symb) {
        printf("tcc_get_symbol() failed...\n");
        return 1;
    }
    prepare_tables(state, &ih);
    ipxe_list_reset(&ih.to_ipxe);
    ipxe_list_reset(&ih.from_ipxe);
    ih.coro_yield = coro_yield;
    ih.malloc = malloc;
    ih.free = free;

    printf("Starting iPXE coroutine!\n");
    coro_t *coro_ipxe = coro_init(main_symb, &ih);
    coro_enter(coro_ipxe);

    const char *url = "http://www.example.com/";
    printf("Request to download %s\n", url);
    push_to_ipxe(strdup("download"));
    push_to_ipxe(strdup(url));
    coro_enter(coro_ipxe);
    downloaded_file *df = pop_from_ipxe();
    assert(df->size > 0);
    printf("Received document of %d bytes!\n", df->size);
    printf("---\n");
    for (size_t i = 0; i < df->size; i++) {
        putchar(df->data[i]);
    }
    printf("---\n");
    free(df->data);
    free(df);

    printf("Request to exit iPXE\n");
    push_to_ipxe(strdup("exit"));
    coro_enter(coro_ipxe);

    //res = main_symb(&ih);

    printf("Returning from iPXE!\n");
    coro_destroy(coro_ipxe);
    free_handover(&ih);
    tcc_delete(state);

    return res;
}

#include "libtcc.c"
