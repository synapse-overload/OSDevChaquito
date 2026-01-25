boot.bin: boot.asm
	nasm -f bin $< -o $@
	dd if=./message.txt of=./boot.bin oflag=append conv=notrunc,sync bs=512 count=1

.PHONY: clean
clean: boot.bin
	rm -f $<

