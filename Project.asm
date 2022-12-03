.model small
.stack 100h
.data


; ----- Main menu variables

filename db '1MM.bmp', 0

filename_main_menu      db '1MM.bmp', 0
                        db '2MM.bmp', 0
                        db '3MM.bmp', 0
                        db '4MM.bmp', 0
                        db '5MM.bmp', 0

picCounter dw 0

eight db 8

handle_file dw ?

bmp_header db 54 dup (0) ; Contains 54 bytes of data

color_palette db 256*4 dup (0) ; Contains 256 bytes of color each value of color is 4 bytes 

Output_lines db 320 dup (0) ; Our Windows contains 320 rows 

error_prompt db 'Error', 13, 10,'$'


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

    call main_menu
    call game

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

showPic:
    call clear_screen

    ; show picture 

    ; Graphic mode
    mov ax, 13h
    int 10h

    ; Process BMP file
    mov dx, offset filename
    call Open_File
    call Get_Header
    call Get_Palette
    call Copy_Pallete
    call Copy_Bitmap_Img

    ; setting zero flag to 1
    mov ax, 1
    mov bx, 1
    cmp bx, ax

    ; waiting for a key press
    mov ah, 0
    int 16h

    ; if any key is not pressed
    jz keyPressed
   
    jmp showPic

keyPressed:

    ; if a key if pressed check which key is pressed

    ; if down key is pressed

    cmp ah, 50H

    jne checkUp ; if down key is not pressed check if up key is pressed

    ; else if down key is pressed

    ; increment the picCounter if it is not at high extreme i.e. 5

    cmp picCounter, 5

    jb nextPic ; change picture by changing the filename

    jmp showPic

    nextPic:

        ; ------ push the source string

        mov bx, offset filename_main_menu 
        
        mov ax, picCounter

        mul eight

        add bx, ax

        push bx

        ; ------ push the destination string

        mov bx, offset filename 
        push bx

        call copyString

        inc picCounter

    jmp showPic ; now show the picture     

    checkUp:

    ; if up key is pressed

    cmp ah, 48H

    jne showPic

    ; decrement the picCounter if it is not at low extreme i.e. 1

    cmp picCounter, 0

    ja prevPic ; change picture by changing the filename

    jmp showPic

    prevPic:

        dec picCounter

        ; ------ push the source string

        mov bx, offset filename_main_menu 
        
        mov ax, picCounter

        mul eight

        add bx, ax

        push bx

        ; ------ push the destination string

        mov bx, offset filename 
        push bx

        call copyString

    jmp showPic ; now show the picture

    call clear_screen
    ret                         

main_menu endp

;----------------------------------------------------

copyString proc
    
    pop si 

    pop bx ; destination

    pop di ; source

    mov cx, 8 ; length of source

    ; copies destination to source string
    ; uses indirect addressing

    L1: 
        mov al, [di]
        mov [bx], al

        inc bx
        inc di
    Loop L1

    push si
    ret

copyString endp

; ----------------------------------------------------

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

; ------------------------------------------

Open_File proc
    ; Open file
    mov ah, 3Dh
    xor al, al
    int 21h
    jc cant_open
    mov [handle_file], ax
    ret
    cant_open:
    mov dx, offset error_prompt
    mov ah, 9h
    int 21h
    ret
Open_File endp

Get_Header proc
    ; Read BMP file bmp_header, 54 bytes
    mov ah,3fh
    mov bx, [handle_file]
    mov cx,54
    mov dx,offset bmp_header
    int 21h
    ret
Get_Header endp

Get_Palette proc
    ; Read BMP file color color_palette, 256 colors * 4 bytes (400h)
    mov ah,3fh
    mov cx,400h
    mov dx,offset color_palette
    int 21h
    ret
Get_Palette endp

Copy_Pallete proc
    ; Copy the colors color_palette to the video memory
    ; The number of the first color should be sent to port 3C8h
    ; The color_palette is sent to port 3C9h
    
    mov si,offset color_palette
    mov cx,256
    mov dx,3C8h
    mov al,0

    ; Copy starting color to port 3C8h

    out dx,al

    ; Copy color_palette itself to port 3C9h

    inc dx
    Get_Pal:

    ; Note: Colors in a BMP file are saved as BGR values rather than RGB.

    mov al,[si+2] ; Get red value.
    shr al,1
    shr al,1     ; Max. is 255, but video color_palette maximal

    ; value is 63. Therefore dividing by 4.

    out dx,al ; Send it.
    mov al,[si+1] ; Get green value.
    shr al,1
    shr al,1    
    out dx,al ; Send it.
    mov al,[si] ; Get blue value.
    shr al,1
    shr al,1    
    out dx,al ; Send it.
    add si,4 ; Point to next color.

    ; (There is a null chr. after every color.)

    loop Get_Pal
    ret
 Copy_Pallete endp

 Copy_Bitmap_Img proc

    ; BMP graphics are saved upside-down.
    ; Read the graphic line by line (200 lines in VGA format),
    ; displaying the lines from bottom to top.

    mov ax, 0A000h
    mov es, ax
    mov cx,200
    PrintBMPLoop:
    push cx

    ; di = cx*320, point to the correct screen line

    mov di,cx
    shl cx,1
    shl cx,1
    shl cx,1
    shl cx,1
    shl cx,1
    shl cx,1

    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1
    shl di,1

    add di,cx

    ; Read one line

    mov ah,3fh
    mov cx,320
    mov dx,offset Output_lines
    int 21h

    ; Copy one line into video memory

    cld 

    ; Clear direction flag, for movsb

    mov cx,320
    mov si,offset Output_lines
    rep movsb 

    ; Copy line to the screen
    ;rep movsb is same as the following code:
    ;mov es:di, ds:si
    ;inc si
    ;inc di
    ;dec cx
    ;loop until cx=0

    pop cx
    loop PrintBMPLoop
    ret
 Copy_Bitmap_Img endp


end