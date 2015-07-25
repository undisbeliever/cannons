
.ifndef ::__TERRAIN_H_
::__TERRAIN_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"

IMPORT_MODULE Terrain

	;; The horizontal offset of the terrain to display
	SINT16	hOffset

	;; The vertical offset of the terrain to display
	UINT16	vOffset

	;; Initializes the map and generates the terrain
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $80
	;;
	;; NOTE: will force blank to load tiles
	ROUTINE Generate

	;; VBlank updater
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers
	ROUTINE VBlank

ENDMODULE

.endif ; __TERRAIN_H_

; vim: ft=asm:

