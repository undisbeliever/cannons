
.ifndef ::__CANNON_H_
::__CANNON_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"

;; Number of cannons per player
CONFIG_DEFINE CANNONS_PER_PLAYER, 3

N_CANNONS = CANNONS_PER_PLAYER * 2

CANNON_WIDTH = 3
CANNON_XOFFSET = -1
CANNON_HEIGHT = 2
CANNON_YOFFSET = -2

CANNON_LAUNCH_XOFFSET = 0
CANNON_LAUNCH_YOFFSET = CANNON_YOFFSET - 1


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

	;; The current power of the cannon (velocity/subframe)
	;; 0:0:8 fixed point integer
	power	.byte

	;; The cannon's x Position on the map
	;; signed 16 bit integer
	xPos	.word

	;; The cannon's y Position on the map
	;; signed 16 bit integer
	yPos	.word
.endstruct


IMPORT_MODULE Cannons
	;; List of cannons in play
	STRUCT	cannons, CannonStruct, CANNONS_PER_PLAYER * 2

	STRUCT	player1Cannons, CannonStruct, CANNONS_PER_PLAYER
	STRUCT	player2Cannons, CannonStruct, CANNONS_PER_PLAYER

	LABEL	player1Cannons_End
	LABEL	player2Cannons_End

	;; Number of cannons player 1 has in play
	BYTE	player1Count

	;; Number of cannons player 2 has in play
	BYTE	player2Count


	;; Spawns the cannons onto the map.
	;; REQUIRE: 8 bit A, 16 bit Index, DB=$7E
	ROUTINE SpawnCannons


	;; Checks if the position occupies a cannon.
	;; REQUIRES: 16 bit A, 16 bit Index, DB access shadow
	;;
	;; INPUT: X/Y the position
	;; OUTPUT:
	;;	X - the address of the cannon, 0 if no collision occurred.
	ROUTINE CheckCollision


	;; Marks the cannon as dead
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;;
	;; INPUT: X - the address of the cannon
	;; OUTPUT: A - the number of cannons the player has left
	ROUTINE MarkCannonDead

ENDMODULE

.endif ; __CANNON_H_

; vim: ft=asm:

