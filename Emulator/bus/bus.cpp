#include <iostream>
#include  <iomanip>
#include "bus.h"


void BUS::write(uint8_t data, uint32_t address)
{
    //std::cout << "BUS: Write ->" << "0x" << std::hex << std::setw(8) << std::setfill('0') << address << std::endl;
    for (auto device : devices)
    {
        if(device->min_address <= address && device->max_address >= address)
        {
            //std::cout << "Device found!" << std::endl;
            device->print();
            device->write(data, address);
            return;
        }
    }
}
uint8_t BUS::read(uint32_t address)
{
    //std::cout << "BUS: Read -> " << "0x" << std::hex << std::setw(8) << std::setfill('0') << address << std::endl;
    for (auto device : devices)
    {
        if(device->min_address <= address && device->max_address >= address)
        {
            return device->read(address);
        }
    }
    return 0x0000;
}

void BUS::add(device* device)
{
    devices.push_back(device);
}
