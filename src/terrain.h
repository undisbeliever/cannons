
.ifndef ::__TERRAIN_H_
::__TERRAIN_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"

IMPORT_MODULE Terrain

	;; Initializes the map and generates the terrain
	;; REQUIRES: 8 bit A, 16 bit Index
	;;
	;; NOTE: will force VBlank
	ROUTINE Generate

ENDMODULE

.endif ; __TERRAIN_H_

; vim: ft=asm:

