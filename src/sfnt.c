#include "sfnt.h"

DLLEXPORT uint32_t
sfnt_checksum(uint8_t* buf, size_t len) {
    uint32_t checksum = 0;
    size_t i;
    uint8_t j;
    for (i = 0; i < len;) {
        uint32_t val = 0;
        for (j = 0; j < 4; j++) {
            val <<= 8;
            if (i < len) {
                val += buf[i++];
            }
        }
        checksum += val;
    }
    return checksum;
}

