all: build/boot.bin

build/boot.bin:
	nasm -f bin ./src/boot/boot.asm -o build/boot.bin

.PHONY: clean
clean:
	rm -rf build/boot.bin
