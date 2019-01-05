#ifndef __SETJMP_H
#define __SETJMP_H

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

#define setjmp(env) (__handles->platform_setjmp(&(env)))
void longjmp(jmp_buf env, int status);

#include "asmc.h"

void longjmp(jmp_buf env, int status) {
  if (status == 0) status = 1;
  __handles->platform_longjmp(&env, status);
}

#endif
