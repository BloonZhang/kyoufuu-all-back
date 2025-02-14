; Position of Counter_0
sm_TOP_LEFT_CORNER_X_0          equ 600 ; Position of LSB counter
sm_TOP_LEFT_CORNER_Y_0          equ 10
; Position of Combo
sm_TOP_LEFT_CORNER_X_COMBO      equ 600
sm_TOP_LEFT_CORNER_Y_COMBO      equ 75

; Settings
sm_RECT_LENGTH                  equ 15
sm_RECT_WIDTH                   equ 3
sm_BORDER_COLOR                 equ $00FFFFFF
sm_FILL_COLOR                   equ $00FFFFFF
sm_BACKGROUND_COLOR             equ $0052D9FF

; Positions of remaining counters
sm_DISTANCE_BETWEEN             equ -30
sm_TOP_LEFT_CORNER_X_1          equ (sm_TOP_LEFT_CORNER_X_0+sm_DISTANCE_BETWEEN)
sm_TOP_LEFT_CORNER_Y_1          equ sm_TOP_LEFT_CORNER_Y_0
sm_TOP_LEFT_CORNER_X_2          equ (sm_TOP_LEFT_CORNER_X_1+sm_DISTANCE_BETWEEN)
sm_TOP_LEFT_CORNER_Y_2          equ sm_TOP_LEFT_CORNER_Y_0
sm_TOP_LEFT_CORNER_X_3          equ (sm_TOP_LEFT_CORNER_X_2+sm_DISTANCE_BETWEEN)
sm_TOP_LEFT_CORNER_Y_3          equ sm_TOP_LEFT_CORNER_Y_0

; Trap codes
sm_PEN_COLOR_TRAPCODE           equ 80
sm_FILL_COLOR_TRAPCODE          equ 81
sm_DRAW_RECTANGLE_TRAPCODE      equ 87  ;d1 = left x, d2 = upper y, d3 = right x, d4 = lower y

; Scoring
sm_BASE_POINTS                  equ 1

sm_Score:
    dc.l    0
sm_Combo:
    dc.l    0
*sm_Counter_0:   ; LSB
*    dc.b    0
*sm_Counter_1:
*    dc.b    0
*sm_Counter_2:
*    dc.b    0
*sm_Counter_3:   ; MSB
*    dc.b    0


sm_SevenSegmentDisplayTable:
*0 = 01111110
*1 = 00110000
*2 = 01101101
*3 = 01111001
*4 = 00110011
*5 = 01011011
*6 = 01011111
*7 = 01110000
*8 = 01111111
*9 = 01111011
    dc.b    %01111110, %00110000, %01101101, %01111001, %00110011, %01011011, %01011111, %01110000, %01111111, %01111011
    dc.l    0   ; long padding just in case

; Public subroutines
; Subroutine: SetupSevenSegmentSubroutine
    ; Draws all seven segments and sets them to 0
    ; Inputs, Returns, Volatile: None
SetupSevenSegmentSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Set pen and fill colors. Maybe redundant
    move.l  #sm_PEN_COLOR_TRAPCODE, d0
    move.l  #sm_BORDER_COLOR, d1
    trap    #15
    move.l  #sm_FILL_COLOR_TRAPCODE, d0
    move.l  #sm_FILL_COLOR, d1
    trap    #15
    ; Prepare d0 early. Note: probably not needed with subroutine logic
    move.l  #sm_DRAW_RECTANGLE_TRAPCODE, d0
sm_SetupFirstCounter:
    ; Set mask (d5) to zero
    lea     sm_SevenSegmentDisplayTable, a0
    move.b  (a0), d5
    ; Draw Combo Counter
    move.l  #(sm_TOP_LEFT_CORNER_X_COMBO), d1
    move.l  #(sm_TOP_LEFT_CORNER_Y_COMBO), d2
    jsr     sm_DrawSevenSegmentAtSubroutine
    ; Draw Counter_0
    move.l  #(sm_TOP_LEFT_CORNER_X_0), d1
    move.l  #(sm_TOP_LEFT_CORNER_Y_0), d2
    jsr     sm_DrawSevenSegmentAtSubroutine
*    ; Draw Counter_1
*    add.l   #(sm_DISTANCE_BETWEEN), d1
*    jsr     sm_DrawSevenSegmentAtSubroutine
*    ; Draw Counter_2
*    add.l   #(sm_DISTANCE_BETWEEN), d1
*    jsr     sm_DrawSevenSegmentAtSubroutine
*    ; Draw Counter_3
*    add.l   #(sm_DISTANCE_BETWEEN), d1
*    jsr     sm_DrawSevenSegmentAtSubroutine
SetupSevenSegmentSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts
    
;Subroutine: HitNoteScoreSubroutine
    ; Increments combo, then adds to score. Updates necessary 7 segments
    ; Inputs, Returns, Volatile: None
HitNoteScoreSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Increment combo
    add.l   #1, sm_Combo
sm_HitNoteComboLoopSetup:
    ; Draw combo
    lea     sm_SevenSegmentDisplayTable, a0
    move.l  #(sm_TOP_LEFT_CORNER_X_COMBO), d1
    move.l  #(sm_TOP_LEFT_CORNER_Y_COMBO), d2
    clr.l   d5
    move.l  sm_Combo, d7
sm_HitNoteComboLoop:
    ; Divide by 10. Put remainder into d6
    divu.w  #10, d7
    swap    d7
    move.w  d7, d6
    ; Move corresponding bitmask into d5 and draw seven segment
    move.b  (0,a0,d6),d5
    jsr     sm_DrawSevenSegmentAtSubroutine
    ; Increment position to prepare for next seven segment
    add.l   #(sm_DISTANCE_BETWEEN), d1
    ; Restore d7 and check if we need to loop again
    ; If d7 is zero, then we're done scoring
    clr.w   d7  ; Restore d7
    swap    d7
    bne     sm_HitNoteComboLoop
sm_HitNoteComboLoopEnd:
    ; Increment Score
    move.l  sm_Combo, d7
    mulu.w  #sm_BASE_POINTS, d7
    add.l   d7, sm_Score
sm_HitNoteScoreLoopSetup:
    ; Check score, starting from LSB, in base 10
    move.l  #(sm_TOP_LEFT_CORNER_X_0), d1
    move.l  #(sm_TOP_LEFT_CORNER_Y_0), d2
    move.l  sm_Score, d7
sm_HitNoteScoreLoop:    ; Note: code essentaily copied from HitNoteComboLoop
    ; Divide by 10. Put remainder into d6
    divu.w  #10, d7
    swap    d7
    move.w  d7, d6
    ; Move corresponding bitmask into d5 and draw seven segment
    move.b  (0,a0,d6),d5
    jsr     sm_DrawSevenSegmentAtSubroutine
    ; Increment position to prepare for next seven segment
    add.l   #(sm_DISTANCE_BETWEEN), d1
    ; Restore d7 and check if we need to loop again
    ; If d7 is zero, then we're done scoring
    clr.w   d7  ; Restore d7
    swap    d7
    bne     sm_HitNoteScoreLoop
sm_HitNoteScoreLoopEnd:
HitNoteScoreSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

;Subroutine: MissNoteScoreSubroutine
    ; Reduces combo to 0. Updates necessary 7 segments, and erases the rest
    ; Inputs, Returns, Volatile: None
MissNoteScoreSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Draw combo to be zero. (Note: get current combo to see how many digits to erase)
    ; Draw LSB of combo to 0
    lea     sm_SevenSegmentDisplayTable, a0
    move.l  #(sm_TOP_LEFT_CORNER_X_COMBO), d1
    move.l  #(sm_TOP_LEFT_CORNER_Y_COMBO), d2
    clr.l   d5
    move.b  (a0), d5
    jsr     sm_DrawSevenSegmentAtSubroutine
sm_MissNoteComboLoopSetup:
    ; Erase the remaining digits of combo (completely erase, not set to 0)
    move.l  sm_Combo, d7
    ; Pre-divide d7 by 10, since we already set the first digit to 0
    divu.w  #10, d7
    swap    d7
    clr.w   d7
    swap    d7
    beq     sm_MissNoteComboLoopEnd ; if d7 is already zero
    ; Move %00000000 into d5 (bitmask) to indicate completely erasing digit
    clr.l   d5      
    ; Increment position
    add.l   #(sm_DISTANCE_BETWEEN), d1
sm_MissNoteComboLoop:
*    ; Divide by 10. Put remainder into d6
*    divu.w  #10, d7
*    swap    d7
*    move.w  d7, d6
*    beq     sm_MissNoteComboLoopEnd
*    ; Move position over
*    add.l   #(sm_DISTANCE_BETWEEN), d1
*    ; d5 = %00000000, which erases
*    jsr     sm_DrawSevenSegmentAtSubroutine
*    ; Increment position to prepare for next seven segment
*    clr.w   d7  ; Restore d7
*    swap    d7
*    bra     sm_MissNoteComboLoop
    ; Divide by 10.
    divu.w  #10, d7
    ; d5 is %00000000, for erasing
    jsr     sm_DrawSevenSegmentAtSubroutine
    ; Increment position to prepare for next seven segment
    add.l   #(sm_DISTANCE_BETWEEN), d1
    ; Restore d7 and check if we need to loop again
    ; If d7 is zero, then we're done scoring
    swap    d7
    clr.w   d7
    swap    d7
    bne     sm_MissNoteComboLoop
sm_MissNoteComboLoopEnd:
    ; Set combo to zero
    move.l  #0, sm_Combo
MissNoteScoreSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts
    
; Subroutine: DrawFPSSubroutine
    ; Draws the FPS using seven-segment displays
    ; Inputs:
    ; d5 = fps (in decimal)
    ; d1,d2 = x,y of top corner of display (LSB)
DrawFPSSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Note: Hardcoded to only happen twice because there's no way d5 (FPS) is going to be 3 digits
    divu    #10, d5
    move.w  d5, d6  ; d6 is tenths place
    swap    d5
    move.w  d5, d7  ; d7 is ones place
    ; Get bitmask into d5 for ones place
    lea     sm_SevenSegmentDisplayTable, a0
    clr.l   d5
    move.b  (0,a0,d7), d5
    jsr     sm_DrawSevenSegmentAtSubroutine
    ; Get bitmask into d5 for tenths place
    move.b  (0,a0,d6), d5
    add.l   #(sm_DISTANCE_BETWEEN), d1
    jsr     sm_DrawSevenSegmentAtSubroutine
DrawFPSSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Private subroutines
; Inputs: 
;   d5 = mask for segments
;   d1,d2 = x,y of top corner of display (not top corner of segment A)
sm_DrawSevenSegmentAtSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    move.l  d1, d3
    move.l  d2, d4
    move.l  #sm_DRAW_RECTANGLE_TRAPCODE, d0
    
    ; A
    btst    #6, d5
    jsr     sm_SetColorForDrawOrErase
    add.l   #(sm_RECT_WIDTH), d1
    add.l   #(sm_RECT_WIDTH + sm_RECT_LENGTH), d3
    add.l   #(sm_RECT_WIDTH), d4
    trap    #15

    ; B
    btst    #5, d5
    jsr     sm_SetColorForDrawOrErase
    add.l   #(sm_RECT_LENGTH), d1
    add.l   #(sm_RECT_WIDTH), d2
    add.l   #(sm_RECT_WIDTH), d3
    add.l   #(sm_RECT_LENGTH), d4
    trap    #15

    ; C
    btst    #4, d5
    jsr     sm_SetColorForDrawOrErase
    add.l   #(sm_RECT_WIDTH + sm_RECT_LENGTH), d2
    add.l   #(sm_RECT_WIDTH + sm_RECT_LENGTH), d4
    trap    #15

    ; D
    btst    #3, d5
    jsr     sm_SetColorForDrawOrErase
    sub.l   #(sm_RECT_LENGTH), d1
    add.l   #(sm_RECT_LENGTH), d2
    sub.l   #(sm_RECT_WIDTH), d3
    add.l   #(sm_RECT_WIDTH), d4
    trap    #15

    ; E
    btst    #2, d5
    jsr     sm_SetColorForDrawOrErase
    sub.l   #(sm_RECT_WIDTH), d1
    sub.l   #(sm_RECT_LENGTH), d2
    sub.l   #(sm_RECT_LENGTH), d3
    sub.l   #(sm_RECT_WIDTH), d4
    trap    #15

    ; F
    btst    #1, d5
    jsr     sm_SetColorForDrawOrErase
    sub.l   #(sm_RECT_WIDTH + sm_RECT_LENGTH), d2
    sub.l   #(sm_RECT_WIDTH + sm_RECT_LENGTH), d4
    trap    #15

    ; G
    btst    #0, d5
    jsr     sm_SetColorForDrawOrErase
    add.l   #(sm_RECT_WIDTH), d1
    add.l   #(sm_RECT_LENGTH), d2
    add.l   #(sm_RECT_LENGTH), d3
    add.l   #(sm_RECT_WIDTH), d4
    trap    #15
sm_DrawSevenSegmentAtEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts
    
; Inputs: Z = 1 for erase, 0 for draw
sm_SetColorForDrawOrErase:
    movem.l  d0-d1, -(sp)   ; Note: has to be movem. move will change the status register
    beq.b   sm_SetEraseColor
sm_SetDrawColor:
    move.l  #sm_PEN_COLOR_TRAPCODE, d0
    move.l  #sm_BORDER_COLOR, d1
    trap    #15
    move.l  #sm_FILL_COLOR_TRAPCODE, d0
    move.l  #sm_FILL_COLOR, d1
    trap    #15
    movem.l  (sp)+, d0-d1
    rts
sm_SetEraseColor:
    move.l  #sm_PEN_COLOR_TRAPCODE, d0
    move.l  #sm_BACKGROUND_COLOR, d1
    trap    #15
    move.l  #sm_FILL_COLOR_TRAPCODE, d0
    move.l  #sm_BACKGROUND_COLOR, d1
    trap    #15
    movem.l  (sp)+, d0-d1
    rts


























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
