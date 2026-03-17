#ifndef __IO_H_
#define __IO_H_

// Port I/O functions implemented in io.asm
void outb(unsigned short port, unsigned char val);
unsigned char inb(unsigned short port);
void halt(void);

#endif
