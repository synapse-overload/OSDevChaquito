#include "os_string.h"
#include "cpuid.h"

void invert_string(unsigned int len, char *buf) {
  if (len == 0) {
      buf[0] = 48;
    } else if (len == 1) {
      // single digit already in place
    } else {
      for (unsigned int i = len - 1; i >= len / 2; --i) {
        char tmp = buf[i];
        buf[i] = buf[len - 1 - i];
        buf[len - 1 - i] = tmp;
      }
    }
}

uint32_t get_local_apic_id(void) {
  uint32_t eax=0, ebx=0, ecx=0, edx=0;
  cpuid_query(1, &eax, &ebx, &ecx, &edx);
  return (uint32_t)(ebx >> 24);
}

uint32_t get_local_apic_ver(void) {
  // Read LAPIC version
  return (*(uint32_t *)0xFEE00030) & 0x000000FF;
}

uint32_t i32_to_s(char *buf, uint32_t number) {
  uint32_t len = 0;
  buf[0] = '\0';
  while (number != 0) {
    char last_digit = (char)((number % 10) & 0x000000FF);
    number /= 10;
    buf[len++] = (char)(last_digit + (char)48);
  }
  buf[len] = '\0';
  invert_string(len, buf);
  return len;
}

void u32_to_hex_s(char *buf, uint32_t n) {
  const char hex[] = "0123456789ABCDEF";
  char tmp[8];
  uint32_t len = 0;

  buf[0] = '\0';

  // 0x00 if input is 0
  if (n == 0) {
    buf[0]='0';
    buf[1]='x';
    buf[2]='0';
    buf[3]='0';
    buf[4]='\0';
    return;
  }
  
  // step every 4 bits and convert to hex
  // by indexing in hex num array
  while (n) {
    tmp[len++] = hex[n & 0xF];
    n >>= 4;
  }

  // 0x preamble
  buf[0]='0';
  buf[1]='x';

  for (uint32_t i = 0; i < len; i++) {
    buf[2+i] = tmp[len-1-i];
  }

  buf[2+len] = '\0';
}

uint32_t get_cpu_family(void) {
  uint32_t eax=0, ebx=0, ecx=0, edx=0;
  cpuid_query(1, &eax, &ebx, &ecx, &edx);
  uint32_t base_family = (eax >> 8) & 0xF;
  uint32_t ext_family  = (eax >> 20) & 0xFF;
  return base_family == 0xF ? base_family + ext_family : base_family;
}

uint32_t get_cpu_model(void) {
  uint32_t eax=0, ebx=0, ecx=0, edx=0;
  cpuid_query(1, &eax, &ebx, &ecx, &edx);
  uint32_t base_family = (eax >> 8) & 0xF;
  uint32_t base_model  = (eax >> 4) & 0xF;
  uint32_t ext_model   = (eax >> 16) & 0xF;
  return (base_family == 0x6 || base_family == 0xF) ? (ext_model << 4) | base_model : base_model;
}

const char *cpu_lookup_name(uint32_t family, uint32_t model) {
  for (uint32_t i = 0; cpu_info_table[i].name; i++) {
    if (cpu_info_table[i].family == family && cpu_info_table[i].model == model)
      return cpu_info_table[i].name;
  }
  return 0;
}