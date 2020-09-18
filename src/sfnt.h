#ifndef __SFNT_H
#define __SFNT_H

#include <stddef.h>
#include <stdint.h>

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif

DLLEXPORT uint32_t sfnt_checksum(uint8_t*, size_t);

#endif /* __SFNT_H */

