
.ifndef ::__RESOURCES_H_
::__RESOURCES_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"

IMPORT_MODULE Resources

	INCLUDE_BINARY	Sprites_Tiles
	INCLUDE_BINARY	Sprites_Palette

ENDMODULE

.endif ; __RESOURCES_H_

; vim: ft=asm:

