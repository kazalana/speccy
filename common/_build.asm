        DEVICE ZXSPECTRUM48
common_begin:
        INCLUDE "common/screen_utils.asm"
        INCLUDE "common/arithmetics.asm"
        INCLUDE "common/text.asm"
common_end:

end:
        SAVEBIN ".build/common/common.bin", common_begin, end - common_begin