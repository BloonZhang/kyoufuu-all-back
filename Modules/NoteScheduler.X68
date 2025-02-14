ns_GET_TIME_TRAPCODE           equ 8
ns_TOTAL_SUBBEATS              equ ((EndOfNoteschedule-NoteSchedule)<<3)-1      ; -1 because CurrentSubBeat is 0-indexed

ns_StartTime:       ; 24/8. TODO: I don't think this variable is used
    dc.l    0
;ns_CurrentTime:
;    dc.l    0
ns_CurrentSubBeat:
    dc.l    -1
ns_NextBeatAtTime:  ; 24/8
    dc.l    0

; Subroutine: StartTimerSubroutine
    ; Starts NoteSchedule timer and sets NextBeatAtTime
    ; Inputs, Returns, Volatile: None
StartTimerSubroutine:
    move.l  d0, -(sp)
    move.l  d1, -(sp)
    ; Trap #15 task 8: Returns time in hundreths of a second since midnight in D1.L. Convert to 24/8
    move.l  #ns_GET_TIME_TRAPCODE, d0
    trap    #15
    lsl.l   #8, d1
    ; Place in StartTime, which is 24/8
    move.l  d1, ns_StartTime
    ; Place next beat in NextBeatAtTime, which is 24/8.
    ; Add the song offset as well
    add.l   #HUNDRETHS_SECOND_PER_SIXTEENTH, d1
    add.l   #SONG_OFFSET<<8, d1
    move.l  d1, ns_NextBeatAtTime
StartTimerSubroutineEnd:
    move.l  (sp)+, d1
    move.l  (sp)+, d0
    rts
    
; Subroutine: CheckTimerSubroutine
    ; Checks timer. Resets timer and spawns a note if necessary
    ; Note: This subroutine is super unoptimized. Called once per frame, so optimize when have time
    ; NOTE: Buggy when the timer goes past midnight
    ; Inputs, returns, Volatile: None
CheckTimerSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If we're out of notes, then return
    cmp.l   #ns_TOTAL_SUBBEATS, ns_CurrentSubBeat
    bge     CheckTimerSubroutineEnd
    ; Trap #15 task 8: Returns time in hundreths of a second since midnight in D1.L. Convert to 24/8
    move.l  #ns_GET_TIME_TRAPCODE, d0
    trap    #15
    lsl.l   #8, d1
    ; Check if timer has passed NextBeatAtTime, which is 24/8
    cmp.l   ns_NextBeatAtTime, d1
    blo     CheckTimerSubroutineEnd
ns_CheckTimerIncrementBeat:
    ; If we're here, that means we moved onto the next sixteenth beat
    add.l   #1, ns_CurrentSubBeat
    ; Also, go ahead and increment the timer.
    add.l   #HUNDRETHS_SECOND_PER_SIXTEENTH, ns_NextBeatAtTime
    ; Check the corresponding bit of NoteSchedule
    ; Remember, the subbeats are represented by bits, not bytes. Every byte therefore has 8 subbeats
    ; TODO: is it actually faster to represent them as bytes?
    ; First, get the corresponding noteschedule byte
    lea     NoteSchedule, a0
    move.l  ns_CurrentSubBeat, d0
    lsr.l   #3, d0              ; there are 8 subbeats in a beat. divide by 8
    move.b  (0,a0,d0), d7
    ; Then, check the specific bit of that noteschedule byte
    ; The specific bit is the 7 - (remainder(currentSubBeat / 8))
    move.l  ns_CurrentSubBeat, d0
    and.l   #%00000000000000000000000000000111, d0
    move.l  #7, d1
    sub.l   d0, d1
    btst    d1, d7  ; Tests the corresponding bit of d7. If it is 0, then beq and skip spawning note
    
    ;move.l  ns_CurrentSubBeat, d0
    ;move.l  (ns_CurrentSubBeat)>>3, d0
    ;move.l  (ns_CurrentSubBeat>>3,a0), d7       ; Note to self: I hate these two lines of code
    ;move.l  #ns_CurrentSubBeat&%00000111, d1
    ;btst    #ns_CurrentSubBeat&%00000111, d7    ; Check if they actually work
    beq     CheckTimersubroutineEnd
ns_CheckTimerSpawnBeat:
    ; If we're here, that means we needed to spawn a beat
    jsr     SpawnNoteSubroutine
CheckTimerSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
