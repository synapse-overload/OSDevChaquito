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

target_include_directories(io PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})