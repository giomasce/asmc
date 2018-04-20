
all: asmc

asmc.o: asmc.asm
	nasm -f elf -F dwarf -g asmc.asm

syscall.o: syscall.asm
	nasm -f elf -F dwarf -g syscall.asm

staging.o: staging.c
	gcc -m32 -c -Og -g -ffreestanding staging.c -o staging.o

asmc: asmc.o staging.o syscall.o
	ld -g -m elf_i386 asmc.o staging.o syscall.o -o asmc
