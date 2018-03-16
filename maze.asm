; Define VGA Port ID's
.EQU 	VGA_HADD 	= 0x90
.EQU 	VGA_LADD 	= 0x91
.EQU 	VGA_COLOR 	= 0x92
.EQU	VGA_READ	= 0x93

.EQU 	BG_COLOR    = 0x03             ; Background:  green

.EQU	BUTTONS 	= 0x24 
.EQU	LEDS		= 0x40
.EQU	SWITCHES	= 0x20
.EQU	SEGMENTS	= 0x81

.CSEG
.ORG 0x10

;---------------------------------------------------------------------
init:	
		MOV		r1, 0xFF	; Initialize “marker” register to be white
		MOV		r0, 0x00	; Initialize “blank” register to be black
		MOV		r2, 0x00	; buttons (directions)

		MOV		r6, 0x1D
		CALL	Draw_title

		MOV    	r6, 0x9A
		CALL	Draw_walls
		MOV		r9, r6			; save wall colors
		
		; CURSOR 
		MOV 	r6, 0xFF 		; set color to white
		MOV 	r8, 0x03 		; set x-component 
		MOV 	r7, 0x13 		; set y-component
		CALL	draw_dot 

		MOV		r25, 0x01		; initialize move counter

		SEI


main:	AND		r0, r0

		BRN    main                    ; continuous loop 
;--------------------------------------------------------------------

Reset:
		

ISR:	
		IN		r2, BUTTONS
		CLC
		CMP		r2, 0x02	; 0x01 = U
		BREQ	Mov_left	; 0x02 = L
		BRCS	Mov_up		; 0x04 = R
							; 0x08 = D
		CMP 	r2, 0x04
		BREQ	Mov_right
		BRN		Mov_down	

Erase:						; sub routine 

		MOV		r6, r0		; set blank
		CALL	draw_dot	; remove current (prev)
		MOV		r6, r1		; reset marker to white 
		RET

Process:					; sub routine
		MOV 	r4,r7 		; copy Y coordinate
		MOV 	r5,r8 		; copy X coordinate
		AND 	r5,0x7F 	; make sure top 1 bits cleared
		AND 	r4,0x3F 	; make sure top 2 bits cleared
		LSR 	r4 			; need to get the bottom bit of r4 into r5
		BRCS	Set

Transfer:
		OUT 	r5,VGA_LADD 	; write bottom 8 address bits to register
		OUT 	r4,VGA_HADD 	; write top 5 address bits to register
		IN	 	r10,VGA_READ	; read color data fropm frame buffer

		RET

Set:
		OR 		r5,0x80 		; set bit if needed
		Brn		Transfer

Mov_up:
		MOV		r20, 0x04
		OUT		r20, LEDS

		; check for wall
		; - process bits for MCU
		; - read data from RAM
		; - compare RGB to background
		SUB		r7, 0x01

		CALL	Process

		ADD		r7, 0x01

		CMP		r10, 0xFF
		BREQ	Mov_up1
		CMP		r10, 0x00
		BRNE	Stop
Mov_up1:	
		CALL	Erase
		SUB		r7, 0x01
		CALL 	draw_dot 	
		BRN		Return


Mov_down:
		MOV		r20, 0x02
		OUT		r20, LEDS

		SUB		r9, 0x01		; help randomize color

		ADD		r7, 0x01

		CALL	Process

		SUB		r7, 0x01

		CMP		r10, 0xFF
		BREQ 	Mov_down1
		CMP		r10, 0x00
		BRNE	Stop
Mov_down1:
		CALL	Erase
		ADD		r7, 0x01
		CALL 	draw_dot 	
		BRN		Return



Mov_left:
		MOV		r20, 0x08
		OUT		r20, LEDS

		SUB		r8, 0x01

		CALL	Process

		ADD		r8, 0x01

		CMP		r10, 0xFF
		BREQ	Mov_left1
		CMP		r10, 0x00
		BRNE	Stop
Mov_left1:
		CALL	Erase
		SUB		r8, 0x01
		CALL 	draw_dot 	
		BRN		Return


Mov_right:
		MOV		r20, 0x01
		OUT		r20, LEDS

		SUB		r9, 0x05		; help randomize color

		ADD		r8, 0x01

		CALL	Process

		CMP		r10, 0x13		; check for win
		BREQ	Draw_win

		SUB		r8, 0x01

		CMP		r10, 0xFF
		BREQ	Mov_right1
		CMP		r10, 0x00
		BRNE	Stop
Mov_right1:
		CALL	Erase
		ADD		r8, 0x01
		CALL 	draw_dot 

		BRN		Return

Stop:
		ROR		r9
		EXOR	r9, 0xB7
		MOV		r6, r9
		PUSH	r7
		PUSH 	r8
		CALL	Draw_walls
		POP 	r8
		POP		r7 

Return:			
		OUT		r25, SEGMENTS
		ADD		r25, 0x01
		RETIE

;------------------------------------------------------------------------------------------
;- Subroutine: draw_dot
;-
;- This subroutine draws a dot on the display the given coordinates:
;-
;- (X,Y) = (r8,r7) with a color stored in r6
;-
;- Tweaked registers: r4,r5
;------------------------------------------------------------------------------------------
draw_dot:
		MOV 	r4,r7 		; copy Y coordinate
		MOV 	r5,r8 		; copy X coordinate
		AND 	r5,0x7F 	; make sure top 1 bits cleared
		AND 	r4,0x3F 	; make sure top 2 bits cleared
		LSR 	r4 			; need to get the bottom bit of r4 into r5
		BRCS 	dd_add80

dd_out:
		OUT 	r5,VGA_LADD 	; write bottom 8 address bits to register
		OUT 	r4,VGA_HADD 	; write top 5 address bits to register
		OUT 	r6,VGA_COLOR	; write color data to frame buffer	
		RET

dd_add80:
		OR 		r5,0x80 		; set bit if needed
		BRN 	dd_out

;--------------------------------------------------------------------
;-  Subroutine: draw_horizontal_line
;-
;-  Draws a horizontal line from (r8,r7) to (r9,r7) using color in r6
;-
;-  Parameters:
;-   r8  = starting x-coordinate
;-   r7  = y-coordinate
;-   r9  = ending x-coordinate
;-   r6  = color used for line
;- 
;- Tweaked registers: r8,r9
;--------------------------------------------------------------------
draw_horizontal_line:
        ADD    r9,0x01          ; go from r8 to r15 inclusive

draw_horiz1:
        CALL   draw_dot          
        ADD    r8,0x01
        CMP    r8,r9
        BRNE   draw_horiz1
        RET
;--------------------------------------------------------------------


;---------------------------------------------------------------------
;-  Subroutine: draw_vertical_line
;-
;-  Draws a horizontal line from (r8,r7) to (r8,r9) using color in r6
;-
;-  Parameters:
;-   r8  = x-coordinate
;-   r7  = starting y-coordinate
;-   r9  = ending y-coordinate
;-   r6  = color used for line
;- 
;- Tweaked registers: r7,r9
;--------------------------------------------------------------------
draw_vertical_line:
         ADD    r9,0x01

draw_vert1:          
         CALL   draw_dot
         ADD    r7,0x01
         CMP    r7,R9
         BRNE   draw_vert1
         RET

; ------ TITLE --------------------------------------------------------------------
Draw_title:

		; A
		MOV		r8,0x0B                 ; starting x coordinate
        MOV		r7,0x09                 ; start y coordinate
        MOV		r9,0x0D                  ; ending x coordinate
        CALL	draw_horizontal_line

		MOV		r8,0x0A                 ; starting x coordinate
        MOV     r7,0x07                 ; start y coordinate
        MOV     r9,0x0B                 ; ending y coordinate
        CALL    draw_vertical_line

		MOV     r8,0x0E                 ; starting x coordinate
        MOV     r7,0x07                 ; start y coordinate
        MOV     r9,0x0B                 ; ending y coordinate
        CALL    draw_vertical_line

		MOV	    r8,0x0B
		MOV	    r7,0x06
		CALL	draw_dot

		MOV		r8, 0x0C
		MOV		r7, 0x05
		CALL	draw_dot

		MOV		r8, 0x0D
		MOV		r7, 0x06
		CALL	draw_dot
	
		; --
		MOV		r8,0x10                 ; starting x coordinate
        MOV		r7,0x08                 ; start y coordinate
        MOV		r9,0x12                  ; ending x coordinate
        CALL	draw_horizontal_line	

		; M
		MOV    r8,0x14                 ; starting x coordinate
        MOV    r7,0x05                 ; start y coordinate
        MOV    r9,0x0B                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV 	r8, 0x15				; X
		MOV		r7, 0x06				; Y
		CALL	draw_dot

		MOV		r8, 0x16
		MOV		r7, 0x07
		CALL	draw_dot

	    MOV		r8, 0x17
		MOV		r7, 0x08
		CALL	draw_dot

		MOV		r8, 0x18
		MOV		r7, 0x07
		CALL	draw_dot

		MOV		r8, 0x19
		MOV		r7, 0x06
		CALL	draw_dot

		MOV    r8,0x1A                 ; starting x coordinate
        MOV    r7,0x05                 ; start y coordinate
        MOV    r9,0x0B                 ; ending y coordinate
        CALL   draw_vertical_line 

		; A
		MOV    r8,0x1E                 ; starting x coordinate
        MOV    r7,0x09                 ; start y coordinate
        MOV    r9,0x20                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x1D                 ; starting x coordinate
        MOV    r7,0x07                 ; start y coordinate
        MOV    r9,0x0B                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x21                 ; starting x coordinate
        MOV    r7,0x07                 ; start y coordinate
        MOV    r9,0x0B                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV	    r8,0x1E
		MOV	    r7,0x06
		CALL	draw_dot

		MOV		r8, 0x1F
		MOV		r7, 0x05
		CALL	draw_dot

		MOV		r8, 0x20
		MOV		r7, 0x06
		CALL	draw_dot

		; Z 
		MOV		r8,0x24                 ; starting x coordinate
        MOV		r7,0x05                 ; start y coordinate
        MOV     r9,0x29                 ; ending x coordinate
        CALL    draw_horizontal_line

		MOV		r8, 0x28
		MOV		r7, 0x06
		CALL	draw_dot

		MOV		r8, 0x27
		MOV		r7, 0x07
		CALL	draw_dot

		MOV		r8, 0x26
		MOV		r7, 0x08
		CALL	draw_dot

		MOV		r8, 0x25
		MOV		r7, 0x09
		CALL	draw_dot

		MOV		r8, 0x24
		MOV		r7, 0x0A
		CALL	draw_dot

		MOV		r8, 0x24
		MOV		r7, 0x0B
		MOV		r9, 0x29
		CALL	draw_horizontal_line

		; E
		MOV    r8,0x2C                 ; starting x coordinate
        MOV    r7,0x05                 ; start y coordinate
        MOV    r9,0x0B                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV		r8, 0x2D
		MOV		r7, 0x05
		MOV		r9, 0x2F
		CALL	draw_horizontal_line
		
		MOV		r8, 0x2D
		MOV		r7, 0x08
		MOV		r9, 0x2E
		CALL	draw_horizontal_line

		MOV		r8, 0x2D
		MOV		r7, 0x0B
		MOV		r9, 0x2F
		CALL	draw_horizontal_line

		; --
		MOV		r8,0x31                 ; starting x coordinate
        MOV		r7,0x08                 ; start y coordinate
        MOV		r9,0x33                  ; ending x coordinate
        CALL	draw_horizontal_line	

		; I
		MOV		r8,0x35                 ; starting x coordinate
        MOV		r7,0x05                 ; start y coordinate
        MOV		r9,0x37                  ; ending x coordinate
        CALL	draw_horizontal_line

		MOV		r8,0x35                 ; starting x coordinate
        MOV		r7,0x0B                 ; start y coordinate
        MOV		r9,0x37                  ; ending x coordinate
        CALL	draw_horizontal_line
		
		MOV     r8,0x36                 ; starting x coordinate
        MOV     r7,0x06                 ; start y coordinate
        MOV     r9,0x0A                 ; ending y coordinate
        CALL    draw_vertical_line

		; N
		MOV     r8,0x3A                 ; starting x coordinate
        MOV     r7,0x05                ; start y coordinate
        MOV     r9,0x0B                 ; ending y coordinate
        CALL    draw_vertical_line

		MOV     r8,0x40                 ; starting x coordinate
        MOV     r7,0x05                ; start y coordinate
        MOV     r9,0x0B                 ; ending y coordinate
        CALL    draw_vertical_line
		
		MOV	    r8, 0x3B
		MOV	 	r7, 0x06
		CALL	draw_dot

		MOV	    r8, 0x3C
		MOV	 	r7, 0x07
		CALL	draw_dot
		
		MOV	    r8, 0x3D
		MOV	 	r7, 0x08
		CALL	draw_dot

		MOV	    r8, 0x3E
		MOV	 	r7, 0x09
		CALL	draw_dot

		MOV	    r8, 0x3F
		MOV	 	r7, 0x0A
		CALL	draw_dot

		; G
		MOV		r8,0x45                 ; starting x coordinate
        MOV		r7,0x05                 ; start y coordinate
        MOV		r9,0x47                 ; ending x coordinate
        CALL	draw_horizontal_line

		MOV		r8,0x45                 ; starting x coordinate
        MOV		r7,0x0B                 ; start y coordinate
        MOV		r9,0x47                 ; ending x coordinate
        CALL	draw_horizontal_line

		MOV		r8,0x47                 ; starting x coordinate
        MOV		r7,0x09                 ; start y coordinate
        MOV		r9,0x48                 ; ending x coordinate
        CALL	draw_horizontal_line

		MOV     r8,0x43                 ; starting x coordinate
        MOV     r7,0x07                 ; start y coordinate
        MOV     r9,0x09                 ; ending y coordinate
        CALL    draw_vertical_line

		MOV	    r8, 0x44
		MOV	 	r7, 0x06
		CALL	draw_dot
		
		MOV	    r8, 0x48
		MOV	 	r7, 0x06
		CALL	draw_dot

		MOV	    r8, 0x48
		MOV	 	r7, 0x0A
		CALL	draw_dot

		MOV	    r8, 0x44
		MOV	 	r7, 0x0A
		CALL	draw_dot

		RET
; ---------------------------------------------------------------------------
Draw_walls:

		 ; TOP BORDER
         MOV    r8,0x06                 ; starting x coordinate
         MOV    r7,0x12                 ; start y coordinate
         MOV    r9,0x49                 ; ending x coordinate
         CALL   draw_horizontal_line

		 ; LEFT BORDER
         MOV    r8,0x05                 ; starting x coordinate
         MOV    r7,0x12                 ; start y coordinate
         MOV    r9,0x37                 ; ending y coordinate
         CALL   draw_vertical_line

		 ; BOTTOM BORDER
		 MOV    r8,0x06                 ; starting x coordinate
         MOV    r7,0x37                 ; start y coordinate
         MOV    r9,0x49                 ; ending x coordinate
         CALL   draw_horizontal_line

		 ; RIGHT BORDER
         MOV    r8,0x4A                 ; starting x coordinate
         MOV    r7,0x12                 ; start y coordinate
         MOV    r9,0x37                 ; ending y coordinate
         CALL   draw_vertical_line
; ----------------------------------------------------------------------

; WALLS
		; HORIZONTAL 

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x14                 ; start y coordinate
        MOV    r9,0x48                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0E                 ; starting x coordinate
        MOV    r7,0x16                 ; start y coordinate
        MOV    r9,0x46                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x18                 ; start y coordinate
        MOV    r9,0x46                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0E                 ; starting x coordinate
        MOV    r7,0x1A                 ; start y coordinate
        MOV    r9,0x44                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x08                 ; starting x coordinate
        MOV    r7,0x15                 ; start y coordinate
        MOV    r9,0x0C                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x08                 ; starting x coordinate
        MOV    r7,0x18                 ; start y coordinate
        MOV    r9,0x0C                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x06                 ; starting x coordinate
        MOV    r7,0x1A                 ; start y coordinate
        MOV    r9,0x0A                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x06                 ; starting x coordinate
        MOV    r7,0x1D                 ; start y coordinate
        MOV    r9,0x0A                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x18                 ; starting x coordinate
        MOV    r7,0x1C                 ; start y coordinate
        MOV    r9,0x21                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x24                 ; starting x coordinate
        MOV    r7,0x1C                 ; start y coordinate
        MOV    r9,0x28                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2C                 ; starting x coordinate
        MOV    r7,0x1C                 ; start y coordinate
        MOV    r9,0x34                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x17                 ; starting x coordinate
        MOV    r7,0x1E                 ; start y coordinate
        MOV    r9,0x20                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x1C                 ; start y coordinate
        MOV    r9,0x14                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x1D                 ; start y coordinate
        MOV    r9,0x14                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0E                 ; starting x coordinate
        MOV    r7,0x1F                 ; start y coordinate
        MOV    r9,0x12                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x15                 ; starting x coordinate
        MOV    r7,0x20                 ; start y coordinate
        MOV    r9,0x21                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2B                 ; starting x coordinate
        MOV    r7,0x1E                 ; start y coordinate
        MOV    r9,0x31                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x40                 ; starting x coordinate
        MOV    r7,0x20                 ; start y coordinate
        MOV    r9,0x44                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x06                 ; starting x coordinate
        MOV    r7,0x36                 ; start y coordinate
        MOV    r9,0x46                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x08                 ; starting x coordinate
        MOV    r7,0x29                 ; start y coordinate
        MOV    r9,0x12                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x08                 ; starting x coordinate
        MOV    r7,0x20                 ; start y coordinate
        MOV    r9,0x0C                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x08                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x0C                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x21                 ; start y coordinate
        MOV    r9,0x13                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0E                 ; starting x coordinate
        MOV    r7,0x23                 ; start y coordinate
        MOV    r9,0x12                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x25                 ; start y coordinate
        MOV    r9,0x13                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0E                 ; starting x coordinate
        MOV    r7,0x27                 ; start y coordinate
        MOV    r9,0x12                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x2B                 ; start y coordinate
        MOV    r9,0x13                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0E                 ; starting x coordinate
        MOV    r7,0x2D                 ; start y coordinate
        MOV    r9,0x12                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x2F                 ; start y coordinate
        MOV    r9,0x13                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0E                 ; starting x coordinate
        MOV    r7,0x31                 ; start y coordinate
        MOV    r9,0x12                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x0F                 ; starting x coordinate
        MOV    r7,0x33                 ; start y coordinate
        MOV    r9,0x13                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x06                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x09                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x06                 ; starting x coordinate
        MOV    r7,0x27                 ; start y coordinate
        MOV    r9,0x09                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x06                 ; starting x coordinate
        MOV    r7,0x2E                 ; start y coordinate
        MOV    r9,0x09                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x06                 ; starting x coordinate
        MOV    r7,0x33                 ; start y coordinate
        MOV    r9,0x09                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x09                 ; starting x coordinate
        MOV    r7,0x2C                 ; start y coordinate
        MOV    r9,0x0C                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x19                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x1F                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x1B                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x1D                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x1B                 ; starting x coordinate
        MOV    r7,0x26                 ; start y coordinate
        MOV    r9,0x1D                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x19                 ; starting x coordinate
        MOV    r7,0x28                 ; start y coordinate
        MOV    r9,0x24                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x17                 ; starting x coordinate
        MOV    r7,0x2B                 ; start y coordinate
        MOV    r9,0x1D                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x18                 ; starting x coordinate
        MOV    r7,0x2D                 ; start y coordinate
        MOV    r9,0x1B                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x17                 ; starting x coordinate
        MOV    r7,0x2F                 ; start y coordinate
        MOV    r9,0x19                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x1B                 ; starting x coordinate
        MOV    r7,0x32                 ; start y coordinate
        MOV    r9,0x27                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x23                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x24                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x20                 ; starting x coordinate
        MOV    r7,0x2A                 ; start y coordinate
        MOV    r9,0x24                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x20                 ; starting x coordinate
        MOV    r7,0x2C                 ; start y coordinate
        MOV    r9,0x24                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x1F                 ; starting x coordinate
        MOV    r7,0x2E                 ; start y coordinate
        MOV    r9,0x25                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x1D                 ; starting x coordinate
        MOV    r7,0x30                 ; start y coordinate
        MOV    r9,0x25                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x15                 ; starting x coordinate
        MOV    r7,0x31                 ; start y coordinate
        MOV    r9,0x16                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x26                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x27                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2B                 ; starting x coordinate
        MOV    r7,0x20                 ; start y coordinate
        MOV    r9,0x2F                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2C                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x2E                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2B                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x2F                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2B                 ; starting x coordinate
        MOV    r7,0x26                 ; start y coordinate
        MOV    r9,0x2F                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2D                 ; starting x coordinate
        MOV    r7,0x28                 ; start y coordinate
        MOV    r9,0x2F                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2F                 ; starting x coordinate
        MOV    r7,0x2A                 ; start y coordinate
        MOV    r9,0x31                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2F                 ; starting x coordinate
        MOV    r7,0x2C                 ; start y coordinate
        MOV    r9,0x35                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2E                 ; starting x coordinate
        MOV    r7,0x34                 ; start y coordinate
        MOV    r9,0x33                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x35                 ; starting x coordinate
        MOV    r7,0x31                 ; start y coordinate
        MOV    r9,0x3B                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x37                 ; starting x coordinate
        MOV    r7,0x33                 ; start y coordinate
        MOV    r9,0x3B                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x3A                 ; starting x coordinate
        MOV    r7,0x2A                 ; start y coordinate
        MOV    r9,0x3D                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x36                 ; starting x coordinate
        MOV    r7,0x2F                 ; start y coordinate
        MOV    r9,0x39                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x40                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x43                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x48                 ; starting x coordinate
        MOV    r7,0x2D                 ; start y coordinate
        MOV    r9,0x49                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x40                 ; starting x coordinate
        MOV    r7,0x34                 ; start y coordinate
        MOV    r9,0x42                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x40                 ; starting x coordinate
        MOV    r7,0x32                 ; start y coordinate
        MOV    r9,0x43                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2E                 ; starting x coordinate
        MOV    r7,0x2E                 ; start y coordinate
        MOV    r9,0x32                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x2D                 ; starting x coordinate
        MOV    r7,0x32                 ; start y coordinate
        MOV    r9,0x32                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x21                 ; starting x coordinate
        MOV    r7,0x26                 ; start y coordinate
        MOV    r9,0x26                 ; ending x coordinate
        CALL   draw_horizontal_line

		MOV    r8,0x1A                 ; starting x coordinate
        MOV    r7,0x34                 ; start y coordinate
        MOV    r9,0x26                 ; ending x coordinate
        CALL   draw_horizontal_line
; ----------------------------------------------------------------------------------------------------------------------------------

		; VERTICAL

		MOV    r8,0x0D                 ; starting x coordinate
        MOV    r7,0x13                 ; start y coordinate
        MOV    r9,0x27                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x0D                 ; starting x coordinate
        MOV    r7,0x2A                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x14                 ; starting x coordinate
        MOV    r7,0x1E                 ; start y coordinate
        MOV    r9,0x33                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x16                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x1E                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x16                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x2F                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x18                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x28                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x08                 ; starting x coordinate
        MOV    r7,0x16                 ; start y coordinate
        MOV    r9,0x17                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x0A                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x1C                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x0A                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x27                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x0A                 ; starting x coordinate
        MOV    r7,0x2E                 ; start y coordinate
        MOV    r9,0x33                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x08                 ; starting x coordinate
        MOV    r7,0x2A                 ; start y coordinate
        MOV    r9,0x2C                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x22                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x24                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x24                 ; starting x coordinate
        MOV    r7,0x1D                 ; start y coordinate
        MOV    r9,0x22                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x20                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x26                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x1E                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x26                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x1A                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x26                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x2A                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x24                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x28                 ; starting x coordinate
        MOV    r7,0x1D                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x2A                 ; starting x coordinate
        MOV    r7,0x26                 ; start y coordinate
        MOV    r9,0x34                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x26                 ; starting x coordinate
        MOV    r7,0x27                 ; start y coordinate
        MOV    r9,0x30                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x48                 ; starting x coordinate
        MOV    r7,0x15                 ; start y coordinate
        MOV    r9,0x26                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x46                 ; starting x coordinate
        MOV    r7,0x19                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x44                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x1F                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x44                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x27                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x44                 ; starting x coordinate
        MOV    r7,0x29                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x36                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x2D                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x34                 ; starting x coordinate
        MOV    r7,0x1D                 ; start y coordinate
        MOV    r9,0x2A                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x32                 ; starting x coordinate
        MOV    r7,0x1E                 ; start y coordinate
        MOV    r9,0x20                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x32                 ; starting x coordinate
        MOV    r7,0x22                 ; start y coordinate
        MOV    r9,0x2A                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x32                 ; starting x coordinate
        MOV    r7,0x2F                 ; start y coordinate
        MOV    r9,0x31                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x38                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x1F                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x38                 ; starting x coordinate
        MOV    r7,0x21                 ; start y coordinate
        MOV    r9,0x26                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x38                 ; starting x coordinate
        MOV    r7,0x28                 ; start y coordinate
        MOV    r9,0x2C                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x3A                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x1F                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x3A                 ; starting x coordinate
        MOV    r7,0x21                 ; start y coordinate
        MOV    r9,0x28                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x3C                 ; starting x coordinate
        MOV    r7,0x1C                 ; start y coordinate
        MOV    r9,0x23                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x3E                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x21                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x40                 ; starting x coordinate
        MOV    r7,0x1B                 ; start y coordinate
        MOV    r9,0x1E                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x40                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x30                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x42                 ; starting x coordinate
        MOV    r7,0x1C                 ; start y coordinate
        MOV    r9,0x1F                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x42                 ; starting x coordinate
        MOV    r7,0x24                 ; start y coordinate
        MOV    r9,0x29                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x42                 ; starting x coordinate
        MOV    r7,0x2B                 ; start y coordinate
        MOV    r9,0x31                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x3E                 ; starting x coordinate
        MOV    r7,0x23                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x3C                 ; starting x coordinate
        MOV    r7,0x25                 ; start y coordinate
        MOV    r9,0x28                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x3C                 ; starting x coordinate
        MOV    r7,0x2C                 ; start y coordinate
        MOV    r9,0x31                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x3C                 ; starting x coordinate
        MOV    r7,0x33                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x3A                 ; starting x coordinate
        MOV    r7,0x2C                 ; start y coordinate
        MOV    r9,0x2F                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x36                 ; starting x coordinate
        MOV    r7,0x33                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x34                 ; starting x coordinate
        MOV    r7,0x2D                 ; start y coordinate
        MOV    r9,0x34                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x30                 ; starting x coordinate
        MOV    r7,0x20                 ; start y coordinate
        MOV    r9,0x24                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x30                 ; starting x coordinate
        MOV    r7,0x26                 ; start y coordinate
        MOV    r9,0x28                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x2C                 ; starting x coordinate
        MOV    r7,0x28                 ; start y coordinate
        MOV    r9,0x2B                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x2C                 ; starting x coordinate
        MOV    r7,0x2D                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x2E                 ; starting x coordinate
        MOV    r7,0x2A                 ; start y coordinate
        MOV    r9,0x2C                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x2E                 ; starting x coordinate
        MOV    r7,0x2F                 ; start y coordinate
        MOV    r9,0x31                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x26                 ; starting x coordinate
        MOV    r7,0x1E                 ; start y coordinate
        MOV    r9,0x22                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x1E                 ; starting x coordinate
        MOV    r7,0x2B                 ; start y coordinate
        MOV    r9,0x2E                 ; ending y coordinate
        CALL   draw_vertical_line

	    MOV    r8,0x1C                 ; starting x coordinate
        MOV    r7,0x2D                 ; start y coordinate
        MOV    r9,0x30                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x1A                 ; starting x coordinate
        MOV    r7,0x2F                 ; start y coordinate
        MOV    r9,0x34                 ; ending y coordinate
        CALL   draw_vertical_line

		MOV    r8,0x18                 ; starting x coordinate
        MOV    r7,0x31                 ; start y coordinate
        MOV    r9,0x35                 ; ending y coordinate
        CALL   draw_vertical_line
; ---------------------------------------------------------------------------------------

		; SINGLE DOTS

		MOV 	r8, 0x35 		; set x-component 
		MOV 	r7, 0x2A 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x37 		; set x-component 
		MOV 	r7, 0x2D 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x38 		; set x-component 
		MOV 	r7, 0x2D 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x39 		; set x-component 
		MOV 	r7, 0x28 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x3D 		; set x-component 
		MOV 	r7, 0x23 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x41 		; set x-component 
		MOV 	r7, 0x24 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x43 		; set x-component 
		MOV 	r7, 0x27 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x45 		; set x-component 
		MOV 	r7, 0x22 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x47 		; set x-component 
		MOV 	r7, 0x21 		; set y-component
		CALL	draw_dot 

		MOV 	r8, 0x08 		; set x-component 
		MOV 	r7, 0x21 		; set y-component
		CALL	draw_dot 
; --------------------------------
		; make entrance/exit
		MOV		r8, 0x05
		MOV		r7, 0x13
		CALL	Erase
		

		MOV		r8, 0x4A		; draw exit
		MOV		r7, 0x36
		MOV		r6, 0x13
		CALL	draw_dot

		RET
; ------------------------------------------------------------------------

; --- WIN ----------------------------------------------------------------

Draw_win:

		PUSH	r7
		PUSH	r8
		MOV		r6,0xCA
		
		; W
		MOV     r8,0x16                 ; starting x coordinate
        MOV     r7,0x1A                 ; start y coordinate
        MOV     r9,0x1E                 ; ending y coordinate
        CALL    draw_vertical_line

		MOV     r8,0x22                 ; starting x coordinate
        MOV     r7,0x1A                 ; start y coordinate
        MOV     r9,0x1F                 ; ending y coordinate
        CALL    draw_vertical_line

		MOV     r8,0x16                 ; starting x coordinate
        MOV     r7,0x20                 ; start y coordinate
        MOV     r9,0x22                 ; ending x coordinate
        CALL    draw_horizontal_line

		MOV 	 r8, 0x1C 		; set x-component 
		MOV 	 r7, 0x1A 		; set y-component
		CALL	 draw_dot 

		MOV 	 r8, 0x1C 		; set x-component 
		MOV 	 r7, 0x1C 		; set y-component
		CALL	 draw_dot 

		MOV 	 r8, 0x1C 		; set x-component 
		MOV 	 r7, 0x1E 		; set y-component
		CALL	 draw_dot 

		; I
		MOV      r8,0x2A                 ; starting x coordinate
        MOV      r7,0x1A                 ; start y coordinate
        MOV      r9,0x20                 ; ending y coordinate
        CALL     draw_vertical_line

		; N
		MOV      r8,0x34                 ; starting x coordinate
        MOV      r7,0x1A                 ; start y coordinate
        MOV      r9,0x3C                 ; ending x coordinate
        CALL     draw_horizontal_line

		MOV      r8,0x3C                 ; starting x coordinate
        MOV      r7,0x1C                 ; start y coordinate
        MOV      r9,0x20                 ; ending y coordinate
        CALL     draw_vertical_line

		MOV      r8,0x32                 ; starting x coordinate
        MOV      r7,0x1E                 ; start y coordinate
        MOV      r9,0x20                 ; ending y coordinate
        CALL     draw_vertical_line

		MOV    	 r8, 0x32 		; set x-component 
		MOV 	 r7, 0x1A 		; set y-component
		CALL	 draw_dot 

		MOV 	 r8, 0x32 		; set x-component 
		MOV 	 r7, 0x1C 		; set y-component
		CALL	 draw_dot 
		
		MOV		 r6, 0x00
		MOV		 r8, 0x4A		; erase dot
		MOV		 r7, 0x36
		CALL	 draw_dot

		POP		 r8
		POP		 r7

		BRN		 Return

.CSEG
.ORG 0x3FF  				; interrupt vector

VECTOR:	BRN		ISR








