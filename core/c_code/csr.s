

.section .init, "ax"
.global _start

.equ MASK, 0b11
_start:
    la x2, trap_vector
    csrw mtvec, x2
    # Setup mevent3
    mv x2, zero
    addi x2, x2, 4
    csrw 0x323, x2
    addi x2, x2, 4
    addi x2, x2, 4
    addi x2, x2, 4

    csrrw x3, 0xf11, zero
    csrrw x4, 0xf12, zero
    csrrw x5, 0xf13, zero
    csrrw x6, 0xf14, zero
    csrrw x7, 0x300, zero
    csrrw x8, 0x301, zero
    csrrw x9, 0x305, zero
    la t0, MASK
    csrrs zero, mstatus, t0


    .word 0xaeaeaeae
    ebreak





trap_vector:
    mret