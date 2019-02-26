# Low level assumptions in `asmc`

This is a (currently incomplete and informal) list of things `asmc`
currently assumes on the underlying computing platform.

## Processor

An x86 CPU which implements at least the following features and
instructions.

### Standard stuff used all over

 * CPU capable of running in 32 bit protected mode with flat
   segmenting, no paging and disabled interrupts.

 * Stack manipulation instructions: push, pop

 * Arithmetic instructions: mov, add, sub, cmp, mul, div, neg

 * Bit manipulation instructions: and, or, xor, not, shl, shr, sar, test

 * Control flow instructions: near call, near ret, near jmp, jcc, hlt

 * IO instructions: in, out

### Boot loader

 * CPU capable of running in 16 bit real mode.

 * Segmenting instructions: mov to segment, far jump, lgdt

 * Interrupt instructions: int, cli

### Kernel and G compiler

### G compiler generated code

 * Arithmetic instructions: lea, idiv, imul, cdq

### 64 bit numbers support

## Firmware

A standard-ish BIOS interface.

## Devices

 * A standard disk controller accessible through its ATA PIO mode
   interface on ports 0x1f0-0x1f7.
