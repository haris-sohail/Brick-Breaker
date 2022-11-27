.model small
.stack 100h
.data

;----------bar's variables
BarStruct struct
	CoordX dw 130
	CoordY dw 190
BarStruct ends
;bar variable
bar BarStruct 1 dup(<>)
;constants
barWidth = 5
barLength = 60
barSpeed = 5
;----------ball's variables
BallStruct struct
	CoordX dw 50
	CoordY dw 50
	SpeedX dw 5
	SpeedY dw 5
BallStruct ends
;ball variable
ball BallStruct 1 dup(<>)
;constants
ballSize = 5
;----------- bricks
NumberOfBricks = 20
BrickStruct struct
	CoordX dw 0
	CoordY dw 0
BrickStruct ends
brickWidth = 20
brickGap equ <10> 
brickLength = 40
brickLoopVar dw 20

brick BrickStruct    <40,20>, <80+brickGap,20>, <130+brickGap,20>, <180+brickGap,20>, <230+brickGap,20>, 
	<40,40+brickGap>, <80+brickGap,40+brickGap>, <130+brickGap,40+brickGap>, <180+brickGap,40+brickGap>, <230+brickGap,40+brickGap>,
	<40,70+brickGap>, <80+brickGap,70+brickGap>, <130+brickGap,70+brickGap>, <180+brickGap,70+brickGap>, <230+brickGap,70+brickGap>
;------------ player
PlayerStruct struct
	Score dw 0
	Lives dw 3
	igName db 30 dup(0)
PlayerStruct ends
;player variable
player PlayerStruct <>

;------------ misc vars
scoreStr db "Score: ",'$'
nameStr_1 db "Player Name: ", '$'
nameStr_2 db "Name: ",'$'
timeVar db 0
windowsWidth = 200
windowsLength = 320
count dw 0



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
	
	setVideoMode MACRO
		mov ah, 0;	setting video mode
		mov al, 13h
		int 10h
	ENDM
	
	clearBrick MACRO si
		
		mov bh, 0; page number
		mov al, 0
		
		mov cx, brick[si].CoordX ;inital x
		mov dx, brick[si].CoordY ;inital y
		mov brickLoopVar, 20
		clearBrickLoop_2:
			mov di, brickLength
			mov cx, brick[si].CoordX
			clearBrickLoop_3:
				call drawPixel
				inc cx
					
			dec di
			cmp di, 0
			jne clearBrickLoop_3
			
			inc dx
		dec brickLoopVar
		cmp brickLoopVar, 0
		jne clearBrickLoop_2

	ENDM

;------- Attaching the data segment
mov ax, @data
mov ds, ax
mov ax, 0

;---------- Main Procedure
main proc
	
	setVideoMode
	
	call inputName
	call drawBrick
	
	call game

mov ah, 4ch
int 21h
main endp

;---------------------------------------------------------------------------------------------
drawBrick proc uses ax bx cx dx si di
	mov bh, 0; page number
	mov si, 0
	mov al, 1
brickLoop_1:
		mov cx, brick[si].CoordX ;inital x
		mov dx, brick[si].CoordY ;inital y
		mov brickLoopVar, 20
		brickLoop_2:
			mov di, brickLength
			mov cx, brick[si].CoordX
			brickLoop_3:
				call drawPixel
				inc cx
				
			dec di
			cmp di, 0
			jne brickLoop_3
			
			inc dx
		dec brickLoopVar
		cmp brickLoopVar, 0
		jne brickLoop_2

inc al
add si, type BrickStruct
cmp si, 60
jb brickLoop_1
ret
drawBrick ENDP

;---------------------------------------------------------------------------------------------
game PROC uses ax bx

timeLoop:
	mov ah, 2ch	;getting the time
	int 21h
	
	;if 1/100 second hasnt passed, repeat loop
	cmp dl, timeVar
	je timeLoop
	
	;displaying the score
	call displayStats
	
	;moving the ball
	clearBall
	call moveBall
	makeBall
	
	;check collision with brick
	call brickCollision
	
	;moving the bar
	clearBar
	call moveBar
	makeBar
	
	;Now that 1/100 sec has passed, store the prev second in time var and repeat the loop again
	mov timeVar, dl
	jmp timeLoop
	
ret
game endp
;----------- 
inputName proc uses ax bx cx dx

	;setting the cursor position
	mov ah, 02h
	mov bh, 0
	mov dh, 12
	mov dl, 8
	int 10h
	
	mov dx, offset nameStr_1
	mov ah, 09h
	int 21h

	mov ah, 03fh ;string input function
	mov bx, 0; keyboard handle 
	mov cx, 30 ; max bytes to read
	mov dx, offset player.igName
	int 21h ;(****character count is stored in ax****)
	
	;putting a dollar sign at the end
	mov si, 0
inputLoop:
	inc si
	cmp player.igName[si], 10
jne inputLoop
	dec si
	mov player.igName[si], '$'
	;mov bx, ax 
	;mov player.igName[bx], '$'
	
	setVideoMode
	
	
ret
inputName endp
;--------------------------
displayStats proc uses ax bx dx
;----------------	Score
	;setting the cursor position
	mov ah, 02h
	mov bh, 0
	mov dh, 1
	mov dl, 1
	int 10h
	
	mov dx, offset scoreStr
	mov ah, 09h
	int 21h
	
	;updating the cursor position for numeric value of score
	mov ah, 02h
	mov bh, 0
	mov dh, 1
	mov dl, 8
	int 10h
	call displayScore
	
;------------ Player Name

	mov ah, 02h
	mov bh, 0
	mov dh, 1
	mov dl, 25
	int 10h
	
	mov dx, offset nameStr_2
	mov ah, 09h
	int 21h
	
	mov ah, 02h
	mov bh, 0
	mov dh, 1
	mov dl, 30
	int 10h
	
	mov dx, offset player.igName
	mov ah, 09h
	int 21h
	
ret
displayStats endp
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
		cmp bar.CoordX, 0
		jle moveBar_Loop
		sub bar.CoordX, barSpeed
	jmp moveBar_Loop

	rightKey:
		;boundaryCheckRight
		mov ax, bar.CoordX
		add ax, barLength
		cmp ax, windowsLength
		jge moveBar_Loop
		add bar.CoordX, barSpeed
	jmp moveBar_Loop
	
	moveBarExit:
ret
moveBar endp
;---------------------------------------------------------------------------------------------
drawBar proc uses ax bx cx dx si di
mov cx, bar.CoordX ;inital x
mov dx, bar.CoordY ;inital y
mov bh, 0; page number

mov si, barWidth

barLoop:
	mov di, barLength
	mov cx, bar.CoordX
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
	mov ax, ball.SpeedX
	add ball.CoordX, ax
	
	;if hit the left wall
	cmp ball.CoordX, 0
	jle reverseSpeedX
	
	;if hit the right wall
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, windowsLength
	jge reverseSpeedX
	
	;moving the ball in y-axis
	mov ax, ball.SpeedY
	add ball.CoordY, ax
	
	;if hit the upper wall
	cmp ball.CoordY, 0
	jle reverseSpeedY
	
	;if hit the lower wall
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, windowsWidth
	jge reverseSpeedY
	
	;checking ball's collision with bar
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, bar.CoordY
	jl moveBallExit 
	
	;barX >= x && x <= barX+length
	mov ax, ball.CoordX
	cmp ax, bar.CoordX
	jl moveBallExit
	
	add ax, ballSize
	mov bx, bar.CoordX
	add bx, barLength
	cmp ax, bx
	jl reverseSpeedY
	
	moveBallExit:
	ret 
	reverseSpeedY:
	neg ball.SpeedY
	ret
	
	reverseSpeedX:
	neg ball.SpeedX
	ret
	
moveBall endp
;---------------------------------------------------------------------------------------------
brickCollision proc uses ax bx cx dx di si
	; ball.x < brick.x +brickLength
	; ball.x + ballLength > brick.x
	; ball.y < brick.y +brickWidth
	; ball.y + ballWidth > brick.y 
	
	mov si, -4
collisionLoop:
	add si, 4
	cmp si, 60
	jg collisionExit
	
	mov ax, brick[si].CoordX
	add ax, brickLength
	cmp ball.CoordX, ax
	jg collisionLoop
	
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, brick[si].CoordX
	jl collisionLoop
	
	mov ax, brick[si].CoordY
	add ax, brickWidth
	cmp ball.CoordY, ax
	jg collisionLoop
	
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, brick[si].CoordY
	jl collisionLoop
	
	;if all above 4 conditions are passed, it means the ball has collided
	;checking if the block has already been cleared
	mov al, 1
	mov ah, 0dh
	mov bh, 0
	mov cx, brick[si].CoordX
	mov dx, brick[si].CoordY
	int 10h
	cmp al, 0; 0 for black colour
	je collisionExit ; if the pixel is already black, skip the clearing
	
	
	clearBrick si
	inc player.Score
	;---------reflection off of a brick
	;if collide from above or below
		
	;mov ax, ball.CoordY
;	add ax, ballSize
	;cmp ax, brick[si].CoordY
	;jle reflectCheck
	
	
;	mov ax, brick[si].CoordY
	;add ax, brickWidth
	;cmp ball.CoordY, ax
	;jl reflectSideways
	
	neg ball.SpeedY
;	jmp collisionExit
	;else if collide from left or right
	;reflectSideways:
	;neg ball.SpeedX
	
	
	
	collisionExit:
ret
brickCollision endp
;---------------------------------------------------------------------------------------------
drawBall proc uses ax bx cx dx si di
	mov cx, ball.CoordX ;inital x
	mov dx, ball.CoordY ;inital y
	mov bh, 0; page number

	mov si, ballSize

	ballLoop:
		mov di, ballSize
		mov cx, ball.CoordX
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
;------------------------
displayScore Proc uses ax bx cx dx
	OUTP:
	MOV AX, player.Score
	MOV DX,0

	HERE:
	CMP AX,0
	JE DISP

	MOV BL,10
	DIV BL

	MOV DL,AH
	MOV DH,0
	PUSH DX
	MOV CL,AL
	MOV CH,0
	MOV AX,CX
	INC COUNT
	JMP HERE

	DISP:
	CMP COUNT,0
	JBE EX2
	POP DX
	ADD DL,48
	MOV AH,02H
	INT 21H
	DEC COUNT
	JMP DISP
	Ex2:
ret
displayScore endp
end