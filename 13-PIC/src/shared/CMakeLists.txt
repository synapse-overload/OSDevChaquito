add_library(shared OBJECT
    memory.c
    cpuid.asm
)

set_source_files_properties(cpuid.asm PROPERTIES
    LANGUAGE ASM_NASM
    COMPILE_FLAGS "-f elf"
)

target_include_directories(shared INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>
)