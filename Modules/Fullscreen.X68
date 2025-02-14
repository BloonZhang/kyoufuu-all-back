; these are from one of my includes, but dropping here for convenience
TASK_GETINPUTS          EQU     19      ; d1 in - $K1K2K3K4 (key codes), d1 out - $B1B2B3B4 (bools)
TASK_WINDOWSIZE         EQU     33      ; d1.l high - width, d1.l low - height, d1 = 0 (get), 1 (window), 2 (full screen)
WINDOWSIZE_WINDOW       EQU     1
WINDOWSIZE_FULL         EQU     2
*-----
* checkFullScreen
*-----
isDown  dc.b    0
isFull  dc.b    0
checkFullScreen:
        moveq   #TASK_GETINPUTS,d0
        moveq   #'F',d1
        trap    #15
        move.b  isDown,d2
        move.b  d1,isDown
        btst    #0,d2         ; was F previously pressed?
        beq     .done
        btst    #0,d1         ; has it been released?
        bne     .done      
       
.switch
        btst    #0,isFull     ; do the switch
        bne     .goWindow
.goFull
        moveq   #TASK_WINDOWSIZE,d0
        moveq   #WINDOWSIZE_FULL,d1
        trap    #15
        bra     .toggle
.goWindow       
        moveq   #TASK_WINDOWSIZE,d0
        moveq   #WINDOWSIZE_WINDOW,d1
        trap    #15
.toggle
        eor.b   #1,isFull      ; flip boolean to match screen mode
.done
        rts