        DEVICE ZXSPECTRUM48
        ORG $8000
        INCLUDE "../vid_out/draw_sprite.asm"

main:  
        LD SP, $6000   ; Stack pointer set to save place

        LD C, 16               ; set X=16
        LD B, 96               ; set Y=96
        LD DE, sprite_data     ; Sprite memory start

main_loop:
        CALL ReadKeys
        CALL DrawSprite

        JP main_loop


;Smiley face
sprite_data:
        db %00111100
        db %01111110
        db %11011011
        db %11111111
        db %11111111
        db %11011011
        db %01100110
        db %00111100


end:
        SAVESNA ".build/main.sna", main