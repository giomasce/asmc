
all: asmasm asmasm.x86 boot.iso

asmasm.o: asmasm.asm library.asm stub.asm
	nasm -f elf -F dwarf -g -w-number-overflow -o asmasm.o stub.asm

staging.o: staging.c platform.h
	gcc -m32 -c -Og -g -ffreestanding staging.c -o staging.o

platform.o: platform.c platform.h
	gcc -m32 -c -Og -g -ffreestanding platform.c -o platform.o

platform_asm.o: platform_asm.asm
	nasm -f elf -F dwarf -g platform_asm.asm

asmasm: asmasm.o staging.o platform.o platform_asm.o
	ld -g -m elf_i386 asmasm.o staging.o platform.o platform_asm.o -o asmasm

full.asm: kernel.asm library.asm asmasm.asm
	cat kernel.asm library.asm asmasm.asm > full.asm

asmasm.x86: full.asm asmasm
	./asmasm > asmasm.x86

boot/boot/grub/grub.cfg: grub.cfg
	mkdir -p boot/boot/grub
	cp grub.cfg boot/boot/grub

boot/boot/asmasm.x86: asmasm.x86
	mkdir -p boot/boot
	cp asmasm.x86 boot/boot

boot.iso: boot/boot/grub/grub.cfg boot/boot/asmasm.x86
	grub-mkrescue -o boot.iso boot
