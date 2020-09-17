#ifndef __FONT_SUBSET_SFNT_H
#define __FONT_SUBSET_SFNT_H

#include "font_subset.h"

DLLEXPORT uint32_t font_subset_sfnt_checksum(uint8_t*, size_t);
DLLEXPORT uint16_t font_subset_sfnt_repack_glyphs_16(fontSubsetPtr, uint16_t*, uint8_t*);

#endif /* __FONT_SUBSET_SFNT_H */
