        IFNDEF __TETRIS_DATA__
        DEFINE __TETRIS_DATA__

ADDR_ATTR_BEGIN EQU $5800
RND_ADDR EQU $4010
ADDR_ATTR_LAST_STR EQU $5AE0
GLASS_Y EQU 23
GLASS_X EQU 16
GLASS_ATTR EQU %00001000
PLR_ATTR EQU 40
PLR_SIZE EQU 4
PLR_ADDR_BEGIN EQU $5806
PREVIEW_ADDR_BEGIN EQU $5956

KEY_REPEAT_THRESHHOLD EQU 7
AUTO_DOWN_THRESHOLD EQU 16 ; it means, autodown fires, when game_auto_down_counter == 16, other worlds each  16*255 game cycles
;GAME_SPEED EQU 255 ; lets try to count it at game cycles loop, game_auto_down_counter will increase each time  game_cycle_counter == GAME_SPEED
GAME_SPEED EQU 64

FREEZE_PLAYER_BIT  EQU 0
KEY_LEFT  EQU %00000001
KEY_RIGHT EQU %00000010
KEY_DOWN  EQU %00000100
KEY_ROT   EQU %00001000
KEY_SPC   EQU %00010000
KEY_LEFT_BIT  EQU 0
KEY_RIGHT_BIT EQU 1
KEY_DOWN_BIT  EQU 2
KEY_ROT_BIT   EQU 3
KEY_SPC_BIT   EQU 4

MAX_SCORE EQU $03E8

;keep actual data size if data grow
PLR_DATA_SIZE EQU (PLR_SIZE + 1) * 2 + 1 ; all data [player_addr_0 .. player_flags_next]

tetramino:
_T0:    db %11100100 ; 2 bytes per figure -> matrix 4x4 bits 
        db %00000000

_T1:    db %01001100
        db %01000000

_T2:    db %01001110
        db %00000000

_T3:    db %01000110
        db %01000000          


_L0:    db %11101000 
        db %00000000

_L1:    db %11000100 
        db %01000000

_L2:    db %00101110 
        db %00000000

_L3:    db %01000100 
        db %01100000

_J0:    db %11100010 
        db %00000000

_J1:    db %01000100 
        db %11000000

_J2:    db %10001110 
        db %00000000

_J3:    db %01100100 
        db %01000000


_O0:    db %01100110 
        db %00000000

_O1:    db %01100110 
        db %00000000

_O2:    db %01100110 
        db %00000000

_O3:    db %01100110 
        db %00000000


_I0:    db %11110000 
        db %00000000

_I1:    db %01000100 
        db %01000100

_I2:    db %11110000 
        db %00000000

_I3:    db %01000100 
        db %01000100


_S0:    db %00110110 
        db %00000000

_S1:    db %01000110 
        db %00100000

_S2:    db %00110110 
        db %00000000

_S3:    db %01000110 
        db %00100000

_Z0:    db %01100011 
        db %00000000

_Z1:    db %00100110 
        db %01000000

_Z2:    db %01100011 
        db %00000000

_Z3:    db %00100110 
        db %01000000

freeze_attr:
         db %00100000
         db %00010000
         db %00001000
         db %00011000
         db %00111000
         db %00110000
         db %01111000

key_flags: db %00000000

game_cycle_flags: db %00000000 ; 1bit check player freeze and game over

game_cycle_counter db 0 ; just simple [0..255] runner, may be usefull for random
game_auto_down_counter db 0
key_auto_repeat_counter db 0

current_player_data:
player_addr_0: dw $5800
player_addr_1: dw $5800
player_addr_2: dw $5800
player_addr_3: dw $5800
player_pos_addr : dw PLR_ADDR_BEGIN ; start address for 4x4 matrix player
player_flags:  ; reserved  fig_Type, fig_typeN
        db 0 ;     000      000        00

player_random: dw tetramino 
player_random_flags db 0

next_player_data:
player_addr_next_0: dw $5800
player_addr_next_1: dw $5800
player_addr_next_2: dw $5800
player_addr_next_3: dw $5800
player_pos_addr_next : dw PLR_ADDR_BEGIN ; start address for 4x4 matrix player - suppose
player_flags_next: db 0


preview_data:
preview_addr_0: dw PREVIEW_ADDR_BEGIN
preview_addr_1: dw PREVIEW_ADDR_BEGIN
preview_addr_2: dw PREVIEW_ADDR_BEGIN
preview_addr_3: dw PREVIEW_ADDR_BEGIN
preview_pos_addr: dw PREVIEW_ADDR_BEGIN ; start address for 4x4 matrix preview

figure_coords_deltas:
        db 0,  1,  2,  3   ; first byte, first 2 strings
        db 32, 33, 34, 35 
        db 64, 65, 66, 67  ; second byte, second 2 strings
        db 96, 97, 98, 99
s1: db $3C, $23, $34, $3B, $15, $34, $39, $34

score_hint:
        db $16,16,GLASS_X + 3,$11,$01,$10,$06, "SCORE: "
score_hint_value:
        db "000"
score_hint_end:

controls_hint:    db $16,0,GLASS_X + 3,$11,$01,$10,$06, "O   - Left"
controls_hint_0:  db $16,1,GLASS_X + 3,$11,$01,$10,$06, "P   - Right"
controls_hint_1:  db $16,2,GLASS_X + 3,$11,$01,$10,$06, "Q   - Rotate"
controls_hint_2:  db $16,3,GLASS_X + 3,$11,$01,$10,$06, "A   - Down"
controls_hint_3:  db $16,4,GLASS_X + 3,$11,$01,$10,$06, "SPC - Drop"
controls_hint_end:

next_hint:
        db $16,8,GLASS_X + 6,$11,$01,$10,$06, "NEXT"
next_hint_end:

        ; $16 - AT (Y, X)
        ; $11 - INK ($01)
        ; $10 - PAPER ($06)



score: dw 0
s2: db $33, $30, $27, $3A, $23, $7B, $27, $20
        ENDIF