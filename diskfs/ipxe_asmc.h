
#include "ipxe_asmc_structs.h"

int main(void);

void *get_table_start(const char *name);
void *get_table_end(const char *name);

void *asmc_malloc(size_t size);
void asmc_free(void *ptr);

void push_to_asmc(void *msg);
void *pop_from_asmc(void);

void coro_yield(void);
