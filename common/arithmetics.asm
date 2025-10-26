        IFNDEF __ARITHMETICS__
        DEFINE __ARITHMETICS__

        EXPORT UpdateValueBlockHL
        EXPORT AddValueBlockHL


; A = 1 → INC, A = 0 → DEC
; HL → block begin (player_addr_0)
; B → number of 2bytes values

UpdateValueBlockHL:
             
.loop:
    PUSH AF ; save flag inc/dec
    LD E, (HL)
    INC HL
    LD D, (HL)
    DEC HL

    POP AF          ; restore A
    OR A
    JR Z, .do_dec
    INC DE
    JR .store

.do_dec:
    DEC DE

.store:
    LD (HL), E
    INC HL
    LD (HL), D
    INC HL          ; goto next 2bytes-value

    DJNZ .loop      
    RET

UpdateValueBlockFromIX_to_IY: ;  take value at IX address, inc\dec value and put it to IY address (B times)
             
.loop:
    PUSH AF ; save flag inc/dec
    LD E, (IX)
    INC IX
    LD D, (IX)
    DEC IX

    POP AF          ; restore A
    OR A
    JR Z, .do_dec
    INC DE
    JR .store

.do_dec:
    DEC DE

.store:
    LD (IY), E
    INC IY
    LD (IY), D
    INC IY          ; goto next byte in 2bytes-value

    INC IX
    INC IX          ; goto next word in IX

    DJNZ .loop      ; пока B ≠ 0 → повторить
    RET

; A = value to add
; HL → block begin (player_addr_0)
; B → number of 2bytes values
AddValueBlockHL:
             
.loop:
    LD E, (HL)
    INC HL
    LD D, (HL)
    DEC HL

    PUSH HL
    LD H, 0
    LD L, A
    ADD DE, HL
    POP HL

.store:
    LD (HL), E
    INC HL
    LD (HL), D
    INC HL          ; перейти к следующему двухбайтному значению

    DJNZ .loop      ; 
    RET

; A = value to add
; IX → block begin source values
; IY → block begin target values 
; B → number of 2bytes values
AddValueBlockFromIX_to_IY:             
.loop:
    LD E, (IX)
    INC IX
    LD D, (IX)
    DEC IX

    PUSH HL
    LD H, 0
    LD L, A
    ADD DE, HL
    POP HL

.store:
    LD (IY), E
    INC IY
    LD (IY), D
    INC IY          ; перейти к следующему двухбайтному значению

    INC IX
    INC IX          ; goto next source word 

    DJNZ .loop      ; 
    RET
        ENDIF