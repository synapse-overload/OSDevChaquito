# Jumping to protected mode

A quick direct set of things you need to do will be found at OS Dev wiki at 
[this link](https://wiki.osdev.org/Protected_Mode)

Switching to protected mode gives you:
- access to a wider address space, enabling 32bit addresses (since this is
focused on 32bit development for self-education purposes)
- in real mode there is no protection against a program overwriting the OS,
which is what the lack of protected mode actually means, this is why it's called
protected mode.
- the specific instructions and memory virtualization modes rely on this mode
being active
- memory access is done via something called the "flat" model
- it introduces descriptor tables where your operations (instructions) are
checked for permissions through the limitations and access rights checking
based on the segment descriptors, check
[OS Dev Wiki on GDT](https://wiki.osdev.org/Global_Descriptor_Table)


Based on the above we need to make a decision on what needs to be enabled. We
will not be using a GDT except for some default values.


In our example we now have two start shell scripts:
- run_it.sh starts qemu in debug mode
- debug_it.sh attaches to the qemu instance started earlier, which listens on
              port 1234 and starts with layout regs and asm already on so you
              can see registers and instructions, you can cycle between views
              with "focus" command in gdb or `<C-x o>` shortcut
