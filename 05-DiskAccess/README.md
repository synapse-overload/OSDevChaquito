Disks are broken up in sectors. The default is 512bytes per sector.
For **spinning disks** the way to access disk data is CHS (cylinder, head,
sector).
The modern way of accessing disks is through LBA (logical block array).

If we want to add a block of data at the end of our binary "disk file" which we
are booting from then we need to pad up to a full 512 block if the data we're
appending is smaller than 512b. Thus we need to use special dd flags:
- `conv`
    - used to specify a type of output file conversion, this is a difficult to
    understand naming, it's actually a series of flags that allow you to say
    you want the file to not be truncated before doing anything and specifying
    `sync` which allows you to pad the source blocks up to the block size in
    `bs`
- `oflag`
    - allows us to specify that we want to append to the output file, not to
    just directly write (I would expect an append flag here to automatically
    mean notrunc in `conv` but that is not the case)

If you want to see the output binary you may use `neovim` and open the file,
but to see it in hex format you need to use the following command in Normal
mode: `%!xxd`.
If you don't want to use neovim you can just open the file with:

```bash
xxd -g 1 boot.bin
```

**NOTE**  
DL register is usually default loaded with the index for the disk which the 
system was booted from.

**IMPORTANT NOTE**  
Remember from our previous experience that the BIOS only loads 1 sector, so
even if you'd expect the message we appended to the binary file to also be in
memory, it's not really there. This is why we load it manually.
