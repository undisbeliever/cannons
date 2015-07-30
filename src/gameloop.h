
.ifndef ::__GAMELOOP_H_
::__GAMELOOP_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"

.enum GameState
	ATTRACT_MODE		=  0
	SCROLL_TO_CANNON	=  2
	SELECT_ANGLE		=  4
	SELECT_POWER		=  6
	CANNONBALL		=  8
	EXPLOSION		= 10
	GAME_OVER		= 12
.endenum

IMPORT_MODULE Gameloop
	;; The current state of the gameloop
	WORD	state

	;; The current cannon in played
	ADDR	selectedCannon

	;; Plays the game.
	;;
	;; REQUIRES: 8 bit A, 16 bit Index.
	ROUTINE PlayGame

ENDMODULE

.endif ; __GAMELOOP_H_

; vim: ft=asm:

