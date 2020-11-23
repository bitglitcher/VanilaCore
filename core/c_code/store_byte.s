#Authot: Benjamin Herrera Navarro

.global _start
.section .init

_start:
    mv      a5, zero
    .loop:
    sb      zero,0(a5)
    addi a5, a5, 1
    jal x0, .loop
    ebreak