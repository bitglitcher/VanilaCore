#Authot: Benjamin Herrera Navarro
#11/8/2020
#9:31PM
#first successful run. :)

.global _start
.section .init

.equ    TERMINAL_ADDRESS, 0x10000
.equ    DISPLAY, 0x10004


_start:

    la x4, DISPLAY #display address
    addi x3, zero, 0 #Counter initialize

    .loop:
    nop
    addi x3, x3, 1 #increment counter
    sw x3, 0(x4) #Show value

    addi x6, zero, 0
    .wait1: #Wait
    li x5, 0xffff
    addi x6, x6, 1
    bge x5, x6, .wait1

    jal .loop # Loop back

