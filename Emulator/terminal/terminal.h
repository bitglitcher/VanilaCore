#ifndef __TERMINAL_H__
#define __TERMINAL_H__

#include "../device/device.h"


class terminal: public device
{

public:
    void write(int8_t data, int8_t address);
    uint8_t read(int8_t address);

private:

};



void terminal::write(int8_t data, int8_t address)
{


}


uint8_t terminal::read(int8_t address)
{


}


#endif