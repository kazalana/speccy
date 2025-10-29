; REM zesarux.exe --enable-remoteprotocol
; started 15.10.2025
        DEVICE ZXSPECTRUM48
        ORG $8000 ;32768

        INCLUDE "../common/screen_utils.asm"
        INCLUDE "../common/arithmetics.asm"
        INCLUDE "../common/text.asm"
        INCLUDE "data.asm"
        INCLUDE "misc.asm"

        
main:   
        DI
        XOR A
        OUT (#fe), A ; black border
        CALL FillScreenAttr ; black paper, black ink
        CALL FillScreen ; clear screen

        LD A, 2
        call $1601  ;stream?

        LD B, 2
.loop_ps        
        PUSH BC
        LD DE, s1
        LD IX, RND_ADDR
        
        LD A, B
        CP 2
        JP Z, .skip

        LD DE, $800
        ADD IX, DE
        LD DE, s2
        
.skip   LD B, 8
.loop_s
        LD A, (DE)
        XOR $55
        CALL DrawSymbol
        
        PUSH DE
        LD DE, $20
        ADD IX, DE
        POP DE
        INC DE

        DJNZ .loop_s
        POP BC
        DJNZ .loop_ps

        LD DE, score_hint
        LD BC, score_hint_end - score_hint
        call $203c

        LD DE, controls_hint
        LD BC, controls_hint_0 - controls_hint
        call $203c

        LD DE, controls_hint_0
        LD BC, controls_hint_1 - controls_hint_0
        call $203c

        LD DE, controls_hint_1
        LD BC, controls_hint_2 - controls_hint_1
        call $203c

        LD DE, controls_hint_2
        LD BC, controls_hint_3 - controls_hint_2
        call $203c

        LD DE, controls_hint_3
        LD BC, controls_hint_end - controls_hint_3
        call $203c

        LD DE, next_hint
        LD BC, next_hint_end - next_hint
        call $203c

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

        LD IX, $4001
        LD B, 8
        CALL DrawCells
        LD IX, $4801
        LD B, 8
        CALL DrawCells
        LD IX, $5001
        LD B, 7
        CALL DrawCells

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
        LD A, (player_random_flags)
        LD (player_flags), A

        ;LD IX, _I1
        LD IY, PLR_ADDR_BEGIN
        LD HL, player_addr_0 ; set real player addresses 
        CALL CreatePlayer

        LD A, PLR_ATTR
        LD HL, player_addr_0
        CALL DrawPlayer_HL  

        CALL UpdatePreview

        LD IX, score
        LD HL, 0
        CALL SaveHLtoIX
        
        LD DE, 0
        CALL UpdateScore
        
;.test  JR .test             

main_loop:

        ; clear key flags if key pressed long enough (besides drop button)
        LD A, (key_flags)
        BIT KEY_SPC_BIT, A
        JR NZ, .skip_auto_repeat_key_check
        LD A, (key_auto_repeat_counter)
         
        OR A
        JP Z, .skip_auto_repeat_key_check
        CP KEY_REPEAT_THRESHHOLD
        JP NZ, .skip_auto_repeat_key_check  
        XOR A   
        LD (key_flags), A ; release key
        LD (key_auto_repeat_counter), A ; reset */
.skip_auto_repeat_key_check

        CALL ReadKeys
        OR A
        JR Z, .check_auto_down ; Z flag is set if A==0 (no key down or key already pressed)

        BIT KEY_LEFT_BIT, A
        JR Z, .no_key_left

        LD HL, (player_pos_addr_next)  ; update player_pos - shift left
        DEC HL
        LD (player_pos_addr_next), HL 

        LD HL, -1
        JR .update_left_or_right_position

.check_auto_down:
        LD A, (game_auto_down_counter)
        OR A
        JP Z, .skip_key_action
        CP AUTO_DOWN_THRESHOLD
        JP NZ, .skip_key_action  ; make auto down, "emulate" down key
        XOR A
        LD (game_auto_down_counter), A ; reset game_auto_down_counter
        LD DE, 1; delta score
        JR .auto_down

.no_key_left:
        BIT KEY_RIGHT_BIT, A
        JR Z, .no_key_left_right
        LD HL, (player_pos_addr_next)  ; update player_pos - shift right
        INC HL
        LD (player_pos_addr_next), HL

        LD HL, 1

.update_left_or_right_position: ;  set A to 0 or 1
        LD IX, player_addr_0
        LD IY, player_addr_next_0
        LD B, PLR_SIZE
        CALL AddValueBlockFromIX_to_IY
        JP .can_move_player

.no_key_left_right:
        BIT KEY_DOWN_BIT, A
        JR Z, .no_key_left_right_down
.auto_down:
        LD HL, (player_pos_addr_next)  ; update player_pos - shift down
        LD E, 32
        LD D, 0
        ADD HL, DE
        LD (player_pos_addr_next), HL
        
        LD HL, 32 ; one string down
        LD IX, player_addr_0
        LD IY, player_addr_next_0
        LD B, PLR_SIZE ;
        CALL AddValueBlockFromIX_to_IY
        
        LD A, (game_cycle_flags)
        OR %00000001
        LD (game_cycle_flags), A; set freeze and game over player flags
        JP .can_move_player
        
.no_key_left_right_down                         ; ROTATE ROUTINE BEGIN
        BIT KEY_ROT_BIT, A
        JP Z, .no_key_left_right_down_rot

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
        JR Z, .skip_figure_state_loop ; type 0 already selected, skip it
.select_curren_figure_state_loop:
        ADD IX, DE
        DJNZ .select_curren_figure_state_loop
.skip_figure_state_loop

        LD IY, (player_pos_addr)
        LD HL, player_addr_next_0 ; set desire player addresses
        CALL CreatePlayer
        JR .can_move_player

                                        ; ROTATE ROUTINE END

                                        ; AUTO FALL DOWN
.no_key_left_right_down_rot 
        BIT KEY_SPC_BIT, A
        JP Z, .skip_key_action

.auto_fall_down_one_time
        LD HL, 32 ; one string down
        LD IX, player_addr_next_0
        LD B, PLR_SIZE ;
        CALL AddValueBlockIX

        LD HL, (player_pos_addr_next)  ; prepare player_pos - shift down
        LD DE, 32
        ADD HL, DE
        LD (player_pos_addr_next), HL

        LD HL, player_addr_next_0
        CALL IsPlayerPosValid ; check next pos is valid
        OR A
        JR NZ, .stop_auto_fall ;  pos not valid - stop auto falling and restore previous position

        JR .auto_fall_down_one_time ;pos valid, move down once again

.stop_auto_fall
        LD HL, -32 ; one string up!
        LD IX, player_addr_next_0
        LD B, PLR_SIZE ;
        CALL AddValueBlockIX ; ok, return on string up and stop

        LD HL, (player_pos_addr_next)  ; also restore player_pos - shift up one string
        LD DE, -32
        ADD HL, DE
        LD (player_pos_addr_next), HL

        XOR A
        LD (game_auto_down_counter), A ; reset auto_down_counter
        
        JR .redraw_player_and_set_new_data

.can_move_player
        LD HL, player_addr_next_0
        CALL IsPlayerPosValid ; check next pos is valid
 
        OR A
        JR Z, .redraw_player_and_set_new_data ; pos valid, apply new data
        
        LD A, (game_cycle_flags)                ; BEGIN PLAYER FREEZE AND RE-CREATED ROUTINE 
        BIT FREEZE_PLAYER_BIT, A
        JR Z, .skip_key_action

        ; choose freeze color, each figType has own
        LD DE, freeze_attr
        LD A, (player_flags)
        SRL A
        SRL A
        SRL A ; A - contains figure type  - 0..6
        LD H, 0
        LD L, A
        ADD DE, HL
        LD A , (DE)

        LD HL, player_addr_0
        CALL DrawPlayer_HL ; freeze

        LD A, (key_flags)
        BIT KEY_SPC_BIT, A
        JR NZ, .skip_reset_key_flags
        XOR A
        LD (key_flags), A
.skip_reset_key_flags
        XOR A
        LD (key_auto_repeat_counter), A ;
        
        CALL ClearFullLines; void func, clear all full lines, as in original tetris

        ;RandomizePlayer was called before, in the begin of game, and use player_random_flags  as current player_flags
        LD HL, player_random
        CALL LoadHLtoIX
        LD A, (player_random_flags)
        LD (player_flags), A
        
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

        CALL UpdatePreview

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

        CP GAME_SPEED        
        JR NZ, .skip_counters_update
        LD A, (game_auto_down_counter)
        INC A
        LD (game_auto_down_counter), A

        LD A, (key_auto_repeat_counter)
        INC A
        LD (key_auto_repeat_counter), A
.skip_counters_update

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
.noP
        LD A, $7F  ; check space
        IN A, ($FE)
        BIT 0, A   
        JR NZ, .noSPACE

        LD A, (key_flags)
        OR A 
        JR Z, .set_key_space_flag 

        XOR A ; skip if some key already pressed (A != 0)
        RET

.set_key_space_flag
        ; set key space flag
        LD A, (key_flags)
        OR KEY_SPC
        LD (key_flags), A
        RET

.noSPACE:
        XOR A
        LD (key_flags), A
        LD (key_auto_repeat_counter), A ; reset
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
        LD (player_random_flags), A
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

        CALL SaveIXtoHL

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

; Add DE to score value
UpdateScore:  
        PUSH HL
        PUSH DE
        PUSH IY
        PUSH IX
        PUSH BC
        PUSH AF

        LD HL, (score)
        ADD HL, DE ; new score value
        
        PUSH HL
        LD DE, MAX_SCORE      ; 1000
        OR A ; reset Carry
        SBC HL, DE ; HL - MAX_SCORE
        POP HL
        JP C, .max_score_reset_skip
        LD HL, 0
.max_score_reset_skip
        
        LD IX, score
        CALL SaveHLtoIX

        LD DE, score_hint_value
        CALL IntToAScii3
        
        LD DE, score_hint_value
        LD IX, $501A                    ; screen pos
        LD B, 3

        CALL DrawSymbols

        POP AF
        POP BC
        POP IX
        POP IY
        POP DE
        POP HL
        
        RET

UpdatePreview:

        LD A, 0    ; erase old preview
        LD HL, preview_addr_0
        CALL DrawPlayer_HL

        CALL RandomizePlayer ; set IX to next(!) figure

        LD HL, player_random  ; will use this as next random
        CALL SaveIXtoHL

        LD IY, PREVIEW_ADDR_BEGIN
        LD HL, preview_addr_0 ; preview addresses 
        CALL CreatePlayer ; create preview here :)

        LD A, PLR_ATTR    ; draw preview
        LD HL, preview_addr_0
        CALL DrawPlayer_HL
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


SaveIXtoHL ; save IX to (HL)
        LD A, IXL                 
        LD (HL), A
        INC HL
        LD A, IXH
        LD (HL), A
        INC HL
        RET

SaveHLtoIX ; save HL to (IX)
        LD A, L                 
        LD (IX), A
        INC IX
        LD A, H
        LD (IX), A
        INC IX
        RET

LoadHLtoIX ; load (HL) to IX
        LD A, (HL)
        INC HL
        LD IXL, A
        LD A, (HL)
        LD IXH, A
        INC HL
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
.full_line_detected

.update_score
        LD DE, 1
        CALL UpdateScore

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

basic_loader:
  db $00,$0a,$0e,$00,$20,$fd,$33,$32,$37,$36,$37,$0e,$00,$00,$ff,$7f,$00,$0d,$00,$14,$11,$00
  db $20,$ef,$22,$22,$af,$33,$32,$37,$36,$38,$0e,$00,$00,$00,$80,$00,$0d,$00,$1e,$0f,$00,$20
  db $f9,$c0,$33,$33,$32,$36,$35,$0e,$00,$00,$f1,$81,$00,$0d,$80,$0d,$80,$20,$f9,$c0,$33,$32
  db $39,$38,$39,$0e,$00,$00,$dd,$80,$00,$0d
basic_loader_end:

        display "Entry point address: ", /d, main
        display "End point address: ", /d, end
        display "code size: ", /d, end - main
        display "Total Binary Size: ", /d, end - $8000
        
        SAVESNA ".build/tetris/main.sna", main
        SAVEBIN ".build/tetris/main.bin", $8000, end - $8000

        EMPTYTAP ".build/tetris/tetris_release.tap"
        SAVETAP ".build/tetris/tetris_release.tap", BASIC," TetrisZX", basic_loader, basic_loader_end - basic_loader, 10
        SAVETAP ".build/tetris/tetris_release.tap", CODE, "main", $8000, end - $8000, main