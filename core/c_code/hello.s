.global _start
.section .init

.equ    TERMINAL_ADDRESS, 0x10000
.equ    DISPLAY, 0x10004

.equ LETTER_F, 70
.equ LETTER_U, 85
.equ LETTER_C, 67
.equ LETTER_K, 75

_start:

    la x4, DISPLAY
    addi x3, zero, 0
    li x3, 0xbeef
    sw x3, 0(x4)
    addi x3, zero, 0
    addi x4, zero, 0


    la x4, TERMINAL_ADDRESS # Terminal Address

    addi x3, zero, 0
    addi x3, x3, LETTER_F # Load character
    sw x3, 0(x4) # Store character

    addi x6, zero, 0
    .wait1:
    li x5, 0x100
    addi x6, x6, 1
    bne x5, x6, .wait1

    addi x3, zero, 0
    addi x3, x3, LETTER_U # Load character
    sw x3, 0(x4) # Store character

    addi x6, zero, 0
    .wait2:
    li x5, 0x100
    addi x6, x6, 1
    bne x5, x6, .wait2

    addi x3, zero, 0
    addi x3, x3, LETTER_C # Load character
    sw x3, 0(x4) # Store character

    addi x6, zero, 0
    .wait3:
    li x5, 0x100
    addi x6, x6, 1
    bne x5, x6, .wait3

    addi x3, zero, 0
    addi x3, x3, LETTER_K # Load character
    sw x3, 0(x4) # Store character

    .loop:

    jal .loop # Loop back
