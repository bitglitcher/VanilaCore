
	.text
main:
	add $r0, $r1
    and $r0, $r1
    ashl $r0, $r1
    ashr $r0, $r1
    bge 0x0
    beq 0x0
    bgeu 0x0
    bgt 0x0
    bgtu 0x0
    ble 0x0
    bleu 0x0
    blt 0x0
    bltu 0x0
    bne 0x0
    cmp $r0, $r1 
    dec $r0, 0x13
    div $r0, $r1
    gsr $r0, 0x3
    inc $r0, 0x13
    jmp $r0
    jmpa 0x12345678
    jsr $r1
    jsra 0x12345678
    ld.b $r2, ($r1)
    ld.l $r2, ($r1)
    ld.s $r2, ($r1)
    lda.b $r2, 0x12345678
    lda.l $r2, 0x12345678
    lda.s $r2, 0x12345678
    ldi.b $r2, 0x12345678
    ldi.l $r2, 0x12345678
    ldi.s $r2, 0x12345678
    ldo.b $r0, -8($fp)
    ldo.l $r0, -8($fp)
    ldo.s $r0, -8($fp)
    lshr $r0, $r1
    mod $r0, $r1
    mov $r0, $r1
    mul $r0, $r1
    mul.x $r0, $r1
    neg $r0, $r1
    nop
    not $r0, $r1
    or $r0, $r1
    pop $r0, $r1
    push $r0, $r1
    ret
    sex.b $r0, $r1
    sex.s $r0, $r1
    ssr $r0, 0x12
    st.b ($r0), $r1
    st.l ($r0), $r1
    st.s ($r0), $r1
    sta.b 0x12345678, $r0
    sta.l 0x12345678, $r0
    sta.s 0x12345678, $r0
    sto.b -8($fp), $r0
    sto.l -8($fp), $r0
    sto.s -8($fp), $r0
    sub $r0, $r1
    swi 0x12345678
    udiv $r0, $r1
    umod $r0, $r1
    umul.x $r0, $r1
    xor $r0, $r1
    zex.b $r0, $r1
    zex.s $r0, $r1
    brk