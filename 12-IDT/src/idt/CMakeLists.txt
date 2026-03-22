add_library(idt_objects OBJECT
    idt.c
    idt.asm
)

set_source_files_properties(idt.asm PROPERTIES
    LANGUAGE ASM_NASM
    COMPILE_FLAGS "-f elf"
)

target_include_directories(idt_objects PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(idt_objects PUBLIC shared io_objects)