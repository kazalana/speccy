    IFNDEF __TETRIS_MISC__
    DEFINE __TETRIS_MISC__

    EXPORT DrawCells

cell: 
    db %11111111
    db %10000001
    db %10000001
    db %10000001
    db %10000001
    db %10000001
    db %10000001
    db %11111111

; IX -  $4000 $4800 $5000
DrawCellString:
    PUSH BC
    LD B, GLASS_X - 1
    LD IY, cell
    ;LD IX, $4000
.draw_cells_loop
    PUSH BC
    PUSH IX
    PUSH IY

    LD B, 8
.draw_cell_loop
    LD A, (IY)
    LD (IX), A
    LD DE, $100
    ADD IX, DE
    INC IY

    DJNZ .draw_cell_loop

    POP IY
    POP IX
    POP BC
    INC IX
    DJNZ .draw_cells_loop

    POP BC
    RET

; IX -  $4000 $4800 $5000
; B  - string amount 8
DrawCells:
.draw_cell_strings_loop
    PUSH IX
    CALL DrawCellString
    POP IX
    LD DE, $20
    ADD IX, DE
    DJNZ .draw_cell_strings_loop
    RET

    ENDIF