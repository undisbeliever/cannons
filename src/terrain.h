
.ifndef ::__TERRAIN_H_
::__TERRAIN_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "routines/pixelbuffer.h"

TERRAIN_WIDTH = PIXELBUFFER_WIDTH * 8
TERRAIN_HEIGHT = PIXELBUFFER_HEIGHT * 8

IMPORT_MODULE Terrain

	;; The horizontal offset of the terrain to display
	SINT16	hOffset

	;; The vertical offset of the terrain to display
	UINT16	vOffset

	;; Initializes the map and generates the terrain
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $80
	ROUTINE Generate

	;; Sets up the display and copies the entrire terrain to VBlank.
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers.
	;;
	;; NOTE: will force blank to load tiles into VRAM
	ROUTINE CopyToVram

	;; Returns the the yPos of the top of the terrain for a given xPos  
	;; REQUIRES: 16 bit A, 16 bit Index, DB access shadow
	;;
	;; INPUT: A = xPos
	ROUTINE GetTopmostYposOfXpos

	;; VBlank updater
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers
	ROUTINE VBlank

ENDMODULE

.endif ; __TERRAIN_H_

; vim: ft=asm:

