set(BOOT_ASM ${CMAKE_CURRENT_SOURCE_DIR}/boot.asm)
set(BOOT_BIN ${CMAKE_CURRENT_BINARY_DIR}/boot.bin)

# Use toolchain-configured NASM compiler; fall back to `nasm` if not set.
if(NOT CMAKE_ASM_NASM_COMPILER)
    find_program(CMAKE_ASM_NASM_COMPILER nasm)
endif()

# Direct custom command to produce boot.bin from boot.asm
add_custom_command(
    OUTPUT ${BOOT_BIN}
    COMMAND ${CMAKE_ASM_NASM_COMPILER} -f bin -o ${BOOT_BIN} ${BOOT_ASM}
    DEPENDS ${BOOT_ASM}
    COMMENT "Assemble boot sector with NASM"
)

add_custom_target(boot_bin ALL DEPENDS ${BOOT_BIN})