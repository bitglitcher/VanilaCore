#Author: Benjamin Herrera Navarro

.global _start
.section .init

.equ    TERMINAL_ADDRESS, 0x10000
.equ    DISPLAY, 0x10004


_start:
    li x1, -1
    li x2, 12

    #that should yield to 1 on x3
    slt x3, x1, x2
    ebreak

    #sthis should yield to 0 on x3
    sltu x3, x1, x2
    ebreak

