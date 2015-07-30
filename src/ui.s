
.include "ui.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"
.include "routines/block.h"
.include "routines/metasprite.h"

.include "terrain.h"
.include "cannons.h"
.include "gameloop.h"
.include "resources.h"
.include "vram.h"

MODULE Ui

SCREEN_WIDTH		= 256
SCREEN_HEIGHT		= 224

CANNON_WIDTH		= 3
CANNON_HEIGHT		= 5	; 2 for body, 3 for arm

CANNON_XOFFSET		= 1
CANNON_YOFFSET		= 2

CANNON_SPRITE_ORDER	= 2	; in front of BG1-BG4, behind explosions
EXPLOSIONS_SPRITE_ORDER = 3	; in front of everything
FLAGS_SPRITE_ORDER	= 3	; in front of everything
TEXT_SPRITE_ORDER	= 3	; in front of everything

RED_CANNON_SPRITE	= 1
RED_DEAD_CANNON_SPRITE	= 2
RED_CANNONBALL_SPRITE	= 3
RED_FLAG_SPRITE		= 4
BLUE_CANNON_SPRITE	= RED_CANNON_SPRITE + 16
BLUE_DEAD_CANNON_SPRITE	= RED_DEAD_CANNON_SPRITE + 16
BLUE_CANNONBALL_SPRITE	= RED_CANNONBALL_SPRITE + 16
BLUE_FLAG_SPRITE	= RED_FLAG_SPRITE + 16

FLAG_XPOS		= 24
FLAG_YPOS		= 24
FLAG_XSPACING		= 8

PRESS_START_XPOS	= (SCREEN_WIDTH - 12 * 8) / 2
PRESS_START_YPOS	= FLAG_YPOS - 3

.rodata
LABEL	StateTable
	.addr	AttractMode
	.addr	ScrollToCannon
	.addr	SelectAngle
	.addr	SelectPower
	.addr	Cannonball
	.addr	Explosion
	.addr	GameOver

.code


.A8
.I16
ROUTINE Init
	TransferToVramLocation	Resources__Sprites_Tiles,	CANNONS_OAM_TILES
	TransferToCgramLocation	Resources__Sprites_Palette,	128

	MetaSprite_Init

	RTS



.A8
.I16
ROUTINE Update
	JSR	MetaSprite__InitLoop

	JSR	DrawCannons
	JSR	DrawFlags

	LDX	Gameloop__state
	JSR	(.loword(StateTable), X)

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


.A8
.I16
ROUTINE SelectAngle
	RTS


.A8
.I16
ROUTINE SelectPower
	RTS


.A8
.I16
ROUTINE Cannonball
	RTS


.A8
.I16
ROUTINE	Explosion
	RTS


.A8
.I16
ROUTINE GameOver
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

	STZ	MetaSprite__size
	
	REP	#$30
.A16
	LDA	#Cannons__cannons

	REPEAT
		TCD

		.assert CANNON_XOFFSET = 1, error, "bad value"
		LDA	z:CannonStruct::xPos
		DEC
		SUB	Terrain__hOffset

		CMP	#SCREEN_WIDTH + CANNON_WIDTH
		BSGE	_DrawCannons_Continue
		CMP	#.loword(-CANNON_WIDTH)
		BSLT	_DrawCannons_Continue

		STA	MetaSprite__xPos


		.assert CANNON_YOFFSET = 2, error, "bad value"
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


.segment "BANK1"


.exportzp MetaSpriteLayoutBank = .bankbyte(*)

PressStartMetaSprite:
	.byte 6

	.repeat 6, i
		.byte	i * 16
		.byte	0
		.word	4 * 16 + i * 2 + TEXT_SPRITE_ORDER << OAM_CHARATTR_ORDER_SHIFT
		.byte	$FF
	.endrepeat


ENDMODULE

