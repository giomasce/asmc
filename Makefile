
all: asmc

asmc.o: asmc.asm
	nasm -f elf -F dwarf -g asmc.asm

staging.o: staging.c platform.h
	gcc -m32 -c -Og -g -ffreestanding staging.c -o staging.o

platform.o: platform.c platform.h
	gcc -m32 -c -Og -g -ffreestanding platform.c -o platform.o

platform_asm.o: platform_asm.asm
	nasm -f elf -F dwarf -g platform_asm.asm

asmc: asmc.o staging.o platform.o platform_asm.o
	ld -g -m elf_i386 asmc.o staging.o platform.o platform_asm.o -o asmc
