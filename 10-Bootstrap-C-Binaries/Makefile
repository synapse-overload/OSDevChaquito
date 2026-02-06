# vim: ts=4 sw=4 sts=4
FILES = build/kernel.asm.o build/kernel.o
INCLUDES = -I ./src
FLAGS = -g -ffreestanding -falign-jumps -falign-functions -falign-labels \
        -falign-loops -fstrength-reduce -fomit-frame-pointer -finline-functions \
		-Wno-unused-function -fno-builtin -Werror -Wno-unused-label -Wno-cpp \
		-Wno-unused-parameter -nostdlib -nostartfiles -nodefaultlibs -Wall -O0


all: bin/boot.bin bin/kernel.bin
	rm -rf ./bin/os.bin
	dd if=bin/boot.bin \
        of=bin/os.bin \
        conv=sync \
        bs=512 \
        count=1
	dd if=bin/kernel.bin \
        of=bin/os.bin \
		oflag=append \
        conv=notrunc,sync \
        bs=512 
	# Get current size and calculate padding needed
	@CURRENT_SIZE=$$(stat -c%s bin/os.bin); \
	TARGET_SIZE=$$((101 * 512)); \
	PADDING=$$((TARGET_SIZE - CURRENT_SIZE)); \
	if [ $$PADDING -gt 0 ]; then \
		dd if=/dev/zero of=bin/os.bin bs=1 count=$$PADDING oflag=append conv=notrunc 2>/dev/null; \
	fi

bin/kernel.bin: $(FILES)
	i686-elf-ld -g -relocatable $(FILES) -o build/kernelfull.o
	i686-elf-gcc $(FLAGS) -T src/linker.ld -o bin/kernel.bin -ffreestanding -O0 -nostdlib build/kernelfull.o

bin/boot.bin: src/boot/boot.asm
	[ -d bin ] || mkdir bin 
	nasm -f bin -o bin/boot.bin ./src/boot/boot.asm

build/kernel.asm.o: src/kernel.asm
	[ -d build ] || mkdir build
	# build with debug syms
	nasm -f elf -g -o build/kernel.asm.o src/kernel.asm

build/kernel.o: src/kernel.c
	i686-elf-gcc $(INCLUDES) $(FLAGS) -std=gnu99 -c ./src/kernel.c -o ./build/kernel.o

.PHONY: clean
clean:
	rm -rf build/*
	rm -rf bin/*
