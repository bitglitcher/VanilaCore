	.file	"bootloader.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC1:
	.string	"%f\n"
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	lui	a5,%hi(.LC0)
	lw	a2,%lo(.LC0)(a5)
	lw	a3,%lo(.LC0+4)(a5)
	addi	sp,sp,-64
	lui	a1,%hi(.LC1)
	addi	a0,sp,8
	addi	a1,a1,%lo(.LC1)
	sw	ra,60(sp)
	call	sprintf
	lw	ra,60(sp)
	li	a0,65536
	addi	a0,a0,-1
	addi	sp,sp,64
	jr	ra
	.size	main, .-main
	.section	.srodata.cst8,"aM",@progbits,8
	.align	3
.LC0:
	.word	536870912
	.word	1081361711
	.ident	"GCC: (GNU) 10.2.0"
