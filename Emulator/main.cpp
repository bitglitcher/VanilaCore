#include <fstream>
#include <iostream>
#include "core/core.h"
#include "bus/bus.h"
#include <memory.h>
#include <limits>



int main()
{

    std::ifstream binary;
    binary.open("ROM.bin", std::ifstream::binary);


    binary.ignore( std::numeric_limits<std::streamsize>::max() );
    std::streamsize size = binary.gcount();
    binary.clear();   //  Since ignore will have set eof.
    binary.seekg( 0, std::ios_base::beg );

    char* buffer = (char*)malloc(size * sizeof(size));

    memset(buffer, 0x00, size);

    binary.read(buffer, size);

    BUS bus;
    MEMORY main_memory(0xffff, 0, 0xffffffff);
    bus.add(&main_memory);


    for(int i = 0; i < size;i++)
    {
        //std::cout << i << ": " << std::hex << (int)buffer[i] << std::endl;
        main_memory.write(buffer[i], i);
    }




    CORE core(0x00, &bus);

    for(int i = 0; i < 69;i++)
    {
        core.execute();
        /* code */
    }
    

    return 0;
}