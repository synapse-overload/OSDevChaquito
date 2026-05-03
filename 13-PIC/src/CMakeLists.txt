add_subdirectory(shared)
add_subdirectory(boot)
add_subdirectory(io)
add_subdirectory(interrupt)

add_library(kernel OBJECT
    kernel.c
    kernel.asm
)

set_source_files_properties(kernel.asm PROPERTIES
    LANGUAGE ASM_NASM
    COMPILE_FLAGS "-f elf"
)

set_source_files_properties(kernel.c PROPERTIES LANGUAGE C COMPILE_FLAGS "-Wno-div-by-zero -Wno-error -Wno-unused-variable")

# io_objects declares PUBLIC include dirs, so they propagate here automatically.
# Only add kernel src itself for kernel-private headers.
target_include_directories(kernel PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(kernel PRIVATE io interrupt shared)

# Convert CMAKE_C_FLAGS into a list so custom command gets separate args instead of one big quoted option
separate_arguments(CMAKE_C_FLAGS_LIST UNIX_COMMAND "${CMAKE_C_FLAGS}")

set(LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/linker.ld)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/kernelfull.o
    COMMAND_EXPAND_LISTS
    COMMAND ${CMAKE_LINKER} -relocatable -o ${CMAKE_CURRENT_BINARY_DIR}/kernelfull.o $<TARGET_OBJECTS:kernel> $<TARGET_OBJECTS:io> $<TARGET_OBJECTS:interrupt> $<TARGET_OBJECTS:shared>
    DEPENDS kernel io interrupt shared
    COMMENT "Linking relocatable kernelfull.o for debug symbols"
)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/kernel.elf
    COMMAND_EXPAND_LISTS
    COMMAND ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS_LIST} -T ${LINKER_SCRIPT} -o ${CMAKE_CURRENT_BINARY_DIR}/kernel.elf ${CMAKE_CURRENT_BINARY_DIR}/kernelfull.o
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/kernelfull.o
    COMMENT "Linking kernel.elf via linker script"
)

# Need to objcopy out the ELF bytes as the processor just executes instructions
# and no loader is in place to read the ELF format and load the segments
# accordingly.
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/kernel.bin
    COMMAND ${CMAKE_OBJCOPY} -O binary ${CMAKE_CURRENT_BINARY_DIR}/kernel.elf ${CMAKE_CURRENT_BINARY_DIR}/kernel.bin
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/kernel.elf
    COMMENT "Extracting raw kernel.bin via objcopy"
)

add_custom_target(kernel_bin ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/kernel.bin)
