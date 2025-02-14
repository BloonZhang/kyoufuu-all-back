; Note: this program is very hardcoded. please don't change the bitmap

; Task codes
ac_SET_PEN_COLOR_TRAPCODE   equ 80
ac_SET_FILL_COLOR_TRAPCODE  equ 81
ac_DRAW_RECTANGLE_TRAPCODE  equ 87

; Yellow color for erasing using primitives
ac_YELLOW_COLOR:            equ $0052D9FF
ac_MEDIUM_YELLOW_COLOR      equ $0050D5FB
ac_DARKEST_YELLOW_COLOR     equ $004ABCDD

ac_BITMAP_HEIGHT:           equ 480

; For up frame (erasing and drawing
ac_UP_RECT_X_1:             equ 311
ac_UP_RECT_Y_1:             equ 115
ac_UP_WIDTH_1:              equ 47
ac_UP_HEIGHT_1:             equ 39
ac_UP_RECT_X_2:             equ 278
ac_UP_RECT_Y_2:             equ 142
ac_UP_WIDTH_2:              equ 37
ac_UP_HEIGHT_2:             equ 30
ac_UP_RECT_X_3:             equ 285
ac_UP_RECT_Y_3:             equ 172
ac_UP_WIDTH_3:              equ 27
ac_UP_HEIGHT_3:             equ 49
ac_UP_RECT_X_4:             equ 285
ac_UP_RECT_Y_4:             equ 221
ac_UP_WIDTH_4:              equ 38
ac_UP_HEIGHT_4:             equ 60
ac_UP_RECT_X_5:             equ 323
ac_UP_RECT_Y_5:             equ 234
ac_UP_WIDTH_5:              equ 31
ac_UP_HEIGHT_5:             equ 67

; for down frame drawing
ac_DOWN_RECT_X_1:             equ 229
ac_DOWN_RECT_Y_1:             equ 320
ac_DOWN_WIDTH_1:              equ 42
ac_DOWN_HEIGHT_1:             equ 33
ac_DOWN_RECT_X_2:             equ 271
ac_DOWN_RECT_Y_2:             equ 308
ac_DOWN_WIDTH_2:              equ 24
ac_DOWN_HEIGHT_2:             equ 26
ac_DOWN_RECT_X_3:             equ 295
ac_DOWN_RECT_Y_3:             equ 296
ac_DOWN_WIDTH_3:              equ 26
ac_DOWN_HEIGHT_3:             equ 34
ac_DOWN_RECT_X_4:             equ 321
ac_DOWN_RECT_Y_4:             equ 238
ac_DOWN_WIDTH_4:              equ 35
ac_DOWN_HEIGHT_4:             equ 83

; For down frame erasing
ac_DOWN_ERASE_X_START       equ 228
ac_DOWN_ERASE_Y_START       equ 292
ac_DOWN_ERASE_HEIGHT        equ 50
ac_DOWN_ERASE_WIDTH         equ 108
ac_DOWN_ERASE_RECT_X_1      equ 229
ac_DOWN_ERASE_RECT_Y_1      equ 342
ac_DOWN_ERASE_WIDTH_1       equ 35
ac_DOWN_ERASE_HEIGHT_1      equ 11
ac_DOWN_ERASE_RECT_X_2      equ 321
ac_DOWN_ERASE_RECT_Y_2      equ 240
ac_DOWN_ERASE_WIDTH_2       equ 31
ac_DOWN_ERASE_HEIGHT_2      equ 73


; For keeping track of note animation
ac_TOTAL_NOTE_FRAMES        equ 4
ac_FRAMES_PER_ANIMATION     equ 1 ; how many game frames should play before the next note animation frame
ac_CurrentNoteFrame:
    dc.l    0
ac_GameFrameCounter
    dc.l    0


; Public subroutines
; Subroutine: SwitchToUpFrameSubroutine
    ; Changes background to the up-frame bitmap
    ; Inputs, Returns, Volatile: None
SwitchToUpFrameSubroutine:
    ;movem.l d0-d7/a0-a6, -(sp)
    move.l  a0, -(sp)
    lea     BackgroundUp, a0
    move.l  a0, AddressOfBitmapToDraw
    jsr     ac_EraseDownFrameSubroutine
    jsr     ac_DrawUpFrameSubroutine
SwitchToUpFrameSubroutineEnd:
    ;movem.l (sp)+, d0-d7/a0-a6
    move.l  (sp)+, a0
    rts

; Subroutine: SwitchToDownFrameSubroutine
    ; Changes background to the down-frame bitmap
    ; Inputs, Returns, Volatile: None
SwitchToDownFrameSubroutine:
    ;movem.l d0-d7/a0-a6, -(sp)
    move.l  a0, -(sp)
    lea     BackgroundDown, a0
    move.l  a0, AddressOfBitmapToDraw
    jsr     ac_EraseUpFrameSubroutine
    jsr     ac_DrawDownFrameSubroutine
SwitchToDownFrameSubroutineEnd:
    ;movem.l (sp)+, d0-d7/a0-a6
    move.l  (sp)+, a0
    rts

; Subroutine: GetNextNoteBitmapSubroutine
    ; Gets the next bitmap for note animation
    ; Inputs: None
    ; Returns: bitmap in a0
    ; Volatile: a0
GetNextNoteBitmapSubroutine:
    ; Note: extremely hardcoded
    movem.l d0-d7/a1-a6, -(sp)
    ; Get current frame
    move.l  ac_CurrentNoteFrame, d0
    cmp.l   #0, d0
    beq.b   ac_NoteFrame0
    cmp.l   #1, d0
    beq.b   ac_NoteFrame1
    cmp.l   #2, d0
    beq.b   ac_NoteFrame2
    cmp.l   #3, d0
    beq.b   ac_NoteFrame3
    cmp.l   #4, d0
    beq.b   ac_NoteFrame4
    cmp.l   #5, d0
    beq.b   ac_NoteFrame5
    cmp.l   #6, d0
    beq.b   ac_NoteFrame6
    cmp.l   #7, d0
    beq.b   ac_NoteFrame7
ac_NoteFrame0:
    lea     NoteBitmap0, a0
    bra     GetNextNoteBitmapContinue
ac_NoteFrame1:
    lea     NoteBitmap1, a0
    bra     GetNextNoteBitmapContinue
ac_NoteFrame2:
    lea     NoteBitmap2, a0
    bra     GetNextNoteBitmapContinue
ac_NoteFrame3:
    lea     NoteBitmap3, a0
    bra     GetNextNoteBitmapContinue
ac_NoteFrame4:
    lea     NoteBitmap4, a0
    bra     GetNextNoteBitmapContinue
ac_NoteFrame5:
    lea     NoteBitmap5, a0
    bra     GetNextNoteBitmapContinue
ac_NoteFrame6:
    lea     NoteBitmap6, a0
    bra     GetNextNoteBitmapContinue
ac_NoteFrame7:
    lea     NoteBitmap7, a0
    move.l  #-1, d0
GetNextNoteBitmapContinue:
    ; Only increment every x frames
*    add.l   #1, ac_GameFrameCounter
*    cmp.l   #ac_FRAMES_PER_ANIMATION, ac_GameFrameCounter
*    blt.b   GetNextNoteBitmapSubroutineEnd
*    move.l  #0, ac_GameFrameCounter
    ; Increment to next frame
    add.l   #1, d0
    move.l  d0, ac_CurrentNoteFrame
GetNextNoteBitmapSubroutineEnd:
    movem.l (sp)+, d0-d7/a1-a6
    rts

; Private subroutines
; For BitmapNoTransparencySubroutine:
; a0 = pointer to .bmp file in memory
; d0 = top left corner of bitmap chunk x
; d1 = top left corner of bitmap chunk y
; d2 = top left corner of output screen x
; d3 = top left corner of output screen y
; d4 = width of bitmap chunk
; d5 = height of bitmap chunk
; Draws the up frame
ac_DrawUpFrameSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    lea     BackgroundUp, a0
    ; Draw 5 bitmap rectangles
    ; rect 1
    move.l  #ac_UP_RECT_X_1, d0
    move.l  #ac_UP_RECT_Y_1, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_UP_WIDTH_1, d4
    move.l  #ac_UP_HEIGHT_1, d5
    jsr     BitmapNoTransparencySubroutine
    ; rect 2
    move.l  #ac_UP_RECT_X_2, d0
    move.l  #ac_UP_RECT_Y_2, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_UP_WIDTH_2, d4
    move.l  #ac_UP_HEIGHT_2, d5
    jsr     BitmapNoTransparencySubroutine
    ; rect 3
    move.l  #ac_UP_RECT_X_3, d0
    move.l  #ac_UP_RECT_Y_3, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_UP_WIDTH_3, d4
    move.l  #ac_UP_HEIGHT_3, d5
    jsr     BitmapNoTransparencySubroutine
    ; rect 4
    move.l  #ac_UP_RECT_X_4, d0
    move.l  #ac_UP_RECT_Y_4, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_UP_WIDTH_4, d4
    move.l  #ac_UP_HEIGHT_4, d5
    jsr     BitmapNoTransparencySubroutine
    ; rect 5
    move.l  #ac_UP_RECT_X_5, d0
    move.l  #ac_UP_RECT_Y_5, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_UP_WIDTH_5, d4
    move.l  #ac_UP_HEIGHT_5, d5
    jsr     BitmapNoTransparencySubroutine
ac_DrawUpFrameSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Erases the up frame from BackgroundUp
ac_EraseUpFrameSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Set pen color for primitives
    move.l  #ac_YELLOW_COLOR, d1
    move.l  #ac_SET_PEN_COLOR_TRAPCODE, d0
    trap    #15
    move.l  #ac_SET_FILL_COLOR_TRAPCODE, d0
    trap    #15
    ; Draw rectangles
    move.l  #ac_DRAW_RECTANGLE_TRAPCODE, d0
    ; Rect 1
    move.l  #ac_UP_RECT_X_1, d1
    move.l  #ac_UP_RECT_Y_1, d2
    move.l  #(ac_UP_RECT_X_1+ac_UP_WIDTH_1), d3
    move.l  #(ac_UP_RECT_Y_1+ac_UP_HEIGHT_1), d4
    trap    #15
    ; Rect 2
    move.l  #ac_UP_RECT_X_2, d1
    move.l  #ac_UP_RECT_Y_2, d2
    move.l  #(ac_UP_RECT_X_2+ac_UP_WIDTH_2), d3
    move.l  #(ac_UP_RECT_Y_2+ac_UP_HEIGHT_2), d4
    trap    #15
    ; Rect 3
    move.l  #ac_UP_RECT_X_3, d1
    move.l  #ac_UP_RECT_Y_3, d2
    move.l  #(ac_UP_RECT_X_3+ac_UP_WIDTH_3), d3
    move.l  #(ac_UP_RECT_Y_3+ac_UP_HEIGHT_3), d4
    trap    #15
    ; Rect 4
    move.l  #ac_UP_RECT_X_4, d1
    move.l  #ac_UP_RECT_Y_4, d2
    move.l  #(ac_UP_RECT_X_4+ac_UP_WIDTH_4), d3
    move.l  #(ac_UP_RECT_Y_4+ac_UP_HEIGHT_4), d4
    trap    #15
    ; Rect 5 (actual bitmap)
    lea     BackgroundBase, a0
    move.l  #ac_UP_RECT_X_5, d0
    move.l  #ac_UP_RECT_Y_5, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_UP_WIDTH_5, d4
    move.l  #ac_UP_HEIGHT_5, d5
    jsr     BitmapNoTransparencySubroutine
ac_EraseUpFrameSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Draws the down frame
ac_DrawDownFrameSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    lea     BackgroundDown, a0
    ; Draw 5 bitmap rectangles
    ; rect 1
    move.l  #ac_DOWN_RECT_X_1, d0
    move.l  #ac_DOWN_RECT_Y_1, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_DOWN_WIDTH_1, d4
    move.l  #ac_DOWN_HEIGHT_1, d5
    jsr     BitmapNoTransparencySubroutine
    ; rect 2
    move.l  #ac_DOWN_RECT_X_2, d0
    move.l  #ac_DOWN_RECT_Y_2, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_DOWN_WIDTH_2, d4
    move.l  #ac_DOWN_HEIGHT_2, d5
    jsr     BitmapNoTransparencySubroutine
    ; rect 3
    move.l  #ac_DOWN_RECT_X_3, d0
    move.l  #ac_DOWN_RECT_Y_3, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_DOWN_WIDTH_3, d4
    move.l  #ac_DOWN_HEIGHT_3, d5
    jsr     BitmapNoTransparencySubroutine
    ; rect 4
    move.l  #ac_DOWN_RECT_X_4, d0
    move.l  #ac_DOWN_RECT_Y_4, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_DOWN_WIDTH_4, d4
    move.l  #ac_DOWN_HEIGHT_4, d5
    jsr     BitmapNoTransparencySubroutine
ac_DrawDownFrameSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Erases the down frame from BackgroundUp
ac_EraseDownFrameSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Set pen color for primitives
    move.l  #ac_MEDIUM_YELLOW_COLOR, d1
    move.l  #ac_SET_PEN_COLOR_TRAPCODE, d0
    trap    #15
    move.l  #ac_SET_FILL_COLOR_TRAPCODE, d0
    trap    #15
    ; Draw some primitives to hide some of the down frame
    ; d2 is height. d7 is counter
ac_EraseDownLoopSetup:
    move.l  #ac_DOWN_ERASE_HEIGHT, d7
    move.l  #ac_DOWN_ERASE_X_START, d1
    move.l  #ac_DOWN_ERASE_Y_START, d2
    move.l  #(ac_DOWN_ERASE_X_START+ac_DOWN_ERASE_WIDTH), d3
    move.l  #(ac_DOWN_ERASE_Y_START+1), d4
    move.l  #ac_MEDIUM_YELLOW_COLOR, d6
    move.l  #ac_DOWN_ERASE_HEIGHT, d7
ac_EraseDownLoop:
    ; Print primitive (single row)
    move.l  #ac_DRAW_RECTANGLE_TRAPCODE, d0
    trap    #15
    ; Increment Y to go one row down
    add.l   #2, d2
    add.l   #2, d4
    ; Decrement color
    sub.l   #$00000101, d6
    move.l  d6, d1
    move.l  #ac_SET_PEN_COLOR_TRAPCODE, d0
    trap    #15
    move.l  #ac_SET_FILL_COLOR_TRAPCODE, d0
    trap    #15
    ; Branch
    sub.l   #2, d7
    cmp.l   #0, d7
    bgt     ac_EraseDownLoop
ac_EraseDownLoopEnd:
    ; Use bitmap printing to hide the rest of the down frame
    ; Rect 1
    lea     BackgroundBase, a0
    move.l  #ac_DOWN_ERASE_RECT_X_1, d0
    move.l  #ac_DOWN_ERASE_RECT_Y_1, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_DOWN_ERASE_WIDTH_1, d4
    move.l  #ac_DOWN_ERASE_HEIGHT_1, d5
    jsr     BitmapNoTransparencySubroutine
    ; Rect 2
    lea     BackgroundBase, a0
    move.l  #ac_DOWN_ERASE_RECT_X_2, d0
    move.l  #ac_DOWN_ERASE_RECT_Y_2, d1
    move.l  d0, d2
    move.l  d1, d3
    move.l  #ac_DOWN_ERASE_WIDTH_2, d4
    move.l  #ac_DOWN_ERASE_HEIGHT_2, d5
    jsr     BitmapNoTransparencySubroutine
ac_EraseDownFrameSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts



