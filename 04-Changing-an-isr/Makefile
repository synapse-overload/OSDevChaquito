boot.bin: boot.asm
	nasm -f bin $< -o $@

.PHONY: clean
clean: boot.bin
	rm -f $<

