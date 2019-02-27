
FOUND := 0
UNAME := $(shell uname -s)

ifeq ($(UNAME),Linux)
FOUND := 1
AR=ar
all: build build/boot_asmasm.x86 build/boot_empty.x86 build/boot_asmg.x86 build/boot_asmg0.x86
endif

ifeq ($(UNAME),Darwin)
FOUND := 1
AR=gar
all: build build/boot_asmasm.x86 build/boot_empty.x86 build/boot_asmg.x86 build/boot_asmg0.x86
endif

ifeq ($(FOUND),0)
@echo "Platform not supported, please add it to Makefile!"
false
endif

# Trivial things
build:
	mkdir $@

diskfs:
	mkdir $@

build/END:
	touch $@

# Bootloader
build/atapio16.asm: lib/atapio.asm
	cat $^ | sed -e 's|atapio_|atapio16_|g' -e 's|ATAPIO_|ATAPIO16_|g' -e 's|platform_|platform16_|g' > $@

build/bootloader.asm: boot/stage1.asm boot/a20.asm boot/strings.asm build/atapio16.asm boot/stage2.asm lib/atapio.asm boot/idt.asm
	cat $^ > $@

build/bootloader.x86.exe: build/bootloader.asm
	nasm -f bin -I lib/ -o $@ $<

build/bootloader.x86.mbr: build/bootloader.x86.exe
	head -c 512 $< > $@

build/bootloader.x86.stage2: build/bootloader.x86.exe
	tail -c +513 $< > $@

# Diskfs image
diskfs/mescc/x86_defs.m1:
	mkdir -p diskfs/mescc
	cp contrib/M2-Planet/test/common_x86/x86_defs.M1 $@

# Unfortunately the order of the files is relevant here, otherwise
# some internal offsets wrap around because they are store in single
# words
diskfs/fasm/fasm.asm: contrib/fasm/source/version.inc contrib/fasm/source/errors.inc contrib/fasm/source/symbdump.inc contrib/fasm/source/preproce.inc contrib/fasm/source/parser.inc contrib/fasm/source/exprpars.inc contrib/fasm/source/assemble.inc contrib/fasm/source/exprcalc.inc contrib/fasm/source/formats.inc contrib/fasm/source/x86_64.inc contrib/fasm/source/avx.inc contrib/fasm/source/tables.inc contrib/fasm/source/messages.inc contrib/fasm/source/variable.inc contrib/fasm/source/asmc/system.inc contrib/fasm/source/asmc/fasm.asm
	mkdir -p diskfs/fasm
	cat $^ > $@

build/diskfs.list: diskfs/* diskfs/mescc/x86_defs.m1 diskfs/fasm/fasm.asm
	(cd diskfs/ ; find -L . -type f) | cut -c3- | sed -e 's|\(.*\)|\1 diskfs/\1|' > $@

build/diskfs.img: build/diskfs.list
	./create_diskfs.py < $< > $@

# Asmasm kernel
build/full-asmasm.asm: lib/multiboot.asm lib/kernel.asm lib/shutdown.asm lib/ar.asm lib/library.asm asmasm/asmasm.asm asmasm/kernel-asmasm.asm lib/top.asm
	cat $^ | grep -v "^ *section " > $@

build/initrd-asmasm.ar: asmasm/main.asm lib/atapio.asm asmasm/atapio_test.asm build/END
	-rm $@
	$(AR) rcs $@ $^

build/asmasm.x86.exe: build/full-asmasm.asm
	nasm -f bin -o $@ $<

build/asmasm.x86: build/asmasm.x86.exe build/initrd-asmasm.ar
	cat $^ > $@

build/boot_asmasm.x86: build/bootloader.x86.mbr build/bootloader.x86.stage2 build/asmasm.x86
	./create_partition.py $^ > $@


# Empty kernel
build/full-empty.asm: lib/multiboot.asm lib/kernel.asm lib/shutdown.asm lib/ar.asm lib/library.asm empty/kernel-empty.asm lib/top.asm
	cat $^ | grep -v "^ *section " > $@

build/initrd-empty.ar: build/END
	-rm $@
	$(AR) rcs $@ $^

build/empty.x86.exe: build/full-empty.asm
	nasm -f bin -o $@ $<

build/empty.x86: build/empty.x86.exe build/initrd-empty.ar
	cat $^ > $@

build/boot_empty.x86: build/bootloader.x86.mbr build/bootloader.x86.stage2 build/empty.x86
	./create_partition.py $^ > $@

# Asmg kernel
build/script.g:
	bash -c "echo -n" > $@

build/full-asmg.asm: lib/multiboot.asm lib/kernel.asm lib/shutdown.asm lib/ar.asm lib/library.asm lib/setjmp.asm lib/pmc.asm asmg/asmg.asm asmg/kernel-asmg.asm lib/top.asm
	cat $^ | grep -v "^ *section " > $@

build/initrd-asmg.ar: asmg/*.g build/script.g test/test.hex2 test/test.m1 test/test_mes.c test/test.asm build/END
	-rm $@
	$(AR) rcs $@ $^

build/asmg.x86.exe: build/full-asmg.asm
	nasm -f bin -o $@ $<

build/asmg.x86: build/asmg.x86.exe build/initrd-asmg.ar
	cat $^ > $@

build/debugfs.img:
	echo -n 'DEBUGFS ' > $@
	dd if=/dev/zero of=$@ bs=1048576 count=10 oflag=append conv=notrunc

build/boot_asmg.x86: build/bootloader.x86.mbr build/bootloader.x86.stage2 build/asmg.x86 build/diskfs.img build/debugfs.img
	./create_partition.py $^ > $@

# Asmg0 kernel
build/full-asmg0.asm: lib/multiboot.asm asmg0/asmg0.asm lib/shutdown.asm asmg0/debug.asm lib/top.asm
	cat $^ | grep -v "^ *section " > $@

build/asmg0.x86.exe: build/full-asmg0.asm
	nasm -f bin -o $@ $<

build/asmg0.x86: build/asmg0.x86.exe asmg0/main.g0
	cat $^ > $@

build/boot_asmg0.x86: build/bootloader.x86.mbr build/bootloader.x86.stage2 build/asmg0.x86
	./create_partition.py $^ > $@
