
.include "terrain.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"
.include "routines/block.h"
.include "routines/screen.h"
.include "routines/random.h"
.include "routines/math.h"
.include "routines/pixelbuffer.h"

.include "vram.h"

MODULE Terrain

SKY   = 0
GREEN = 1
RED   = 2
BLUE  = 3

.define WIDTH PIXELBUFFER_WIDTH * 8
.define HEIGHT PIXELBUFFER_HEIGHT * 8

;; Displacement value for Midpoint Displacement Algorithm
;; 0:7:8 fixed point
CONFIG	TERRAIN_DISPLACE, 50 * 256

;; Roughness value for Midpoint Displacement Algorithm
;; 0:7:8 fixed point
CONFIG	TERRAIN_ROUGHNESS, 140

;; Minimum height value for first/last line of terrain.
CONFIG	TERRAIN_END_MIN, 20

;; Maximum height value for first/last line of terrain.
CONFIG	TERRAIN_END_MAX, HEIGHT - TERRAIN_END_MIN

.assert PixelBuffer__bufferBank = $7E, error, "Bad Value"
.segment "SHADOW"
	;; Terrain height for each X position of pixelbuffer
	;; 0:8:8 format
	WORD	terrainXposTable,	WIDTH + 1
	WORD	tmp1
	WORD	tmp2
	WORD	tmp3
	WORD	tmp4

.code

.A8
.I16
ROUTINE Generate
	JSR	GenerateTerrainTable

	REP	#$20
.A16
	; ::TODO setColor macro::
	LDA	#$0000
	STA	f:PixelBuffer__colorBits
	JSR	PixelBuffer__FillBuffer

	JSR	RenderBuffer

	SEP	#$20
.A8

	JSR	SetupScreen
	TransferToVramLocation PixelBuffer__buffer, CANNONS_BG1_TILES + 8

	RTS


.A16
.I16
ROUTINE RenderBuffer
	PEA	.bankbyte(*) << 8 | PixelBuffer__bufferBank
	PLB

	; ::TODO setColor macro::
	LDA	#$00FF
	STA	PixelBuffer__colorBits

	LDX	#.sizeof(terrainXposTable) - 1
	STX	tmp2

	LDX	#WIDTH - 1
	STX	tmp1

	REPEAT
		LDX	tmp2
		DEX
		DEX
		STX	tmp2

		LDA	terrainXposTable, X
		AND	#$00FF
		TAY

		RSB16	#HEIGHT

		LDX	tmp1
		JSR	PixelBuffer__DrawVerticalLine

		DEC	tmp1
	UNTIL_MINUS

	PLB

	RTS


;; Uses the Midpoint Displacement Algorithm to generate the terrainXposTable list.
.A8
.I16
ROUTINE GenerateTerrainTable
	; terrainXposTable[0] = random(TERRAIN_END_MIN, TERRAIN_END_MAX)
	; terrainXposTable[WIDTH] = random(TERRAIN_END_MIN, TERRAIN_END_MAX)
	;
	; displacement = TERRAIN_DISPLACE
	; dx = WIDTH / 2 * 2
	;
	; repeat:
	;	center = dx
	;	repeat:
	;		point = (terrainXposTable[center - dx] + terrainXposTable[center + dy]) / 2
	;		point += random(-displacement, displacement)
	;
	;		if point > HEIGHT:
	;			point = HEIGHT - 1
	;		else if point < 0
	;			point = 1
	;
	;		terrainXposTable[center] = point
	;
	;		center += dx * 2
	;	until center > WIDTH * 2
	;
	;	displacement *= TERRAIN_ROUGHNESS
	;
	;	dx /= 2
	; until dx < 2

	;; ::MAYDO make displacement and roughness user configurable?::

tmp_dx		= tmp1
tmp_center	= tmp2
tmp_point	= tmp3
tmp_displacement= tmp4

	LDX	#TERRAIN_END_MIN * 256
	LDY	#TERRAIN_END_MAX * 256
	JSR	Random__Rnd_U16X_U16Y
	STY	terrainXposTable

	LDX	#TERRAIN_END_MIN * 256
	LDY	#TERRAIN_END_MAX * 256
	JSR	Random__Rnd_U16X_U16Y
	STY	terrainXposTable + .sizeof(terrainXposTable) - 2

	REP	#$20
.A16

	LDA	#TERRAIN_DISPLACE
	STA	tmp_displacement

	LDA	#WIDTH / 2 * 2

	REPEAT
		STA	tmp_dx

		REPEAT
			STA	tmp_center
			ADD	tmp_dx
			TAY

			LDA	tmp_center
			SUB	tmp_dx
			TAX

			LDA	terrainXposTable, X
			ADD	terrainXposTable, Y
			ROR
			STA	tmp_point


			LDA	tmp_displacement
			ASL
			TAY

			SEP	#$20
.A8
			JSR	Random__Rnd_U16Y
			REP	#$20
.A16
			TYA
			ADD	tmp_point
			SUB	tmp_displacement

			; Remember: A is 0:8:8 fixed point integer

			CMP	#(HEIGHT - 1) * 256
			IF_GE
				CMP	#(256 - (256 - HEIGHT) / 2) * 256
				IF_GE
					LDA	#1 * 256
				ELSE
					LDA	#(HEIGHT - 2) * 256
				ENDIF
			ENDIF

			LDX	tmp_center
			STA	terrainXposTable, X

			TXA
			CLC
			ADC	tmp_dx
			ADC	tmp_dx
			CMP	#WIDTH * 2
		UNTIL_GE

		; displacement = displacement * roughness
		; ::SHOULDO a 0:8:8 * 0:8:8 fixed point integer math routine::

		LDY	tmp_displacement
		LDX	#TERRAIN_ROUGHNESS
		JSR	Math__Multiply_S16Y_S16X_S32XY

		LDA	Math__product32 + 1
		STA	tmp_displacement

		LDA	tmp_dx
		LSR
		CMP	#2
	UNTIL_LT

	SEP	#$20
.A8

	RTS


.A8
.I16
ROUTINE SetupScreen
	; Prevent screen tearing
	JSR	Screen__WaitFrame

	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#CANNONS_SCREEN_MODE
	STA	BGMODE

	Screen_SetVramBaseAndSize	CANNONS

	REP	#$20
.A16

	SEP	#$20
.A8

	TransferToCgramLocation		Palette, 0

	STZ	BG1HOFS
	STZ	BG1HOFS

	LDA	#$FF
	STA	BG1VOFS
	STA	BG1VOFS

	LDA	#TM_BG1
	STA	TM

	; Generate tilemap
	REP	#$20
.A16
	LDA	#CANNONS_BG1_MAP
	STA	VMDATA

	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	LDA	#1
	JSR	PixelBuffer__WriteTileMapToVram

	SEP	#$20
.A8

	RTS



.segment "BANK1"

LABEL Palette
	.word	$7EC5, $02E0, $001F, $3C00	; sky blue, green, red, blue
Palette_End:

ENDMODULE

