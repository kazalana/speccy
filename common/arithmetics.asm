        IFNDEF __ARITHMETICS__
        DEFINE __ARITHMETICS__

        EXPORT AddValueBlockIX
        EXPORT AddValueBlockFromIX_to_IY
        EXPORT IntToAScii3
; A = 1 → INC, A = 0 → DEC
; HL → block begin (player_addr_0)
; B → number of 2bytes values
/*

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
*/
; HL = value to add
; IX → block begin (player_addr_0)
; B → number of 2bytes values
AddValueBlockIX:
             
.loop:
    LD E, (IX)
    INC IX
    LD D, (IX)
    DEC IX
    ADD DE, HL

.store:
    LD (IX), E
    INC IX
    LD (IX), D
    INC IX          ; next word value

    DJNZ .loop      ; 
    RET

; HL = value to add
; IX → block begin source values
; IY → block begin target values 
; B → number of 2bytes values
AddValueBlockFromIX_to_IY:             
.loop:
    LD E, (IX)
    INC IX
    LD D, (IX)
    DEC IX

    ADD DE, HL

.store:
    LD (IY), E
    INC IY
    LD (IY), D
    INC IY          ; goto next target

    INC IX
    INC IX          ; goto next source word 

    DJNZ .loop      ; 
    RET


; HL = value [0, 999]
; [DE] = ASCII 3 bytes "XXX" 

IntToAScii3:
    LD B, 0
    LD C, 100
    CALL Digit
    LD C, 10
    CALL Digit
    LD C, 1
    CALL Digit
    RET

; Divise HL on C, result to ASCII in (DE), remainder remains in HL
Digit:
    LD A, 0
.loop:
    INC A
    OR A
    SBC HL, BC
    JR NC, .loop
    DEC A
    ADD HL, BC
    ADD A, '0'
    LD (DE), A
    INC DE
    RET
        ENDIF