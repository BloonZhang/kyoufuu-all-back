fd_GET_TIME_TRAPCODE            equ 8
fd_DELAY_TRAPCODE               equ 23

fd_FPS_COUNTER_TOP_LEFT_X       equ 40
fd_FPS_COUNTER_TOP_LEFT_Y       equ 10

fd_StartTimeOfThisFrame     ; When this frame started
    dc.l    0
fd_PauseUntil   ; Stores time until next frame should be played
    dc.l    0
fd_FPSOfThisFrame   ; the FPS of last frame
    dc.l    0

; Subroutine: StartFrameTimerSubroutine
    ; Starts the timer for the frame timer
    ; Inputs, Returns, Volatile: None
StartFrameTimerSubroutine:
    movem.l d0-d1, -(sp)
    ; Get current time into d1
    move.l  #fd_GET_TIME_TRAPCODE, d0
    trap    #15
    move.l  d1, fd_StartTimeOfThisFrame
    add.l   #TIME_BETWEEN_FRAMES_HUNDRETHS, d1
    move.l  d1, fd_PauseUntil
StartFrameTimerSubroutineEnd:
    movem.l (sp)+, d0-d1
    rts

; Subroutine: DelayUntilNextFrameSubroutine
    ; Delays the game until the next frame should be rendered
    ; Also calculates the FPS
    ; Inputs, Returns, Volatile: None
DelayUntilNextFrameSubroutine:
    movem.l d0-d1, -(sp)
    ; Get current time into d1
    move.l  #fd_GET_TIME_TRAPCODE, d0
    trap    #15
    ; Check amount of time to delay
    sub.l   fd_PauseUntil, d1
    ; If currentTime - fd_PauseUntil >=0 , then we can continue the game
    bgt.b   fd_DelayUntilNextFrameCalculate
    ; Otherwise, delay by how long until PauseUntil
    neg.l   d1
    move.l  #fd_DELAY_TRAPCODE, d0
    trap    #15
fd_DelayUntilNextFrameCalculate:
    ; Get current time into d1 again
    move.l  #fd_GET_TIME_TRAPCODE, d0
    trap    #15
    ; frame rate is 100 / (CurrentTime-fd_StartTimeOfThisFrame)
    ; Watch out for divide by zero errors LOL
    sub.l   fd_StartTimeOfThisFrame, d1
    beq.b   DelayUntilNextFrameSubroutineEnd
    move.l  #100, d2
    divu    d1, d2
    and.l   #$0000FFFF, d2
    ; Set up inputs for subroutine call
    move.l  d2, d5
    move.l  #fd_FPS_COUNTER_TOP_LEFT_X, d1
    move.l  #fd_FPS_COUNTER_TOP_LEFT_Y, d2
    jsr     DrawFPSSubroutine
DelayUntilNextFrameSubroutineEnd:
    movem.l (sp)+, d0-d1
    rts

*DelayUntilNextFrameError:
*    ; print out the word lag
*    move.l  #0, d0
*    lea     fd_LagString, a1
*    trap    #15
*    movem.l (sp)+, d0-d1
*    rts
*fd_LagString: dc.b 'l', 0
*              dc.l 0
