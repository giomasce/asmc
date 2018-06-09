
AR=ar

all: build build/asmasm_linux build/boot_asmasm.x86 build/boot_empty.x86 build/boot_asmg.x86 build/boot.iso

# Trivial things
build:
	mkdir build

build/zero_sect.bin:
	dd if=/dev/zero bs=512 count=1 of=$@

build/END:
	touch $@

# Bootloader
build/bootloader.x86.exe: boot/bootloader.asm lib/atapio.asm
	nasm -f bin -I lib/ -o $@ $<

# Asmasm executable
build/asmasm_linux.asm: asmasm/asmasm_linux.asm lib/library.asm asmasm/asmasm.asm
	cat $^ > $@

build/asmasm_linux.o: build/asmasm_linux.asm
	nasm -f elf -F dwarf -g -w-number-overflow -o $@ $<

build/platform_linux.o: lib/platform_linux.c lib/platform.h
	gcc -m32 -c -Og -g -Ilib -o $@ $<

build/asmasm_linux: build/asmasm_linux.o build/platform_linux.o
	gcc -m32 -Og -g -o $@ $^

build/boot_asmasm.x86: build/bootloader.x86.exe build/asmasm.x86 build/zero_sect.bin
	cat $^ > $@

# Asmasm kernel
build/full-asmasm.asm: lib/kernel.asm lib/ar.asm lib/library.asm asmasm/asmasm.asm asmasm/kernel-asmasm.asm lib/top.asm
	cat $^ | grep -v "^ *bits " | grep -v "^ *org " > $@

build/initrd-asmasm.ar: asmasm/main.asm lib/atapio.asm build/END
	-rm $@
	$(AR) rcs $@ $^

build/asmasm.x86.exe: build/full-asmasm.asm build/asmasm_linux
	./build/asmasm_linux $< > $@

build/asmasm.x86: build/asmasm.x86.exe build/initrd-asmasm.ar
	cat $^ > $@

# Empty kernel
build/full-empty.asm: lib/kernel.asm lib/ar.asm lib/library.asm empty/kernel-empty.asm lib/top.asm
	cat $^ | grep -v "^ *bits " | grep -v "^ *org " > $@

build/initrd-empty.ar: build/END
	-rm $@
	$(AR) rcs $@ $^

build/empty.x86.exe: build/full-empty.asm build/asmasm_linux
	./build/asmasm_linux $< > $@

build/empty.x86: build/empty.x86.exe build/initrd-empty.ar
	cat $^ > $@

build/boot_empty.x86: build/bootloader.x86.exe build/empty.x86 build/zero_sect.bin
	cat $^ > $@

# Asmg kernel
build/full-asmg.asm: lib/kernel.asm lib/ar.asm lib/library.asm asmg/asmg.asm asmg/kernel-asmg.asm lib/top.asm
	cat $^ | grep -v "^ *bits " | grep -v "^ *org " > $@

build/initrd-asmg.ar: asmg/*.g test/test.c test/first.h test/other.h build/END
	-rm $@
	$(AR) rcs $@ $^

build/asmg.x86.exe: build/full-asmg.asm build/asmasm_linux
	./build/asmasm_linux $< > $@

build/asmg.x86: build/asmg.x86.exe build/initrd-asmg.ar
	cat $^ > $@

build/boot_asmg.x86: build/bootloader.x86.exe build/asmg.x86 build/zero_sect.bin
	cat $^ > $@

# GRUB ISO image
build/boot/boot/grub/grub.cfg: boot/grub.cfg
	mkdir -p build/boot/boot/grub
	cp $^ $@

build/boot/boot/asmasm.x86: build/asmasm.x86
	mkdir -p build/boot/boot
	cp $^ $@

build/boot/boot/empty.x86: build/empty.x86
	mkdir -p build/boot/boot
	cp $^ $@

build/boot/boot/asmg.x86: build/asmg.x86
	mkdir -p build/boot/boot
	cp $^ $@

build/boot.iso: build/boot/boot/grub/grub.cfg build/boot/boot/asmasm.x86 build/boot/boot/empty.x86 build/boot/boot/asmg.x86
	cd build && grub-mkrescue -o boot.iso boot
