
.ifndef ::__CANNONBALL_H_
::__CANNONBALL_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"


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


IMPORT_MODULE CannonBall
	;; The Cannonball
	STRUCT	cannonBall, CannonBallStruct

	;; Updates the cannon ball's x and y velocity
	;; REQUIRE: 8 bit A, 16 bit Index, DB access registers
	;;
	;; INPUT: DP = cannon
	ROUTINE	SetVelocity


ENDMODULE

.endif ; __CANNONBALL_H_

; vim: ft=asm:

