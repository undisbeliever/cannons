
.include "cannons.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"
.include "routines/random.h"
.include "routines/math.h"
.include "routines/pixelbuffer.h"

.include "terrain.h"

;; Spacing between the edge of the map and the cannons
CONFIG CANNON_SPACE_TO_EDGE, 25

;; The minimum and maximum spacing between the player's cannons
CONFIG CANNON_MIN_SPACING, 15
CONFIG CANNON_MAX_SPACING, TERRAIN_WIDTH / 3 / CANNONS_PER_PLAYER

;; Default values for the cannons
CONFIG	CANNON_DEFAULT_ANGLE, 45
CONFIG	CANNON_DEFAULT_POWER, 100

.assert CANNON_MAX_SPACING * CANNONS_PER_PLAYER + CANNON_SPACE_TO_EDGE * 2 < TERRAIN_WIDTH, error, "CANNON_MAX_SPACING too large"
.assert CANNON_MIN_SPACING < CANNON_MAX_SPACING, error, "CANNON_MIN_SPACING must be smaller than CANNON_MAX_SPACING"
.assert CANNON_MIN_SPACING > 3, error, "CANNON_MIN_SPACING too small"


MODULE Cannons

.segment "SHADOW"
LABEL	cannons

	STRUCT	player1Cannons, CannonStruct, CANNONS_PER_PLAYER
LABEL player1Cannons_End

	STRUCT	player2Cannons, CannonStruct, CANNONS_PER_PLAYER
LABEL player2Cannons_End

cannons_End:

	BYTE	player1Count
	BYTE	player2Count

	WORD	tmp1
	WORD	tmp2
	WORD	tmp3


.code

; DB = $7E
.A8
.I16
ROUTINE SpawnCannons
	; player = 0
	; xPpos = CANNON_SPACE_TO_EDGE
	;
	; player1Count = CANNONS_PER_PLAYER
	; player2Count = CANNONS_PER_PLAYER
	;
	; for dp in player1Cannons:
	;	dp->player = 0
	;	dp->alive = true
	;	dp->angle = CANNON_DEFAULT_ANGLE
	;	dp->power = CANNON_DEFAULT_POWER
	;
	;	y = Random(CANNON_MIN_SPACING, CANNON_MAX_SPACING)
	;	xPos += y
	;	dp->xPos = xPos
	;	dp->yPos = Terrain__GetTopmostYposOfXpos(dp->xPos)
	;
	;
	; xPos = TERRAIN_WIDTH - CANNON_SPACE_TO_EDGE
	;
	; for dp in player2Cannons:
	;	dp->player = 1
	;	dp->alive = true
	;	dp->angle = CANNON_DEFAULT_ANGLE
	;	dp->power = CANNON_DEFAULT_POWER
	;
	;	y = Random(CANNON_MIN_SPACING, CANNON_MAX_SPACING)
	;	xPos -= y
	;	dp->xPos = xPos
	;	dp->yPos = Terrain__GetTopmostYposOfXpos(dp->xPos)

tmp_player		= tmp1
tmp_xPos		= tmp2

	STZ	tmp_player

	LDX	#CANNON_SPACE_TO_EDGE
	STX	tmp_xPos

	LDA	#CANNONS_PER_PLAYER
	STA	player1Count
	STA	player2Count

	REP	#$30
.A16
	LDA	#player1Cannons

	REPEAT
		TCD

		SEP	#$20
.A8
		STZ	z:CannonStruct::player

		LDA	#1
		STA	z:CannonStruct::alive
		LDA	#CANNON_DEFAULT_ANGLE
		STA	z:CannonStruct::angle
		LDA	#CANNON_DEFAULT_POWER
		STA	z:CannonStruct::power

		LDX	#CANNON_MIN_SPACING
		LDY	#CANNON_MAX_SPACING
		JSR	Random__Rnd_U16X_U16Y

		REP	#$20
.A16
		TYA
		ADD	tmp_xPos
		STA	tmp_xPos
		STA	z:CannonStruct::xPos

		; A = xPos
		JSR	Terrain__GetTopmostYposOfXpos
		STA	z:CannonStruct::yPos

		TDC
		ADD	#.sizeof(CannonStruct)
		CMP	#player1Cannons_End
	UNTIL_GE



	LDX	#TERRAIN_WIDTH - CANNON_SPACE_TO_EDGE
	STX	tmp_xPos

	LDA	#player2Cannons

	REPEAT
		TCD

		SEP	#$20
.A8
		LDA	#1
		STA	z:CannonStruct::player
		STA	z:CannonStruct::alive
		LDA	#CANNON_DEFAULT_ANGLE
		STA	z:CannonStruct::angle
		LDA	#CANNON_DEFAULT_POWER
		STA	z:CannonStruct::power

		LDX	#CANNON_MIN_SPACING
		LDY	#CANNON_MAX_SPACING
		JSR	Random__Rnd_U16X_U16Y

		REP	#$20
.A16
		TYA
		RSB16	tmp_xPos
		STA	tmp_xPos
		STA	z:CannonStruct::xPos

		; A = xPos
		JSR	Terrain__GetTopmostYposOfXpos
		STA	z:CannonStruct::yPos

		TDC
		ADD	#.sizeof(CannonStruct)
		CMP	#player2Cannons_End
	UNTIL_GE

	SEP	#$20
.A8
	RTS



; IN: X/Y the position
; OUT: X of the address
.A16
.I16
ROUTINE CheckCollision
tmp_x	= tmp1
tmp_y	= tmp2

	STX	tmp_x
	STY	tmp_y

	LDX	#cannons

	REPEAT
		LDA	a:CannonStruct::alive, X
		IF_BIT	#$00FF
			LDA	a:CannonStruct::xPos, X
			SUB	#-CANNON_XOFFSET
			CMP	tmp_x
			IF_LT
				ADD	#CANNON_WIDTH
				CMP	tmp_x
				IF_GE
					LDA	a:CannonStruct::yPos, X
					SUB	#-CANNON_YOFFSET
					CMP	tmp_y
					IF_LT
						ADD	#CANNON_WIDTH
						CMP	tmp_y
						IF_GE
							RTS
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDIF

		TXA
		ADD	#.sizeof(CannonStruct)
		TAX
		CPX	#cannons_End
	UNTIL_GE

	LDX	#0

	RTS


; IN: X - cannon
; OUT: A - number of cannons left for the player
.A8
.I16
ROUTINE MarkCannonDead
	; if cannon->alive:
	;	cannon->alive = false
	;	if cannon->player == 0
	;		player1Count--
	;	else
	;		player2Count--

	LDA	a:CannonStruct::alive, X
	IF_NOT_ZERO
		STZ	a:CannonStruct::alive, X

		LDA	a:CannonStruct::player, X
		IF_ZERO
			DEC	player1Count
		ELSE
			DEC	player2Count
		ENDIF
	ENDIF

	RTS

ENDMODULE

