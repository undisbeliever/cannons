
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
	STRUCT	cannonBall, CannonBallStruct

	WORD	tmp1
	WORD	tmp2


.code


; DP = cannon
ROUTINE SetPosition
	; cannonBall.xPos = dp->xPos - CANNON_LAUNCH_XOFFSET
	; cannonBall.yPos = dp->yPos - CANNON_LAUNCH_YOFFSET

	PHP
	REP	#$30
.A16

	.assert CANNON_LAUNCH_XOFFSET = 0, error, "bad code"
	LDA	z:CannonStruct::xPos
	STA	cannonBall + CannonBallStruct::xPos + 2
	STZ	cannonBall + CannonBallStruct::xPos

	.assert CANNON_LAUNCH_YOFFSET = -3, error, "bad code"
	LDA	z:CannonStruct::yPos
	DEC
	DEC
	DEC
	STA	cannonBall + CannonBallStruct::yPos + 2
	STZ	cannonBall + CannonBallStruct::yPos

	PLP

	RTS



; DP = cannon
; OUT: cannonBall's xVecl, yVecl
.A8
.I16
ROUTINE SetVelocity
	; cannonBall.yVecl = - sineTable[angle] * dp->power
	;
	; cannonBall.xVecl = - sineTable[angle + 90] * dp->power
	;
	; if dp->player != 0:
	;	cannonBall.xVecl = -cannonBall.xVecl
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

	; power = 0:3:5 - convert to 1:9:9
	LDA	z:CannonStruct::power
	AND	#$FF
	ASL
	ASL
	ASL
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
	STA	cannonBall + CannonBallStruct::yVecl

	; sign extend
	LDA	Math__product32 + 3
	IF_BIT	#$0080
		ORA	#$FF00
	ELSE
		AND	#$00FF
	ENDIF
	STA	cannonBall + CannonBallStruct::yVecl + 2

	NEG32	cannonBall + CannonBallStruct::yVecl


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
	STA	cannonBall + CannonBallStruct::xVecl

	; sign extend
	LDA	Math__product32 + 3
	IF_BIT	#$0080
		ORA	#$FF00
	ELSE
		AND	#$00FF
	ENDIF
	STA	cannonBall + CannonBallStruct::xVecl + 2

	LDA	z:CannonStruct::player
	AND	#$FF
	IF_NOT_ZERO
		NEG32	cannonBall + CannonBallStruct::xVecl
	ENDIF

	SEP	#$20
.A8

	RTS



.A16
.I16
ROUTINE Update
	; cannonBall.xPos += cannonBall.xVecl
	; cannonBall.yPos += cannonBall.yVecl
	;
	; if cannonBall.xPos < 0 | cannonBall.xPos >= TERRAIN_WIDTH | cannonBall.yPos >= TERRAIN_HEIGHT:
	;	return CannonBallState::OUT_OF_BOUNDS
	;
	; cannonBall.yVecl += CANNONBALL_GRAVITY
	;
	; X = Cannon__CheckCollision(cannonBall.xPos, cannonBall.yPos)
	;
	; if X != NULL
	;	return CannonBallState::HIT_CANNON, X
	; else if Terrain__IsPixelOccupied(cannonBall.xPos, cannonBall.yPos)
	;	return CannonBallState::HIT_GROUND
	; else:
	; 	return CannonBallState::FLYING

	CLC
	LDA	cannonBall + CannonBallStruct::xPos
	ADC	cannonBall + CannonBallStruct::xVecl
	STA	cannonBall + CannonBallStruct::xPos
	LDA	cannonBall + CannonBallStruct::xPos + 2
	ADC	cannonBall + CannonBallStruct::xVecl + 2
	STA	cannonBall + CannonBallStruct::xPos + 2

	BMI	Update_OutOfBounds
	CMP	#TERRAIN_WIDTH
	BSGE	Update_OutOfBounds


	CLC
	LDA	cannonBall + CannonBallStruct::yPos
	ADC	cannonBall + CannonBallStruct::yVecl
	STA	cannonBall + CannonBallStruct::yPos
	LDA	cannonBall + CannonBallStruct::yPos + 2
	ADC	cannonBall + CannonBallStruct::yVecl + 2
	STA	cannonBall + CannonBallStruct::yPos + 2

	CMP	#TERRAIN_HEIGHT
	IF_SGE
Update_OutOfBounds:
		LDA	#CannonBallState::OUT_OF_BOUNDS
		RTS
	ENDIF

	CLC
	LDA	cannonBall + CannonBallStruct::yVecl
	ADC	#.loword(CANNONBALL_GRAVITY)
	STA	cannonBall + CannonBallStruct::yVecl
	LDA	cannonBall + CannonBallStruct::yVecl + 2
	ADC	#.hiword(CANNONBALL_GRAVITY)
	STA	cannonBall + CannonBallStruct::yVecl + 2


	; Check if collides with another cannon.
	LDX	cannonBall + CannonBallStruct::xPos + 2
	LDY	cannonBall + CannonBallStruct::yPos + 2
	JSR	Cannons__CheckCollision

	CPX	#0
	IF_NE
		LDA	#CannonBallState::HIT_CANNON
		RTS
	ENDIF


	; Check if collides with terrain
	LDX	cannonBall + CannonBallStruct::xPos + 2
	LDY	cannonBall + CannonBallStruct::yPos + 2
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

