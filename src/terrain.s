
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

;; The height of pixels each BG layer displays.
BG_DISPLAY_HEIGHT = 16 * 8

.define WIDTH PIXELBUFFER_WIDTH * 8
.define HEIGHT PIXELBUFFER_HEIGHT * 8

SCREEN_WIDTH = 256
SCREEN_HEIGHT = 224

;; Displacement value for Midpoint Displacement Algorithm
;; 0:10:6 fixed point integer
CONFIG	TERRAIN_DISPLACEMENT, 70 * 64

;; Minimum displacement
;; 0:10:6 fixed point integer
CONFIG	TERRAIN_MIN_DISPLACEMENT, 30

;; Roughness value for Midpoint Displacement Algorithm
;; 0:0:16 fixed point integer
CONFIG	TERRAIN_ROUGHNESS, $8CCC	; ~0.55

;; Minimum height value for first/last line of terrain.
CONFIG	TERRAIN_END_MIN, 20

;; Maximum height value for first/last line of terrain.
CONFIG	TERRAIN_END_MAX, HEIGHT - TERRAIN_END_MIN

.struct HdmaTmTableStruct
	nScanlines	.byte
	tm		.byte
.endstruct

.assert PixelBuffer__bufferBank = $7E, error, "Bad Value"
.segment "SHADOW"
	;; Terrain height for each X position of pixelbuffer
	;; 0:10:6 fixed point integer
	WORD	terrainXposTable,	WIDTH + 1
	WORD	tmp1
	WORD	tmp2
	WORD	tmp3
	WORD	tmp4

	SINT16	hOffset
	UINT16	vOffset

	WORD	bg1vOffset
	WORD	bg2vOffset
	WORD	bg3vOffset

	STRUCT	hdmaTmTable, HdmaTmTableStruct, 3
	BYTE	endHdmaTmTable


	;; If 0, there is no update, else update the tiles next to it.
	ADDR	bufferLocationToUpdate
.code


.A8
.I16
ROUTINE Generate
	JSR	GenerateTerrainTable

	REP	#$20
.A16
	LDA	#PIXELBUFFER_COLOR0
	STA	f:PixelBuffer__colorBits
	JSR	PixelBuffer__FillBuffer

	JSR	RenderBuffer

	SEP	#$20
.A8

	RTS



.A8
.I16
ROUTINE CopyToVram

	LDX	#0
	STX	bufferLocationToUpdate

	; Prevent screen tearing
	JSR	Screen__WaitFrame

	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#CANNONS_SCREEN_MODE
	STA	BGMODE

	Screen_SetVramBaseAndSize	CANNONS

	TransferToCgramLocation		Palette, 0
	TransferToCgramLocation		Palette, 32
	TransferToCgramLocation		Palette, 64

	TransferToVramLocation		Tilemap, CANNONS_BG1_MAP

	TransferToVramLocation PixelBuffer__buffer, CANNONS_BG1_TILES

	RTS



; DB access registers
.A8
.I16
ROUTINE VBlank
	REP	#$20
	SEP	#$10
.A16
.I8

	LDA	bufferLocationToUpdate
	IF_NOT_ZERO
		; update buffer
		SUB	#16
		JSR	VBlank_CopyRow

		LDA	bufferLocationToUpdate
		ADD	#PIXELBUFFER_WIDTH * 16 - 16
		JSR	VBlank_CopyRow

		LDA	bufferLocationToUpdate
		SUB	#PIXELBUFFER_WIDTH * 16 + 16
		JSR	VBlank_CopyRow

		STZ	bufferLocationToUpdate
	ENDIF



	LDA	hOffset
	IF_MINUS
		STZ	hOffset
	ELSE
		CMP	#WIDTH - SCREEN_WIDTH
		IF_GE
			LDA	#WIDTH - SCREEN_WIDTH - 1
			STA	hOffset
		ENDIF
	ENDIF

	LDA	vOffset
	CMP	#HEIGHT - SCREEN_HEIGHT
	IF_PLUS
		LDA	#HEIGHT - SCREEN_HEIGHT - 1
		STA	vOffset
	ENDIF

	LDX	hOffset
	LDY	hOffset + 1

	STX	BG1HOFS
	STY	BG1HOFS
	STX	BG2HOFS
	STY	BG2HOFS
	STX	BG3HOFS
	STY	BG3HOFS

	LDA	#.loword(-1)
	ADD	vOffset
	STA	bg1vOffset

	LDA	#.loword(-1 - BG_DISPLAY_HEIGHT)
	ADD	vOffset
	STA	bg2vOffset

	LDA	#.loword(-1 - BG_DISPLAY_HEIGHT * 2)
	ADD	vOffset
	STA	bg3vOffset

	LDX	bg1vOffset
	STX	BG1VOFS
	LDY	bg1vOffset + 1
	STY	BG1VOFS

	LDX	bg2vOffset
	STX	BG2VOFS
	LDY	bg2vOffset + 1
	STY	BG2VOFS

	LDX	bg3vOffset
	STX	BG3VOFS
	LDY	bg3vOffset + 1
	STY	BG3VOFS

	LDX	#0
	STX	HDMAEN

	LDA	vOffset
	IF_MINUS
		CMP	#.loword(-128)
		IF_MINUS
			; ::BUGFIX HDMA nScanlines must be < 128::
			NEG16
			AND	#$7F
			TAX
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 0 + HdmaTmTableStruct::nScanlines
			LDX	#TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 0 + HdmaTmTableStruct::tm

			LDX	#127
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 1 + HdmaTmTableStruct::nScanlines
			LDX	#TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 1 + HdmaTmTableStruct::tm

			LDX	#BG_DISPLAY_HEIGHT
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 2 + HdmaTmTableStruct::nScanlines
			
			LDX	#TM_BG1 | TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 2 + HdmaTmTableStruct::tm

			LDX	#0
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 3 + HdmaTmTableStruct::nScanlines
		ELSE	
			NEG16
			TAX
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 0 + HdmaTmTableStruct::nScanlines

			LDX	#TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 0 + HdmaTmTableStruct::tm

			LDX	#BG_DISPLAY_HEIGHT
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 1 + HdmaTmTableStruct::nScanlines
			
			LDX	#TM_BG1 | TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 1 + HdmaTmTableStruct::tm

			LDX	#BG_DISPLAY_HEIGHT
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 2 + HdmaTmTableStruct::nScanlines
			
			LDX	#TM_BG2 | TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 2 + HdmaTmTableStruct::tm

			LDX	#0
			STX	endHdmaTmTable
		ENDIF
	ELSE
		LDA	vOffset
		CMP	#.loword(BG_DISPLAY_HEIGHT)
		IF_LT
			RSB16	#BG_DISPLAY_HEIGHT

			TAX
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 0 + HdmaTmTableStruct::nScanlines

			LDX	#TM_BG1 | TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 0 + HdmaTmTableStruct::tm

			LDX	#BG_DISPLAY_HEIGHT
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 1 + HdmaTmTableStruct::nScanlines
			
			LDX	#TM_BG2 | TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 1 + HdmaTmTableStruct::tm

			LDX	#BG_DISPLAY_HEIGHT
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 2 + HdmaTmTableStruct::nScanlines
			
			LDX	#TM_BG3 | TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 2 + HdmaTmTableStruct::tm

			LDX	#0
			STX	endHdmaTmTable
		ELSE
			RSB16	#BG_DISPLAY_HEIGHT * 2

			TAX
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 0 + HdmaTmTableStruct::nScanlines

			LDX	#TM_BG2 | TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 0 + HdmaTmTableStruct::tm

			LDX	#BG_DISPLAY_HEIGHT
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 1 + HdmaTmTableStruct::nScanlines
			
			LDX	#TM_BG3 | TM_OBJ
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 1 + HdmaTmTableStruct::tm

			LDX	#0
			STX	hdmaTmTable + .sizeof(HdmaTmTableStruct) * 2 + HdmaTmTableStruct::nScanlines
		ENDIF
	ENDIF

	; Setup HDMA Registers
	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_ADDRESSING_ABSOLUTE | DMAP_TRANSFER_1REG | (.lobyte(TM) << 8)
	STA	DMAP7			; also sets BBAD7

	LDA	#.loword(hdmaTmTable)
	STA	A1T7
	LDX	#.bankbyte(hdmaTmTable)
	STX	A1B7

	LDX	#HDMAEN_DMA7
	STX	HDMAEN

	REP	#$10
	SEP	#$20
.A8
.I16

	RTS



.A16
.I8
ROUTINE VBlank_CopyRow

	LDY	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STY	VMAIN

	PHA
	LSR
	ADD	#CANNONS_BG1_TILES
	STA	VMADD

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
	STA	DMAP0

	LDY	#.bankbyte(PixelBuffer__buffer)
	STY	A1B0

	PLA
	ADD	#.loword(PixelBuffer__buffer)
	STA	A1T0

	LDA	#16 * 3
	STA	DAS0

	LDY	#MDMAEN_DMA0
	STY	MDMAEN

	RTS



; IN: X = xPos, Y = yPos
ROUTINE CenterOnPosition
	PHP

	REP	#$30
.A16
.I16

	TXA
	SUB	#SCREEN_WIDTH / 2
	IF_MINUS
		LDA	#0
	ELSE
		CMP	#WIDTH - SCREEN_WIDTH
		IF_GE
			LDA	#WIDTH - SCREEN_WIDTH - 1
		ENDIF
	ENDIF

	STA	hOffset


	TYA
	SUB	#SCREEN_HEIGHT / 2
	CMP	#HEIGHT - SCREEN_HEIGHT
	IF_PLUS
		LDA	#HEIGHT - SCREEN_HEIGHT - 1
		STA	vOffset
	ENDIF

	STA	vOffset

	PLP
	RTS



; IN: A = xPos
; OUT: A = yPos
.A16
.I16
ROUTINE GetTopmostYposOfXpos
	; Just uses the terrainXposTable to get the yPos to save a lot of CPU time.

	; ::MAYDO use PixelBuffer__GetPixel instead if terrainXposTable is dirty ::

	ASL
	TAX

	; 0:16:6 fixed point integer
	LDA	terrainXposTable, X
	LSR
	LSR
	LSR
	LSR
	LSR
	LSR

	RTS



; IN: X/Y = pixel position
; OUT: c clear if sky
.A16
.I16
ROUTINE IsPixelOccupied
	; Bounds checking

	CPX	#0
	BMI	_IsPixelOccupied_OffScreen

	CPX	#TERRAIN_WIDTH
	BPL	_IsPixelOccupied_OffScreen

	CPY	#0
	BMI	_IsPixelOccupied_OffScreen

	CPY	#TERRAIN_HEIGHT
	IF_PLUS
_IsPixelOccupied_OffScreen:
		CLC
		RTS
	ENDIF

	PEA	.bankbyte(*) << 8 | PixelBuffer__bufferBank
	PLB

	JSR	PixelBuffer__GetPixel

	PLB

	.assert SKY = 0, error, "Bad assumption"
	CMP	#1

	; carry clear if A = 0, set if A != 0
	RTS



; IN: X/Y = pixel position
; IN: A = player
.A8
.I16
ROUTINE DrawCreator
	; if x < 1:
	;	x = 1
	; if x > TERRAIN_WIDTH - 1:
	;	x = TERRAIN_WIDTH - 1
	; if y < 1:
	;	y = 1
	; if y > TERRAIN_HEIGHT - 2:
	;	y = TERRAIN_HEIGHT - 2
	;
	; PixelBuffer__colorBits = 0
	; PixelBuffer__SetPixel(x, y - 1)
	; PixelBuffer__SetPixel(x - 1, y)
	; PixelBuffer__SetPixel(x, y)
	; PixelBuffer__SetPixel(x + 1, y)
	;
	; if player == 0:
	;	PixelBuffer__colorBits = PIXELBUFFER_COLOR2
	; else:
	;	PixelBuffer__colorBits = PIXELBUFFER_COLOR3
	;
	; PixelBuffer__colorBits(x, y + 1)

tmp_cannonBall	= tmp1
tmp_x		= tmp2
tmp_y		= tmp3

	PEA	.bankbyte(*) << 8 | PixelBuffer__bufferBank
	PLB

	CPX	#1
	IF_MINUS
		LDX	#1
	ENDIF

	CPX	#TERRAIN_WIDTH + 2
	IF_PLUS
		LDX	#TERRAIN_WIDTH - 1
	ENDIF

	STX	tmp_x


	CPY	#1
	IF_MINUS
		LDY	#1
	ENDIF

	CPY	#TERRAIN_HEIGHT + 2
	IF_PLUS
		LDY	#TERRAIN_HEIGHT - 1
	ENDIF
	STY	tmp_y



	CMP	#0
	IF_EQ
		.assert RED = 2, error, "Bad assumption"
		LDY	#PIXELBUFFER_COLOR2
	ELSE
		.assert BLUE = 3, error, "Bad assumption"
		LDY	#PIXELBUFFER_COLOR3
	ENDIF

	STY	tmp_cannonBall


	REP	#$30
.A16
	; Draw creator
	LDA	#0
	STA	PixelBuffer__colorBits

	LDX	tmp_x
	LDY	tmp_y
	DEY
	JSR	PixelBuffer__SetPixel

	LDX	tmp_x
	DEX
	LDY	tmp_y
	JSR	PixelBuffer__SetPixel

	LDX	tmp_x
	LDY	tmp_y
	JSR	PixelBuffer__SetPixel

	LDX	tmp_x
	INX
	LDY	tmp_y
	JSR	PixelBuffer__SetPixel


	; Draw cannonball
	LDA	tmp_cannonBall
	STA	PixelBuffer__colorBits

	LDA	tmp_cannonBall
	LDX	tmp_x
	LDY	tmp_y
	INY
	JSR	PixelBuffer__SetPixel


	LDX	tmp_x
	LDY	tmp_y
	JSR	PixelBuffer__TileOffsetForPosition
	STX	bufferLocationToUpdate

	SEP	#$20
.A8

	PLB
	RTS



.A16
.I16
ROUTINE RenderBuffer
	PEA	.bankbyte(*) << 8 | PixelBuffer__bufferBank
	PLB

	LDA	#PIXELBUFFER_COLOR1
	STA	PixelBuffer__colorBits

	LDX	#WIDTH - 1
	STX	tmp1

	LDX	#.sizeof(terrainXposTable)
	STX	tmp2

	REPEAT
		LDX	tmp2
		DEX
		DEX
		STX	tmp2

		; 0:16:6 fixed point integer
		LDA	terrainXposTable, X
		LSR
		LSR
		LSR
		LSR
		LSR
		LSR
		TAY

		RSB16	#HEIGHT

		LDX	tmp1
		JSR	PixelBuffer__DrawVerticalLine

		DEC	tmp1
	UNTIL_MINUS

	PLB

	RTS



;; Uses the Midpoint Displacement Algorithm to generate the terrainXposTable list.
;; This algorithm is preformed using 0:7:9 fixed point math.

; DB = PixelBuffer__bufferBank
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

	LDX	#TERRAIN_END_MIN * 64
	LDY	#TERRAIN_END_MAX * 64
	JSR	Random__Rnd_U16X_U16Y
	STY	terrainXposTable

	LDX	#TERRAIN_END_MIN * 64
	LDY	#TERRAIN_END_MAX * 64
	JSR	Random__Rnd_U16X_U16Y
	STY	terrainXposTable + .sizeof(terrainXposTable) - 2

	REP	#$20
.A16

	LDA	#TERRAIN_DISPLACEMENT
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

			; Remember: A is 0:10:6 fixed point integer

			CMP	#(HEIGHT - 1) * 64
			IF_GE
				CMP	#(64 - (64 - HEIGHT) / 2) * 64
				IF_GE
					LDA	#1 * 64
				ELSE
					LDA	#(HEIGHT - 2) * 64
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
		; displacement is 0:10:6 fixed point
		; roughness is 0:0:16 fixed point

		LDY	tmp_displacement
		LDX	#TERRAIN_ROUGHNESS
		JSR	Math__Multiply_U16Y_U16X_U32XY

		; XY/product32 = 0:10:26 fixed point
		TXA
		AND	#$7FFF
		CMP	#TERRAIN_MIN_DISPLACEMENT
		IF_LT
			LDA	#TERRAIN_MIN_DISPLACEMENT
		ENDIF

		STA	tmp_displacement

		LDA	tmp_dx
		LSR
		CMP	#2
	UNTIL_LT

	SEP	#$20
.A8

	RTS



.segment "BANK1"

LABEL Palette
	.word	$7EC5, $02E0, $001F, $3C00	; sky blue, green, red, blue
Palette_End:

;; A 62x32 tilemap of the terrain.
.assert PIXELBUFFER_WIDTH = 64, error, "Bad config"
.assert PIXELBUFFER_HEIGHT = 16 * 3, error, "Bad config"
LABEL Tilemap
	; left map
	.repeat 16, yTile
		.repeat 32, xTile
			.word 64 * yTile + xTile
		.endrepeat
	.endrepeat
	.repeat 16 * 32
		.word $FFFF
	.endrepeat

	; right map
	.repeat 16, yTile
		.repeat 32, xTile
			.word 64 * yTile + xTile + 32
		.endrepeat
	.endrepeat
	.repeat 16 * 32
		.word $FFFF
	.endrepeat
Tilemap_End:

ENDMODULE

