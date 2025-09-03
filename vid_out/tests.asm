        DEVICE ZXSPECTRUM48

        ORG $8000
start:  
        LD SP, $5B00    ; Stack pointer set to save place (wtf???)

        LD B, (currentY)
        LD A, (currentY)
        NOP

currentY:
        db 96

end:

        SAVESNA "vid_out/build/tests.sna", start
