
/* Stuff is a bit complicated here, because we are already in iPXE
   namespace, so we cannot use asmc's stdlib, because it would clash
   with iPXE. OTOH, iPXE stuff is not yet initialized. So we just pass
   a few pointers with the needed library functions and data. Clearly,
   type definitions in this file must be manually kept in sync with
   their original versions. */

#include "ipxe_handover.h"

int main();

ipxe_handover *ih;

int pre_main(ipxe_handover *ih_) {
    ih = ih_;
    return main();
}

static table_sect *find_section(const char *name) {
    int i;
    for (i = 0; i < ih->sects_num; i++) {
        const char *name2 = ih->sects[i].name;
        int j;
        for (j = 0; ; j++) {
            if (name[j] != name2[j]) break;
            if (name2[j] == '\0') {
                return &ih->sects[i];
            }
        }
    }
    return 0;
}

// Just a random number, but such that subtracting any reasonable
// structure size does not wrap around (otherwise reverse for cycles
// choke).
#define EMPTY_LIST ((void*) 0x100000)

void *get_table_start(const char *name) {
    table_sect *sect = find_section(name);
    if (!sect) return EMPTY_LIST;
    return sect->data;
}

void *get_table_end(const char *name) {
    table_sect *sect = find_section(name);
    if (!sect) return EMPTY_LIST;
    return sect->data + sect->len;
}
