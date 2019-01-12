
#include "run_tcc.h"

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    printf("Here is where we compile iPXE!\n");
    return 0;
}

// Include the actual tinycc compiler
#define USE_SOFTFLOAT 1
#define ONE_SOURCE 1

#include "libtcc.c"
