#include "device.h"

device::device(/* args */)
{
}

device::~device()
{
}

void device::write(uint8_t data, uint32_t address)
{

}
uint8_t device::read(uint32_t address)
{

}

void device::print()
{
    std::cout << "max_address -> " << max_address << std::endl;
    std::cout << "min_address -> " << min_address << std::endl;
}