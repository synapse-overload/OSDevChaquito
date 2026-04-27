#ifndef __OS_STRING_H_
#define __OS_STRING_H_

#include "stdint.h"

void        invert_string(unsigned int len, char *buf);
uint32_t    get_local_apic_id(void);
uint32_t    get_local_apic_ver(void);
uint32_t    i32_to_s(char *buf, uint32_t number);
void        u32_to_hex_s(char *buf, uint32_t n);
uint32_t    get_cpu_family(void);
uint32_t    get_cpu_model(void);
const char *cpu_lookup_name(uint32_t family, uint32_t model);

#endif