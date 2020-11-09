# ef000000
	.section .text
	.global	_start
_start:	
	/* End simulation by writing to 0x00c0ffee */
	ldi.s   $r0, 0xabef
	sta.b   0x0c0ffee0, $r0
	sta.b   0xdead, $r0
	
