
.ifndef ::__UI_H_
::__UI_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"

IMPORT_MODULE Ui

	;; If non-zero then the animation is completed.
	BYTE	animationComplete


	;; Initializes the UI module
	;; REQUIRES: 8 bit A, 16 bit Index, DB access registers, Force Blank
	ROUTINE Init

	;; Builds the UI
	ROUTINE Update

	;; Starts the explosion animation at a given location
	;; REQUIRE: 8 bit A, 16 bit Index
	;;
	;; INPUT: X/Y explosion location
	ROUTINE StartExplosionAnimation

	;; Starts a small explosion animation at a given location
	;; REQUIRE: 8 bit A, 16 bit Index
	;;
	;; INPUT: X/Y explosion location
	ROUTINE StartSmallExplosionAnimation

ENDMODULE

.endif ; __UI_H_

; vim: ft=asm:

