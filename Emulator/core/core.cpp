//Author: Benjamin Herrera Navarro
//Date: 10/19/2020 7:16PM
#include "core.h"
#include "../bus/bus.h"

CORE::CORE(uint32_t startup_vector, BUS* bus)
{
    this->PC = startup_vector;
    this->bus = bus;
}


void CORE::execute()
{
    //Read from memory
    bus->read(PC);
    bus->write(PC, PC);
    //Decode instruction lenght
    PC++;
}