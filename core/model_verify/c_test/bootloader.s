	.file	"bootloader.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	li	a5,-1078001664
	sw	a5,-20(s0)
	lw	a5,-20(s0)
 #APP
# 12 "bootloader.c" 1
	srai a5, a5, 16 
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	li	a5,23
	mv	a0,a5
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	main, .-main
	.ident	"GCC: (GNU) 10.2.0"
