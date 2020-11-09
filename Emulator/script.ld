

MEMORY
{
    RAM (wr) : org = 0x00000000, len = 1M
}

SECTIONS
{
    . = 0x00000000;
    .text : { * (.text); }
}

OUTPUT(ROM.bin)