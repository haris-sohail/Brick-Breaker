.model small
.stack 100h
.data

;----------bar's variables
BarStruct struct
	CoordX dw 130
	CoordY dw 190
	Length_ dw 60
	Width_ dw 5
	Speed dw 10
BarStruct ends
;bar variable
bar BarStruct 1 dup(<>)

;----------ball's variables
BallStruct struct
	CoordX dw 158
	CoordY dw 180
	SpeedX dw 5
	SpeedY dw 5
BallStruct ends
;ball variables
ball BallStruct 1 dup(<>)
isBallLaunched db 0
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
	
brokenBricks dw 15 dup(-1)
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
LivesStr db "Lives: ",'$'
levelStr db "Level: ", '$'
gameLevel dw 1
timeRemaining dw 0
timeVar_1 db 0
timeVar_2 db 0
windowsWidth = 200
windowsLength = 320
statsVar dw 0
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
	
	attachBallToBar MACRO
		mov ax, bar.CoordX
		mov ball.CoordX, ax
		add ball.CoordX, 28
		mov ax, bar.CoordY
		sub ax, 10
		mov ball.CoordY, ax
		mov isBallLaunched, 0
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
	
	addBrokenBrick MACRO
		mov di, -1
		brokenBrickLoop:
			inc di
			cmp brokenBricks[di], -1
		jne brokenBrickLoop
		mov brokenBricks[di], ax ;(ax has the value of si)
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
	
	updateTime MACRO
		;----------- 4 mins of game time
		;if
		cmp timeVar_2, dh
		je timeSkip
		;else
		inc timeRemaining
		mov timeVar_2, dh
		;-setting the cursor position
		mov ah, 02h
		mov bh, 0
		mov dh, 1
		mov dl, 17
		int 10h
		
		mov ax, timeRemaining
		mov statsVar, ax
		call updateStats
		;---
		cmp timeRemaining, 240
		je exitGame
		
		timeSkip:
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
game PROC uses ax bx cx dx si di

timeLoop:
	mov ah, 2ch	;getting the time
	int 21h
	
	;updating game time
	updateTime
	
	;updating game level
	;call updateLevel

	;if 1/100 second hasnt passed, repeat loop
	cmp dl, timeVar_1
	je timeLoop
	
	;displaying the score
	call displayStats
	
	call brickCollision
	
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
	mov timeVar_1, dl
	jmp timeLoop
	
	exitGame:
ret
game endp
;---------------------------------------------------
updateLevel Proc uses si
	;checking if the broken bricks array is completely filled
		;mov si, 0
		;levelLoop:
		;	cmp brokenBricks[si], -1
		;	je updateLevelExit 			;still has space left in it
		;inc si
		;cmp si, 15
		;jne  levelLoop
	;else 
		;inc	gameLevel
		;sub bar.Length_, 10
		;add bar.Speed, 10
		;updateLevelExit:
	
ret
updateLevel endp
;--------------------------------------------------
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
	mov ax, player.Score
	mov statsVar, ax
	call updateStats
	
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
	
	;------------ Lives
	call clearHearts
	
	mov ah, 02h
	mov bh, 0
	mov dh, 24
	mov dl, 1
	int 10h
	
	mov dx, offset LivesStr
	mov ah, 09h
	int 21h
	
	
	mov ah, 02h
	mov bh, 0
	mov dh, 24
	mov dl, 7
	int 10h
	
	cmp player.Lives, 0
	jne skipskip
	mov player.Lives, 3
	
	skipskip:

	mov cx, player.Lives

displayHearts:
	mov dl, 3;	displaying hearts
	mov ah, 02h
	int 21h
loop displayHearts
	
	;------------- levelStr
	mov ah, 02h
	mov bh, 0
	mov dh, 24
	mov dl, 32
	int 10h
	
	mov dx, offset levelStr
	mov ah, 09h
	int 21h
	
	mov ah, 02h
	mov bh, 0
	mov dh, 24
	mov dl, 38
	int 10h
	
	mov ax, gameLevel
	mov statsVar, ax
	call updateStats

	;------------ 
	
ret
displayStats endp
;-------------------
clearHearts Proc uses ax bx cx dx
	mov ah, 06h
	mov bh, 0 ; black colour
	mov al, 2
	mov ch, 23
	mov dh, 24
	mov cl, 1
	mov dl, 9
	int 10h
ret
clearHearts endp
;---------------------------------------------------------------------------------------------
moveBar PROC uses ax bx cx dx
moveBar_Loop:

	mov ah, 01;checking for button input
	int 16h
	jz moveBarExit

	mov ah, 00;saving the pressed button
	int 16h
	cmp ah, 4Bh; left key
	je leftKey
	cmp ah, 4Dh; right key
	je rightKey
	cmp ah, 57 ;space key
	je launchBall
	jmp moveBarExit
	
	launchBall:
	mov isBallLaunched, 1
	jmp moveBarExit

	leftKey:
	
		;boundaryCheckLeft
		cmp bar.CoordX, 0
		jle moveBar_Loop
		mov ax, bar.Speed
		sub bar.CoordX, ax
		
		;move the ball along the bar if its not launched
		cmp isBallLaunched, 0
		jne moveBar_Loop
		clearBall
		mov ax, bar.Speed
		sub ball.CoordX, ax
		
	jmp moveBar_Loop
	

	rightKey:
		;boundaryCheckRight
		mov ax, bar.CoordX
		add ax, bar.Length_
		cmp ax, windowsLength
		jge moveBar_Loop
		mov ax, bar.Speed
		add bar.CoordX, ax
		
		;move the ball along the bar if its not launched
		cmp isBallLaunched, 0
		jne moveBar_Loop
		clearBall
		mov ax, bar.Speed
		add ball.CoordX, ax
		
	jmp moveBar_Loop
	
	moveBarExit:
ret
moveBar endp
;---------------------------------------------------------------------------------------------
drawBar proc uses ax bx cx dx si di
mov cx, bar.CoordX ;inital x
mov dx, bar.CoordY ;inital y
mov bh, 0; page number

mov si, bar.Width_

barLoop:
	mov di, bar.Length_
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
	cmp isBallLaunched, 0
	je moveBallExit
	
	call brickCollision
	
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
	jge youDied
	
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
	add bx, bar.Length_
	cmp ax, bx
	jl reverseSpeedY
	
	;if not collision occurs, simply return
	moveBallExit:
	ret 
	
	;reversing direction after collision
	reverseSpeedY:
	neg ball.SpeedY
	ret
	
	reverseSpeedX:
	neg ball.SpeedX
	ret
	
	youDied:
	dec player.Lives
	;neg ball.SpeedY
	
	attachBallToBar
	ret
	
	
moveBall endp
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
brickCollision proc uses ax bx cx dx di si
	; ball.x < brick.x +brickLength
	; ball.x + ballLength > brick.x
	; ball.y < brick.y +brickWidth
	; ball.y + ballWidth > brick.y 
	
	mov si, -4
	mov di, 0
collisionLoop:
	add si, type BrickStruct
	cmp si, 60
	jg collisionExit
	
	mov ax, brick[si].CoordX
	add ax, brickLength
	cmp ball.CoordX, ax
	jge collisionLoop
	
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, brick[si].CoordX
	jle collisionLoop
	
	mov ax, brick[si].CoordY
	add ax, brickWidth
	cmp ball.CoordY, ax
	jge collisionLoop
	
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, brick[si].CoordY
	jle collisionLoop
	
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
	
	mov ax, si
	mov di, 0
	checkForBrokenBrick:
		cmp brokenBricks[di], ax  ; if its already inside the broken bricks array, skip over it
		je collisionExit
	inc di
	cmp di, 15
	jne checkForBrokenBrick
		
	addBrokenBrick ; ax = si	(else add it to the array list)
	clearBrick si
	inc player.Score
	;---------reflection off of a brick
	neg ball.SpeedY
	
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
updateStats Proc uses ax bx cx dx
	OUTP:
	MOV AX, statsVar
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
updateStats endp
end