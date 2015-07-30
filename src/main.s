; Initialisation code

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"
.include "includes/config.inc"
.include "routines/random.h"
.include "routines/screen.h"
.include "routines/controller.h"

.include "gameloop.h"


;; Initialisation Routine
ROUTINE Main
	REP	#$10
	SEP	#$20
.A8
.I16

	; ::TODO Setup Sound Engine::

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDXY	#$753fd14d		; source: random.org
	STXY	Random__Seed

	LDA	#MEMSEL_FASTROM
	STA	MEMSEL

	REPEAT
		JSR	Gameloop__PlayGame
	FOREVER


.segment "COPYRIGHT"
		;1234567890123456789012345678901
	.byte	"Cannons                        ", 10
	.byte	"(c) 2015, The Undisbeliever    ", 10
	.byte	"MIT Licensed                   ", 10
	.byte	"One Game Per Month Challange   ", 10

