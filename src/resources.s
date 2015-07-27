
.include "resources.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"

MODULE Resources

.segment "BANK1"

	INCLUDE_BINARY	Sprites_Palette,	"resources/tiles4bpp/sprites.clr"
	INCLUDE_BINARY	Sprites_Tiles,		"resources/tiles4bpp/sprites.4bpp"


ENDMODULE

