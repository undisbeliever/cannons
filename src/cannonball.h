
.ifndef ::__CANNONBALL_H_
::__CANNONBALL_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"

;; Gravity of the cannonball.
;; 1:15:16 fixed point
CONFIG CANNONBALL_GRAVITY, 98 * $10000 / 50 / 10

.struct CannonBallStruct
	;; Cannonball's xPos
	;; 1:15:16 fixed point
	xPos	.res 4

	;; Cannonball's xPos
	;; 1:15:16 fixed point
	yPos	.res 4


	;; Cannonball's xVelocity
	;; 1:15:16 fixed point
	xVecl	.res 4

	;; Cannonball's xVelocity
	;; 1:15:16 fixed point
	yVecl	.res 4
.endstruct

.enum CannonBallState
	FLYING
	OUT_OF_BOUNDS
	HIT_GROUND
	HIT_CANNON
.endenum

.assert CannonBallState::FLYING = 0, error, "Bad Value"


IMPORT_MODULE CannonBall
	;; The Cannonball
	STRUCT	cannonBall, CannonBallStruct

	;; Sets the cannonball's position to the cannon's position
	;; REQUIRE: 16 bit Index, DB access shadow
	ROUTINE	SetPosition

	;; Updates the cannon ball's x and y velocity
	;; REQUIRE: 8 bit A, 16 bit Index, DB access registers
	;;
	;; INPUT: DP = cannon
	ROUTINE	SetVelocity


	;; Processes a single frame of a cannonball.
	;;
	;; REQUIRE: 16 bit A, 16 bit Index, DP access shadow
	;;
	;; RETURN: Cannonstate enum determing state of cannon
	;;	X - address of cannon if hit by cannonball, else 0
	;;	Zero flag set if not hit by anything
	ROUTINE Update

ENDMODULE

.endif ; __CANNONBALL_H_

; vim: ft=asm:

