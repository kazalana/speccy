        DEVICE ZXSPECTRUM48

        ORG $8000 ;32768
        INCLUDE "../vid_out/draw_sprite.asm"
        INCLUDE "player.inc"
main:  
        LD SP, $6100   ; Stack pointer set to save place
        ei ; IT DOESN'T WORK ??

        xor A
        out (#fe),a ; black border
        CALL FillScreenAttr ; fill screen ATTR-s with PAPER=BLACK, INK=BLACK

        LD HL, (old_x)
        CALL DrawPlayer
        
.test3  JR .test3        
        
.test2
        LD IY, sprite_data_original
        CALL DrawSprite8x8_light

        ;JR .test2
;.test   JR .test
        ;CALL EraseSprite8x8

main_loop:
        
        ;CALL WaitVSync
        ;CALL WaitVSyncTest
        
        ;CALL WaitVSyncSafe
        LD A, (flags)
        BIT 0, A
        JR Z, .no_erase
        ; Стираем по старым координатам
        PUSH HL
        LD A, (old_y)
        LD H, A
        LD A, (old_x)
        LD L, A
        XOR A
        LD (flags), A ; clear erase flag
        ;CALL WaitVSyncHALT
        ;HALT
        ei:halt:di
        LD IY, sprite_data_empty
        CALL DrawSprite8x8_light
        POP HL
        
        LD IY, Player_A
        CALL DrawSprite8x8_light
        JP main_loop
.no_erase

        ; Обработка клавиш — обновляет HL
        CALL ReadKeys

        ; Сохраняем новые координаты
        ;LD A, H
        ;LD (old_y), A
        ;LD A, L
        ;LD (old_x), A

        ; Рисуем по новым координатам
        

        JP main_loop


; ReadKeys: modifies B and C based on key state
ReadKeys:
        ; Check Q (up)
        LD A, %11111011
        IN A, ($FE)
        BIT 0, A
        JR NZ, .noQ
        CALL PrePositionChanged
        DEC H
.noQ:

        ; Check A (down)
        LD A, %11111101
        IN A, ($FE)
        BIT 0, A
        JR NZ, .noA
        CALL PrePositionChanged
        INC H  
.noA:
        ; Check O (left)
        LD A, %11011111
        IN A, ($FE)
        BIT 1, A
        JR NZ, .noO
        CALL PrePositionChanged
        DEC L
.noO:
        ; Check P (right)
        LD A, %11011111
        IN A, ($FE)
        BIT 0, A
        JR NZ, .noP
        CALL PrePositionChanged
        INC L
        INC L
        INC L

.noP:
        RET

PrePositionChanged
        ; erase old sprite
        LD A, 1
        LD (flags), A ; set erase flag
        LD A, H
        LD (old_y), A
        LD A, L
        LD (old_x), A
        RET


WaitDelay:
        PUSH DE
        LD DE, 100       ; experimentally determined
.wait_loop:
        DEC DE
        LD A, D
        OR E
        JP NZ, .wait_loop
        POP DE
        RET

WaitVSyncSafe:
        LD BC, $FE
        LD D, 100
.loop:
        IN A, (C)
        BIT 7, A
        JR Z, .done
        DEC D
        JP NZ, .loop
.done:
        RET

WaitVSyncHALT:
    EI
    HALT
    RET

WaitVSyncTest:
    LD BC, $FE
.loop:
    IN A, (C)
    BIT 7, A
    JR NZ, .loop
    JP WaitVSyncTest
    RET

WaitVSync:
    LD BC, $FE
.wait:
    IN A, (C)
    BIT 7, A
    JP NZ, .wait
.wait2:
    IN A, (C)
    BIT 7, A
    JP Z, .wait2
    RET

FillScreen:        
        LD HL, $4000
        LD DE, $4001
        LD BC, 6144 - 1
        LD (HL), A
        LDIR
        RET

FillScreenAttr:        
        LD HL, $5800
        LD DE, $5801
        LD BC, 768 - 1
        LD (HL), A
        LDIR
        RET

;Smiley face
sprite_data_original:
        db %00111100
        db %01111110
        db %11011011
        db %11111111
        db %11111111
        db %11011011
        db %01100110
        db %00111100

sprite_data_empty:
        db %00000000
        db %00000000
        db %00000000
        db %00000000
        db %00000000
        db %00000000
        db %00000000
        db %00000000


flags: db %00000000 ; 1 - erase sprite bit

; must be one by one (for LD HL, old_x)
old_x: db 120    ; old X coordinate
old_y: db 175    ; old Y coordinate


end:
        display "code size: ", /d, end - main
        SAVESNA ".build/smiley/main.sna", main
        SAVEBIN ".build/smiley/main.bin", main, end - main