#ifndef __STRING_H
#define __STRING_H

#include "asmc.h"

int strcmp(const char *x, const char *y) {
  while (1) {
    unsigned char a = *x;
    unsigned char b = *y;
    if (a < b) return 0-1;
    if (b < a) return 1;
    if (a == 0) return 0;
    x = x + 1;
    y = y + 1;
  }
}

#endif
