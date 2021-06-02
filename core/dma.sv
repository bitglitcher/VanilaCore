//Author: Benjamin Herrera Navarro
//Date: 11/8/2020
//9:33PM



//Direct memory access unit
module dma
(
    //Used to access the devices to which move data
    WB4.master master_wb,
    //Used to recieve data from the CPU
    WB4.slave slave_wb,
    output logic irq
);

//Address REGISTER
//0x00000 start
//0x00001 count
//0x00002 conf
//0x00003 irq_clear

reg [31:0] start;
reg [31:0] count;
reg [31:0] offset;
reg [31:0] conf;


//Configuration register
//BIT         ON                OFF        
//0           AUTO INCREMENT    SINGLE ADDRESS WRITE
//1           IRQ ON FINISH


endmodule
