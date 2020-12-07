/********************************************************************
 * Part of Mike Field's emulate-risc-v project.
 *
 * (c) 2018 Mike Field <hamster@snap.net.nz>
 *
 * See https://github.com/hamsternz/emulate-risc-v for licensing
 * and additional info
 *
 ********************************************************************/
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include "riscv.h"
#include "memory.h"
#include "memorymap.h"
#include "display.h"

int main(int argc, char *argv[]) {

  if(!memory_initialise()) {
    return 0;
  }

  if(!riscv_initialise()) {
    return 0;
  }

  riscv_reset();


  //Run for N machine cycles
  for(int i = 0;i < 10000;i++)
  {
    memory_run();
    riscv_run();
    riscv_dump();
  }


  riscv_finish();
  memory_finish();
  
  return 0;
}
