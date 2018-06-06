
AR=gar

all: asmasm asmasm.x86 boot.iso cc asmg boot.x86

asmasm.o: asmasm.asm library.asm stub.asm
	nasm -f elf -F dwarf -g -w-number-overflow -o asmasm.o stub.asm

staging.o: staging.c platform.h
	gcc -m32 -c -Og -g -ffreestanding staging.c -o staging.o

platform.o: platform.c platform.h
	gcc -m32 -c -Og -g -ffreestanding platform.c -o platform.o

platform_asm.o: platform_asm.asm
	nasm -f elf -F dwarf -g platform_asm.asm

asmasm: asmasm.o staging.o platform.o platform_asm.o
	gcc -m32 -O0 -g -o asmasm asmasm.o staging.o platform.o platform_asm.o

full-asmasm.asm: kernel.asm ar.asm library.asm asmasm.asm kernel-asmasm.asm top.asm
	cat kernel.asm ar.asm library.asm asmasm.asm kernel-asmasm.asm top.asm | grep -v "^ *section " | grep -v "^ *bits " | grep -v "^ *org " > full-asmasm.asm

END:
	touch END

initrd-asmasm.ar: main.asm atapio.asm END
	-rm initrd-asmasm.ar
	$(AR) rcs initrd-asmasm.ar main.asm atapio.asm END

asmasm.x86.exe: full-asmasm.asm asmasm
	./asmasm full-asmasm.asm > asmasm.x86.exe

asmasm.x86: asmasm.x86.exe initrd-asmasm.ar
	cat asmasm.x86.exe initrd-asmasm.ar > asmasm.x86

boot/boot/grub/grub.cfg: grub.cfg
	mkdir -p boot/boot/grub
	cp grub.cfg boot/boot/grub

boot/boot/asmasm.x86: asmasm.x86
	mkdir -p boot/boot
	cp asmasm.x86 boot/boot

full-empty.asm: kernel.asm ar.asm library.asm kernel-empty.asm top.asm
	cat kernel.asm ar.asm library.asm kernel-empty.asm top.asm | grep -v "^ *section " | grep -v "^ *bits " | grep -v "^ *org " > full-empty.asm

initrd-empty.ar: END
	-rm initrd-empty.ar
	$(AR) rcs initrd-empty.ar END

empty.x86.exe: full-empty.asm asmasm
	./asmasm full-empty.asm > empty.x86.exe

empty.x86: empty.x86.exe initrd-empty.ar
	cat empty.x86.exe initrd-empty.ar > empty.x86

boot/boot/empty.x86: empty.x86
	mkdir -p boot/boot
	cp empty.x86 boot/boot

boot.iso: boot/boot/grub/grub.cfg boot/boot/asmasm.x86 boot/boot/empty.x86 boot/boot/asmg.x86
	grub-mkrescue -o boot.iso boot

cc: cc.c
	gcc -m32 -O0 -fwrapv -g -o cc cc.c

asmg.o: asmg.asm gstub.asm library.asm
	nasm -f elf -F dwarf -g -w-number-overflow -o asmg.o gstub.asm

gstaging.o: gstaging.c platform.h
	gcc -m32 -c -Og -g -ffreestanding gstaging.c -o gstaging.o

asmg: asmg.o gstaging.o platform.o platform_asm.o
	gcc -m32 -O0 -g -o asmg asmg.o gstaging.o platform.o platform_asm.o

full-asmg.asm: kernel.asm ar.asm library.asm kernel-asmg.asm asmg.asm top.asm
	cat kernel.asm ar.asm library.asm kernel-asmg.asm asmg.asm top.asm | grep -v "^ *section " > full-asmg.asm

initrd-asmg.ar: main.g test.c first.h other.h utils.g malloc.g vector.g map.g preproc.g ast.g END
	-rm initrd-asmg.ar
	$(AR) rcs initrd-asmg.ar main.g test.c first.h other.h utils.g malloc.g vector.g map.g preproc.g ast.g END

asmg.x86.exe: full-asmg.asm
	nasm -f bin full-asmg.asm -o asmg.x86.exe

asmg.x86: asmg.x86.exe initrd-asmg.ar
	cat asmg.x86.exe initrd-asmg.ar > asmg.x86

boot/boot/asmg.x86: asmg.x86
	mkdir -p boot/boot
	cp asmg.x86 boot/boot

bootloader.x86.exe: bootloader.asm
	nasm bootloader.asm -f bin -o bootloader.x86.exe

zero_sect.bin:
	dd if=/dev/zero bs=512 count=1 of=zero_sect.bin

boot.x86: bootloader.x86.exe asmg.x86 zero_sect.bin
	cat bootloader.x86.exe asmg.x86 zero_sect.bin > boot.x86
