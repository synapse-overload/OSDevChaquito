# Lab 08: Cross-Compiler

## What's This About?

This lab builds a **cross-compiler** - a compiler that runs on your machine but generates code for a different target. In this case, we're building `i686-elf-gcc` to compile our operating system kernel.

## Why Can't I Just Use My Regular GCC?

Your system's GCC (probably `x86_64-linux-gnu`) is built to create **Linux user-space programs**. It assumes:
- You're running on Linux with a kernel
- You have glibc (the standard C library)
- You're building apps that run in user-space
- Various Linux-specific conventions

But your OS kernel needs a **bare-metal compiler** (`i686-elf`) because:
- You ARE the OS - there's no kernel underneath
- No standard library (you'll write your own basic functions)
- Direct hardware access
- No assumptions about the environment

Think of it this way: Your regular compiler is like a contractor who builds houses (assumes foundation, utilities, etc.). You need a contractor who can work on raw land - that's the cross-compiler.

## What Do These Scripts Build?

### 1. `build_binutils.sh` - The Toolchain
Builds the GNU binutils for `i686-elf`:
- **Assembler** (`as`) - converts assembly to machine code
- **Linker** (`ld`) - combines object files
- **Other tools** - objdump, objcopy, etc.

### 2. `build_compiler.sh` - The Compiler
Builds GCC itself for `i686-elf`:
- **gcc** - the C compiler
- **g++** - the C++ compiler (optional but nice to have)
- **libgcc** - compiler runtime library

## What Do Those Flags Mean?

- `--target=i686-elf` - Build for 32-bit x86 bare metal (the magic sauce!)
- `--prefix=$HOME/opt/cross` - Install to your home directory
- `--disable-nls` - No internationalization (English-only error messages)
- `--without-headers` - No C library headers (we're bare metal!)
- `--enable-languages=c,c++` - Build C and C++ support

## Understanding Target Triplets

Target format: `architecture-vendor-os-abi`

**Bare metal targets (for OS dev):**
- `i686-elf` - 32-bit x86 bare metal
- `x86_64-elf` - 64-bit x86 bare metal
- `arm-none-eabi` - ARM bare metal

**Hosted targets (for regular apps):**
- `x86_64-linux-gnu` - 64-bit Linux with glibc
- `i686-w64-mingw32` - 32-bit Windows
- `arm-linux-gnueabihf` - ARM Linux

The key: **`elf` or `none` in the OS field = bare metal!**

## Do I HAVE to Build My Own?

Nope! You can use prebuilt cross-compilers:

```bash
# Ubuntu/Debian (if available)
sudo apt-get install gcc-i686-elf

# Or download prebuilt toolchains from various sources
```

Building your own is recommended by OSDev wiki for learning and compatibility, but prebuilt works fine.

## Quick Start

1. Run the install script (if you have one) to get GCC/binutils source
2. Run `build_binutils.sh` first (builds the toolchain)
3. Run `build_compiler.sh` (builds the compiler)
4. Add `$HOME/opt/cross/bin` to your PATH
5. Use `i686-elf-gcc` to compile your kernel!

## Resources

- [OSDev Wiki: GCC Cross-Compiler](https://wiki.osdev.org/GCC_Cross-Compiler)
- [OSDev Wiki: Target Triplet](https://wiki.osdev.org/Target_Triplet)
- [GCC Installation Docs](https://gcc.gnu.org/install/)

---

**TL;DR:** You need `i686-elf-gcc` because regular GCC thinks it's building for Linux, but you're building an OS that runs on bare metal. The "elf" target is what makes the difference.
