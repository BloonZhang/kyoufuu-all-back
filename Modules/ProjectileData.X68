*;    ORG $100 ; DELETE

p_MAX_PROJECTILES               equ 16

p_DESPAWN_THRESHOLD             equ 480

; Default values
; Physics in 24/8 fixed point
p_PROJECTILE_L_SPAWN_X          equ (nd_CHOP_NOTE_POSITION-27)<<8
p_PROJECTILE_L_SPAWN_Y          equ (nd_NoteStartingYPosition)<<8
p_PROJECTILE_R_SPAWN_X          equ (nd_CHOP_NOTE_POSITION+27)<<8
p_PROJECTILE_R_SPAWN_Y          equ (nd_NoteStartingYPosition)<<8
p_PROJECTILE_MIN_HORZ_VELOCITY  equ $00000300
p_PROJECTILE_MAX_HORZ_VELOCITY  equ $00001000
p_PROJETILE_HORZ_VELOCITY_OFFSET    equ -$00001000  ; For the L slice
p_PROJECTILE_DEFAULT_Y_VELOCITY equ -$00001000
p_GRAVITY_ACCELERATION          equ $000004CC

; Position and Velocity treated in 24/8 fixed point
p_FirstProjectileCounter:    dc.l    0
p_NumberOfActiveProjectiles: dc.l    0
p_ProjectileXPositionQueue:
   dcb.l   p_MAX_PROJECTILES,0
p_ProjectileYPositionQueue:
   dcb.l   p_MAX_PROJECTILES,0
p_ProjectileXVelocityQueue:
   dcb.l   p_MAX_PROJECTILES,0
p_ProjectileYVelocityQueue:
    dcb.l   p_MAX_PROJECTILES,0
p_ProjectileLeftOrRight:    ; Stores whether the projectile is a left slice (0) or a right slice (FFFFFFFF)
    dcb.l   p_MAX_PROJECTILES,0
       
; Subroutine: UpdateProjectilesSubroutine
    ; Updates the velocity and position of all notes
    ; Inputes, Returns, Volatile: None
UpdateProjectilesSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If there are no projetiles, just return
    cmp.l   #0, p_NumberOfActiveProjectiles
    beq     UpdateProjectilesSubroutineEnd
    ; Go through all active projectiles, and increase their velocity and position
p_UpdateProjectilesLoopSetup:
    ; d5 = temp register for data movement
    ; d6 = firstProjCounter
    ; for (d7 = 0; d7 < nd_NumberOfActiveProjs; d7++)
    ;   update arrays[d6]
    ;   d6++. If d6 >= nd_MAX_NOTES, d6 = 0
    clr.l   d5
    move.l  p_FirstProjectileCounter, d6
    lsl.l   #2, d6
    clr.l   d7
    lea     p_ProjectileXPositionQueue, a0
    lea     p_ProjectileXVelocityQueue, a1
    lea     p_ProjectileYPositionQueue, a2
    lea     p_ProjectileYVelocityQueue, a3
p_UpdateProjectilesLoop:
    ; Update X position
    move.l  (0,a0,d6), d5
    add.l   (0,a1,d6), d5
    move.l  d5, (0,a0,d6)
    ; Update Y position
    move.l  (0,a2,d6), d5
    add.l   (0,a3,d6), d5
    move.l  d5, (0,a2,d6)
    ; Update Y velocity
    add.l   #p_GRAVITY_ACCELERATION, (0,a3,d6)
p_UpdateProjectilesLoopContinue:
    ; Increment d6. Reset to 0 if needed
    jsr     p_IncrementD6
    ; Increment d7 for the loop
    add.l   #1, d7
    cmp.l   p_NumberOfActiveProjectiles, d7
    blt     p_UpdateProjectilesLoop
p_UpdateProjectilesLoopEnd:
UpdateProjectilesSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts


; Subroutine: DrawProjectilesSubroutine
    ; Draws all the projectils in storate
    ; Inputs:   a1 = address to Left slice BMP
    ;           a2 = address to Right slice BMP
    ; Returns, Volatile: None
DrawProjectilesSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If there are no projetiles, just return
    cmp.l   #0, p_NumberOfActiveProjectiles
    beq     DrawProjectilesSubroutineEnd
p_DrawProjectilesLoopSetup:
    ; a0 = address to bitmap to draw. Either a1 or a2
    ; d6 = firstProjCounter
    ; for (d7 = 0; d7 < nd_NumberOfActiveProjs; d7++)
    ;   check if L or R
    ;   print corresponding bitmap
    ;   d6++. If d6 >= nd_MAX_NOTES, d6 = 0
    move.l  p_FirstProjectileCounter, d6
    lsl.l   #2, d6
    clr.l   d7
    lea     p_ProjectileXPositionQueue, a4
    lea     p_ProjectileYPositionQueue, a5
    lea     p_ProjectileLeftOrRight, a6
    ; Subroutine: BitmapSubroutine inputs: 
    move.l  #0, d0
    move.l  #0, d1
    move.l  #SLICE_BITMAP_WIDTH, d4
    move.l  #SLICE_BITMAP_HEIGHT, d5
p_DrawProjectilesLoop:
    ; get data required to print bitmap
    move.l  (0,a4,d6), d2
    lsr.l   #8, d2
    move.l  (0,a5,d6), d3
    lsr.l   #8, d3
    cmp.l   #0, (0,a6,d6) ; left slice (0) or right slice (FFFFFFFF)
    bne.b   p_SetA0ToRight
p_SetA0ToLeft:
    move.l  a1, a0
    bra     p_DrawProjectilesLoopContinue
p_SetA0ToRight:
    move.l  a2, a0
p_DrawProjectilesLoopContinue:
    ; Inputs ready to print
    jsr     BitmapSubroutine
    ; Increment d6. Reset to 0 if needed
    jsr     p_IncrementD6
    ; Increment d7 for the loop
    add.l   #1, d7
    cmp.l   p_NumberOfActiveProjectiles, d7
    blt     p_DrawProjectilesLoop
p_DrawProjectilesLoopEnd:
DrawProjectilesSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Subroutine: SaveProjParametersSubroutine
    ; Saves all projectile locations to SaveBitmapParameterSubroutine
    ; Inputs, Returns, Volatile: None
SaveProjParametersSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If there are no projetiles, just return
    cmp.l   #0, p_NumberOfActiveProjectiles
    beq     SaveProjParametersSubroutineEnd
p_SaveProjParametersLoopSetup:
    ; d6 = firstProjCounter
    ; for (d7 = 0; d7 < nd_NumberOfActiveProjs; d7++)
    ;   check if L or R
    ;   print corresponding bitmap
    ;   d6++. If d6 >= nd_MAX_NOTES, d6 = 0
    lea     p_ProjectileXPositionQueue, a0
    lea     p_ProjectileYPositionQueue, a2
    move.l  p_FirstProjectileCounter, d6
    lsl.l   #2, d6
    clr.l   d7
p_SaveProjParametersLoop:
    *; SaveBitmapParameterSubroutine inputs:
    *; d2 = Xoffset and/or Xprintoffset (they should be equal)
    *; d3 = Yoffset and/or Yprintoffset
    *; d4, d5 = chunkWidth, chunkHeight
    move.l  (0,a0,d6), d2
    lsr.l   #8, d2
    move.l  (0,a2,d6), d3
    lsr.l   #8, d3
    move.l  #SLICE_BITMAP_WIDTH, d4
    move.l  #SLICE_BITMAP_HEIGHT, d5
    jsr     SaveBitmapParameterSubroutine
    ; Increment d6. Reset to 0 if needed
    jsr     p_IncrementD6
    ; Increment d7 for the loop
    add.l   #1, d7
    cmp.l   p_NumberOfActiveProjectiles, d7
    blt     p_SaveProjParametersLoop
p_SaveProjParametersLoopEnd:
SaveProjParametersSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts


; Subroutine: SpawnProjectilesSubroutine
    ; Spawns two projectiles, one L and R
    ; Inputs, Returns, Volatile: None
SpawnProjectilesSubroutine:
    bsr     p_SpawnProjectileLSubroutine
    bsr     p_SpawnProjectileRSubroutine
SpawnProjectilesSubroutineEnd:
    rts


; Subroutine: DespawnFirstProjSubroutine
    ; Despawns the oldest projectile
    ; Inputs, Returns, Volatile: None
DespawnFirstProjSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; subtract number of active projectiles
    sub.l   #1, p_NumberOfActiveProjectiles
    ; Increment firstprojcounter, resetting if needed
    move.l  p_FirstProjectileCounter, d6
    lsl.l   #2, d6
    jsr     p_IncrementD6
    lsr.l   #2, d6
    move.l  d6, p_FirstProjectileCounter
DespawnFirstProjSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts


; Subroutine: CheckFirstProjSubroutine
    ; Called every frame. checks if the first note has sunk too far
    ; Inputes, Returns, Volatile: None
CheckFirstProjSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; If there are no projetiles, just return
    cmp.l   #0, p_NumberOfActiveProjectiles
    beq     CheckFirstProjSubroutineEnd
    ; Check y position of first note
    move.l  p_FirstProjectileCounter, d6
    lsl.l   #2, d6
    lea     p_ProjectileYPositionQueue, a4
    move.l  (0,a4,d6), d7
    lsr.l   #8, d7
    ; Check if too low
    cmp.l   #p_DESPAWN_THRESHOLD, d7
    blt.b   CheckFirstProjSubroutineEnd
    ; If too low, despawn
    jsr     DespawnFirstProjSubroutine
CheckFirstProjSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Private subroutines
; Spawns a left slice
p_SpawnProjectileLSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Increment number of actives projectiles
    add.l   #1, p_NumberOfActiveProjectiles
    ; d6 = firstprojcounter + numberofactiveprosj - 1
    move.l  p_FirstProjectileCounter, d6
    add.l   p_NumberOfActiveProjectiles, d6
    sub.l   #1, d6
    lsl.l   #2, d6
    ; Check that d6 isn't too large. If it is, d6 = d6 - maxprojs
    cmp.l   #p_MAX_PROJECTILES<<2, d6
    blt     p_SpawnProjLCreateNewData
    sub.l   #p_MAX_PROJECTILES<<2, d6
p_SpawnProjLCreateNewData:
    ; set the default values to position and velocities
    ; Left slice
    lea     p_ProjectileXPositionQueue, a0
    lea     p_ProjectileXVelocityQueue, a1
    lea     p_ProjectileYPositionQueue, a2
    lea     p_ProjectileYVelocityQueue, a3  
    lea     p_ProjectileLeftOrRight, a4
    move.l  #p_PROJECTILE_L_SPAWN_X , (0,a0,d6)
    move.l  #p_PROJECTILE_L_SPAWN_Y, (0,a2,d6)
    ; Random number for XVelocity
    move.l  #p_PROJECTILE_MIN_HORZ_VELOCITY, d0
    move.l  #p_PROJECTILE_MAX_HORZ_VELOCITY, d1
    jsr     GetRandomBetweenSubroutine
    add.l   #p_PROJETILE_HORZ_VELOCITY_OFFSET, d7
    move.l  d7, (0,a1,d6)
    move.l  #p_PROJECTILE_DEFAULT_Y_VELOCITY, (0,a3,d6)
    move.l  #0, (0,a4,d6) ; To indicate left slice
p_SpawnProjectileLSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts

; Spawns a right slice
p_SpawnProjectileRSubroutine:
    movem.l d0-d7/a0-a6, -(sp)
    ; Increment number of actives projectiles
    add.l   #1, p_NumberOfActiveProjectiles
    ; d6 = firstprojcounter + numberofactiveprosj - 1
    move.l  p_FirstProjectileCounter, d6
    add.l   p_NumberOfActiveProjectiles, d6
    sub.l   #1, d6
    lsl.l   #2, d6
    ; Check that d6 isn't too large. If it is, d6 = d6 - maxprojs
    cmp.l   #p_MAX_PROJECTILES<<2, d6
    blt     p_SpawnProjRCreateNewData
    sub.l   #p_MAX_PROJECTILES<<2, d6
p_SpawnProjRCreateNewData:
    ; set the default values to position and velocities
    ; TODO: randomize
    ; Right slice
    lea     p_ProjectileXPositionQueue, a0
    lea     p_ProjectileXVelocityQueue, a1
    lea     p_ProjectileYPositionQueue, a2
    lea     p_ProjectileYVelocityQueue, a3  
    lea     p_ProjectileLeftOrRight, a4
    move.l  #p_PROJECTILE_R_SPAWN_X , (0,a0,d6)
    move.l  #p_PROJECTILE_R_SPAWN_Y, (0,a2,d6)
    ; Random number for XVelocity
    move.l  #p_PROJECTILE_MIN_HORZ_VELOCITY, d0
    move.l  #p_PROJECTILE_MAX_HORZ_VELOCITY, d1
    jsr     GetRandomBetweenSubroutine
    move.l  d7, (0,a1,d6)
    move.l  #p_PROJECTILE_DEFAULT_Y_VELOCITY, (0,a3,d6)
    move.l  #$FFFFFFFF, (0,a4,d6) ; To indicate right slice
p_SpawnProjectileRSubroutineEnd:
    movem.l (sp)+, d0-d7/a0-a6
    rts



; Helper method
; Increments d6 specifically. If greater than or equal to MAX_PROJECTILES, then goes down to zero
p_IncrementD6:
   add.l   #4, d6
   cmp.l   #p_MAX_PROJECTILES<<2, d6
   blt     nd_IncrementD6End
   clr.l   d6
p_IncrementD6End
   rts





**~Font name~Courier New~
**~Font size~10~
**~Tab type~1~
**~Tab size~4~
