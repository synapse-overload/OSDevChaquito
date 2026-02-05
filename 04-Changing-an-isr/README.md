In this example we change the ISR that is called for interrupt 0 which is
normally the interrupt that gets called on a 0 division error. 
0 division is usually an exception.

Remember that interrupts do the following:
- before getting called the old state is pushed (in hardware, context is:
EFLAGS, CS, EIP) on the stack
- interrupt code is executed (mind the fact that any and all other registers 
not saved will be set according to whatever the previous code was doing, this
means that the isr itself would do well to push registers it means to change,
a common practice is to use a "pusha" macro that just saves all regs)
- an `iret` instruction is executed leading to the execution resuming from
where it was before the interrupt got called, i.e. the context: EFLAGS,CS,EIP

There are 256 interrupts.
The interrupt descriptor table (IDT) has entries like this:
```
+--------+---------+--------+---------+--------+-------------+
| OFFSET | SEGMENT | OFFSET | SEGMENT | OFFSET | SEGMENT ... |
+--------+---------+--------+---------+--------+-------------+
| 0x0000 | 0x07c0  | 0x8d00 | 0x0000  | 0x08bd | ...         |
+--------+---------+--------+---------+--------+-------------+
 2 bytes  2 bytes ...
```
Each entry takes up 4 bytes (2 offset, 2 seg).
