*-----------------------------------------------------------
* Title      : Bitmap Subroutine Shell Function
* Written by : Jeffrey Zhang
* Date       : October 2, 2023
* Description: Shell function surrounding a subroutines that
*              prints out a specified chunk of a 32-bit
*              bitmap onto the output window screen
*-----------------------------------------------------------

; ---------------------------------
; ---------------------------------
; ---- BEGIN COPY FROM HERE -------
; ---------------------------------
; ---------------------------------
; Helpful constants
RESIZE_WINDOW_TRAP_CODE         EQU     33
PEN_COLOR_TRAP_CODE             EQU     80
DRAW_PIXEL_TRAP_CODE            EQU     82

; Set Window size subroutine
; Function: Sets window size to specified size
; Inputs:
; d0 = width
; d1 = height
; Return: None
; Volatile: None
WindowResizeSubroutine:
    movem.l d0-d1, -(sp)
    swap    d1
    move.w  d0, d1
    swap    d1
    move.l  #RESIZE_WINDOW_TRAP_CODE, d0
    trap    #15
WindowResizeSubroutineEnd:
    movem.l (sp)+, d0-d1
    rts


; Subroutine: Preprocess Bitmap
    ; function: goes through a bitmap and changes all pixel data to 00BBGGRR format.
    ; if the alpha channel is under some preset value, then instead converts to FF000000
    ; Inputs: a0 ptr to bitmap header
PreprocessBitmapSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Get file size into a1 (end of bitmap pixel data)
    move.l  (2,a0), d7
    jsr     EndianSubroutine
    move.l  a0, a1
    add.l   d7, a1
    ; Get address of first pixel into a0
    move.l  (10,a0), d7
    jsr     EndianSubroutine
    add.l   d7, a0
db_PreprocessBitmapLoop:
    ; For each pixel, move into d0.
    ; Pixel data is stored as BBGGRRAA
    ; We want it to be 00BBGGRR, or FF000000
    move.l  (a0), d0
    ; If alpha channel is 50 or less
    cmp.b   #50, d0
    bhi.b   db_PreprocessIsColorPixel
db_PreprocessIsAlphaPixel:
    move.l  #$FF000000, (a0)
    bra     db_PreprocessBitmapLoopContinue
db_PreprocessIsColorPixel:
    ; change BBGGRRAA to 00BBGGRR. that's just a lsr
    lsr.l   #8, d0
    move.l  d0, (a0)
db_PreprocessBitmapLoopContinue:
    ; Increment a0
    add.l   #4, a0
    ; check if a0 has reached a1 yet. If not, loop
    cmp.l   a1, a0
    blo     db_PreprocessBitmapLoop
db_PreprocessBitmapLoopEnd:
PreprocessBitmapSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Bitmap subroutine
; Function: Prints out a 32-bit bitmap
; Note: Some edge cases will output an error message to the window
;       Other edge cases will be handled gracefully
; Inputs: 
; a0 = pointer to .bmp file in memory
; d0 = top left corner of bitmap chunk x
; d1 = top left corner of bitmap chunk y
; d2 = top left corner of output screen x
; d3 = top left corner of output screen y
; d4 = width of bitmap chunk
; d5 = height of bitmap chunk
; Return:
; Will clear d0 and d1 if inputs are too large
; Will change d4 and d5 if inputs are too large
; Volatile:
; d6-d7, a1
BitmapSubroutine:
    movem.l d0-d7/a0-a6, -(sp) ; push input from stack
*    clr.l   d0              ; Clear data regs just in case
*    clr.l   d1
*    clr.l   d2
*    clr.l   d3
*    clr.l   d4
*    clr.l   d5
db_GetInfoFromHeader:
; Gets offset of pixel data
; a0 = address for reading header
; a1 = location of first pixel
; d0 = reserved for trap #15
; d1 = reserved for trap #15
; d3 = width from header (totalW)
; d4 = height from header (totalH)
; d7 = temp reg for endian
    move.l  a0, a1
    ;move.l  (32,sp), a0
    add.l   #10, a0
    move.l  (a0), d7
    jsr     EndianSubroutine
    add.l   d7, a1
; Gets width and height
    add.l   #8, a0
    move.l  (a0)+, d7
    jsr     EndianSubroutine
    move.l  d7, d3
    move.l  (a0)+, d7
    jsr     EndianSubroutine
    move.l  d7, d4
; Set up output window dims
; with a little bit of padding just in case
    ;move.w  d3, d1
    ;add.l   #1, d1
    ;swap    d1
    ;move.w  d4, d1
    ;add.l   #1, d1
    ;move.l  #RESIZE_WINDOW_TRAP_CODE, d0
    ;trap    #15
    clr.l   d1

; Check more edge cases
; d6 = temp register for edge cases
; d7 = temp register for edge cases
*db_CheckEdgeCasesRound2:
*db_ECCheckxoffset:
*; Edge case 5.1: xoffset is greater than or equal to totalW
*; If this is the case, just set it to 0
*    move.l  (sp), d7
*    cmp.l   d3, d7
*    blt     db_ECCheckxoffsetEnd
*    clr.l   d7
*    move.l  d7, (sp)
*db_ECCheckxoffsetEnd:
*db_ECCheckyoffset:
*; Edge case 5.2: yoffset is greater than or equal to totalH
*; If this is the case, just set it to 0
*    move.l  (4,sp), d7
*    cmp.l   d4, d7
*    blt     db_ECCheckyoffsetEnd
*    clr.l   d7
*    move.l  d7, (4,sp)
*db_ECCheckyoffsetEnd:
*db_ECCheckChunkWidth:
*; Edge case 6.1: xoffset + chunk width is greater than totalW
*;                Also check if chunk width is 0
*    move.l  (sp), d6    ; d6 = xoffset
*    move.l  (16,sp), d7 ; d7 = chunkW
*    add.l   d6, d7      ; d7 = xoffset + chunkW
*    cmp.l   d3, d7      ; Compare d7 to totalW
*    bgt     db_ECCheckChunkWidthFix
*    cmp.l   d6, d7      ; Compare d7 to d6. If they are the same, chunk is 0, and needs to be re-set
*    bne     db_ECCheckChunkWidthEnd   
*db_ECCheckChunkWidthFix:
*    move.l  d3, d7      ; If xoffset + chunkW is too large, then re-set chunkW to be acceptable
*    sub.l   d6, d7      ; that is, chunkW = totalW - xoffset
*    move.l  d7, (16,sp) ; Note that this changes the value in the stack, and therfore the return of d4
*db_ECCheckChunkWidthEnd:
*db_ECCheckChunkHeight:
*;Edge case 6.2: yoffset + chunk height is greater than totalH
*;               Also check if chunk height is 0
*    move.l  (4,sp), d6  ; d6 = yoffset
*    move.l  (20,sp), d7 ; d7 = chunkH
*    add.l   d6, d7      ; d7 = yoffset + chunkH
*    cmp.l   d4, d7      
*    bgt     db_ECCheckChunkHeightFix
*    cmp.l   d6, d7      ; Compare d7 to d6. If they are the same, chunk is 0, and needs to be re-set
*    bne     db_ECCheckChunkHeightEnd
*db_ECCheckChunkHeightFix:
*    move.l  d4, d7      ; If yoffset + chunkH is too large, then re-set chunkH to be acceptable
*    sub.l   d6, d7
*    move.l  d7, (20,sp)
*db_ECCheckChunkHeightEnd:
*db_CheckEdgeCasesRound2End:

; Begin print to screen
db_PrintLoopSetup:
; d0 = reserved for trap #15
; d1 = counter for x (width). From xoffset to width. Also reserved for trap #15
; d2 = counter for y (height). From height-yoffset-1 to 0
; d3 = width from header. Also chunkWidth - 1 for inner loop
; d4 = height from header. Also counter for x (width) instead of d1 for optimization
; d5 = yprintoffset
; d6 = temp reg for SkipRows. Also for skipping columns
; d7 = temp reg for endian, for SkipRows
    ;move.l  d4, d2      ; d2 = totalHeight. Not done yet
    ;move.l  (4,sp), d4
    ;sub.l   d4, d2      ; d2 = totalHeight - yoffset. Not done yet
    ;sub.l   #1, d2      ; d2 = totalHeight - yoffset - 1. Done
    move.l  (12,sp), d5 ; d5 = yprintoffset
    move.l  (20,sp), d2 ; d2 = chunkHeight -1 + yprintoffset
    sub.l   #1, d2
    add.l   d5, d2
db_SkipRowsSetup:
    move.l  d4, d6      ; d6 contains number of rows to skip (totalHeight - chunkHeight - yoffset)
    sub.l   (20,sp), d6
    sub.l   (4,sp), d6
    beq     db_SkipRowsEnd ; if d6 is zero, no need to skip anything
    move.l  d3, d7      ; d7 contains the totalWidth
    mulu.w  #4, d7      ; multiply by 4, because each pixel is 4 bytes
db_SkipRowsLoop:
    ;add.l   d7, a1      ; skip that many pixels
    ;sub.l   #1, d6      ; do it d6 number of times
    ;bgt     db_SkipRowsLoop
    mulu.w  d6, d7
    add.l   d7, a1
db_SkipRowsEnd:
    ; Set up constants for inner loop as well
    move.l  (sp), d7    ; d7 = xoffset
    move.l  d3, d6      ; d6 = totalW - chunkW - xoffset
    sub.l   (16,sp), d6
    sub.l   d7, d6
*    move.l  (16,sp), d3 ; d3 = chunkWidth + xprintoffset
*    add.l   (8,sp), d3

    move.l  (8,sp), a4  ; a4 = xprintoffset

    move.l  (20,sp), d5 ; d5 = chunkH - 1
    sub.l   #1, d5
    
    add.l   d6, d6      ; d6 = d6*4, because pixel data is longs
    add.l   d6, d6
    add.l   d7, d7      ; d7 = d7*4, because pixel data is longs
    add.l   d7, d7
db_PrintLoop:
    move.l  (16,sp), d3 ; d3 = chunkWidth - 1
    sub.l   #1, d3
*    clr.l   d4          ; d4 = xprintoffset
*    add.l   (8,sp), d4
    move.l   a4, d4
    ; Skip xoffset columns
    add.l   d7, a1   ; skip columns equal to number of offset
db_PrintLoopInner:
    ; get pen color (aka pixel color)
    move.l   (a1)+, d1
*db_CheckForAlpha:
*    cmp.b   #50, d1     ; Information stored as BGRA. Skip the pixel if alpha is less than, say, 50
*    bls.b   db_SkipOnePixel
*    lsr.l   #8, d1      ; Information stored as BGRA. Trap#15 looking for XBGR
*    move.l  #PEN_COLOR_TRAP_CODE, d0
*    trap    #15
db_CheckForAlpha: ; this is with preprocessing
    cmp.l   #$FF000000, d1  ; If the pixel is FF000000, then skip it
    beq.b   db_SkipOnePixel
    move.l  #PEN_COLOR_TRAP_CODE, d0
    trap    #15
db_PrintOnePixel:
    move.l  #DRAW_PIXEL_TRAP_CODE, d0
    move.l  d4, d1   ; move d4 to d1
    ; Print at d1, d2
    trap    #15
db_SkipOnePixel:
db_FinishOnePixel:
*    ; Increment d4
    add.l   #1, d4
*    cmp.w   d3, d4
*    blt     db_PrintLoopInner
    dbf     d3, db_PrintLoopInner
db_PrintLoopInnerEnd:
    ; Skip totalW-chunkW-xoffset columns
    add.l   d6, a1 
    ; Increment d2
    sub.l   #1, d2
    ; Decrement d5. If not negative yet, branch back
    dbf     d5, db_PrintLoop
db_PrintLoopEnd:
db_BitmapSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6 ; pop input from stack
    rts



; Bitmap subroutine with no transparency
    ; Same at BitmapSubroutine, but assumes that none of the pixels are transparent (FF000000)
    ; Not commented well, see BitmapSubroutine for comments
BitmapNoTransparencySubroutine:
    movem.l d0-d7/a0-a6, -(sp) ; push input from stack
dbnt_GetInfoFromHeader:
; Gets offset of pixel data
    move.l  a0, a1
    add.l   #10, a0
    move.l  (a0), d7
    jsr     EndianSubroutine
    add.l   d7, a1
; Gets width and height
    add.l   #8, a0
    move.l  (a0)+, d7
    jsr     EndianSubroutine
    move.l  d7, d3
    move.l  (a0)+, d7
    jsr     EndianSubroutine
    move.l  d7, d4
    clr.l   d1
; Begin print to screen
dbnt_PrintLoopSetup:
    move.l  (12,sp), d5 ; d5 = yprintoffset
    move.l  (20,sp), d2 ; d2 = chunkHeight -1 + yprintoffset
    sub.l   #1, d2
    add.l   d5, d2
dbnt_SkipRowsSetup:
    move.l  d4, d6      ; d6 contains number of rows to skip (totalHeight - chunkHeight - yoffset)
    sub.l   (20,sp), d6
    sub.l   (4,sp), d6
    beq     dbnt_SkipRowsEnd ; if d6 is zero, no need to skip anything
    move.l  d3, d7      ; d7 contains the totalWidth
    mulu.w  #4, d7      ; multiply by 4, because each pixel is 4 bytes
dbnt_SkipRowsLoop:
    mulu.w  d6, d7
    add.l   d7, a1
dbnt_SkipRowsEnd:
    move.l  (sp), d7    ; d7 = xoffset
    move.l  d3, d6      ; d6 = totalW - chunkW - xoffset
    sub.l   (16,sp), d6
    sub.l   d7, d6
    move.l  (16,sp), d3 ; d3 = chunkWidth + xprintoffset
    add.l   (8,sp), d3
    move.l  (8,sp), a4  ; a4 = xprintoffset
    move.l  (20,sp), d5 ; d5 = chunkH - 1
    sub.l   #1, d5
    add.l   d6, d6      ; d6 = d6*4, because pixel data is longs
    add.l   d6, d6
    add.l   d7, d7      ; d7 = d7*4, because pixel data is longs
    add.l   d7, d7
dbnt_PrintLoop:
    move.l  (16,sp), d3 ; d3 = chunkWidth - 1
    sub.l   #1, d3
    move.l   a4, d4
    ; Skip xoffset columns
    add.l   d7, a1   ; skip columns equal to number of offset
dbnt_PrintLoopInner:
    ; get pen color (aka pixel color)
    move.l   (a1)+, d1
    move.l  #PEN_COLOR_TRAP_CODE, d0
    trap    #15
    move.l  #DRAW_PIXEL_TRAP_CODE, d0
    move.l  d4, d1   ; move d4 to d1
    ; Print at d1, d2
    trap    #15
    add.l   #1, d4
    dbf     d3, dbnt_PrintLoopInner
dbnt_PrintLoopInnerEnd:
    add.l   d6, a1 
    sub.l   #1, d2
    dbf     d5, dbnt_PrintLoop
dbnt_PrintLoopEnd:
dbnt_BitmapSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6 ; pop input from stack
    rts




; Endian Subroutine
; Function: converts long from big/little endian
; Inputs: d7 = long to be converted
; Outputs: d7 = converted long
EndianSubroutine:
    rol.w   #8, d7      ; Convers to big endian
    swap    d7
    rol.w   #8, d7
EndianSubroutineEnd:
    rts
; ---------------------------------
; ---------------------------------
; -------- END COPY TO HERE -------
; ---------------------------------
; ---------------------------------




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
