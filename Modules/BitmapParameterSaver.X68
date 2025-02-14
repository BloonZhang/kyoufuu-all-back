bps_STORAGE_SIZE                equ 32

bps_IndexCounter:
    dc.l    0
bps_XOffsetStorage:
    dcb.l   bps_STORAGE_SIZE,0
bps_YOffsetStorage:
    dcb.l   bps_STORAGE_SIZE,0
bps_XChunkStorage:
    dcb.l   bps_STORAGE_SIZE,0
bps_YChunkStorage:
    dcb.l   bps_STORAGE_SIZE,0

; Subroutine: SaveBitmapParameterSubroutine
; Saves the Xoffset, Yoffset, chunkW, and chunkH info for a bitmap
    ; Inputs:
    ; d0 = Xoffset
    ; d1 = Yoffset
    ; d4 = chunkWidth
    ; d5 = chunkHeight
    ; Returns: None
    ; Volatile: None
SaveBitmapParameterSubroutine:
    ; protect registers
    movem.l  d0-d7/a0-a6, -(sp)
    
    ; d7 will be our index for storage
    move.l  bps_IndexCounter, d7
    lsl.l   #2, d7
    
    ; Move all registers into the corresponding array
    lea     bps_XOffsetStorage, a1
    move.l  d2, (0,a1,d7)
    lea     bps_YOffsetStorage, a1
    move.l  d3, (0,a1,d7)
    lea     bps_XChunkStorage, a1
    move.l  d4, (0,a1,d7)
    lea     bps_YChunkStorage, a1
    move.l  d5, (0,a1,d7)
    
    ; increment d7 for next time subroutine is called
    lsr.l   #2, d7
    add.l   #1, d7
    move.l  d7, bps_IndexCounter
SaveBitmapParameterSubroutineEnd:
    ; pop registers
    movem.l  (sp)+, d0-d7/a0-a6
    rts
    
; Subroutine: DrawSavedBitmapsSubroutine
    ; Draws all bitmaps based on the saved bitmap parameters
    ; Inputs:
    ; a0 = pointer to .bmp file in memory
    ; Outputs: None
    ; Volatile: None
DrawSavedBitmapsSubroutine:
    ; protect registers
    movem.l d0-d7/a0-a6, -(sp)
    ; Uses BitmapSubroutine in DrawBitmap.X68. 
    ; Inputs forthat are: 
    ; a0 = address
    ; d0,d1 = x,y top left corner of chunk
    ; d2,d3 = x,y where to print on screen. For this intent, equal to d0,d1
    ; d4, d5 = width,height of chunk
dsp_DrawSavedBitmapsLoopSetup:
    ; Get index into d7. This is how many bitmaps we need to redraw
    move.l  bps_IndexCounter, d7
    cmp.l   #0, d7
    beq     DrawSavedBitmapsSubroutineEnd
    ; predecrement d7
    sub.l   #1, d7
    lsl.l   #2, d7
dsp_DrawSavedBitmapsLoop:
    ; prepares registers for BitmapSubroutine
    lea     bps_XOffsetStorage, a1
    move.l  (0,a1,d7),d0
    move.l  d0, d2
    lea     bps_YOffsetStorage, a1
    move.l  (0,a1,d7),d1
    move.l  d1, d3
    lea     bps_XChunkStorage, a1
    move.l  (0,a1,d7),d4
    lea     bps_YChunkStorage, a1
    move.l  (0,a1,d7),d5
    ; actually draws the bitmap
    jsr    BitmapNoTransparencySubroutine
    ; check if there's more to draw
    sub.l   #4, d7
    bge     dsp_DrawSavedBitmapsLoop
dsp_DrawSavedBitmapsLoopEnd:
    ; set d7 to be 0
    clr.l   d7
    move.l  d7, bps_IndexCounter
DrawSavedBitmapsSubroutineEnd:
    ;pop registers
    movem.l (sp)+, d0-d7/a0-a6
    rts










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
