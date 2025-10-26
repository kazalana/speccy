; REM zesarux.exe --enable-remoteprotocol
; started 15.10.2025
        DEVICE ZXSPECTRUM48
        ORG $8000 ;32768

        INCLUDE "../common/screen_utils.asm"
        INCLUDE "../common/arithmetics.asm"

ADDR_ATTR_BEGIN EQU $5800
RND_ADDR EQU $60FF
ADDR_ATTR_LAST_STR EQU $5AE0
GLASS_Y EQU 23
GLASS_X EQU 16
GLASS_ATTR EQU %00001000
PLR_ATTR EQU 42
FREEZE_ATTR EQU %00010000
PLR_SIZE EQU 4
PLR_ADDR_BEGIN EQU $5806

AUTO_DOWN_THRESHOLD EQU 16 ; it means, autodown fires, when game_auto_down_counter == 255, other worlds each  255*255 game cycles
GAME_SPEED EQU 255 ; lets try to count it at game cycles loop, game_auto_down_counter will increase each time  game_cycle_counter == GAME_SPEED

FREEZE_PLAYER_BIT  EQU 0
KEY_LEFT  EQU %00000001
KEY_RIGHT EQU %00000010
KEY_DOWN  EQU %00000100
KEY_ROT   EQU %00001000
KEY_LEFT_BIT  EQU 0
KEY_RIGHT_BIT EQU 1
KEY_DOWN_BIT  EQU 2
KEY_ROT_BIT   EQU 3

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

key_flags: db %00000000

game_cycle_flags: db %00000000 ; 1bit check player freeze and game over

game_cycle_counter db 0 ; just simple [0..255] runner, may be usefull for random
game_auto_down_counter db 0

current_player_data:
player_addr_0: dw $5800
player_addr_1: dw $5800
player_addr_2: dw $5800
player_addr_3: dw $5800
player_pos_addr : dw PLR_ADDR_BEGIN ; start address for 4x4 matrix player
player_flags:  ; reserved  fig_Type, fig_typeN
        db 0 ;     000      000        00

next_player_data:
player_addr_next_0: dw $5800
player_addr_next_1: dw $5800
player_addr_next_2: dw $5800
player_addr_next_3: dw $5800
player_pos_addr_next : dw PLR_ADDR_BEGIN ; start address for 4x4 matrix player - suppose
player_flags_next: db 0

figure_coords_deltas:
        db 0,  1,  2,  3   ; first byte, first 2 strings
        db 32, 33, 34, 35 
        db 64, 65, 66, 67  ; second byte, second 2 strings
        db 96, 97, 98, 99

main:
        DI
        XOR A
        OUT (#fe), A ; black border
        CALL FillScreenAttr ; black paper, black ink
        CALL FillScreen ; clear screen

.draw_glass
        LD HL, ADDR_ATTR_BEGIN
        LD A, GLASS_ATTR
        LD DE, GLASS_X
        LD B, GLASS_Y
.draw_glass_walls_loop
        LD (HL), A
        ADD HL, DE
        LD (HL), A
        ADD HL, DE
        DJNZ .draw_glass_walls_loop
        

.draw_glass_bottom
        LD HL, ADDR_ATTR_BEGIN + 32*GLASS_Y
        LD B, GLASS_X + 1
        LD A, GLASS_ATTR
.draw_glass_bottom_loop
        LD (HL), A
        INC HL
        DJNZ .draw_glass_bottom_loop

/*
.draw_glass_debug_data
        LD HL, ADDR_ATTR_BEGIN + 1 + 32*(GLASS_Y-1)

        LD C, 2
.draw_glass_debug_loop

        LD B, GLASS_X - 2
        LD A, FREEZE_ATTR
.draw_glass_debug_str_loop
        LD (HL), A
        INC HL
        DJNZ .draw_glass_debug_str_loop

        LD HL, ADDR_ATTR_BEGIN + 1 + 32*(GLASS_Y-2)

        DEC C
        JR NZ, .draw_glass_debug_loop
*/
        CALL RandomizePlayer ; set IX to current figure
        ;LD IX, _I1
        LD IY, PLR_ADDR_BEGIN
        LD HL, player_addr_0 ; set real player addresses 
        CALL CreatePlayer

        LD A, PLR_ATTR
        LD HL, player_addr_0
        CALL DrawPlayer_HL
        

main_loop:
        CALL ReadKeys
        OR A
        JR Z, .check_auto_down ; Z flag is set if A==0 (no key down or key already pressed)

        BIT KEY_LEFT_BIT, A
        JR Z, .no_key_left

        LD HL, (player_pos_addr_next)  ; update player_pos - shift left
        DEC HL
        LD (player_pos_addr_next), HL 

        LD A, 0
        JR .update_left_or_right_position

.check_auto_down:
        LD A, (game_auto_down_counter)
        OR A
        JP Z, .skip_key_action
        CP AUTO_DOWN_THRESHOLD
        JP NZ, .skip_key_action  ; make auto down, "emulate" down key
        XOR A
        LD (game_auto_down_counter), A ; reset game_auto_down_counter
        JR .auto_down

.no_key_left:
        BIT KEY_RIGHT_BIT, A
        JR Z, .no_key_left_right
        LD HL, (player_pos_addr_next)  ; update player_pos - shift right
        INC HL
        LD (player_pos_addr_next), HL

        LD A, 1

.update_left_or_right_position: ;  set A to 0 or 1
        LD IX, player_addr_0
        LD IY, player_addr_next_0
        LD B, PLR_SIZE
        CALL UpdateValueBlockFromIX_to_IY
        JR .can_move_player

.no_key_left_right:
        BIT KEY_DOWN_BIT, A
        JR Z, .no_key_left_right_down
.auto_down:
        LD HL, (player_pos_addr_next)  ; update player_pos - shift down
        LD E, 32
        LD D, 0
        ADD HL, DE
        LD (player_pos_addr_next), HL
        
        LD A, 32 ; one string down
        LD IX, player_addr_0
        LD IY, player_addr_next_0
        LD B, PLR_SIZE ;
        CALL AddValueBlockFromIX_to_IY
        
        LD A, (game_cycle_flags)
        OR %00000001
        LD (game_cycle_flags), A; set freeze and game over player flags
        JR .can_move_player
        
.no_key_left_right_down                         ; ROTATE ROUTINE BEGIN
        BIT KEY_ROT_BIT, A
        JP Z, .skip_key_action

        LD A, (player_flags)  ; load current figure type and current rotate state 
        LD B, A ;
        
        LD IX, tetramino
        SRL B
        SRL B
        SRL B ; B - contains figure type  - 0..6
        JR Z, .skip_figure_select ;  figure indexed with 0 already selected kak-by
.select_current_figure_loop
        LD DE, 8   ; 8 - byte per figure, TODO - make it constant 
        ADD IX, DE
        DJNZ .select_current_figure_loop

.skip_figure_select
        AND 3 ; A - comntains current figure state (rotate) 0..3 ; may be it is too overhead, navskyak
        INC A ; set next state
        AND 3
        LD B, A ; B = current state
        LD A, (player_flags)
        AND %11111100
        OR B
        LD (player_flags_next), A ; save new state

        LD DE, 2 ; each state - 2 bytes
        LD A, B

        OR A
        jr Z, .skip_figure_state_loop ; type 0 already selected, skip it
.select_curren_figure_state_loop:
        ADD IX, DE
        DJNZ .select_curren_figure_state_loop
.skip_figure_state_loop

        LD IY, (player_pos_addr)
        LD HL, player_addr_next_0 ; set desire player addresses
        CALL CreatePlayer
        JR .can_move_player
        ;JR .skip_key_action

        ;LD A, PLR_ATTR
        ;LD HL, player_addr_0
        ;CALL DrawPlayer_HL ; draw in new positions
        ;JP .skip_key_action                             ; ROTATE ROUTINE END

.can_move_player
        LD HL, player_addr_next_0
        CALL IsPlayerPosValid ; check next pos is valid
 
        OR A
        JR Z, .redraw_player_and_set_new_data ; pos valid, apply new data
        
        LD A, (game_cycle_flags)                ; BEGIN PLAYER FREEZE AND RE-CREATED ROUTINE 
        BIT FREEZE_PLAYER_BIT, A
        JR Z, .skip_key_action

        LD A, FREEZE_ATTR
        LD HL, player_addr_0
        CALL DrawPlayer_HL ; freeze

        CALL ClearFullLines; void func, clear all full lines, as in original tetris

        CALL RandomizePlayer ; set new figure address to IX
        
        LD IY, PLR_ADDR_BEGIN ;set player start position
        LD (player_pos_addr), IY
        LD (player_pos_addr_next), IY
        LD HL, player_addr_0 ; set real player addresses
        CALL CreatePlayer

        LD HL, player_addr_0 ; set real player addresses
        CALL IsPlayerPosValid ; check new born player pos is valid

        OR A
        JP NZ, main ; GAME OVER HERE!

        LD A, PLR_ATTR
        LD HL, player_addr_0
        CALL DrawPlayer_HL ; 
        JR .skip_key_action ; done main logic routine, continue
                                                ; END PLAYER FREEZE AND RE-CREATED, LINE  ROUTINE

.redraw_player_and_set_new_data
        LD A, 0; ; erase old position
        LD HL, player_addr_0
        CALL DrawPlayer_HL
        
        LD A, PLR_ATTR
        LD HL, player_addr_next_0
        CALL DrawPlayer_HL ; draw in new positions
        
        LD   HL, next_player_data   ; set new player data (source address)
        LD   DE, current_player_data        ; (target address)
        LD   BC, PLR_DATA_SIZE 
        LDIR
        
.skip_key_action:
        XOR A
        LD (game_cycle_flags), A; reset game cycle flags

        LD   HL, current_player_data       ; restore player data as is
        LD   DE, next_player_data     
        LD   BC, PLR_DATA_SIZE 
        LDIR
        
        LD A, (game_cycle_counter)
        INC A
        LD (game_cycle_counter), A

        ;LD A, (game_cycle_counter)
        CP GAME_SPEED        
        JR NZ, .skip_auto_down_update
        LD A, (game_auto_down_counter)
        INC A
        LD (game_auto_down_counter), A
.skip_auto_down_update

        JP main_loop

ReadKeys:
        ; Check Q (up)
        LD A, %11111011
        IN A, ($FE)
        BIT 0, A
        JR NZ, .noQ

        LD A, (key_flags)
        OR A 
        JR Z, .set_key_rot_flag 

        XOR A ; skip if some key already pressed (A != 0)
        RET

.set_key_rot_flag
        LD A, (key_flags)
        OR KEY_ROT
        LD (key_flags), A
        RET
.ret_Q
        RET
.noQ:

        ; Check A (down)
        LD A, %11111101
        IN A, ($FE)
        BIT 0, A
        JR NZ, .noA

        LD A, (key_flags)
        OR A 
        JR Z, .set_key_down_flag 

        XOR A ; skip if some key already pressed (A != 0)
        RET

.set_key_down_flag 
        ; set key down flag
        LD A, (key_flags)
        OR KEY_DOWN
        LD (key_flags), A
        RET

.noA:
        ; Check O (left)
        LD A, %11011111
        IN A, ($FE)
        BIT 1, A
        JR NZ, .noO

        LD A, (key_flags)
        OR A 
        JR Z, .set_key_left_flag 

        XOR A ; skip if some key already pressed (A != 0)
        RET

.set_key_left_flag
        ; set key left flag
        LD A, (key_flags)
        OR KEY_LEFT
        LD (key_flags), A
        RET

.noO:
        ; Check P (right)
        LD A, %11011111
        IN A, ($FE)
        BIT 0, A
        JR NZ, .noP
        
        LD A, (key_flags)
        OR A 
        JR Z, .set_key_right_flag 

        XOR A ; skip if some key already pressed (A != 0)
        RET

.set_key_right_flag
        ; set key right flag
        LD A, (key_flags)
        OR KEY_RIGHT
        LD (key_flags), A
        RET
.noP:
        LD A, (key_flags)
        XOR A
        LD (key_flags), A
        RET


DrawPlayer_HL:
        LD B, PLR_SIZE
.loop_draw_player_HL
        LD E, (HL)
        INC HL
        LD D, (HL)
        DEC HL

        LD (DE), A
        INC HL
        INC HL
        
        DJNZ .loop_draw_player_HL

        RET

; IX -> address of random figure
RandomizePlayer:
        LD IX, tetramino ; choose figure - set first and add random
        LD A, R;(RND_ADDR) 

.loop_mod7:
        CP 7
        JR C, .loop_mod7_done
        SUB 7
        JR .loop_mod7
.loop_mod7_done:
        OR A
        JR Z, .skip_select_random_figure
        LD B, A ; random times 0..6
        LD DE, 8
.select_random_figure_loop:
        ADD IX, DE  
        DJNZ .select_random_figure_loop:
.skip_select_random_figure
        ; save current player figure type and reset any type_N (first rotation type)
        SLA A
        SLA A
        SLA A        
        LD (player_flags), A
        RET

    
; IX - figure address
; IY - player pos, high byte in attribute address - PLR_ADDR_BEGIN($5806) at start
; HL - player address, 4 address, to save player (for current or next pos)
CreatePlayer:
        LD DE, figure_coords_deltas      ; table start attr adresses 
        LD B, 2                         ; 2 bytes per figure 

.loop_byte:
        LD A, (IX)
        INC IX

        LD C, 8                   ;
.loop_bit:
        RLC A                     ; bit 7 → flag carry
        JR NC, .skip              ; if carry bit not set → skip
        
        PUSH AF
        PUSH DE
        PUSH IX
        LD A, (DE)                ; take delta coord from table Dij

        LD E, A                   ; make word value from delta byte in DE
        LD D, 0

        LD IX, IY;
        ADD IX, DE                ; IX has full address for Xij = IY + Dij

        LD A, IXL                 ; save IX to (HL)
        LD (HL), A
        INC HL
        LD A, IXH
        LD (HL), A
        INC HL

        POP IX
        POP DE
        POP AF

.skip:
        INC DE                    ; next coord from table
        DEC C                     ; next bit 
        JR NZ, .loop_bit

        DEC B
        JR NZ, .loop_byte

        RET
; HL - desired player start address to check
; A == 0 position valid
; A != 0 position invalid
IsPlayerPosValid:
        LD B, PLR_SIZE
.check_player_pos_loop
        
        LD E, (HL)
        INC HL
        LD D, (HL)
        DEC HL
        LD A, (DE)

        CP PLR_ATTR
        JR Z, .check_player_pos_next_byte ; byte in next player position is self-player byte (free to move in it)
        OR A
        JR Z, .check_player_pos_next_byte ; byte in next player position is free byte (free to move in it)

        LD A, 1  ; invalid pos detected
        RET

.check_player_pos_next_byte:
        INC HL
        INC HL
        DJNZ .check_player_pos_loop
        XOR A
        RET


ClearFullLines
        LD HL, ADDR_ATTR_BEGIN + 1    
        LD B, 0 ; from up to down, from 0 to GLASS Y
.clear_lines_loop
        LD IX, HL ; save current line start
        LD C, GLASS_X - 1 
.check_line_loop:
        LD A, (HL)
        INC HL

        OR A
        JR Z, .check_next_line

        DEC C
        JR NZ, .check_line_loop
        ; full line detected
        XOR A                         ; BEGIN CLEAR LINE AND MOVE ALL ABOVE LINES DATA DOWN ROUTINE
        PUSH BC

        PUSH BC
        LD HL, IX  ; restore current line start
        LD B, GLASS_X - 1 
.clear_line_loop:
        LD (HL), A
        INC HL
        DJNZ .clear_line_loop
        POP BC

        LD HL, IX  ; restore current line start 
        ; MOVE ALL LINES ABOVE DOWN ONE STRING
        ;LD A, GLASS_Y -1
        ;SUB B           ; count lines above
        LD C, B   ; lines above amount
.move_all_lines_down_one_string_loop        
        ; move data pointer down glass to current "downing" string
        LD DE, ADDR_ATTR_BEGIN + 1 ; DE as glass data pointer, set to data begin

        PUSH BC
        PUSH HL
        LD HL, 32
        LD B, C
        DEC B ; skip erased line
.set_glass_data_pointer_loop
        ADD DE, HL
        DJNZ .set_glass_data_pointer_loop
        POP HL
        POP BC

        LD HL, DE ; set HL to one above string start

        LD B, GLASS_X - 1
.move_one_line_down_loop
        LD A, (HL) ; take value from string above
        PUSH HL ;  save one string above start 
        LD DE,  32
        ADD HL, DE ; put value to one string down
        LD (HL), A 
        POP HL ;  restore one string above start
        INC HL ; iterate through string above with HL
        DJNZ .move_one_line_down_loop

        DEC C
        JR NZ, .move_all_lines_down_one_string_loop

        POP BC                         ; END CLEAR LINE AND MOVE ALL ABOVE LINES DATA DOWN ROUTINE

        ;LD DE, 32
        ;ADD HL, DE ; next line - skip erased one

.check_next_line
        LD HL, IX ; restore current line start
        LD DE, 32
        ADD HL, DE ; next line
        
        INC B
        LD A, B
        CP GLASS_Y
        JR NZ,  .clear_lines_loop
        RET        
end:

;basic_loader:
;  db $00,$0a,$0e,$00,$20,$fd,"32767",$0e,$00,$00,$ff,$7f,$00,$0d     ; 10 CLEAR 32767
;  db $00,$14,$07,$00,$20,$ef,$22,$22,$20,$af,$0d,"32768"                     ; 20 LOAD "" CODE
;  db $00,$1e,$0f,$00,$20,$f9,$c0,"32989",$0e,$00,$00,$00,$80,$00,$0d ; 30 RANDOMIZE USR 32989
;basic_loader_end:

basic_loader:
  db $00,$0a,$0e,$00,$20,$fd,$33,$32,$37,$36,$37,$0e,$00,$00,$ff,$7f,$00,$0d,$00,$14,$11,$00,$20,$ef,$22,$22,$af,$33,$32,$37,$36,$38,$0e,$00,$00,$00,$80,$00,$0d,$00,$1e,$0f,$00,$20,$f9,$c0,$33,$33,$30,$30,$32,$0e,$00,$00,$ea,$80,$00,$0d,$80,$0d,$80,$20,$f9,$c0,$33,$32,$39,$38,$39,$0e,$00,$00,$dd,$80,$00,$0d
basic_loader_end:



        display "Entry point address: ", /d, main
        display "End point address: ", /d, end
        display "code size: ", /d, end - main
        display "Total Binary Size: ", /d, end - $8000
        
        SAVESNA ".build/tetris/main.sna", main
        SAVEBIN ".build/tetris/main.bin", $8000, end - $8000

        EMPTYTAP ".build/tetris/main.tap"
        SAVETAP ".build/tetris/main.tap", BASIC," Tetris", basic_loader, basic_loader_end - basic_loader, 10
        SAVETAP ".build/tetris/main.tap", CODE, "main", $8000, end - $8000, main