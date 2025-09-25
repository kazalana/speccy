
        IFNDEF __DRAW_SPRITE__
        DEFINE __DRAW_SPRITE__

        EXPORT DrawSprite8x8
        EXPORT EraseSprite8x8
        EXPORT GetPixelAddr
        EXPORT draw_sprite_build_begin

        INCLUDE "video_line_table.inc"
draw_sprite_build_begin


DrawSprite8x8_addresses:
        db %00000000 ; first byte address
        db %00000000

        db %00000000  ; second byte address
        db %00000000

        db %00000000  ; third byte address
        db %00000000
        
        db %00000000 ;  fourth byte address
        db %00000000

        db %00000000 ;  fifth byte address
        db %00000000

        db %00000000 ;  sixth byte address
        db %00000000

        db %00000000 ;  seventh byte address
        db %00000000

        db %00000000 ;  eighth byte address
        db %00000000


DrawSprite8x8_light:
        PUSH HL
        PUSH IY

        LD A, L
        AND 0x07        ; A = L % 8, bit coordinate (0..7)
        LD C, A         ; save bit coordinate in C (1..7) - shift count
  
        LD A, L
        SRL A
        SRL A
        SRL A           ; A = L/8, byte coordinate (0..31)
        LD L, A         ; save byte coordinate in L
       
        LD B, 8 
        
.draw_one_byte
        CALL GetPixelAddrTable
        LD A, C
        OR A
        JR NZ, .shift_byte_light   ; if C!=0 -  shift needed

        LD A, (IY)
        LD (IX), A ;draw one byte
        JR .next_byte_light

.shift_byte_light
        LD A, (IY)
        CALL ShiftRightN
        

        LD (IX), A ;    draw one byte
        LD A, (IY)
        CALL ShiftLeft8MinusN ; A = A << (8 - N)

        INC IX
                LD (IX), A ;draw one byte
        DEC IX

.next_byte_light
        INC IY; move to next line of sprite data
        INC H ; Move to next line (Y++)
        DJNZ .draw_one_byte

        POP IY
        POP HL
 
        RET

DrawSprite8x8:
        ; Input:  H(Y=0..191) L(X=0..255)  
        ;         IY - address of sprite data (8 bytes for 8x8 sprite)
        ; Output: draws sprite at (X,Y)
        ;         IX - address of byte in video memory of upper-left pixel of sprite
        ;         C - 0 or 1..7 - byte coordinate
        ; Destroys: A, B
        ; Uses: GetPixelAddr, ShiftRightN, ShiftLeft8MinusN
        ; If X is not multiple of 8, sprite is shifted and drawn in two memory bytes
        ; Uses DrawSpriteAtOneBytePlace to draw at byte-aligned position
        ; Uses ShiftRightN and ShiftLeft8MinusN to shift sprite data
        ; Uses GetPixelAddr to calculate video memory address

        PUSH HL
        PUSH IY

        LD A, L
        AND 0x07        ; A = L % 8, bit coordinate (0..7)
        LD C, A         ; save bit coordinate in C (1..7) - shift count
  
        LD A, L
        SRL A
        SRL A
        SRL A           ; A = L/8, byte coordinate (0..31)
        LD L, A         ; save byte coordinate in L
       
        LD B, 8           ; Number of rows (8 pixels high - hardcoded for now)
.put_one_byte_over_video_memory_byte
        
        ;CALL GetPixelAddr ; get address of byte in video memory
        CALL GetPixelAddrTable ; get address of byte in video memory

        LD A, 8
        SUB B  
        PUSH HL
        PUSH DE
        LD HL, DrawSprite8x8_addresses
        SLA A ; A = 2 * (8 - B) - one address per byte (2 bytes per address)
        LD E, A
        LD D, 0
        ADD HL, DE
        CALL SaveIX
        POP DE
        POP HL

        ; now IX has address of byte in video memory
        ; shift sprite data if needed 
        LD A, C
        OR A
        JR NZ, .shift_byte   ; if C!=0 -  shift needed

        ;save current sprite data for erasing later
        /* a mojet i naher ne nado
        PUSH IY
        PUSH BC
                LD IY, sprite_previous_data
.set_previous_data
                INC IY
                DJNZ .set_previous_data
                LD A, (IX)
                LD (IY), A
        POP BC
        POP IY
        */

        LD A, (IY)
        LD (IX), A ;draw one byte
        JR .next_byte

.shift_byte
        LD A, (IY)
        CALL ShiftRightN
        
        ;LD D, (IX)
        ;OR D ; put over existing data

        LD (IX), 0 ;    clear one byte
        LD (IX), A ;    draw one byte
        LD A, (IY)
        CALL ShiftLeft8MinusN ; A = A << (8 - N)

        INC IX
                LD (IX), A ;draw one byte
        DEC IX

.next_byte
        INC IY; move to next line of sprite data
        INC H ; Move to next line (Y++)
        DJNZ .put_one_byte_over_video_memory_byte

        POP IY
        POP HL
        
        ;PUSH HL
        ;LD HL, DrawSprite8x8_addresses
        ;CALL LoadIX
        ;POP HL

        RET ;DrawSprite8x8


ShiftRightN:
        PUSH BC
.loopR:
        SRL A
        DEC C
        JP NZ, .loopR

        POP BC
    RET


ShiftLeft8MinusN:
        PUSH BC

        EX AF, AF'
        LD A, 8
        SUB C           ; A = 8 - N
        LD C, A
        EX AF, AF'
.loopL:
        SLA A
        DEC C
        JP NZ, .loopL

        POP BC
    RET

;HL = address to save to
SaveIX 
        LD A, IXL
        LD (HL), A
        INC HL
        LD A, IXH
        LD (HL), A
        DEC HL
        RET

;HL = address to load to IX
LoadIX:
        LD A, (HL)
        LD IXL, A
        INC HL
        LD A, (HL)
        LD IXH, A
        DEC HL
        RET

; Input: IX — адрес верхнего левого байта
;        C — битовая позиция (0..7)
;        H — Y координата
EraseSprite8x8:
        PUSH HL

        LD B, 8
.erase_loop:

        LD A, 8
        SUB B  
        PUSH DE
        LD HL, DrawSprite8x8_addresses
        SLA A ; A = 2 * (8 - B) - one address per byte (2 bytes per address)
        LD E, A
        LD D, 0
        ADD HL, DE
        CALL LoadIX
        POP DE

        LD (IX), 0
        LD A, C
        OR A
        JR Z, .next_line

        INC IX
        LD (IX), 0
        DEC IX

.next_line:
        INC H
        DJNZ .erase_loop
        POP HL
        RET

; Input:  H(Y=0..191), L(X=0..31)
; Output: IX(address of byte in video memory)
;       15	14	13	12	11	10	9	8	7	6	5	4	3	2	1	0
;       0	1	0	[ Y[7:6] ]	[     Y[2:0]     ]      [      Y[5:3]   ]	[            X[4:0]             ]
GetPixelAddr:
        PUSH HL
        PUSH BC

        PUSH HL
        POP  BC  ; Load X,Y from HL

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
        LD IX, HL
        
        POP BC
        POP HL
        RET

GetPixelAddrTable:
        PUSH HL
        PUSH DE
        PUSH BC
                LD A, H              ; H = Y
                LD HL, VideoLineAddrTable
                LD B, 0
                LD C, A
                ADD HL, BC    
                ADD HL, BC           ; HL = HL + 2*Y                   
                LD E, (HL)
                INC HL
                LD D, (HL)
                LD IX, DE            ; IX = адрес начала строки Y
        POP BC
        POP DE
        POP HL

        ; add X offset
        PUSH HL
        PUSH BC
                LD B, 0
                LD C, L
                ADD IX, BC 
        POP BC
        POP HL

        RET

        ENDIF