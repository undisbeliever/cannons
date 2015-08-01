
.ifndef ::__CANNON_H_
::__CANNON_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"

;; Number of cannons per player
CONFIG_DEFINE CANNONS_PER_PLAYER, 3

N_CANNONS = CANNONS_PER_PLAYER * 2


CANNON_MIN_ANGLE = 0
CANNON_MAX_ANGLE = 180

CANNON_MIN_POWER = 10
CANNON_MAX_POWER = 200

.struct CannonStruct
	;; If non-zero then the cannon is alive
	alive	.byte

	;; The player the cannon belongs to
	;; zero = player 1, non-zero = player 2
	player	.byte

	;; The current angle of the cannon
	;; Values are 0 to 180.
	angle	.byte

	;; The current power of the cannon
	;; 0:4:4 fixed point integer
	power	.byte

	;; The cannon's x Position on the map
	;; signed 16 bit integer
	xPos	.word

	;; The cannon's y Position on the map
	;; signed 16 bit integer
	yPos	.word
.endstruct


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


IMPORT_MODULE Cannons
	;; The Cannonball
	STRUCT	cannonBall, CannonBallStruct

	;; List of cannons in play
	STRUCT	cannons, CannonStruct, CANNONS_PER_PLAYER * 2

	;; Number of cannons player 1 has in play
	BYTE	player1Count

	;; Number of cannons player 2 has in play
	BYTE	player2Count


	;; Spawns the cannons onto the map.
	;; REQUIRE: 8 bit A, 16 bit Index, DB=$7E
	ROUTINE SpawnCannons

	;; Updates the cannon ball's x and y velocity
	;; REQUIRE: 8 bit A, 16 bit Index, DB access registers
	;;
	;; INPUT: DP = cannon
	ROUTINE	SetCannonBallVelocity


ENDMODULE

.endif ; __CANNON_H_

; vim: ft=asm:

