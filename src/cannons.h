
.ifndef ::__CANNON_H_
::__CANNON_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"

;; Number of cannons per player
CONFIG_DEFINE CANNONS_PER_PLAYER, 3

.struct CannonStruct
	;; If non-zero then the cannon is alive
	alive	.byte

	;; The player the cannon belongs to
	;; zero = player 1, non-zero = player 2
	player	.byte

	;; The current angle of the cannon
	;; Values are 0 to 180.
	angle	.byte

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

	;; Number of cannons player 1 has in play
	BYTE	player1Count

	;; Number of cannons player 2 has in play
	BYTE	player2Count

	;; The current cannon the user is playing.
	ADDR	currentCannon


	;; Spawns the cannons onto the map.
	;; REQUIRE: 8 bit A, 16 bit Index, DB=$7E
	ROUTINE SpawnCannons


ENDMODULE

.endif ; __CANNON_H_

; vim: ft=asm:

