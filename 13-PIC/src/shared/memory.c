#include "memory.h"

void memset(void* dest, int value, uint32_t count)
{  
    unsigned char* ptr = (unsigned char*)dest;
    for (uint32_t i = 0; i < count; ++i) {
        *ptr++ = (unsigned char)value;
    }
}