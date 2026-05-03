set(INTERRUPT_C_SOURCES
    idt.c
    pic.c
)

set(INTERRUPT_ASM_SOURCES
    idt.asm
)

add_library(interrupt OBJECT
    ${INTERRUPT_C_SOURCES}
    ${INTERRUPT_ASM_SOURCES}
)

target_include_directories(interrupt PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(interrupt PUBLIC shared io)