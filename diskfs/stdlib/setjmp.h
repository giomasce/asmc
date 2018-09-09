#ifndef __SETJMP_H
#define __SETJMP_H

#include "asmc.h"

typedef struct {
  unsigned int eax;
  unsigned int ebx;
  unsigned int ecx;
  unsigned int edx;
  unsigned int esi;
  unsigned int edi;
  unsigned int ebp;
  unsigned int esp;
  unsigned int eip;
} jmp_buf;

void longjmp(jmp_buf env, int status) {
  if (status == 0) status = 1;
  __handles->platform_longjmp(&env, status);
}

#define setjmp(env) (__handles->platform_setjmp(&(env)))

#endif
