#ifndef __BUS_H__
#define __BUS_H__

#include <stdint.h>
#include <vector>
#include "../device/device.h"

class BUS
{
    public:
        void add(device* device);
        void write(uint8_t data, uint32_t address);
        uint8_t read(uint32_t address);

    private:
        std::vector<device*> devices;
};

#endif