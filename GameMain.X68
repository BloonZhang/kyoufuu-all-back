*-----------------------------------------------------------
* Title      : Jeffrey's Rhythm Game
* Written by : Jeffrey Zhang
* Date       : October 18, 2023
* Description: Rhythm game in assembly
*-----------------------------------------------------------
    ORG     $10
; EQU statements
; Used in NoteData
NOTE_BITMAP_WIDTH                   equ 40
NOTE_BITMAP_HEIGHT                  equ 39
; Used in ProjectileData
SLICE_BITMAP_WIDTH                  equ 27
SLICE_BITMAP_HEIGHT                 equ 39
; Default values, used in NoteData
nd_NoteStartingXPosition:           equ    620
nd_NoteStartingYPosition:           equ    320
nd_NoteStartingXVelocity:           equ    -18     ; Note to self: velocity does not affect delay before BGM starts playing. Change with care
nd_NoteStartingYVelocity:           equ    0
;Timing, used in NoteData
nd_CHOP_NOTE_POSITION   equ 243
nd_CHOP_NOTE_WINDOW     equ 51

; Used in NoteScheduler
SONG_OFFSET                         equ 99        ; delay in hundreths of a second before the first note spawns. Use to sync up the first note
SONG_BPM                            equ 135       ; 135 bpm = 0x87, multiplied by 2^8
                                                  ; 135 bpm. 1/135 minutes per beat. 60/135 sec per beat. 6000/135 hundreths sec per beat. 1500/135 hundreths sec per sixteenth beat. <<8 for 24/8 fixed point
HUNDRETHS_SECOND_PER_SIXTEENTH      equ ($005DC00/SONG_BPM) ; This is in 24/8 fixed point
NoteSchedule:                                       ; NoteSchedule holds the time of all the notes to spawn, in a visual format. 1 bit = 1 sixteenth note. 1 = spawn note                                                    
                                                    ; Note to grader: I made these comments in VSCode, I promise the code isn't corrupted.
    dc.b    %10000000,%00000000                     ; (外出た瞬間) 終わったわ
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 天気は良いのに　進めない
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 風　強すぎて　お亡くなり
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 定期　定期　的に オールバック
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🎵
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🎵
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🎵
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🎵
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 地下に潜りたいな
    dc.b    %10000000,%00000000,%10000000,%00000000 ; って　思いました
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 風さえなくなれば
    dc.b    %10000000,%00000000,%10000000,%00000000 ; あったかいのに
    dc.b    %10000000,%00000000,%10000000,%00000000 ; ずっと座りたいな
    dc.b    %10000000,%00000000,%10000000,%00000000 ; って　思いました
    dc.b    %10000000,%00000000,%10000000,%00000000 ; いやいや　と　外でたら
    dc.b    %10100000,%00000000,%00000000,%00001000 ; ハト　ハト　ハト　ハト　大乱闘 aaaa
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 外出た瞬間　終わったわ
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 天気は良いのに　進めない
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 風　強すぎて　お亡くなり
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 定期　定期　的にオールバック
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🍈    🍈
    dc.b    %10001000,%00000000,%00000000,%00001000 ; 🍈🍈🍈🍈🍈🍈🍈🍈
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🎵
    dc.b    %10000000,%00000000,%10000000,%00001000 ; 🎵 fweeee
    dc.b    %00000000,%00000000,%10000000,%00000000 ; 外出た瞬間　終わったわ
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 天気は良いのに　進めない
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 風　強すぎて　お亡くなり
    dc.b    %10000000,%00000000,%00000000,%00001000 ; 定期　定期　的にオールバック そっ
    dc.b    %10000000,%00000000,%10000000,%00000000 ; と出た瞬間　終わったわ
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 天気は良いのに　進めない
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 風　強すぎて　お亡くなり
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 定期　定期　的にオールバック
    dc.b    %10000000,%00000000,%00000000,%00001000 ; 髪の毛　強風オールバック 🍈
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🎵
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🎵
    dc.b    %10000000,%00000000,%10000000,%00000000 ; 🎵
    dc.b    %10000000,%00000000,%10000000,%00001000 ; 🎵🍈
EndOfNoteSchedule:                                ; Indicate end of NoteSchedule
    dc.b    0                                     ; byte padding so NoteSchedule doesn't bug out
    dc.l    0                                     ; long Padding just in case
    
; Used in FrameDelay
FRAME_RATE                          equ 20
TIME_BETWEEN_FRAMES_HUNDRETHS       equ 100/FRAME_RATE

    
; Used in GameMain
DRAWING_MODE_SETTINGS_TRAPCODE      equ 92
DOUBLE_BUFFER_ON                    equ 17
SWAP_TO_BUFFER_TRAPCODE             equ 94
AddressOfBitmapToDraw                               ; We will not always be drawing the default Bitmap background.
    dc.l    0                                       ; Stores the address of the bitmap we will be using. Changed by AnimationController.X68


; Include Modules
    ORG     $1000
; Subroutine: WindowResizeSubroutine
    ; Inputs:
    ; d0 = width of window
    ; d1 = height of window
    ; Return: None
    ; Volatile: None
; Subroutine: Preprocess Bitmap
    ; Goes through a bitmap and changes all pixel data to 00BBGGRR format.
    ; if the alpha channel is under some preset value, then instead converts to FF000000
    ; Inputs: a0 ptr to bitmap header
    ; Returns, Volatile: None
; Subroutine: BitmapSubroutine
    ; Inputs: 
    ; a0 = pointer to .bmp file in memory
    ; d0 = top left corner of bitmap chunk x
    ; d1 = top left corner of bitmap chunk y
    ; d2 = top left corner of output screen x
    ; d3 = top left corner of output screen y
    ; d4 = width of bitmap chunk
    ; d5 = height of bitmap chunk
    ; Returns, Volatile: None
; Subroutine: BitmapNoTransparencySubroutine
    ; Same at BitmapSubroutine, but assumes that none of the pixels are transparent
    ; Undefined behavior if the pixels have been preproceesed as transparent
    ; Inputs: Same as BitmapSubroutine
    ; Returns, Volatile: None
    INCLUDE 'Modules/DrawBitmap.X68'
    
; Subroutines: LoadSoundsSubroutine, PlayBGMSubroutine, PlaySFX#Subroutine, StopAllSoundsSubroutine
    ; All subroutines:
    ; Inputs: None
    ; Returns: None
    ; Volatile: None
    INCLUDE 'Modules/PlaySound.X68'

; Subroutine: UpdateNotesSubroutine 
    ; Updates the position of all notes
    ; Inputs, Returns, Volatile: None
; Subroutine: DrawNotesSubroutine
    ; Draws all the notes in storage
    ; Inputs:
    ;   a0 = address to note bitmap
    ; Returns, Volatile: None
; Subroutine: SaveNoteParametersSubroutine
    ; Saves all note locations to SaveBitmapParameterSubroutine
    ; Inputs, Returns, Volatile: None
; Subroutine: SpawnNoteSubroutine
    ; Spawns a note at the default spawn position with the default velocity
    ; Inputes, Returns, Volatile: None
; Subroutine: DespawnFirstNoteSubroutine
    ; Despawns the oldest note
    ; Inputs, Returns, Volatile: None
    INCLUDE 'Modules/NoteData.X68'

; Subroutine: UpdateProjectilesSubroutine
    ; Updates the velocity and position of all notes
    ; Inputes, Returns, Volatile: None
; Subroutine: DrawProjectilesSubroutine
    ; Draws all the projectils in storate
    ; Inputs:   a1 = address to Left slice BMP
    ;           a2 = address to Right slice BMP
    ; Returns, Volatile: None
; Subroutine: SaveProjParametersSubroutine
    ; Saves all projectile locations to SaveBitmapParameterSubroutine
    ; Inputs, Returns, Volatile: None
; Subroutine: SpawnProjectilesSubroutine
    ; Spawns two projectiles, one L and R
    ; Inputs, Returns, Volatile: None
; Subroutine: DespawnFirstProjSubroutine
    ; Despawns the oldest projectile
    ; Inputs, Returns, Volatile: None
; Subroutine: CheckFirstProjSubroutine
    ; Called every frame. checks if the first note has sunk too far
    ; Inputes, Returns, Volatile: None
    INCLUDE 'Modules/ProjectileData.X68'

; Subroutine: StartTimerSubroutine
    ; Starts NoteSchedule timer and sets NextBeatAtTime
    ; Inputs, Returns, Volatile: None
; Subroutine: CheckTimerSubroutine
    ; Checks timer. Resets timer and spawns a note if necessary
    ; Note: This subroutine is super unoptimized. Called once per frame, so optimize when have time
    ; NOTE: Buggy when the timer goes past midnight
    ; Inputs, returns, Volatile: None
    INCLUDE 'Modules/NoteScheduler.X68'

; Subroutine: SaveBitmapParameterSubroutine
    ; Saves the Xoffset, Yoffset, chunkW, and chunkH info for a bitmap
    ; Inputs:
    ; d2 = Xoffset and/or Xprintoffset (they should be equal)
    ; d3 = Yoffset and/or Yprintoffset
    ; d4 = chunkWidth
    ; d5 = chunkHeight
    ; Returns: None
    ; Volatile: None
; Subroutine: DrawSavedBitmapsSubroutine
    ; Draws all bitmaps based on the saved bitmap parameters
    ; Inputs:
    ; a0 = pointer to .bmp file in memory
    ; Outputs: None
    ; Volatile: None
    INCLUDE 'Modules/BitmapParameterSaver.X68'

; Subroutine: ReadPlayerInputSubroutine
    ; Checks if player pressed Space this frame
    ; Inputs: None
    ; Returns: Z flag = 0 if no, 1 if yes
    ; Volatile; None
    INCLUDE 'Modules/InputController.X68'
    
; Subroutine: SetupSevenSegmentSubroutine
    ; Draws all seven segments and sets them to 0
    ; Inputs, Returns, Volatile: None
;Subroutine: HitNoteScoreSubroutine
    ; Increments combo, then adds to score. Updates necessary 7 segments
    ; Inputs, Returns, Volatile: None
;Subroutine: MissNoteScoreSubroutine
    ; Reduces combo to 0. Updates necessary 7 segments, and erases the rest
    ; Inputs, Returns, Volatile: None
; Subroutine: DrawFPSSubroutine
    ; Draws the FPS using seven-segment displays
    ; Inputs:
    ; d5 = fps (in decimal)
    ; d1,d2 = x,y of top corner of display (LSB)
    INCLUDE 'Modules/ScoreManager.X68'

; Subroutine: StartFrameTimerSubroutine
    ; Starts the timer for the frame timer
    ; Inputs, Returns, Volatile: None
; Subroutine: DelayUntilNextFrameSubroutine
    ; Delays the game until the next frame should be rendered
    ; Also calculates the FPS
    ; Inputs, Returns, Volatile: None
    INCLUDE 'Modules/FrameDelay.X68'

; Subroutine: SwitchToUpFrameSubroutine
    ; Changes background to the up-frame bitmap
    ; Inputs, Returns, Volatile: None
; Subroutine: SwitchToDownFrameSubroutine
    ; Changes background to the down-frame bitmap
    ; Inputs, Returns, Volatile: None
; Subroutine: GetNextNoteBitmapSubroutine
    ; Gets the next bitmap for note animation
    ; Inputs: None
    ; Returns: bitmap in a0
    ; Volatile: a0
    INCLUDE 'Modules/AnimationController.X68'
    
; Subroutine: SeedRNGSubroutine
    ; Sets the seed for the RNG using current time
    ; Inputs, Returns, Volatile: None
; Subroutine: GetRandomBetweenSubroutine
    ; Gets a random number between two input numbers
    ; Inputs: d0 = lower bound
    ;         d1 = upper bound
    ; Returns: d7 = random number
    ; Volatile: d7
    INCLUDE 'Modules/RNG.X68'

    ORG    $10000
START:                  ; first instruction of program

Setup:
; Preprocess bitmaps
    lea     BackgroundBitmap, a0
    jsr     PreprocessBitmapSubroutine
    lea     BackgroundUp, a0
    jsr     PreprocessBitmapSubroutine
    lea     BackgroundDown, a0
    jsr     PreprocessBitmapSubroutine
    lea     SliceLBitmap, a0
    jsr     PreprocessBitmapSubroutine
    lea     SliceRBitmap, a0
    jsr     PreprocessBitmapSubroutine
    lea     NoteBitmap0, a0
    jsr     PreprocessBitmapSubroutine
    lea     NoteBitmap1, a0
    jsr     PreprocessBitmapSubroutine
    lea     NoteBitmap2, a0
    jsr     PreprocessBitmapSubroutine
    lea     NoteBitmap3, a0
    jsr     PreprocessBitmapSubroutine
    lea     NoteBitmap4, a0
    jsr     PreprocessBitmapSubroutine
    lea     NoteBitmap5, a0
    jsr     PreprocessBitmapSubroutine
    lea     NoteBitmap6, a0
    jsr     PreprocessBitmapSubroutine
    lea     NoteBitmap7, a0
    jsr     PreprocessBitmapSubroutine
    
; Load Sounds
    jsr     LoadSoundsSubroutine            ; Subroutine for setting up sounds in DirectX memory
    move.l  #640, d0                        ; Set parameters to resize window
    move.l  #480, d1
    jsr     WindowResizeSubroutine          
    
; Prepare RNG
    jsr     SeedRNGSubroutine
; test debugging
    move.l  #10, d0
    move.l  #25, d1
    jsr     GetRandomBetweenSubroutine
    
; Draw background
    clr.l   d0
    clr.l   d1
    clr.l   d2
    clr.l   d3
    move.l  #640, d4
    move.l  #480, d5
    lea     BackgroundBitmap, a0            ; a0 = backgroundbitmap
    move.l  a0, AddressOfBitmapToDraw
    jsr     BitmapNoTransparencySubroutine  ; print background bitmap
    jsr     SwitchToUpFrameSubroutine
    move.l  #DOUBLE_BUFFER_ON, d1           ; Turn on double buffering
    move.l  #DRAWING_MODE_SETTINGS_TRAPCODE, d0
    trap    #15                            ; commented out for debugging purposes
    
; Draw seven segment displays
    jsr     SetupSevenSegmentSubroutine

; Clear registers
    clr.l   d0
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    clr.l   d5
    clr.l   d6
    clr.l   d7
Play:
; Start the BGM
    jsr     PlayBGMSubroutine
; Start the timer
    jsr     StartTimerSubroutine
GameLoop:
; Start the timer for the frame rate
    jsr     StartFrameTimerSubroutine
    
; Spawn in notes based on the scheduler
    jsr     CheckTimerSubroutine
    
; Redraw background
    move.l  AddressOfBitmapToDraw, a0
    jsr     DrawSavedBitmapsSubroutine
    
; Physics updates
    jsr     UpdateNotesSubroutine
    jsr     UpdateProjectilesSubroutine
    jsr     CheckFirstProjSubroutine
    
; Save bitmap area that is about to be drawn over
    jsr     SaveNoteParametersSubroutine
    jsr     SaveProjParametersSubroutine
; Redraw notes
    ;lea     NoteBitmap, a0
    jsr     GetNextNoteBitmapSubroutine
    jsr     DrawNotesSubroutine
    lea     SliceLBitmap, a1
    lea     SliceRBitmap, a2
    jsr     DrawProjectilesSubroutine
    ; Swap buffers
    move.l  #SWAP_TO_BUFFER_TRAPCODE, d0
    trap    #15
    
; Check player input
    ; Returns: Z flag = 0 if no, 1 if yes. i.e. bne if no, beq if yes
    jsr     ReadPlayerInputSubroutine
    bne     SkipInput
    ; If player pressed space this frame
    jsr     PlaySFX1Subroutine
    jsr     CheckFirstNoteSubroutine    ; check if hit or miss, and update score accordingly
    ;jsr     SpawnProjectilesSubroutine   ; debugging purposes
    ;jsr     HitNoteScoreSubroutine  ; debugging purposes
    ;jsr     MissNoteScoreSubroutine ; debugging purposes
SkipInput:
    ; Swap buffers
    move.l  #SWAP_TO_BUFFER_TRAPCODE, d0
    trap    #15
    

    
GameLoopContinue:
; Delay for frame if necessary
    jsr     DelayUntilNextFrameSubroutine
; Repeat gameloop
    bra     GameLoop
GameLoopEnd:

    SIMHALT

BackgroundBase:
BackgroundBitmap:   INCBIN  'Art/Background.bmp'
NoteBitmap0:        INCBIN  'Art/Melon0.bmp'
NoteBitmap1:        INCBIN  'Art/Melon1.bmp'
NoteBitmap2:        INCBIN  'Art/Melon2.bmp'
NoteBitmap3:        INCBIN  'Art/Melon3.bmp'
NoteBitmap4:        INCBIN  'Art/Melon4.bmp'
NoteBitmap5:        INCBIN  'Art/Melon5.bmp'
NoteBitmap6:        INCBIN  'Art/Melon6.bmp'
NoteBitmap7:        INCBIN  'Art/Melon7.bmp'
SliceLBitmap:       INCBIN  'Art/Slice_L.bmp'
SliceRBitmap:       INCBIN  'Art/Slice_R.bmp'
; Used by AnimationController
BackgroundUp:       INCBIN  'Art/BackgroundUp.bmp'
BackgroundDown:     INCBIN  'Art/BackgroundDown.bmp'

    END    START

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
