
.include "cannonball.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"
.include "routines/random.h"
.include "routines/math.h"
.include "routines/pixelbuffer.h"

.include "cannons.h"
.include "terrain.h"


MODULE CannonBall

.segment "SHADOW"
	UINT32	xPos
	UINT32	yPos

	UINT32	xVecl
	UINT32	yVecl


	WORD	tmp1
	WORD	tmp2
	WORD	tmp_subframeCounter

.code


; DP = cannon
ROUTINE SetPosition
	; xPos = dp->xPos - CANNON_LAUNCH_XOFFSET
	; yPos = dp->yPos - CANNON_LAUNCH_YOFFSET

	PHP
	REP	#$30
.A16

	.assert CANNON_LAUNCH_XOFFSET = 0, error, "bad code"
	LDA	z:CannonStruct::xPos
	STA	xPos + 2
	STZ	xPos

	.assert CANNON_LAUNCH_YOFFSET = -3, error, "bad code"
	LDA	z:CannonStruct::yPos
	DEC
	DEC
	DEC
	STA	yPos + 2
	STZ	yPos

	PLP

	RTS



; DP = cannon
; OUT: s xVecl, yVecl
.A8
.I16
ROUTINE SetVelocity
	; yVecl = - sineTable[angle] * dp->power
	;
	; xVecl = - sineTable[angle + 90] * dp->power
	;
	; if dp->player != 0:
	;	xVecl = -xVecl
	;

.assert CANNON_MIN_ANGLE >= 0, error, "Bad Assumption"
.assert CANNON_MAX_ANGLE + 90 < 360, error, "Bad Assumption"

tmp_angle	= tmp1
tmp_convertedPow = tmp2

	REP	#$30
.A16

	LDA	z:CannonStruct::angle
	AND	#$00FF
	ASL
	STA	tmp_angle
	TAX

	LDA	f:SineTable, X
	TAX

	; power = 0:0:8 - convert to 1:9:9
	LDA	z:CannonStruct::power
	AND	#$FF
	ASL
	STA	tmp_convertedPow

	TAY

	SEP	#$20
.A8
	JSR	Math__Multiply_S16Y_S16X_S32XY

	REP	#$20
.A16
	; product32 = 1:0:15 * 1:9:9 = 1:7:24
	; convert to 1:15:16

	LDA	Math__product32 + 1
	STA	yVecl

	; sign extend
	LDA	Math__product32 + 3
	IF_BIT	#$0080
		ORA	#$FF00
	ELSE
		AND	#$00FF
	ENDIF
	STA	yVecl + 2

	NEG32	yVecl


	LDA	tmp_angle
	ADD	#90 * 2
	TAX

	LDA	f:SineTable, X
	TAX

	LDY	tmp_convertedPow

	SEP	#$20
.A8
	JSR	Math__Multiply_S16Y_S16X_S32XY

	REP	#$20
.A16
	; product32 = 1:0:15 * 1:9:9 = 1:7:24
	; convert to 1:15:16

	LDA	Math__product32 + 1
	STA	xVecl

	; sign extend
	LDA	Math__product32 + 3
	IF_BIT	#$0080
		ORA	#$FF00
	ELSE
		AND	#$00FF
	ENDIF
	STA	xVecl + 2

	LDA	z:CannonStruct::player
	AND	#$FF
	IF_NOT_ZERO
		NEG32	xVecl
	ENDIF

	SEP	#$20
.A8

	RTS



.A16
.I16
ROUTINE Update
	; for i = SUBFRAMES to 0:
	;	r, X = UpdateSubframe()
	;	if r != #CannonBallState::FLYING
	;		return r, X

	LDA	#SUBFRAMES
	STA	tmp_subframeCounter
	REPEAT
		JSR	UpdateSubframe

		.assert CannonBallState::FLYING = 0, error, "Bad assumption"

		IF_NOT_ZERO
			RTS
		ENDIF

		DEC	tmp_subframeCounter
	UNTIL_ZERO

	LDA	#CannonBallState::FLYING
	RTS



.A16
.I16
ROUTINE UpdateSubframe
	; xPos += xVecl
	; yPos += yVecl
	;
	; if xPos < 0 | xPos >= TERRAIN_WIDTH | yPos >= TERRAIN_HEIGHT:
	;	return CannonBallState::OUT_OF_BOUNDS
	;
	; yVecl += CANNONBALL_GRAVITY
	;
	; X = Cannon__CheckCollision(xPos, yPos)
	;
	; if X != NULL
	;	return CannonBallState::HIT_CANNON, X
	; else if Terrain__IsPixelOccupied(xPos, yPos)
	;	return CannonBallState::HIT_GROUND
	; else:
	; 	return CannonBallState::FLYING

	CLC
	LDA	xPos
	ADC	xVecl
	STA	xPos
	LDA	xPos + 2
	ADC	xVecl + 2
	STA	xPos + 2

	BMI	Update_OutOfBounds
	CMP	#TERRAIN_WIDTH
	BPL	Update_OutOfBounds


	CLC
	LDA	yPos
	ADC	yVecl
	STA	yPos
	LDA	yPos + 2
	ADC	yVecl + 2
	STA	yPos + 2

	CMP	#TERRAIN_HEIGHT
	IF_PLUS
Update_OutOfBounds:
		LDA	#CannonBallState::OUT_OF_BOUNDS
		RTS
	ENDIF

	CLC
	LDA	yVecl
	ADC	#.loword(CANNONBALL_GRAVITY)
	STA	yVecl
	LDA	yVecl + 2
	ADC	#.hiword(CANNONBALL_GRAVITY)
	STA	yVecl + 2


	; Check if collides with another cannon.
	LDX	xPos + 2
	LDY	yPos + 2
	JSR	Cannons__CheckCollision

	CPX	#0
	IF_NE
		LDA	#CannonBallState::HIT_CANNON
		RTS
	ENDIF


	; Check if collides with terrain
	LDX	xPos + 2
	LDY	yPos + 2
	JSR	Terrain__IsPixelOccupied

	IF_C_SET
		LDA	#CannonBallState::HIT_GROUND
		RTS
	ENDIF

	LDA	#CannonBallState::FLYING
	RTS


.segment "BANK1"

	.include "tables/sine.inc"


ENDMODULE

