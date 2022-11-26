.model small
.stack 100h
.data


; ----- Main menu variables

text_main_menu db "BRICK BREAKER GAME", '$'
text_new_game db "NEW GAME", '$'
text_resume_game db "RESUME GAME", '$'
text_instructions db "INSTRUCTIONS", '$'
text_highscore db "HIGH SCORE", '$'
text_exit db "EXIT", '$'



;----------bar's variables
barInitX dw 130
barInitY dw 190

barWidth = 5
barLength = 60
barSpeed = 10
;----------ball's variables
ballInitX dw 50
ballInitY dw 50
ballSpeedX dw 5
ballSpeedY dw 5
timeVar db 0

windowsWidth = 200
windowsLength = 320

ballSize = 5

.code
;------------- MACROs
    makeBall MACRO
        mov al, 0fh; white colour ball
        call drawBall
    ENDM

    clearBall MACRO
        mov al, 00h; black colour ball
        call drawBall
    ENDM

    makeBar MACRO
        mov al, 0fh; white colour bar
        call drawBar
    ENDM

    clearBar MACRO
        mov al, 00h; black colour bar
        call drawBar
    ENDM

;------- Attaching the data segment
mov ax, @data
mov ds, ax
mov ax, 0

;---------- Main Procedure
main proc
    mov ah, 0;  setting video mode
    mov al, 13h
    int 10h

    ;call game
    call main_menu

mov ah, 4ch
int 21h
main endp
;---------------------------------------------------------------------------------------------
game PROC uses ax bx

timeLoop:
    mov ah, 2ch ;getting the time
    int 21h
    
    ;if 1/100 sec hasnt passed, repeat loop
    cmp dl, timeVar
    je timeLoop
    
    ;moving the ball
    clearBall
    call moveBall
    makeBall
    
    ;moving the bar
    clearBar
    call moveBar
    makeBar
    
    ;Now that 1/100 sec has passed, store the sec in time var and repeat the loop again
    mov timeVar, dl
    jmp timeLoop
    
ret
game endp
;---------------------------------------------------------------------------------------------
moveBar PROC uses ax bx cx dx
moveBar_Loop:

    mov ah, 01;taking input
    int 16h
    jz moveBarExit

    mov ah, 00;taking input
    int 16h
    cmp ah, 4Bh; left key
    je leftKey
    cmp ah, 4Dh; right key
    je rightKey

    leftKey:
        ;boundaryCheckLeft
        cmp barInitX, 0
        jle moveBar_Loop
        sub barInitX, barSpeed
    jmp moveBar_Loop

    rightKey:
        ;boundaryCheckRight
        mov ax, barInitX
        add ax, barLength
        cmp ax, windowsLength
        jge moveBar_Loop
        add barInitX, barSpeed
    jmp moveBar_Loop
    
    moveBarExit:
ret
moveBar endp
;---------------------------------------------------------------------------------------------
drawBar proc uses ax bx cx dx si di
mov cx, barInitX ;inital x
mov dx, barInitY ;inital y
mov bh, 0; page number

mov si, barWidth

barLoop:
    mov di, barLength
    mov cx, barInitX
    barNestedLoop:
        call drawPixel
        inc cx
        
    dec di
    cmp di, 0
    jne barNestedLoop
    
    inc dx
dec si
cmp si, 0
jne barLoop
ret
drawBar endp

;---------------------------------------------------------------------------------------------
drawPixel PROC
    mov ah, 0ch
    int 10h
ret
drawPixel endp
;---------------------------------------------------------------------------------------------
moveBall PROC uses ax 
    
    ;moving the ball in x-axis
    mov ax, ballSpeedX
    add ballInitX, ax
    
    ;if hit the left wall
    cmp ballInitX, 0
    jle reverseSpeedX
    
    ;if hit the right wall
    mov ax, ballInitX
    add ax, ballSize
    cmp ax, windowsLength
    jge reverseSpeedX
    
    ;moving the ball in y-axis
    mov ax, ballSpeedY
    add ballInitY, ax
    
    ;if hit the upper wall
    cmp ballInitY, 0
    jle reverseSpeedY
    
    ;if hit the lower wall
    mov ax, ballInitY
    add ax, ballSize
    cmp ax, windowsWidth
    jge reverseSpeedY
    
    ;checking ball's collision with bar
    mov ax, ballInitY
    add ax, ballSize
    cmp ax, barInitY
    jl moveBallExit 
    
    ;barX >= x && x <= barX+length
    mov ax, ballInitX
    cmp ax, barInitX
    jl moveBallExit
    
    add ax, ballSize
    mov bx, barInitX
    add bx, barLength
    cmp ax, bx
    jl reverseSpeedY
    
    moveBallExit:
    ret 
    reverseSpeedY:
    neg ballSpeedY
    ret
    
    reverseSpeedX:
    neg ballSpeedX
    ret
    
moveBall endp
;---------------------------------------------------------------------------------------------
drawBall proc uses ax bx cx dx si di
    mov cx, ballInitX ;inital x
    mov dx, ballInitY ;inital y
    mov bh, 0; page number

    mov si, ballSize

    ballLoop:
        mov di, ballSize
        mov cx, ballInitX
        ballNestedLoop:
            call drawPixel
            inc cx
            
        dec di
        cmp di, 0
        jne ballNestedLoop
        
        inc dx
    dec si
    cmp si, 0
    jne ballLoop
ret
drawBall endp

;----------------------------------------------------
main_menu proc

    call clear_screen

    ; show the brick breaker game title

    mov ah,02h       ;cursor position
    mov bh,00h       ;page number
    mov dh,04h       ;row 
    mov dl,04h       ;column
    int 10h                          
        
    mov ah,09h                       
    mov dx, offset text_main_menu      
    int 21h                          

main_menu endp

;----------------------------------------------------

clear_screen proc

    mov ah,0      ;video mode
    mov al,13h    ; 320x200 pixels mode
    int 10h
        
    mov ah,0Bh    ; background color function
    mov bh,0
    mov bl,0      ;black background
    int 10h                  
            
    ret
clear_screen endp


end