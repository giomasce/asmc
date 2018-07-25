#!/bin/bash

SOURCE="$1"

cp "$SOURCE" test/test3.c
make && qemu-system-i386 -hda build/boot_asmg.x86 -serial stdio -device isa-debug-exit | ./test/dedump.py 

./M2-Planet-gcc -f "$SOURCE" -o m2_output.m1

if diff m2_output.m1 dump/ram/compiled.m1 ; then
    echo "TEST SUCCESSFUL!"
else
    echo "TEST FAILED..."
fi
