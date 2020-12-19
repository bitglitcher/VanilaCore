	.file	"bootloader.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"%d\n"
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-64
	lui	a1,%hi(.LC0)
	addi	a0,sp,8
	li	a2,10
	addi	a1,a1,%lo(.LC0)
	sw	ra,60(sp)
	call	sprintf
	lw	ra,60(sp)
	li	a0,65536
	addi	a0,a0,-1
	addi	sp,sp,64
	jr	ra
	.size	main, .-main
	.ident	"GCC: (GNU) 10.2.0"
