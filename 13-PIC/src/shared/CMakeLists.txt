set(SHARED_C_SOURCES
    memory.c
    os_string.c
)

set(SHARED_ASM_SOURCES
    cpuid.asm
)
add_library(shared OBJECT
    ${SHARED_C_SOURCES}
    ${SHARED_ASM_SOURCES}
)

foreach(ASM_FILE IN LISTS SHARED_ASM_SOURCES)
    set_source_files_properties(${ASM_FILE} PROPERTIES
        LANGUAGE ASM_NASM
        COMPILE_FLAGS "-f elf"
    )
endforeach()

target_include_directories(shared INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>
)