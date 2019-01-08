
#include <stdio.h>

#define USE_SOFTFLOAT 1
#define ONE_SOURCE 1
#define TCC_TARGET_I386 1

#include "libtcc.h"
#include "libtcc.c"

int main(int argc, char *argv[]) {
    TCCState *state = tcc_new();
    tcc_delete(state);
    return 0;
}
