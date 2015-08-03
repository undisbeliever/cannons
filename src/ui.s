
.include "ui.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"
.include "routines/block.h"
.include "routines/math.h"
.include "routines/metasprite.h"

.include "terrain.h"
.include "cannonball.h"
.include "cannons.h"
.include "gameloop.h"
.include "resources.h"
.include "vram.h"

MODULE Ui

SCREEN_WIDTH		= 256
SCREEN_HEIGHT		= 224

CANNON_AIM_COUNT	= 3
CANNON_AIM_MULTIPLIER   = 2 * SUBFRAMES
CANNON_AIM_TILE		= 16

CANNON_SPRITE_ORDER	= 2	; in front of BG1-BG4, behind explosions
CANNON_AIM_SPRITE_ORDER	= 3	; in front of everything
CANNONBALL_SPRITE_ORDER = 3	; in front of everything
EXPLOSIONS_SPRITE_ORDER = 3	; in front of everything
FLAGS_SPRITE_ORDER	= 3	; in front of everything
TEXT_ORDER		= 3	; in front of everything

RED_CANNON_SPRITE	= 1
RED_DEAD_CANNON_SPRITE	= 2
RED_CANNONBALL_SPRITE	= 3
RED_FLAG_SPRITE		= 4
BLUE_CANNON_SPRITE	= RED_CANNON_SPRITE + 16
BLUE_DEAD_CANNON_SPRITE	= RED_DEAD_CANNON_SPRITE + 16
BLUE_CANNONBALL_SPRITE	= RED_CANNONBALL_SPRITE + 16
BLUE_FLAG_SPRITE	= RED_FLAG_SPRITE + 16

NUMBER_BOTTOM_OFFSET	= 16
NUMBER_BOTTOM_YOFFSET	= 8
NUMBER_XSPACING		= 9
NUMBER_TILE_OFFSET	= 6
NUMBER_DRAW_DIGITS	= 3

FLAG_XPOS		= 24
FLAG_YPOS		= 24
FLAG_XSPACING		= 8

N_EXPLOSION_FRAMES	= 8
ANIMATION_FRAME_DELAY	= 2

EXPLOSION_SPRITE	= $60
EXPLOSION_XOFFSET	= -8
EXPLOSION_YOFFSET	= -8

SMALL_EXPLOSION_SPRITE	= $80
SMALL_EXPLOSION_XOFFSET	= -4
SMALL_EXPLOSION_YOFFSET	= -4


TEXT_YPOS		= FLAG_YPOS - 3

PRESS_START_XPOS	= (SCREEN_WIDTH - 12 * 8) / 2
PRESS_START_YPOS	= TEXT_YPOS

ANGLE_XPOS		= (SCREEN_WIDTH - 8 * NUMBER_XSPACING - 32) / 2
ANGLE_YPOS		= TEXT_YPOS
ANGLE_SELECTED_PALETTE	= 1
ANGLE_NORMAL_PALETTE	= 0

POWER_XPOS		= ANGLE_XPOS + 5 * NUMBER_XSPACING
POWER_YPOS		= TEXT_YPOS
POWER_SELECTED_PALETTE	= 1
POWER_NORMAL_PALETTE	= 0

ANGLE_DEGREES_TILE	= $20


.rodata
LABEL	StateTable
	.addr	AttractMode
	.addr	ScrollToCannon
	.addr	SelectAngle
	.addr	SelectPower
	.addr	Cannonball
	.addr	Explosion
	.addr	GameOver


.segment "SHADOW"
	BYTE	animationComplete
	WORD	animation_xPos
	WORD	animation_yPos
	ADDR	animation_framePtr
	BYTE	animation_framesLeft
	BYTE	animation_frameDelay

	WORD	tmp1
	WORD	tmp2
	WORD	tmp3


.code


.A8
.I16
ROUTINE Init
	TransferToVramLocation	Resources__Sprites_Tiles,	CANNONS_OAM_TILES
	TransferToCgramLocation	Resources__Sprites_Palette,	128

	LDX	#0
	STX	animation_framePtr

	MetaSprite_Init

	RTS



; IN: X/Y = position
.A8
.I16
ROUTINE	StartSmallExplosionAnimation
	STX	animation_xPos
	STY	animation_yPos

	LDX	#.loword(SmallExplosionAnimation)
	STX	animation_framePtr

	LDA	#N_EXPLOSION_FRAMES
	STA	animation_framesLeft

	LDA	#ANIMATION_FRAME_DELAY
	STA	animation_frameDelay

	STZ	animationComplete

	RTS



; IN: X/Y = position
.A8
.I16
ROUTINE	StartExplosionAnimation
	STX	animation_xPos
	STY	animation_yPos

	LDX	#.loword(ExplosionAnimation)
	STX	animation_framePtr

	LDA	#N_EXPLOSION_FRAMES
	STA	animation_framesLeft

	LDA	#ANIMATION_FRAME_DELAY
	STA	animation_frameDelay

	STZ	animationComplete

	RTS



.A8
.I16
ROUTINE Update
	LDX	Gameloop__state
	CPX	#GameState::CANNONBALL
	IF_EQ
		LDX	CannonBall__xPos + 2
		LDY	CannonBall__yPos + 2
		JSR	Terrain__CenterOnPosition
	ENDIF

	JSR	MetaSprite__InitLoop

	JSR	DrawCannons
	JSR	DrawFlags

	LDX	Gameloop__state
	JSR	(.loword(StateTable), X)

	JSR	ProcessAnimation

	JMP	MetaSprite__FinalizeLoop


.A8
.I16
ROUTINE	AttractMode
	LDY	#PRESS_START_XPOS
	STY	MetaSprite__xPos
	LDY	#PRESS_START_YPOS
	STY	MetaSprite__yPos

	LDY	#0
	LDX	#.loword(PressStartMetaSprite)
	JMP	MetaSprite__ProcessMetaSprite_Y


.A8
.I16
ROUTINE ScrollToCannon
	RTS


; DP = cannon
.A8
.I16
ROUTINE SelectAngle
	JSR	DrawAimCrosshairs

	LDY	#ANGLE_SELECTED_PALETTE
	JSR	DrawAngle

	LDY	#POWER_NORMAL_PALETTE
	JSR	DrawPower

	RTS


; DP = cannon
.A8
.I16
ROUTINE SelectPower
	JSR	DrawAimCrosshairs

	LDY	#ANGLE_NORMAL_PALETTE
	JSR	DrawAngle

	LDY	#POWER_SELECTED_PALETTE
	JSR	DrawPower

	RTS



; DP = cannon
.A8
.I16
ROUTINE Cannonball
	; if dp->player == 0:
	;	charAttr = RED_CANNONBALL_SPRITE + CANNONBALL_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
	; else:
	;	charAttr = BLUE_CANNONBALL_SPRITE + CANNONBALL_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
	;
	; xPos = int(Cannonball__cannonBall.xPos) - Terrain__hOffset
	; yPos = int(Cannonball__cannonBall.xPos) - Terrain__vOffset
	; size = 0
	; MetaSprite__ProcessSprite(xPos, yPos, charAttr, size)

	REP	#$20
.A16

	LDA	z:CannonStruct::player
	AND	#$00FF
	IF_ZERO
		LDA	#RED_CANNONBALL_SPRITE + CANNONBALL_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
	ELSE
		LDA	#BLUE_CANNONBALL_SPRITE + CANNONBALL_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
	ENDIF
	STA	MetaSprite__charAttr

	LDA	CannonBall__xPos + 2
	SUB	Terrain__hOffset
	STA	MetaSprite__xPos

	LDA	CannonBall__yPos + 2
	SUB	Terrain__vOffset
	STA	MetaSprite__yPos

	SEP	#$20
.A8

	STZ	MetaSprite__size
	JSR	MetaSprite__ProcessSprite

	RTS



; DP = cannon
.A8
.I16
ROUTINE	Explosion
	RTS


; DP = cannon
.A8
.I16
ROUTINE GameOver
	RTS



;; Process the animation.
.A8
.I16
ROUTINE ProcessAnimation
	LDX	animation_framePtr
	IF_NOT_ZERO

		REP	#$30
.A16
		LDA	animation_xPos
		SUB	Terrain__hOffset
		STA	MetaSprite__xPos


		LDA	animation_yPos
		SUB	Terrain__vOffset
		STA	MetaSprite__yPos


		LDA	f:MetaSpriteLayoutBank << 16, X
		TAX

		SEP	#$20
.A8

		LDY	#0
		JSR	MetaSprite__ProcessMetaSprite_Y


		DEC	animation_frameDelay
		IF_ZERO
			DEC	animation_framesLeft
			IF_ZERO
				LDA	#1
				STA	animationComplete

				LDX	#0
			ELSE
				LDX	animation_framePtr
				INX
				INX
			ENDIF
			STX	animation_framePtr

			LDA	#ANIMATION_FRAME_DELAY
			STA	animation_frameDelay
		ENDIF
	ENDIF

	RTS



;; Draws the cannons using metasprites
.A8
.I16
ROUTINE DrawCannons
	; size = 0
	; for dp in cannons:
	;	xPos = dp->xPos - Terrain__hOffset - CANNON_XOFFSET
	;	if xPos < - CANNON_WIDTH || xPos > SCREEN_WIDTH + CANNON_WIDTH
	;		continue
	;	yPos = dp->yPos - Terrain__vOffset - CANNON_YOFFSET
	;	if yPos < - CANNON_HEIGHT || yPos > SCREEN_HEIGHT + CANNON_HEIGHT
	;		continue
	;
	;	if dp->player == 0
	;		charAttr = RED_CANNON_SPRITE + CANNON_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
	;	else
	;		charAttr = RED_CANNON_SPRITE + CANNON_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
	;
	;	if dp->alive == 0:
	;		charAttr++
	;
	;	MetaSprite__ProcessSprite(xPos, yPos, charAttr, size)

	PHD
	STZ	MetaSprite__size
	
	REP	#$30
.A16
	LDA	#Cannons__cannons

	REPEAT
		TCD

		.assert CANNON_XOFFSET = -1, error, "bad value"
		LDA	z:CannonStruct::xPos
		DEC
		SUB	Terrain__hOffset

		CMP	#SCREEN_WIDTH + CANNON_WIDTH
		BSGE	_DrawCannons_Continue
		CMP	#.loword(-CANNON_WIDTH)
		BSLT	_DrawCannons_Continue

		STA	MetaSprite__xPos


		.assert CANNON_YOFFSET = -2, error, "bad value"
		LDA	z:CannonStruct::yPos
		DEC
		DEC
		SUB	Terrain__vOffset

		CMP	#SCREEN_HEIGHT + CANNON_HEIGHT
		BSGE	_DrawCannons_Continue
		CMP	#.loword(-CANNON_HEIGHT)
		BSLT	_DrawCannons_Continue

		STA	MetaSprite__yPos

		LDX	MetaSprite__xPos
		LDY	MetaSprite__yPos

		LDA	z:CannonStruct::player
		IF_NOT_BIT #$FF
			LDA	#RED_CANNON_SPRITE + CANNON_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
		ELSE
			LDA	#BLUE_CANNON_SPRITE + CANNON_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
		ENDIF
		STA	MetaSprite__charAttr

		LDA	z:CannonStruct::alive
		IF_NOT_BIT #$FF
			; cannon is dead

			.assert RED_CANNON_SPRITE + 1 = RED_DEAD_CANNON_SPRITE, error, "invalid value"
			INC	MetaSprite__charAttr
		ENDIF

		SEP	#$20
.A8
		JSR	MetaSprite__ProcessSprite


_DrawCannons_Continue:
		REP	#$20
.A16
		TDC
		ADD	#.sizeof(CannonStruct)
		CMP	#Cannons__cannons + Cannons__cannons__size
	UNTIL_GE

	SEP	#$20

	PLD
	RTS



;; Draws the flags using metasprites
.A8
.I16
ROUTINE DrawFlags
	LDY	#RED_FLAG_SPRITE | (FLAGS_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT)
	STY	MetaSprite__charAttr
	LDY	#FLAG_XPOS
	STY	MetaSprite__xPos
	LDY	#FLAG_YPOS
	STY	MetaSprite__yPos
	STZ	MetaSprite__size

	LDA	Cannons__player1Count
	IF_NOT_ZERO
		REPEAT
		PHA

		JSR	MetaSprite__ProcessSprite

		LDA	MetaSprite__xPos
		ADD	#FLAG_XSPACING
		STA	MetaSprite__xPos

		PLA
		DEC
		UNTIL_ZERO
	ENDIF


	LDY	#BLUE_FLAG_SPRITE | (FLAGS_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT)
	STY	MetaSprite__charAttr
	LDY	#SCREEN_WIDTH - FLAG_XPOS - FLAG_XSPACING
	STY	MetaSprite__xPos
	LDY	#FLAG_YPOS
	STY	MetaSprite__yPos
	STZ	MetaSprite__size

	LDA	Cannons__player2Count
	IF_NOT_ZERO
		REPEAT
		PHA

		JSR	MetaSprite__ProcessSprite

		LDA	MetaSprite__xPos
		SUB	#FLAG_XSPACING
		STA	MetaSprite__xPos

		PLA
		DEC
		UNTIL_ZERO
	ENDIF

	RTS



; Y = palette
; DP = selectedCannon
.A8
.I16
ROUTINE	DrawAngle
	LDX	#ANGLE_XPOS
	STX	MetaSprite__xPos
	LDX	#ANGLE_YPOS
	STX	MetaSprite__yPos

	LDA	z:CannonStruct::angle
	JSR	DrawNumber_8A

	LDA	#ANGLE_DEGREES_TILE
	STA	MetaSprite__charAttr
	JSR	MetaSprite__ProcessSprite

	RTS



; Y = palette
; DP = selectedCannon
.A8
.I16
ROUTINE	DrawPower
	LDX	#POWER_XPOS
	STX	MetaSprite__xPos
	LDX	#POWER_YPOS
	STX	MetaSprite__yPos

	LDA	z:CannonStruct::power
	JSR	DrawNumber_8A

	STZ	MetaSprite__charAttr
	LDX	#.loword(PowerMetaSprite)
	JSR	MetaSprite__ProcessMetaSprite

	RTS



; DP = selectedCannon
.A8
.I16
ROUTINE DrawAimCrosshairs
	; CannonBall__SetVelocity()
	; cannonball.xVecl *= CANNON_AIM_MULTIPLIER
	; cannonball.yVecl *= CANNON_AIM_MULTIPLIER
	;
	; size = 0
	; charAttr = CANNON_AIM_TILE + CANNON_AIM_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
	; xPos = dp->xPos - Terrain__hOffset - CANNON_LAUNCH_XOFFSET
	; yPos = dp->yPos - Terrain__vOffset - CANNON_LAUNCH_YOFFSET
	;
	; for i = CANNON_AIM_COUNT to 0:
	;	xPos += cannonball.xVecl	// include fractional component
	;	yPos += cannonball.yVecl	// include fractional component

tmp_counter	= tmp1
tmp_xFractional	= tmp2
tmp_yFractional = tmp3

	JSR	CannonBall__SetVelocity

	STZ	MetaSprite__size
	
	REP	#$30
.A16
	.assert CANNON_AIM_MULTIPLIER = 16, error, "Bad Code"
	.repeat 4
		ASL	CannonBall__xVecl
		ROL	CannonBall__xVecl + 2
		ASL	CannonBall__yVecl
		ROL	CannonBall__yVecl + 2
	.endrepeat

	LDA	#CANNON_AIM_TILE + CANNON_AIM_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
	STA	MetaSprite__charAttr

	.assert CANNON_LAUNCH_XOFFSET = 0, error, "bad code"
	LDA	z:CannonStruct::xPos
	SUB	Terrain__hOffset
	STA	MetaSprite__xPos


	.assert CANNON_LAUNCH_YOFFSET = -3, error, "bad code"
	LDA	z:CannonStruct::yPos
	DEC
	DEC
	DEC
	SUB	Terrain__vOffset
	STA	MetaSprite__yPos

	LDA	#CANNON_AIM_COUNT
	STA	tmp_counter

	STZ	tmp_xFractional
	STZ	tmp_yFractional

	REPEAT
		REP	#$30
.A16
		CLC
		LDA	tmp_xFractional
		ADC	CannonBall__xVecl
		STA	tmp_xFractional

		LDA	MetaSprite__xPos
		ADC	CannonBall__xVecl + 2
		STA	MetaSprite__xPos


		CLC
		LDA	tmp_yFractional
		ADC	CannonBall__yVecl
		STA	tmp_yFractional

		LDA	MetaSprite__yPos
		ADC	CannonBall__yVecl + 2
		STA	MetaSprite__yPos

		SEP	#$30
.A8
		JSR	MetaSprite__ProcessSprite

		DEC	tmp_counter
	UNTIL_ZERO

	SEP	#$20
.A8

	RTS



; MetaSprite__xPos = xPos
; MetaSprite__yPos = yPos
; Y = palete
; A = number
; OUT: MetaSprite__xPos = end of text
.A8
.I16
ROUTINE DrawNumber_8A

tmp_charAttr	= tmp1
tmp_endOfXpos	= tmp2
tmp_oldYpos	= tmp3


	REP	#$30
.A16
	AND	#$00FF
	TAX

	.assert OAM_CHARATTR_PALETTE_SHIFT = 9, error, "Bad Value"
	TYA
	AND	#7
	XBA
	ASL
	ORA	#NUMBER_TILE_OFFSET + TEXT_ORDER << OAM_CHARATTR_ORDER_SHIFT
	STA	tmp_charAttr

	LDA	MetaSprite__yPos
	STA	tmp_oldYpos

	LDA	MetaSprite__xPos
	ADD	#NUMBER_XSPACING * (NUMBER_DRAW_DIGITS - 1)
	STA	MetaSprite__xPos
	ADD	#NUMBER_XSPACING
	STA	tmp_endOfXpos

	TXY

	SEP	#$20
.A8
	STZ	MetaSprite__size

	REPEAT
		; Y = number
		LDA	#10
		JSR	Math__Divide_U16Y_U8A

		PHY

		REP	#$30
.A16
		TXA
		ADD	tmp_charAttr
		STA	MetaSprite__charAttr

		SEP	#$20
.A8

		JSR	MetaSprite__ProcessSprite

		LDA	MetaSprite__yPos
		ADD	#NUMBER_BOTTOM_YOFFSET
		STA	MetaSprite__yPos

		LDA	MetaSprite__charAttr
		ADD	#NUMBER_BOTTOM_OFFSET
		STA	MetaSprite__charAttr

		JSR	MetaSprite__ProcessSprite

		; Restore old yPos
		LDA	tmp_oldYpos
		STA	MetaSprite__yPos

		LDA	MetaSprite__xPos
		SUB	#NUMBER_XSPACING
		STA	MetaSprite__xPos

		PLY
	UNTIL_ZERO

	LDX	tmp_endOfXpos
	STX	MetaSprite__xPos

	RTS



.segment "BANK1"


.exportzp MetaSpriteLayoutBank = .bankbyte(*)

PressStartMetaSprite:
	.byte 6

	.repeat 6, i
		.byte	i * 16
		.byte	0
		.word	$40 + i * 2 + TEXT_ORDER << OAM_CHARATTR_ORDER_SHIFT
		.byte	$FF
	.endrepeat

PowerMetaSprite:
	.byte	2

	; Do not show ORDER - uses palette from DrawNumber_8A
	.repeat 2, i
		.byte	i * 16
		.byte	0
		.word	$21 + i * 2
		.byte	$FF
	.endrepeat


ExplosionAnimation:
	.repeat	N_EXPLOSION_FRAMES, i
		.addr	.ident(.sprintf("ExplosionFrame%d", i))
	.endrepeat


	.repeat	N_EXPLOSION_FRAMES, i
		.ident(.sprintf("ExplosionFrame%d", i)):
			.byte	1
			.byte	.lobyte(EXPLOSION_XOFFSET)
			.byte	.lobyte(EXPLOSION_YOFFSET)
			.word	EXPLOSION_SPRITE + 2 * i + EXPLOSIONS_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
			.byte	$FF	; large
	.endrepeat


SmallExplosionAnimation:
	.repeat	N_EXPLOSION_FRAMES, i
		.addr	.ident(.sprintf("SmallExplosionFrame%d", i))
	.endrepeat


	.repeat	N_EXPLOSION_FRAMES, i
		.ident(.sprintf("SmallExplosionFrame%d", i)):
			.byte	1
			.byte	.lobyte(SMALL_EXPLOSION_XOFFSET)
			.byte	.lobyte(SMALL_EXPLOSION_YOFFSET)
			.word	SMALL_EXPLOSION_SPRITE + 2 * i + EXPLOSIONS_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
			.byte	$00	; small
	.endrepeat


ENDMODULE

