/*
Author: Benjamin Herrera Navarro.
Date: 10/24/2020
1:17AM
*/
#ifndef __CORE_H__
#define __CORE_H__


#include <stdint.h>
#include "../device/device.h"
#include "../memory/memory.h"
#include "../bus/bus.h"
#include "inset.h"

//Special purpose registers
//Status register
//INDEX     REG   BIT   FUNC    SIGN
//0x00      STR : 0     = AB -> signed
//0x00      STR : 1     = EB -> signed
//0x00      STR : 2     = BA -> signed
//0x00      STR : 3     = AB -> unsigned
//0x00      STR : 4     = EB -> unsigned
//0x00      STR : 5     = BA -> unsigned

typedef struct {
    unsigned char ab : 1;
    unsigned char eq : 1;
    unsigned char ba : 1;
    unsigned char uab : 1;
    unsigned char ueq : 1;
    unsigned char uba : 1;
} CCR_BITFIELD; //Condition code register bitfield

typedef union {
    CCR_BITFIELD bitset; //When using SPR as CCR
    uint32_t value; //Normal CCR
} SPR_T;

/*
    (fp){0x00},
    (sp){0x01},
    (r0){0x02},
    (r1){0x03},
    (r2){0x04},
    (r3){0x05},
    (r4){0x06},
    (r5){0x07},
    (r6){0x08},
    (r7){0x09},
    (r8){0x0a},
    (r9){0x0b},
    (r10){0x0c},
    (r11){0x0d},
    (r12){0x0e},
    (r13){0x0f}
*/

enum REGISTERS { FP, SP, R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13 };

class CORE
{
    public:
    CORE(uint32_t startup_vector, BUS* bus);

    void execute();

    uint8_t get_ins_opcode(uint8_t data);

    private:
    BUS* bus;
    uint32_t PC;
    uint32_t REGS[15];
    SPR_T SPR[MAX_SPR];
};

#endif