;    ORG $100 ; DELETE

nd_MAX_NOTES            equ 5
; Saved in GameMain
; NOTE_BITMAP_WIDTH equ
; NOTE_BITMAP_HEIGHT equ
;nd_CHOP_NOTE_POSITION   equ 243
;nd_CHOP_NOTE_WINDOW     equ 51
nd_CHOP_NOTE_MINIMUM    equ (nd_CHOP_NOTE_POSITION-nd_CHOP_NOTE_WINDOW)
nd_CHOP_NOTE_MAXIMUM    equ (nd_CHOP_NOTE_POSITION+nd_CHOP_NOTE_WINDOW)
nd_MISS_NOTE_POSITION   equ (nd_CHOP_NOTE_MINIMUM-nd_CHOP_NOTE_WINDOW)

; TODO: treat position and velocity as fixed point
nd_FirstNoteCounter:    dc.l    0
nd_NumberOfActiveNotes: dc.l    0
nd_NoteXPositionQueue:
    dcb.l   nd_MAX_NOTES,0
nd_NoteYPositionQueue:
    dcb.l   nd_MAX_NOTES,0
nd_NoteXVelocityQueue:
    dcb.l   nd_MAX_NOTES,0
nd_NoteYVelocityQueue:
    dcb.l   nd_MAX_NOTES,0
        
; Default values
; In GameMain.X68
;nd_NoteStartingXPosition:   dc.l    500
;nd_NoteStartingYPosition:   dc.l    300
;nd_NoteStartingXVelocity:   dc.l    -5
;nd_NoteStartingYVelocity:   dc.l    1
        
;START: ; DELETE

; Subroutine: UpdateNotesSubroutine 
    ; Updates the position of all notes
    ; Inputs, Returns, Volatile: None
UpdateNotesSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If there are no notes on screen, just reutrn
    cmp.l   #0, nd_NumberOfActiveNotes
    beq     UpdateNotesSubroutineEnd
    ; Go through all active notes, and increase their position based on their velocity
nd_UpdateNotesLoopSetup:
    ; d5 = temp register for data movement
    ; d6 = firstNoteCounter
    ; for (d7 = 0; d7 < nd_NumberOfActiveNotes; d7++)
    ;   update arrays[d6]
    ;   d6++. If d6 >= nd_MAX_NOTES, d6 = 0
    clr.l   d5
    move.l  nd_FirstNoteCounter, d6    
    lsl.l   #2, d6 
    clr.l   d7
    lea     nd_NoteXPositionQueue, a0
    lea     nd_NoteXVelocityQueue, a1 ; optimized to a0 + nd_MAX_NOTES?
    lea     nd_NoteYPositionQueue, a2
    lea     nd_NoteYVelocityQueue, a3
nd_UpdateNotesLoop:
    ; Get note X position and add X velocity
    move.l  (0,a0,d6), d5
    add.l   (0,a1,d6), d5
    ; If X position is less than missed position, then missed the note. Proceed to despawn note
    cmp.l   #nd_MISS_NOTE_POSITION, d5
    bgt.b   nd_UpdateNotesDidNotMiss
nd_UpdateNotesMissedNote:
    jsr     MissNoteScoreSubroutine
    jsr     DespawnFirstNoteSubroutine  ; TODO: is this buggy because we're updating NumberOfActiveNotes within the loop?
    sub.l   #1, d7                      ; Answer: yes, so just be jank and subtract one from d7
    bra     nd_UpdateNotesLoopContinue
nd_UpdateNotesDidNotMiss:
    ; If X position was fine, then keep going
    move.l  d5, (0,a0,d6)
    ; Get note Y position and add Y velocity
    move.l  (0,a2,d6), d5
    add.l   (0,a3,d6), d5
    move.l  d5, (0,a2,d6)
nd_UpdateNotesLoopContinue:
    ; Increment d6. If too high, reset to zero
    bsr     nd_IncrementD6
    ; Incremet d7 for the for loop
    add.l   #1, d7
    cmp.l   nd_NumberOfActiveNotes, d7
    blt     nd_UpdateNotesLoop
nd_UpdateNotesLoopEnd:
UpdateNotesSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Subroutine: DrawNotesSubroutine
    ; Draws all the notes in storage
    ; Inputs:
    ;   a0 = address to note bitmap
    ; Returns, Volatile: None
DrawNotesSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If there are no notes on screen, just reutrn
    cmp.l   #0, nd_NumberOfActiveNotes
    beq     UpdateNotesSubroutineEnd
nd_DrawNotesLoopSetup:
    ; a0 = address to bitmap
    ; d6 = firstNoteCounter
    ; for (d7 = 0; d7 < nd_NumberOfActiveNotes; d7++)
    ;   print note d6
    ;   d6++. If d6 >= nd_MAX_NOTES, d6 = 0
    ;clr.l   d5
    move.l  nd_FirstNoteCounter, d6     
    lsl.l   #2, d6
    clr.l   d7
    lea     nd_NoteXPositionQueue, a4
    lea     nd_NoteYPositionQueue, a5
    ; Subroutine: BitmapSubroutine inputs: 
    ; a0 = pointer to .bmp file in memory
    ; d0 = top left corner of bitmap chunk x
    ; d1 = top left corner of bitmap chunk y
    ; d2 = top left corner of output screen x
    ; d3 = top left corner of output screen y
    ; d4 = width of bitmap chunk
    ; d5 = height of bitmap chunk
    move.l  #0, d0  ; Top left corner of bitmap is just 0,0
    move.l  #0, d1
    move.l  #NOTE_BITMAP_WIDTH, d4
    move.l  #NOTE_BITMAP_HEIGHT, d5
nd_DrawNotesLoop:
    ; get data required to print bitmap
    move.l  (0,a4,d6), d2
    move.l  (0,a5,d6), d3
    bsr     BitmapSubroutine
    ; Increment d6. If too high, reset to zero
    bsr     nd_IncrementD6
    ; Incremet d7 for the for loop
    add.l   #1, d7
    cmp.l   nd_NumberOfActiveNotes, d7
    blt     nd_DrawNotesLoop
nd_DrawNotesLoopEnd:
DrawNotesSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Subroutine: SaveNoteParametersSubroutine
    ; Saves all note locations to SaveBitmapParameterSubroutine
    ; Inputs, Returns, Volatile: None
SaveNoteParametersSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If there are no notes on screen, just reutrn
    cmp.l   #0, nd_NumberOfActiveNotes
    beq     UpdateNotesSubroutineEnd
    ; d6 = firstNoteCounter
    ; for (d7 = 0; d7 < nd_NumberOfActiveNotes; d7++)
    ;   save note d6 into BitmapParameterSaver
    ;   d6++. If d6 >= nd_MAX_NOTES, d6 = 0
nd_SaveNoteParametersLoopSetup:
    lea     nd_NoteXPositionQueue, a0
    lea     nd_NoteYPositionQueue, a2
    move.l  nd_FirstNoteCounter, d6
    lsl.l   #2, d6
    clr.l   d7
nd_SaveNoteParametersLoop:
    ; SaveBitmapParameterSubroutine inputs:
    ; d2 = Xoffset and/or Xprintoffset (they should be equal)
    ; d3 = Yoffset and/or Yprintoffset
    ; d4 = chunkWidth
    ; d5 = chunkHeight
    move.l  (0,a0,d6), d2
    move.l  (0,a2,d6), d3
    move.l  #NOTE_BITMAP_WIDTH, d4
    move.l  #NOTE_BITMAP_HEIGHT, d5
    jsr     SaveBitmapParameterSubroutine
    ; Increment d6. If too high, reset to zero
    bsr     nd_IncrementD6
    ; Increment d7 for the for loop
    add.l   #1, d7
    cmp.l   nd_NumberOfActiveNotes, d7
    blt     nd_SaveNoteParametersLoop
nd_SaveNoteParametersLoopEnd:
SaveNoteParametersSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts


; Subroutine: SpawnNoteSubroutine
    ; Spawns a note at the default spawn position with the default velocity
    ; Inputes, Returns, Volatile: None
SpawnNoteSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Increment number of active notes
    add.l   #1, nd_NumberOfActiveNotes
    ; d6 = firstnotecounter + numberofactivenotes - 1
    move.l  nd_FirstNoteCounter, d6
    add.l   nd_NumberOfActiveNotes, d6
    sub.l   #1, d6
    lsl.l   #2, d6
    ; check that d6 isn't too large. If it is, d6 = d6 - maxnotes
    cmp.l   #nd_MAX_NOTES<<2, d6
    blt     nd_SpawnNoteCreateNewData
    sub.l   #nd_MAX_NOTES<<2, d6
nd_SpawnNoteCreateNewData:
    ; Set the default values to position and velocities
    lea     nd_NoteXPositionQueue, a0
    lea     nd_NoteXVelocityQueue, a1
    lea     nd_NoteYPositionQueue, a2
    lea     nd_NoteYVelocityQueue, a3  
    move.l  #nd_NoteStartingXPosition, (0,a0,d6)
    move.l  #nd_NoteStartingYPosition, (0,a2,d6)
    move.l  #nd_NoteStartingXVelocity, (0,a1,d6)
    move.l  #nd_NoteStartingYVelocity, (0,a3,d6)
SpawnNoteSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Subroutine: DespawnFirstNoteSubroutine
    ; Despawns the oldest note
    ; Inputs, Returns, Volatile: None
DespawnFirstNoteSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Subtract number of active notes
    sub.l   #1, nd_NumberOfActiveNotes
    ; Increment firstnotecouter, resetting if needed
    move.l  nd_FirstNoteCounter, d6
    lsl.l   #2, d6
    jsr     nd_IncrementD6
    lsr.l   #2, d6
    move.l  d6, nd_FirstNoteCounter
DespawnFirstNoteSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts


; Subroutine: CheckFirstNoteSubroutine
    ; Called when the player inputs space. Checks if the first note is available to be chopped
    ; Inputs, Returns, Volatile: None
CheckFirstNoteSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If there are no notes on screen, just break combo
    cmp.l   #0, nd_NumberOfActiveNotes
    beq     nd_CheckFirstNoteMiss    
    ; Check if the first note is within the chop area by getting X position of first note
    move.l  nd_FirstNoteCounter, d6
    lsl.l   #2, d6
    lea     nd_NoteXPositionQueue, a4
    move.l  (0,a4,d6),d7
    ; Check if too far right
    cmp.l   #nd_CHOP_NOTE_MAXIMUM, d7
    bhi.b   nd_CheckFirstNoteMiss
    ; Check if too far left
    cmp.l   #nd_CHOP_NOTE_MINIMUM, d7
    blo.b   nd_CheckFirstNoteMiss
    ; At this point, chop the note
    jsr     SpawnProjectilesSubroutine
    jsr     HitNoteScoreSubroutine
    jsr     DespawnFirstNoteSubroutine
    bra     CheckfirstNoteSubroutineEnd
nd_CheckFirstNoteMiss:
    jsr     MissNoteScoreSubroutine
CheckFirstNoteSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts


; Helper method
; Increments d6 specifically. If greater than or equal to MAX_NOTES, then goes down to zero
nd_IncrementD6:
    add.l   #4, d6
    cmp.l   #nd_MAX_NOTES<<2, d6
    blt     nd_IncrementD6End
    clr.l   d6
nd_IncrementD6End
    rts

;    SIMHALT ; DELETE
;    END START ; DELETE







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
