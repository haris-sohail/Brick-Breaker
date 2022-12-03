.model small
.stack 100h

.data

;----------bar's variables
BarStruct struct
	CoordX dw 130
	CoordY dw 190
	Length_ dw 60
	Width_ dw 5
	Speed dw 20
BarStruct ends
;bar variable
bar BarStruct 1 dup(<>)

;----------ball's variables
BallStruct struct
	CoordX dw 0
	CoordY dw 0
	SpeedX dw 5
	SpeedY dw 5
BallStruct ends
;ball variables
ball BallStruct 1 dup(<>)
isBallLaunched db 0
;constants
ballSize = 5
;----------- bricks
BrickStruct struct
	CoordX dw 0
	CoordY dw 0
	Health dw 1
BrickStruct ends
brickWidth = 20
brickLength = 40
bricksCount dw 0
brick BrickStruct    <40,20>, <90,20>, <140,20>, <190,20>, <240,20>, 
					 <40,50>, <90,50>, <140,50>, <190,50>, <240,50>,
					 <40,80>, <90,80>, <140,80>, <190,80>, <240,80>
						
;------------ player
PlayerStruct struct
	Score dw 0
	Lives dw 3
	igName db 30 dup(0)
PlayerStruct ends
;player variable
player PlayerStruct <>

;------------ misc vars
scoreMsg db "Score: ",'$'
nameMsg_1 db "Player Name: ", '$'
nameMsg_2 db "Name: ",'$'
livesMsg db "Lives: ",'$'
levelMsg db "Level: ", '$'
pauseMsg db "Game is paused.", 10,9, "  Press esc to resume.", '$' ;10 for linefeed, 9 for tab

gameLevel dw 1
timeRemaining dw 0
timeVar_1 db 0
timeVar_2 db 0
windowsWidth = 200
windowsLength = 320
statsVar dw 0
count dw 0
isGamePaused dw 0

.code
;include img.inc
;------------- MACROs
	makeBall MACRO
		mov al, 0fh; white colour ball
		call drawBall
	ENDM

	clearBall MACRO
		mov al, 00h; black colour ball
		call drawBall
	ENDM
	
	beepSound MACRO
		mov ah, 2h
		mov dl, 07h
		int 21h
	ENDM
	
	attachBallToBar MACRO
	clearBall
		mov ax, bar.CoordX
		mov ball.CoordX, ax
		mov bx, bar.Length_; 	getting the midpoint of the paddle
		shr bx, 1
		add ball.CoordX, bx
		mov ax, bar.CoordY
		sub ax, 10
		mov ball.CoordY, ax
		mov isBallLaunched, 0
		
		
		or ball.SpeedY,0
		js directionSkip1
		neg ball.SpeedY
		directionSkip1:
		
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
	
	displayPauseMsg MACRO
		;-setting the cursor position
		mov ah, 02h
		mov bh, 0
		mov dh, 18	;row
		mov dl, 13	;col
		int 10h
		
		mov dx, offset pauseMsg
		mov ah, 09h
		int 21h
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
		cmp timeRemaining, 1000
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
	call drawBricks
	call game

mov ah, 4ch
int 21h
main endp


;---------------------------------------------------------------------------------------------
game PROC uses ax bx cx dx si di

	attachBallToBar
	
gameLoop:
	mov ah, 2ch	;getting system time
	int 21h
	
	;updating game time
	.if(isGamePaused == 0)
		updateTime
		call updateGameLevel
	.endif

	;if 1/100 second hasnt passed, repeat loop
	cmp dl, timeVar_1
	je gameLoop
	
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
	call keyboardInput
	makeBar
	

	;Now that 1/100 sec has passed, store the prev second in time var and repeat the loop again
	mov timeVar_1, dl
	jmp gameLoop
	
	exitGame:
ret
game endp
;---------------------------------------------------
updateGameLevel Proc uses si ax
	.if(bricksCount == 15) 
		inc	gameLevel
		mov bricksCount, 0
		
		; Condition for game level 2
		.if(gameLevel == 2)
			sub bar.Length_, 20
			;add ball.SpeedX, 3
			add ball.SpeedY, 3
			mov si, 0
			.while(si < (BrickStruct * 15))
				mov brick[si].Health, 2
			add si, type BrickStruct
			.endw
			
		; Conditions for game level 3
		.else 
			add ball.SpeedX, 3
			;add ball.SpeedY, 3
			mov si, 0
			.while(si < (BrickStruct * 15))
				mov brick[si].Health, 3
			add si, type BrickStruct
			.endw
		.endif
		
		; reverting the bricks to their original coordinates and displaying them
		attachBallToBar
		mov si, 0
		.while(si < BrickStruct * 15)
			neg brick[si].CoordX
			neg brick[si].CoordY
		add si, type BrickStruct
		.endw
		call drawBricks
		
	.endif
ret
updateGameLevel endp
;--------------------------------------------------
inputName proc uses ax bx cx dx

	;setting the cursor position
	mov ah, 02h
	mov bh, 0
	mov dh, 12
	mov dl, 8
	int 10h
	
	mov dx, offset nameMsg_1
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
	
	mov dx, offset scoreMsg
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
	
	mov dx, offset nameMsg_2
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
	
	mov ah, 02h ;changing cursor position
	mov bh, 0
	mov dh, 24
	mov dl, 1
	int 10h
	
	mov dx, offset livesMsg
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
	
	;------------- levelMsg
	mov ah, 02h
	mov bh, 0
	mov dh, 24
	mov dl, 30
	int 10h
	
	mov dx, offset levelMsg
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
clearPausedMsg Proc uses ax bx cx dx
	local parentLoopCount:word, childLoopCount: word
	mov parentLoopCount, 25
	mov childLoopCount, 160
	mov cx, 80 ;x coord
	mov dx, 140 ;y- coord
	
	.while(parentLoopCount>0)
		mov cx, 80
		mov childLoopCount, 160
		.while(childLoopCount>0)
		mov ah, 0ch	;write pixel
		mov al, 0	;black color
		mov bh, 0
		int 10h
		inc cx
		dec childLoopCount
		.endw
	inc dx
	dec parentLoopCount
	.endw
ret
clearPausedMsg endp
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
clearScreen proc uses ax bx cx dx
	MOV AH, 06h
	MOV AL, 0
	MOV CX, 0
	MOV DH, 25
	MOV DL, 40
	MOV BH, 0
	INT 10h
ret
clearScreen endp
;---------------------------------------------------------------------------------------------
keyboardInput PROC uses ax bx cx dx
keyboardInput_Loop:

	mov ah, 01;checking for button input
	int 16h
	jz keyboardInputExit

	mov ah, 00;saving the pressed button
	int 16h
	cmp ah, 4Bh; left key
	je leftKey
	cmp ah, 4Dh; right key
	je rightKey
	cmp ah, 57 ;space key
	je launchBall
	cmp ah, 01
	je pauseGame
	jmp keyboardInputExit
	
	
	launchBall:
	;if game is paused
		.if(isGamePaused == 1)
		jmp keyboardInputExit
		.endif
	;else
	mov isBallLaunched, 1
	jmp keyboardInputExit
	
	pauseGame:
	.if(isGamePaused == 0)
	displayPauseMsg
	mov isGamePaused, 1
	mov isBallLaunched,  0
	.else
	call clearPausedMsg
	mov isGamePaused, 0
	mov isBallLaunched,  1
	.endif
	jmp keyboardInputExit


	leftKey:
		;if game is paused
		.if(isGamePaused == 1)
		jmp keyboardInputExit
		.endif
	
		;boundaryCheckLeft
		cmp bar.CoordX, 0
		jle keyboardInput_Loop
		mov ax, bar.Speed
		sub bar.CoordX, ax
		
		;move the ball along the bar if its not launched
		cmp isBallLaunched, 0
		jne keyboardInput_Loop
		clearBall
		mov ax, bar.Speed
		sub ball.CoordX, ax
		
	jmp keyboardInput_Loop
	

	rightKey:
		;if game is paused
		.if(isGamePaused == 1)
		jmp keyboardInputExit
		.endif
	
		;boundaryCheckRight
		mov ax, bar.CoordX
		add ax, bar.Length_
		cmp ax, windowsLength
		jge keyboardInput_Loop
		mov ax, bar.Speed
		add bar.CoordX, ax
		
		;move the ball along the bar if its not launched
		cmp isBallLaunched, 0
		jne keyboardInput_Loop
		clearBall
		mov ax, bar.Speed
		add ball.CoordX, ax
		
	jmp keyboardInput_Loop
	
	keyboardInputExit:
ret
keyboardInput endp
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
	
	;moving the ball in x-axis
	mov ax, ball.SpeedX
	add ball.CoordX, ax
	
		;moving the ball in y-axis
	mov ax, ball.SpeedY
	add ball.CoordY, ax
	
	;if hit the left wall
	cmp ball.CoordX, 0
	jle reverseSpeedX
	
	;if hit the right wall
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, windowsLength
	jge reverseSpeedX
	

	
	;if hit the upper wall
	cmp ball.CoordY, 0
	jle reverseSpeedY
	
	;if hit the lower wall
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, windowsWidth
	jge youDied
	
	;checking ball's collision with bar
	
	
	
	mov ax, bar.CoordX
	add ax, bar.Length_
	cmp ball.CoordX, ax
	jg moveBallExit
	
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, bar.CoordX
	jl moveBallExit
	
	mov ax, bar.CoordY
	add ax, bar.Width_
	cmp ball.CoordY, ax
	jg moveBallExit
	
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, bar.CoordY
	jl moveBallExit
	; if collides, reverseSpeedY
	jmp reverseSpeedY
	
	;if no collision occurs, simply return
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
	;neg ball.SpeedYs
	attachBallToBar
	ret
	
	
moveBall endp
;---------------------------------------------------------------------------------------------
drawBricks proc uses ax bx cx dx si di
	local brickLoopVar:word, colorTracker:word
	mov colorTracker, 0
	mov brickLoopVar, 20
	mov bh, 0; page number
	mov si, 0
	mov al, 9
brickLoop_1:
	.if(colorTracker == 4)
		mov colorTracker, 0
		mov al, 9
	.else
		inc colorTracker
		inc al
	.endif
	
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

add si, type BrickStruct
cmp si, type BrickStruct * 15
jb brickLoop_1
ret
drawBricks ENDP

;---------------------------------------------------------------------------------------------
brickCollision proc uses ax bx cx dx di si
	; ball.x < brick.x +brickLength
	; ball.x + ballLength > brick.x
	; ball.y < brick.y +brickWidth
	; ball.y + ballWidth > brick.y 
	local collisionVar:word, brickLoopVar:word
	
	mov si, 0
	mov di, 0
	mov collisionVar, 0
	.while(collisionVar < 15)
	
	mov ax, brick[si].CoordX
	add ax, brickLength
	cmp ball.CoordX, ax
	jg collisionSkip
	
	mov ax, ball.CoordX
	add ax, ballSize
	cmp ax, brick[si].CoordX
	jl collisionSkip
	
	mov ax, brick[si].CoordY
	add ax, brickWidth
	cmp ball.CoordY, ax
	jg collisionSkip
	
	mov ax, ball.CoordY
	add ax, ballSize
	cmp ax, brick[si].CoordY
	jl collisionSkip
	
	;if all above 4 conditions are passed, it means the ball has collided
	;checking if the block has already been cleared
	
	dec brick[si].Health
	.if(brick[si].Health == 0)
		clearBrick si
		inc bricksCount
		
		;changing the bricks coordinates so the ball wont collide with them once they've been broken
		neg brick[si].CoordX
		neg brick[si].CoordY
	.endif
	
	;generating beepsound
	beepSound
	; increasing the player score
	inc player.Score
	;---------reflection off of a brick
	neg ball.SpeedY
	ret
	
	collisionSkip:
add si, type BrickStruct
inc collisionVar
.endw

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