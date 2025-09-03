        IFNDEF __DRAW_SPRITE__
        DEFINE __DRAW_SPRITE__

        EXPORT DrawSprite
        EXPORT GetPixelAddr
        EXPORT DrawSprite
;Input DE - sprite data address
;      B - Y position (0..191)  
;      C - X position (0..31)  (X/8)
;Draws 8x8 sprite at (X*8,Y)
DrawSprite:
        
        PUSH BC           ; Save X,Y to HL
        POP  HL           ; 

        LD B, 8           ; Number of rows (8 pixels high - hardcoded for now)
draw_sprite_line:
        PUSH BC ; Save loop index

        ;calculate address
        PUSH HL
        POP  BC  ; Load X,Y from HL       
        CALL GetPixelAddr

        ;draw one line
        LD A, (DE)
        LD (HL), A
        INC DE
        INC B ; Move to next line (Y++)
        
        PUSH BC 
        POP  HL ; save new X,Y to HL

        POP BC ; Restore loop index
        DJNZ draw_sprite_line

        RET


; Input:  B(Y=0..191), C(X=0..31)
; Output: HL(address of byte in video memory)
;       15	14	13	12	11	10	9	8	7	6	5	4	3	2	1	0
;       0	1	0	[ Y[7:6] ]	[     Y[2:0]     ]      [      Y[5:3]   ]	[            X[4:0]             ]
GetPixelAddr:
        LD      A, C
        AND     0x1F        ; L[0..4] = X >> 3
        LD      L, A        ; Y[0..2] → L[0..2]

        LD      A, B
        AND     0x07
        LD      H, A        ; Y[0..2] → H[0..2]

        LD      A, B
        AND     0x38
        RLCA
        RLCA
        OR      L
        LD      L, A        ; Y[3..5] → L[5..7]

        LD      A, B
        AND     0xC0
        RRCA
        RRCA
        RRCA
        OR      H
        OR      0x40        ; Set video memory base in H
        LD      H, A        ; Y[6..7] → H[3..4]

        RET
        ENDIF