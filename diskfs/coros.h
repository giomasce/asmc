
#include <assert.h>
#include <stdbool.h>
#include <string.h>
#include <setjmp.h>

typedef struct {
    bool runnable;
    void *stack;
    void (*target)(void*);
    void *ctx;
    jmp_buf caller_regs;
    jmp_buf callee_regs;
} coro_t;

coro_t *curr_coro;

void coro_enter(coro_t *coro) {
    _force_assert(!curr_coro);
    _force_assert(coro->runnable);
    curr_coro = coro;
    if (setjmp(coro->caller_regs) == 0) {
        longjmp(coro->callee_regs, 1);
    }
    curr_coro = NULL;
}

void coro_yield() {
    coro_t *coro = curr_coro;
    _force_assert(coro);
    _force_assert(curr_coro);
    if (setjmp(coro->callee_regs) == 0) {
        longjmp(coro->caller_regs, 1);
    }
}

void coro_wrapper() {
    coro_t *coro = curr_coro;
    _force_assert(coro);
    coro->target(coro->ctx);
    coro->runnable = false;
    coro_yield();
    // We should not arrive here, because we cannot return!
    _force_assert(false);
}

coro_t *coro_init_with_stack_size(void (*target)(void*), void *ctx, size_t stack_size) {
    coro_t *ret = malloc(sizeof(coro_t));
    memset(ret, 0, sizeof(coro_t));
    ret->runnable = true;
    ret->stack = malloc(stack_size);
    ret->target = target;
    ret->ctx = ctx;
    ret->callee_regs.esp = ((unsigned long) ret->stack) + stack_size;
    ret->callee_regs.eip = (unsigned long) &coro_wrapper;
    return ret;
}

coro_t *coro_init(void (*target)(void*), void *ctx) {
    return coro_init_with_stack_size(target, ctx, 65536);
}

void coro_destroy(coro_t *coro) {
    _force_assert(!coro->runnable);
    free(coro->stack);
    free(coro);
}
