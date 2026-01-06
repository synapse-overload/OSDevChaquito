boot.bin: boot.asm
	nasm -f bin ./boot.asm -o ./boot.bin

.PHONY: clean
clean: boot.bin
	rm -f boot.bin

