
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
.include "cannonball.h"
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
		JSR	Random__AddJoypadEntropy
		JSR	Controller__UpdateRepeatingDPad

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
		.assert .sizeof(CannonStruct) = 8, error, "Bad value"
		TYA
		ASL
		ASL
		ASL
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

	LDA	Controller__pressed + 1
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



; DP = selectedCannon
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



; DP = selectedCannon
.A8
.I16
ROUTINE SelectAngle
	; ::TODO get player 2 controller if player2::
	LDA	Controller__pressed + 1

	IF_BIT #JOYH_B
		LDX	#GameState::SELECT_POWER
		STX	state

	ELSE_BIT #JOYH_UP
		LDA	z:CannonStruct::angle
		INC
		CMP	#CANNON_MAX_ANGLE
		IF_GE
			LDA	#CANNON_MAX_ANGLE
		ENDIF
		STA	z:CannonStruct::angle

	ELSE_BIT #JOYH_DOWN
		.assert CANNON_MIN_ANGLE = 0, error, "Bad Value"
		LDA	z:CannonStruct::angle
		IF_NOT_ZERO
			DEC
		ENDIF
		STA	z:CannonStruct::angle

	ELSE_BIT #JOYH_RIGHT
		LDA	z:CannonStruct::angle
		ADD	#10
		CMP	#CANNON_MAX_ANGLE
		IF_GE
			LDA	#CANNON_MAX_ANGLE
		ENDIF
		STA	z:CannonStruct::angle

	ELSE_BIT #JOYH_LEFT
		LDA	z:CannonStruct::angle
		CMP	#10 + CANNON_MIN_ANGLE
		IF_GE
			SUB	#10
		ELSE
			LDA	#CANNON_MIN_ANGLE
		ENDIF
		STA	z:CannonStruct::angle
	ENDIF

	RTS



; DP = selectedCannon
.A8
.I16
ROUTINE SelectPower
	; ::TODO get player 2 controller if player2::
	LDA	Controller__pressed

	IF_BIT #JOYL_A
		LDX	#GameState::SELECT_ANGLE
		STX	state

		RTS
	ENDIF

	; ::TODO get player 2 controller if player2::
	LDA	Controller__pressed + 1

	IF_BIT #JOYH_B
		JMP	FireCannon

	ELSE_BIT #JOYH_UP
		LDA	z:CannonStruct::power
		INC
		CMP	#CANNON_MAX_POWER
		IF_GE
			LDA	#CANNON_MAX_POWER
		ENDIF
		STA	z:CannonStruct::power

	ELSE_BIT #JOYH_DOWN
		LDA	z:CannonStruct::power
		CMP	#CANNON_MIN_POWER + 1
		IF_GE
			DEC
		ENDIF
		STA	z:CannonStruct::power

	ELSE_BIT #JOYH_RIGHT
		LDA	z:CannonStruct::power
		ADD	#10
		CMP	#CANNON_MAX_POWER
		IF_GE
			LDA	#CANNON_MAX_POWER
		ENDIF
		STA	z:CannonStruct::power

	ELSE_BIT #JOYH_LEFT
		LDA	z:CannonStruct::power
		CMP	#10 + CANNON_MIN_POWER
		IF_GE
			SUB	#10
		ELSE
			LDA	#CANNON_MIN_POWER
		ENDIF
		STA	z:CannonStruct::power
	ENDIF

	RTS


; DP = selectedCannon
.A8
.I16
ROUTINE FireCannon
	JSR	CannonBall__SetVelocity

	LDX	#GameState::CANNONBALL
	STX	state

	; ::TODO fire cannon::

	RTS


; DP = selectedCannon
.A8
.I16
ROUTINE Cannonball
	RTS



; DP = selectedCannon
.A8
.I16
ROUTINE	Explosion
	RTS



; DP = selectedCannon
.A8
.I16
ROUTINE GameOver
	RTS



ENDMODULE

