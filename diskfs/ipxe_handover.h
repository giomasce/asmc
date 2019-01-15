
typedef struct {
    char *name;
    char *data;
    int len;
} table_sect;

typedef struct {
    int sects_num;
    table_sect *sects;
} ipxe_handover;
