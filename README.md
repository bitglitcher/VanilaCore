# VanilaCore
RISC-V Implementation in System Verilog. This is now a fully working RV32I core with machine mode, the only missing feature to have a complete machine mode implementation is the memory protection unit (MPU).

## Missing Features
  ### Core
  - MPU <- In Progress
  - S Mode
  - U Mode
  - Pipelining
  - A Extention
  - M Extention
  - Debug Mode
  - Load/Store Buffer
  - FENCE.I
  
  ### SoC
  - Cache <- In Progress
  - SPI Controller <- In Progress
  - Matrix Interconnect <- In Progress
  - DMA
  - HDMI Controller
  
 ## Implemented
  - Machine mode
  - Most CSRs for machine mode
  - Unaligned Load Stores
  - UART
  
 ## Goal
 The main goal is to have a fully working application processor that can run the linux kernel. 
