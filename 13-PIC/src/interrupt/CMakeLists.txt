set(INTERRUPT_C_SOURCES
    idt.c
    pic.c
)

set(INTERRUPT_ASM_SOURCES
    idt.asm
    pic.asm
)

add_library(interrupt OBJECT
    ${INTERRUPT_C_SOURCES}
    ${INTERRUPT_ASM_SOURCES}
)

foreach(ASM_FILE IN LISTS INTERRUPT_ASM_SOURCES)
    set_source_files_properties(${ASM_FILE} PROPERTIES
        LANGUAGE ASM_NASM
        COMPILE_FLAGS "-f elf"
    )
endforeach()

target_include_directories(interrupt PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(interrupt PUBLIC shared io)