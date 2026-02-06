# Lab 00: Prerequisites and Setup

Before jumping into bootloader code, you need to get your dev environment set up. This is all educational stuff for learning OS fundamentals from scratch.

## What you need

### Hardware

Nothing crazy - everything runs in QEMU:
- Any modern x86_64 CPU
- 2GB RAM (4GB is better)
- ~5GB disk space (mostly for the cross-compiler build later)

### Software

| Tool | What it does | Version |
|------|--------------|---------|
| NASM | Assembler for our .asm files | 2.14+ |
| QEMU | Emulator to test the bootloader/kernel | 4.0+ |
| GDB | Debugger | 8.0+ |
| Make | Build automation | 4.0+ |
| GCC/G++ | Needed to build the cross-compiler later | 7.0+ |
| binutils | objdump, ld, and other binary tools | 2.30+ |

### Distros supported

The installer script works on:
- Ubuntu 20.04+ (and derivatives like Mint)
- Fedora 35+
- AlmaLinux 8+ (RHEL clones)

## Getting started

### Easy way - run the installer

Just run the script and it'll figure out your distro and install everything:

```bash
cd 00-Prerequisites
chmod +x install_prereqs.sh
./install_prereqs.sh
```

It'll detect your distro, install packages, and verify everything works.

### Manual install

If you're on a different distro or prefer doing it yourself:

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y nasm qemu-system-x86 gdb make gcc g++ \
    build-essential bison flex libgmp3-dev libmpc-dev \
    libmpfr-dev texinfo libisl-dev
```

**Fedora:**
```bash
sudo dnf install -y nasm qemu-system-x86 gdb make gcc gcc-c++ \
    bison flex gmp-devel mpfr-devel libmpc-devel \
    texinfo isl-devel
```

**AlmaLinux/RHEL:**
```bash
sudo dnf install -y nasm qemu-system-x86 gdb make gcc gcc-c++ \
    bison flex gmp-devel mpfr-devel libmpc-devel \
    texinfo
```

## Checking if it worked

Make sure everything installed correctly:

```bash
# Check NASM
nasm -v
# Expected: NASM version 2.14.xx or higher

# Check QEMU i386 emulator
qemu-system-i386 --version
# Expected: QEMU emulator version 4.x.x or higher

# Check GDB
gdb --version
# Expected: GNU gdb version 8.x or higher

# Check Make
make --version
# Expected: GNU Make 4.x

# Check GCC
gcc --version
# Expected: gcc version 7.x or higher
```

## What gets installed

### Main tools

- NASM - assembles our .asm files
- QEMU - i386 emulator for testing
- GDB - debugger
- Make - builds everything

### Dependencies for later

You'll need these in Lab 08 when we build the cross-compiler:

- GCC/G++ - to build the cross-compiler
- Binutils - linker, objdump, etc
- bison/flex - parser stuff
- GMP/MPFR/MPC/ISL - math libraries GCC needs

Note: Don't worry about i686-elf-gcc yet, we build it in Lab 08.

## Why these tools?

### i686-elf-gcc (cross-compiler)

We need a special compiler that targets bare metal i686:
- i686 = 32-bit x86 (Pentium Pro era)
- elf = just the binary format, nothing Linux-specific
- No standard library = we're on bare metal, no OS underneath

Your regular GCC won't work because it's set up for making Linux programs, not kernels.

### qemu-system-i386

Yeah the name says "i386" but it actually supports i686 instructions just fine. It's just QEMU's name for their 32-bit x86 emulator.

We use this instead of qemu-system-x86_64 to match our 32-bit kernel.

## Troubleshooting

### Can't find qemu-system-i386

Some distros name the QEMU packages differently. Try:
```bash
# On Ubuntu you might need this specific package
sudo apt install qemu-system-x86

# Check what got installed
dpkg -L qemu-system-x86 | grep bin
```

### Missing isl-devel on AlmaLinux

ISL isn't in the base repos. It's optional for newer GCC anyway. You can either enable PowerTools:
```bash
sudo dnf config-manager --set-enabled powertools  # AlmaLinux 8
# or
sudo dnf config-manager --set-enabled crb         # AlmaLinux 9

sudo dnf install isl-devel
```

Or just skip it, GCC will build fine without it.

### Permission denied running scripts

Just make them executable:
```bash
chmod +x install_prereqs.sh
```

### Got qemu-system-x86_64 but not i386

Install the full package:
```bash
# Ubuntu
sudo apt install qemu-system

# Fedora/Alma
sudo dnf install qemu-system-x86
```

## What's next

After everything's installed, head to Lab 01 and start with the bootloader. Each lab builds on the previous one so go in order.

## Test it out

Try Lab 01 to make sure everything works:

```bash
cd ../01-Bootloader
make
./run_it.sh
```

QEMU should start up with the bootloader message. Exit with Ctrl+A then X.

## Resources

- [NASM docs](https://www.nasm.us/doc/)
- [QEMU docs](https://www.qemu.org/documentation/)
- [GDB manual](https://sourceware.org/gdb/documentation/)
- [OSDev Wiki](https://wiki.osdev.org/Required_Knowledge)
- [Cross-compiler setup](https://wiki.osdev.org/GCC_Cross-Compiler)

---

This is a learning project - the code focuses on understanding concepts rather than production practices.
