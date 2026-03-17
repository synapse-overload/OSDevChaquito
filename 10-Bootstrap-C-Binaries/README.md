# Bootstrapping C code

This lab focuses on adding the possibility of calling C code from the kernel 
assembly stub which is run immediately after loading the kernel from the 
disk after reading it from the disk.

The main points here are:
- contemplation of adding an .asm section which is not done because the code
  relies on .text for code execution due to the ELF binary format which is
  used when compiling that code.
- linker script is enhanced with align directives
- debugger demonstrates the functionality of running the kernel_main func
  by setting a breakpoint in it to prove it reaches that address
- makefile gets FLAGS which is a huge set of flags used for compilation

A solid example of the mentality here can be found in this
[OS Dev wiki article](https://wiki.osdev.org/Bare_Bones)

Explanation of flags used in the project:
Examples:
```Makefile
FLAGS = -g -ffreestanding -falign-jumps -falign-functions -falign-labels \
        -falign-loops -fstrength-reduce -fomit-frame-pointer -finline-functions \
		    -Wno-unused-function -fno-builtin -Werror -Wno-unused-label -Wno-cpp \
	 	    -Wno-unused-parameter -nostdlib -Wall -O0

-relocatable
```
- `relocatable`
  - partial linking (also called incremental linking). According to
    the [LD documentation](https://sourceware.org/binutils/docs/ld/Options.html)
    this linker option combines multiple object files into a
    single relocatable object file while:
      - preserving relocation info for a later final link
      - resolve internal references between input objects
      - do not resolve external references at this stage
      - the output file is still an object file, note this is not
        equivalent to a statically linked library which packs
        the object files within
- `ffreestanding`
  - this one should be self explanatory by now, it's meant to
    remove dependence on standard library
- `nostdlib`
  - further removal of stdlib but from linkage perspective
    it's similar to passing `-nostartfiles` and `-nodefaultlib`
    check the wonderfully difficult to follow: 
    [GCC Linker options](https://gcc.gnu.org/onlinedocs/gcc/Link-Options.html#index-nostdlib)
    i say this because the implication that `-nostdlib` stops
    `-nostartfiles` is in the documentation for the latter not
    the former, i.e. heavy reliance on reading the docs
    completely from start to finish... so gentle
- `nodefaultlib`  - this one is omitted because `nostartfiles` is implied by
                    `nostdlib` and that one implies nodefaultlib
- `falign-jumps`
  - align jump labels to power of 2 addresses
  - this option takes a parameter n but we stick with the default for the arch
  - the default is machine-dependent (for 32bit x86 it's )
  - [Docs](https://gcc.gnu.org/onlinedocs/gcc-10.2.0/gcc/Optimize-Options.html#index-falign-jumps)
- `falign-functions` 
  - align function to power of 2 addresses
  - similar to the above option, docs in the same link
- `falign-labels`
  - align jump locations to power of 2 addresses
  - note this option is impacted by the value in align-functions option
  - similar to the above option, docs in the same link
- `falign-loops`, `fstrength-reduce` 
  -  ancient, do not use: [Gcc 3.2.3](https://gcc.gnu.org/onlinedocs/gcc-3.2.3/gcc/Optimize-Options.html)  
  - [What is strength reduction?](https://en.wikipedia.org/wiki/Strength_reduction)
  - In the 10.2.0 gcc version we're using the `gcc/common.opt` file even says:  
  ```
    fstrength-reduce
    Common Ignore
    Does nothing.  Preserved for backward compatibility.
  ```
- `fomit-frame-pointer`
- `finline-functions`
- `Wno-unused-function`
- `fno-builtin`
  - do not optimize standard functions into the compiler builtin
    versions of them (the compiler has implementations that it
    just outputs into code), it'a [C dialect option](https://gcc.gnu.org/onlinedocs/gcc/C-Dialect-Options.html#index-fno-builtin) and impacts these
    [functions](https://gcc.gnu.org/onlinedocs/gcc/Library-Builtins.html) 
- `Werror`
- `Wno-unused-label`
- `Wno-cpp`
- `Wno-unused-parameter`
- `Wall`