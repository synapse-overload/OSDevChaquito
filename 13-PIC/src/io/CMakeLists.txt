set(IO_C_SOURCES
    serial_comm.c
)

set(IO_ASM_SOURCES
    io.asm
)

add_library(io OBJECT
    ${IO_C_SOURCES}
    ${IO_ASM_SOURCES}
)

foreach(ASM_FILE IN LISTS IO_ASM_SOURCES)
    set_source_files_properties(${ASM_FILE} PROPERTIES
        LANGUAGE ASM_NASM
        COMPILE_FLAGS "-f elf"
    )
endforeach()

target_include_directories(io PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})