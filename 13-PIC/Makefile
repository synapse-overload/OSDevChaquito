#!/bin/bash

.PHONY: all
all: tags
	rm -rf build
	mkdir build
	cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_TOOLCHAIN_FILE=i686-elf-toolchain.cmake -DCMAKE_BUILD_TYPE=Debug -S . -B build/
	cmake --build build
	bash scripts/gen_nasm_compile_commands.sh . build
	ln -sf build/compile_commands.json

# Generate a tags file indexing both C/H and NASM assembly symbols.
# Requires Universal Ctags (https://ctags.io).
# Use with <C-]> in Vim/Neovim or a ctags extension in VS Code as a
# fallback when clangd cannot navigate to an assembly implementation.
.PHONY: tags
tags:
	ctags -R --languages=C,Asm --fields=+l --extras=+f -f tags src/

.PHONY: clean
clean:
	rm -rf build
	rm -f compile_commands.json tags .asm-lsp.toml
