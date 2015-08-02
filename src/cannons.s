
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
	STRUCT	cannons, CannonStruct, CANNONS_PER_PLAYER * 2
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
	; leftXpos = CANNON_SPACE_TO_EDGE
	; rightXpos = TERRAIN_WIDTH - CANNON_SPACE_TO_EDGE
	;
	; player1Count = CANNONS_PER_PLAYER
	; player2Count = CANNONS_PER_PLAYER
	;
	; for dp in cannons:
	;	y = Random(CANNON_MIN_SPACING, CANNON_MAX_SPACING)
	;	dp->alive = true
	;	dp->angle = CANNON_DEFAULT_ANGLE
	;	dp->power = CANNON_DEFAULT_POWER
	;	dp->player = player
	;
	;	if player == 0:
	;		player = 1
	;		leftXpos += y
	;		dp->xPos = leftXpos
	;	else:
	;		player = 0
	;		rightXpos -= y
	;		dp->xPos = rightXpos
	;
	;	dp->yPos = Terrain__GetTopmostYposOfXpos(dp->xPos)

tmp_player		= tmp1
tmp_leftXpos		= tmp2
tmp_rightXpos		= tmp3

	STZ	tmp_player

	LDX	#CANNON_SPACE_TO_EDGE
	STX	tmp_leftXpos

	LDX	#TERRAIN_WIDTH - CANNON_SPACE_TO_EDGE
	STX	tmp_rightXpos

	LDA	#CANNONS_PER_PLAYER
	STA	player1Count
	STA	player2Count

	REP	#$30
.A16
	LDA	#cannons

	REPEAT
		TCD

		SEP	#$20
.A8
		LDX	#CANNON_MIN_SPACING
		LDY	#CANNON_MAX_SPACING
		JSR	Random__Rnd_U16X_U16Y

		LDA	#1
		STA	z:CannonStruct::alive
		LDA	#CANNON_DEFAULT_ANGLE
		STA	z:CannonStruct::angle
		LDA	#CANNON_DEFAULT_POWER
		STA	z:CannonStruct::power

		LDA	tmp_player
		STA	z:CannonStruct::player
		IF_ZERO
			INC
			STA	tmp_player

			REP	#$20
.A16
			TYA
			ADD	tmp_leftXpos
			STA	tmp_leftXpos
			STA	z:CannonStruct::xPos
		ELSE
.A8
			STZ	tmp_player

			REP	#$20
.A16
			TYA
			RSB16	tmp_rightXpos
			STA	tmp_rightXpos
			STA	z:CannonStruct::xPos
		ENDIF
.A16

		; A = xPos
		JSR	Terrain__GetTopmostYposOfXpos
		STA	z:CannonStruct::yPos

		TDC
		ADD	#.sizeof(CannonStruct)
		CMP	#cannons_End
	UNTIL_GE

	SEP	#$20
.A8
	RTS


ENDMODULE

