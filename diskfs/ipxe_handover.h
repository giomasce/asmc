#ifndef __IPXE_HANDOVER_H
#define __IPXE_HANDOVER_H

#ifndef __ASMC_TYPES_H
typedef unsigned int size_t;
#endif

typedef struct {
    char *name;
    char *data;
    int len;
} table_sect;

typedef struct ipxe_list_elem {
    struct ipxe_list_elem *next;
    void *msg;
} ipxe_list_elem;

typedef struct ipxe_list {
    ipxe_list_elem *head;
    ipxe_list_elem *tail;
} ipxe_list;

typedef struct {
    int sects_num;
    table_sect *sects;
    ipxe_list to_ipxe;
    ipxe_list from_ipxe;
    void (*coro_yield)();
    void *(*malloc)(size_t size);
    void (*free)(void *ptr);
} ipxe_handover;

static void ipxe_list_reset(ipxe_list *list) {
    list->head = 0;
    list->tail = 0;
}

static void ipxe_list_push(ipxe_handover *ih, ipxe_list *list, void *msg) {
    ipxe_list_elem *e = ih->malloc(sizeof(ipxe_list_elem));
    e->next = 0;
    e->msg = msg;
    if (!list->head) {
        // Empty list, this is the first and last item
        list->head = e;
        list->tail = e;
    } else {
        // Pushing after tail
        list->tail->next = e;
        list->tail = e;
    }
}

static void *ipxe_list_pop(ipxe_handover *ih, ipxe_list *list) {
    ipxe_list_elem *e = list->head;
    if (!e) {
        // Empty list, return zero
        return 0;
    } else {
        // Return head element
        void *msg = e->msg;
        list->head = e->next;
        if (!list->head) {
            list->tail = 0;
        }
        ih->free(e);
        return msg;
    }
}

#endif
