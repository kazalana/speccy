        IFNDEF __COMMON_TEXT__
        DEFINE __COMMON_TEXT__

; attr_addr = $5800 + ((screen_addr − $4000)/8)


; A - ascii_code, symbol to get
; HL - result
GetSymbolAddr:
        ; calc symbol addr
        ; addr = $3d00 + (ascii_code - 32) * 8

        SUB 32

        LD L, A
        LD H, 0
        ADD HL, HL          ; *2
        ADD HL, HL          ; *4
        ADD HL, HL          ; *8

        LD DE, $3D00
        ADD HL, DE          ; HL = $3D00 + (DE - 32) * 8
        RET

; A - ascii_code, symbol to draw
; IX - screen pos
DrawSymbol:
        PUSH HL
        PUSH DE
        PUSH BC
        PUSH IX
        CALL GetSymbolAddr

        LD B, 8
        LD DE, $100
.loop:
        LD A, (HL)
        LD (IX), A
        INC HL
        ADD IX, DE
        DJNZ .loop

        POP IX
        POP BC
        POP DE
        POP HL
        RET

; A  - ascii_code, symbol to draw
; IX - screen pos
; DE - symbols start
; B  - size
DrawSymbols:
.draw_symbols_loop:
        PUSH BC
        PUSH DE
        PUSH IX

        LD A, (DE)
        CALL DrawSymbol
        
        POP IX
        POP DE
        POP BC

        INC DE
        INC IX

        DJNZ .draw_symbols_loop
        RET

        ENDIF