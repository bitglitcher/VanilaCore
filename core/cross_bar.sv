


module cross_bar
(
    //Define master
    WB4.slave cpu,
    WB4.master memory, //New masters
    WB4.master uart, //New masters
    //WB4.master seven_segments,
    WB4.master uart_rx
);

parameter MEMORY_START = 32'h00000000;
parameter MEMORY_END =   32'h000fffff;
parameter UART_START =   32'h00100000;
parameter UART_END =     32'h00100000;
parameter DISPLAY_START =32'h01000000;
parameter DISPLAY_END =  32'h01000000;
parameter UART_RX_START =32'h10000000;
parameter UART_RX_END =  32'h10000004;


always_comb
begin
    memory.ADR = cpu.ADR;
    memory.DAT_O = cpu.DAT_O;
    memory.WE = cpu.WE; 
    memory.CYC = cpu.CYC;
    uart.ADR = cpu.ADR;
    uart.DAT_O = cpu.DAT_O;
    uart.WE = cpu.WE; 
    uart.CYC = cpu.CYC;
    //seven_segments.ADR = cpu.ADR;
    //seven_segments.DAT_O = cpu.DAT_O;
    //seven_segments.WE = cpu.WE; 
    //seven_segments.CYC = cpu.CYC;
    uart_rx.ADR = cpu.ADR;
    uart_rx.DAT_O = cpu.DAT_O;
    uart_rx.WE = cpu.WE; 
    uart_rx.CYC = cpu.CYC;
end




//address decoding
always_comb
begin
        if((cpu.ADR <= MEMORY_END) & (cpu.ADR >= MEMORY_START)) 
        begin
            cpu.DAT_I = memory.DAT_I;
            memory.STB <= cpu.STB;
            uart.STB <= 0;
            //seven_segments.STB <= 0; //Strobe 0 on other devices
            uart_rx.STB = 0;
            cpu.ACK <= memory.ACK;
        end
        else if((cpu.ADR <= UART_END) & (cpu.ADR >= UART_START))  
        begin
            cpu.DAT_I = uart.DAT_I; //Data input to CPU
            uart.STB <= cpu.STB; //Strobe select
            memory.STB <= 0; //Strobe 0 on other devices
            //seven_segments.STB <= 0; //Strobe 0 on other devices
            uart_rx.STB = 0;
            cpu.ACK <= uart.ACK; //ACK input signal
        end
        //else if((cpu.ADR <= DISPLAY_END) & (cpu.ADR >= DISPLAY_START))  
        //begin
        //    cpu.DAT_I = seven_segments.DAT_I; //Data input to CPU
        //    seven_segments.STB <= cpu.STB; //Strobe select
        //    memory.STB <= 0; //Strobe 0 on other devices
        //    uart.STB <= 0; //Strobe 0 on other devices
        //    uart_rx.STB = 0;
        //    cpu.ACK <= seven_segments.ACK; //ACK input signal
        //end
        else if((cpu.ADR <= UART_RX_END) & (cpu.ADR >= UART_RX_START))
        begin
            cpu.DAT_I = uart_rx.DAT_I; //Data input to CPU
            uart_rx.STB <= cpu.STB; //Strobe select
            cpu.ACK <= uart_rx.ACK; //ACK input signal
            
            memory.STB <= 0; //Strobe 0 on other devices
            uart.STB <= 0; //Strobe 0 on other devices
            //seven_segments.STB <= 0;
        end
        else
        begin
            cpu.DAT_I = 0;
            uart.STB <= 0;
            memory.STB <= 0;
            uart_rx.STB = 0;
            //seven_segments.STB <= 0;
            cpu.ACK <= 1;
        end
end




endmodule
