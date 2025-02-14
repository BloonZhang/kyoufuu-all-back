rng_RANDOMVAL       ds.l    1
rng_TEMPRANDOMLONG  ds.l    1


; Subroutine: SeedRNGSubroutine
    ; Sets the seed for the RNG using current time
    ; Inputs, Returns, Volatile: None
SeedRNGSubroutine:
    movem.l d0-d7/a0-a6,-(sp)
    ; use time as a seed
    move.l  #8,d0 
    TRAP    #15
    move.l  d1,rng_RANDOMVAL
SeedRNGSubroutineEnd:
    movem.l (sp)+,d0-d7/a0-a6
    rts

; Subroutine: GetRandomBetweenSubroutine
    ; Gets a random number between two input numbers
    ; Inputs: d0 = lower bound
    ;         d1 = upper bound
    ; Returns: d7 = random number
    ; Volatile: d7
GetRandomBetweenSubroutine:
    movem.l d0-d6/a0-a6,-(sp)
    ; Get current random value into d3
    move.l  rng_RANDOMVAL, d3
    ; Perform some random operations
    ; Random mask in d4
    ; Number of loops into d5
    move.l  #%00101111001011110010111100101111, d4
    move.l  #18, d5
rng_Ninc0:
    add.l   d3, d3
    bcc.b   rng_Ninc1
    eor.l   d4, d3
rng_Ninc1:
    dbf     d5, rng_Ninc0
    ; At this point, d3 has a random number
    move.l  d3, rng_RANDOMVAL
    ; First bring d3 down to a smaller number
    lsr.l   #8, d3
    lsr.l   #8, d3
    ; Modulate it by the different between d1 and d0
    sub.l   d0, d1
    divu.w  d1, d3
    clr.w   d3  ; clear the quotient, we don't care about it
    swap    d3  ; swap into the remainder
    ; Add the lower bound
    add.l   d0, d3
    ; Move into d7 for return
    move.w  d3, d7
GetRandomBetweenSubroutineEnd:
    movem.l (sp)+,d0-d6/a0-a6
    rts