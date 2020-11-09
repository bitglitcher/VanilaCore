//Author: Benjamin Herrera Navarro
//Date: 11/8/2020
//9:33PM



//Direct memory access unit
module dma
(
    //Used to access the devices to which move data
    WB4.master master_wb,
    //Used to recieve data from the CPU
    WB4.slave slave_wb
);

//Address REGISTER
//0x00000 start
//0x00001 count
//0x00002 begin
//0x00003 busy

reg [31:0] start;
reg [31:0] count;






endmodule
