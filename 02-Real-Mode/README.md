Refine the previously written bootloader by:
- setting up Segment registers for segmented memory access model
- define our start symbol

When the BIOS first loads us we don't know what the segment registers are.
Question: What would happen if the segments are somehow SET, what would happen 
if DS is not 0 when using the `loadsb` instruction?

It's important to note that in this example we're moving the origin to address
0 to make it visible that the BIOS moves our boot sector (i.e. in this case the
entire 512 byte program we've prepared here) at address 0x7c00.
NOTE: The CS:IP values are not well defined, but execution is guaranteed to
start at 0x7c00 (see
[x8086 Boot environment](https://en.wikipedia.org/wiki/BIOS#Boot_environment) )
