LOAD_SOUND_DIRECTX_TRAP     EQU 74
PLAY_SOUND_DIRECTX_TRAP     EQU 75
STOP_SOUND_DIRECTX_TRAP     EQU 77

BGM_INDEX                   EQU 0
SFX1_INDEX                  EQU 1

; Note: filepaths are relative to Main file
; background music
pl_BGM:     dc.b    'Audio/BGM.wav', 0
; sfx1: clap/snare
pl_SFX1:    dc.b    'Audio/SFX1.wav', 0

pl_padding: dc.l    0

; LoadSoundsSubroutine:
; Inputs: None
; Returns: None
; Volatile: None
LoadSoundsSubroutine:
    movem.l d0-d1, -(sp)
    
    ; Load BGM
    lea     pl_BGM, a1
    move.l  #BGM_INDEX, d1  ; d1 = index
    move.l  #LOAD_SOUND_DIRECTX_TRAP, d0
    trap    #15

    ; Load SFX1
    lea     pl_SFX1, a1
    move.l  #SFX1_INDEX, d1  ; d1 = index
    move.l  #LOAD_SOUND_DIRECTX_TRAP, d0
    trap    #15
LoadSoundsSubroutineEnd:
    ; return
    movem.l (sp)+, d0-d1
    rts


; PlayBGMSubroutine:
; Inputs: None
; Returns: None
; Volatile: None
PlayBGMSubroutine:
    ; protect variables
    movem.l d0-d2, -(sp)
    ; Select index for BGM
    move.l  #BGM_INDEX, d1
    ; TODO: use task #77 for looping?
    ; Play BGM
    move.l  #PLAY_SOUND_DIRECTX_TRAP, d0
    trap    #15
PlayBGMSubroutineEnd:
    ; return
    movem.l (sp)+, d0-d2
    rts


; PlaySFX#Subroutine:
; Inputs: None
; Returns: None
; Volatile: None
PlaySFX1Subroutine:
    ; protect variables
    movem.l d0-d2, -(sp)
    ; Select index for BGM
    move.l  #SFX1_INDEX, d1
    ; TODO: use task #77 for looping?
    ; Play BGM
    move.l  #PLAY_SOUND_DIRECTX_TRAP, d0
    trap    #15
PlaySFX1SubroutineEnd:
    ; return
    movem.l (sp)+, d0-d2
    rts
    

; StopAllSoundsSubroutine:
; Inputs: None
; Returns: None
; Volatile: None
StopAllSoundsSubroutine:
    ; protect variables
    movem.l d0-d2, -(sp)
    ; stop sounds using control directx trap
    move.l  #3, d2
    move.l  #STOP_SOUND_DIRECTX_TRAP, d0
    trap    #15
StopAllSoundsSubroutineEnd:
    ; return
    movem.l (sp)+, d0-d2
    rts
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
