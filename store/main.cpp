#include <iostream>
#include <bitset>



int main()
{
    uint32_t data = 0xdeadbeef;
    uint8_t byte = 0x    ae;
    std::cout << "DATA: " << std::bitset<32>(data) << std::endl;


    uint8_t data_bytes[4];
    data_bytes [0] = ((data >> 0) & 0xff);
    data_bytes [1] = ((data >> 8) & 0xff);
    data_bytes [2] = ((data >> 16) & 0xff);
    data_bytes [3] = ((data >> 24) & 0xff);


    return 0;
}