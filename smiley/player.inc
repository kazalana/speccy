        IFNDEF __PLAYER__
        DEFINE __PLAYER__
        INCLUDE "../vid_out/draw_sprite.asm"
Player:
Player_A:
        db %00000000
        db %00000000
        db %00000001
        db %00000001
        db %00000001
        db %00000001
        db %00110011
        db %00110011

Player_B:
        db %00000000
        db %00000000
        db %10000000
        db %10000000
        db %10000000
        db %10000000
        db %11001100
        db %11001100

Player_C:
        db %00110111
        db %00111111
        db %01111101
        db %01100001
        db %11000001
        db %11000001
        db %11000001
        db %11000001

Player_D:
        db %11101100
        db %11111100
        db %10111110
        db %10000110
        db %10000011
        db %10000011
        db %10000011
        db %10000011

DrawPlayer:
        PUSH HL
        LD IY, Player_A
        CALL DrawSprite8x8_light

        LD A, L
        ADD A, 8
        LD L, A

        LD IY, Player_B
        CALL DrawSprite8x8_light

        LD A, H
        ADD 8
        LD H, A

        LD IY, Player_D
        CALL DrawSprite8x8_light

        LD A, L
        SUB 8
        LD L, A

        LD IY, Player_C
        CALL DrawSprite8x8_light
        
        POP HL
        RET


        ENDIF ; __PLAYER__