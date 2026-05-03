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

target_include_directories(shared INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>
)