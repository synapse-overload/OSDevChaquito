#!/bin/bash

.PHONY: all
all:
	rm -rf build
	mkdir build
	cmake -DCMAKE_TOOLCHAIN_FILE=i686-elf-toolchain.cmake -DCMAKE_BUILD_TYPE=Debug -S . -B build/
	cmake --build build

.PHONY: clean
clean:
	rm -rf build
