//Author: Benjamin Herrera Navarro
//Date: 1/26/2020
//This piece of code will test if the timers and trap unit work correctly
#include <stdint.h>
#include "memory_map.h"

extern void _set_time_int(int cycles);
extern uint64_t _get_time();

volatile char* terminal_buff_size = (char*)TERMINAL_SIZE;
volatile char* terminal_i = (char*)TERMINAL_I_DATA;


void print(char* string)
{
  //TERMINAL_ADDR_L is just a macro defined on "memory_map.h"
  volatile char* terminal_base_addr = (char*)TERMINAL_ADDR_L;
  char* ptr = string;
  while(*ptr != '\0')
  {
    *terminal_base_addr = *ptr;
    ptr = ptr + 1;
  }
  return;
}

void trap_handler(uint32_t mepc, uint32_t mcause, uint32_t mtval)
{
  print("Currently on trap handler! :)\n");
}

uint32_t cnt;
void timer_interrupt_handler()
{
  print("Currently on timer handler %d\n");
  _set_time_int(0x04000);

}

int main()
{
    while(1);
    return 0;
}