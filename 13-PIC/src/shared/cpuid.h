#ifndef __CPUID_H__
#define __CPUID_H__

#include <stdint.h>

void cpuid_query(uint32_t leaf, uint32_t *eax, uint32_t *ebx, uint32_t *ecx, uint32_t *edx);

#endif