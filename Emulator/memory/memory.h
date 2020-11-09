#ifndef __MEMORY_H__
#define __MEMORY_H__

#include <stdint.h>
#include <vector>
#include "../device/device.h"

//4KB for each block allocated
#define MEM_BYTES (4096)

typedef struct
{
    /* data */
    std::vector<int8_t>* memory;
    size_t memory_region;
} MEM_BLOCK;


class MEMORY : public device
{
    public:
        MEMORY(int initial_size, uint32_t min_address, uint32_t max_address);
        uint8_t read(uint32_t addr);
        void write(uint8_t data, uint32_t addr);
        ~MEMORY();
    private:
        /* data */
        std::vector<MEM_BLOCK> vector_mem; 
};


#endif