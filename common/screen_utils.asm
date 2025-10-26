        IFNDEF __SCREEN_UTILS__
        DEFINE __SCREEN_UTILS__

        EXPORT FillScreenAttr

; Apply 'A' - screen attribute to all screen attr table
FillScreenAttr:        
        LD HL, $5800
        LD DE, $5801
        LD BC, 768 - 1
        LD (HL), A
        LDIR
        RET

; Apply 'A' - to all screen memory
FillScreen:        
        LD HL, $4000
        LD DE, $4001
        LD BC, 6144 - 1
        LD (HL), A
        LDIR
        RET             
        ENDIF