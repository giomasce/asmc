
all: asmc asmc.x86 boot.iso

asmc.o: asmc.asm stub.asm
	nasm -f elf -F dwarf -g -o asmc.o stub.asm

staging.o: staging.c platform.h
	gcc -m32 -c -Og -g -ffreestanding staging.c -o staging.o

platform.o: platform.c platform.h
	gcc -m32 -c -Og -g -ffreestanding platform.c -o platform.o

platform_asm.o: platform_asm.asm
	nasm -f elf -F dwarf -g platform_asm.asm

asmc: asmc.o staging.o platform.o platform_asm.o
	ld -g -m elf_i386 asmc.o staging.o platform.o platform_asm.o -o asmc

full.asm: kernel.asm asmc.asm
	cat kernel.asm asmc.asm > full.asm

asmc.x86: full.asm asmc
	./asmc > asmc.x86

boot/boot/grub/grub.cfg: grub.cfg
	mkdir -p boot/boot/grub
	cp grub.cfg boot/boot/grub

boot/boot/asmc.x86: asmc.x86
	mkdir -p boot/boot
	cp asmc.x86 boot/boot

boot.iso: boot/boot/grub/grub.cfg boot/boot/asmc.x86
	grub-mkrescue -o boot.iso boot
