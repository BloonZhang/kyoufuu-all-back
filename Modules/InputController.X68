ic_KEYCODE_SPACEBAR                    equ $20
ic_GET_INPUT_TRAPCODE                  equ 19
ic_InputHeldDown:                                    ; essentially bool InputHeldDown = false
    dc.b    0
    dc.l    0                                     ; long Padding just in case
    
; Subroutine: ReadPlayerInputSubroutine
    ; Checks if player pressed Space this frame
    ; Inputs: None
    ; Returns: Z flag = 0 if no, 1 if yes
    ; Volatile; None
ReadPlayerInputSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Check if spacebar is held down
    move.l  #ic_GET_INPUT_TRAPCODE, d0
    move.l  #ic_KEYCODE_SPACEBAR, d1
    trap    #15
    andi.l  #$FF, d1    ; d1 = 0 if no spacebar. d1 = FF if yes spacebar
    beq.b   ic_SpaceIsUp
    ;bra     ic_SpawnIsDown
; If space bar is down
ic_SpaceIsDown:
    ; If Spacebar is held down, check if it wasn't previously held down
    cmp.b   #0, ic_InputHeldDown
    bne.b   ReadPlayerInputReturnFalse
ic_SpaceDownThisFrame:
    ; At this point, spacebar was pressed this frame
    move.b  #1, ic_InputHeldDown
    jsr     SwitchToDownFrameSubroutine
    bra     ReadPlayerInputReturnTrue
; If space bar is up
ic_SpaceIsUp:
    ; If the spacebar is up, check if it was previously held down
    cmp.b   #1, ic_InputHeldDown
    bne.b   ReadPlayerInputReturnFalse
ic_SpaceIsUpThisFrame:
    ; At this point, spacebar was released this frame
    move.b  #0, ic_InputHeldDown
    jsr     SwitchToUpFrameSubroutine
    ;bra     ReadPlayerInputReturnFalse
; Return False
ReadPlayerInputReturnFalse:
    move.l  #1, d0  ; To set Z = 0
    movem.l (sp)+, d0-d7/a0-a6
    rts
; Return True
ReadPlayerInputReturnTrue:
    move.l  #0, d0  ; To set Z = 1
    movem.l (sp)+, d0-d7/a0-a6
    rts     

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
