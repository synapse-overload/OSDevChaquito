add_library(io_objects OBJECT
    serial_comm.c
    io.asm
)

set_source_files_properties(io.asm PROPERTIES
    LANGUAGE ASM_NASM
    COMPILE_FLAGS "-f elf"
)

target_include_directories(io_objects PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})