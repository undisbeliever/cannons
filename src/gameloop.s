
.include "gameloop.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"
.include "routines/block.h"
.include "routines/controller.h"
.include "routines/screen.h"
.include "routines/random.h"

.include "terrain.h"
.include "cannons.h"
.include "ui.h"

;; Number of frames before respawning the game
CONFIG	ATTARACT_MODE_RESPAWN_FRAME_DELAY, 5 * FPS


MODULE Gameloop

.segment "SHADOW"
	WORD	state
	WORD	selectedCannon

	WORD	attract_timer

	WORD	tmp1


.rodata

LABEL StateTable
	.addr	AttractMode
	.addr	ScrollToCannon
	.addr	SelectAngle
	.addr	SelectPower
	.addr	Cannonball
	.addr	Explosion
	.addr	GameOver


.code

.A8
.I16
ROUTINE PlayGame
	LDX	#GameState::ATTRACT_MODE
	STX	state

	REPEAT
		REP	#$30
.A16
		LDA	selectedCannon
		TCD

		SEP	#$20
.A8

		LDX	state
		JSR	(.loword(StateTable), X)

		JSR	Ui__Update
		JSR	Screen__WaitFrame
	FOREVER


.A8
.I16
ROUTINE	SetAttractMode
	LDX	#GameState::ATTRACT_MODE
	STX	state

	LDX	#0
	STX	selectedCannon

	LDX	#0
	STX	attract_timer



.A8
.I16
ROUTINE	AttractMode

	LDX	attract_timer
	DEX
	IF_MINUS
		; ::BUGFIX cannot press start when generating terrain::
		; ::SHOULDDO save state and allow exit by checking for start during VBlank?::
		LDA	#INIDISP_FORCE
		STA	INIDISP

		JSR	Terrain__Generate
		JSR	Cannons__SpawnCannons
		JSR	Terrain__CopyToVram
		JSR	Ui__Init

		; Select random cannon to focus on.
		PHD
		LDY	#N_CANNONS
		JSR	Random__Rnd_U16Y

		REP	#$20
.A16
		.assert .sizeof(CannonStruct) = 7, error, "Bad value"
		TYA
		STA	tmp1
		ASL
		ASL
		ASL
		SUB	tmp1
		ADD	#Cannons__cannons
		TCD

		SEP	#$20
.A8

		LDX	z:CannonStruct::xPos
		LDY	z:CannonStruct::yPos
		JSR	Terrain__CenterOnPosition

		PLD

		; prevent tearing
		JSR	Screen__WaitFrame

		LDA	#15
		STA	INIDISP

		LDX	#ATTARACT_MODE_RESPAWN_FRAME_DELAY
	ENDIF

	STX	attract_timer

	JSR	Ui__Update
	JSR	Screen__WaitFrame

	LDA	Controller__current + 1
	AND	#JOYH_START
	BNE	StartGame

	RTS



.A8
.I16
ROUTINE	StartGame
	LDA	#INIDISP_FORCE
	STA	INIDISP

	JSR	Terrain__Generate
	JSR	Cannons__SpawnCannons
	JSR	Terrain__CopyToVram
	JSR	Ui__Init

	LDX	#Cannons__cannons
	STX	selectedCannon

	LDX	Cannons__cannons + CannonStruct::xPos
	LDY	Cannons__cannons + CannonStruct::yPos
	JSR	Terrain__CenterOnPosition

	LDA	#15
	STA	INIDISP

	LDX	#GameState::SELECT_ANGLE
	STX	state

	RTS



; DP = currentCannon
.A8
.I16
ROUTINE ScrollToCannon
	; ::TODO slowly scroll to position::
	LDX	z:CannonStruct::xPos
	LDY	z:CannonStruct::yPos
	JSR	Terrain__CenterOnPosition

	LDX	#GameState::SELECT_ANGLE
	STX	state

	RTS



; DP = currentCannon
.A8
.I16
ROUTINE SelectAngle
	RTS



; DP = currentCannon
.A8
.I16
ROUTINE SelectPower
	RTS



; DP = currentCannon
.A8
.I16
ROUTINE Cannonball
	RTS



; DP = currentCannon
.A8
.I16
ROUTINE	Explosion
	RTS



; DP = currentCannon
.A8
.I16
ROUTINE GameOver
	RTS



ENDMODULE

