
import global_pkg::*;

//This is a crossbar switch that allows to have multiple masters cummunicating to slave devices
module cross_bar
#(
    parameter N_SLAVES = 2;    
    parameter N_MASTER = 1;    
)
(
    WB4 [N_SLAVES-1:0] masters;
    WB4 [N_MASTER-1:0] slaves;
    memory_map_t [N_SLAVES-1:0] slave_memory_map;
);

parameter MEMORY_START = 32'h00000000;
parameter MEMORY_END =   32'h000fffff;

//Device Region
parameter UART_START =   32'h00100000;
parameter UART_END =     32'h00100000;
parameter DISPLAY_START =32'h00100010;
parameter DISPLAY_END =  32'h00100010;
parameter UART_RX_START =32'h00100020;
parameter UART_RX_END =  32'h00100024;
parameter TIMER_START =  32'h00100030;
parameter TIMER_END =    32'h0010003f;


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
    timer_dev.ADR = cpu.ADR;
    timer_dev.DAT_O = cpu.DAT_O;
    timer_dev.WE = cpu.WE; 
    timer_dev.CYC = cpu.CYC;
end




//address decoding
always_comb
begin
        if((cpu.ADR <= MEMORY_END) & (cpu.ADR >= MEMORY_START)) 
        begin
            cpu.DAT_I = memory.DAT_I;
            memory.STB <= cpu.STB;
            uart.STB <= 0;
            timer_dev.STB <= 0;
            //seven_segments.STB <= 0; //Strobe 0 on other devices
            uart_rx.STB = 0;
            cpu.ACK <= memory.ACK;
        end
        else if((cpu.ADR <= UART_END) & (cpu.ADR >= UART_START))  
        begin
            cpu.DAT_I = uart.DAT_I; //Data input to CPU
            uart.STB <= cpu.STB; //Strobe select
            memory.STB <= 0; //Strobe 0 pon other devices
            //seven_segments.STB <= 0; //Strobe 0 on other devices
            uart_rx.STB = 0;
            timer_dev.STB <= 0;
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
            
            timer_dev.STB <= 0;
            memory.STB <= 0; //Strobe 0 on other devices
            uart.STB <= 0; //Strobe 0 on other devices
            //seven_segments.STB <= 0;
        end
        else if((cpu.ADR <= TIMER_END) & (cpu.ADR >= TIMER_START))
        begin
            cpu.DAT_I = timer_dev.DAT_I; //Data input to CPU
            cpu.ACK <= timer_dev.ACK; //ACK input signal
            timer_dev.STB <= cpu.STB; //Strobe select
            
            uart_rx.STB <= 0; //Strobe select
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
            timer_dev.STB = 0;
            //seven_segments.STB <= 0;
            cpu.ACK <= 1;
        end
end


typedef struct packed {
    logic [31:0] DAT;
    logic [$clog2(N_MASTER)-1:0] STB;
    logic [$clog2(N_MASTER)-1:0] WE;
} CONNECT_LAYER;

logic [31:0] DAT;
logic [$clog2(N_MASTER)-1:0] STB;
logic [$clog2(N_MASTER)-1:0] WE;



//Arbitrer, this will chosse which master will take the bus
always_comb begin : arbitrer
    
end


//Select lines for the master multiplexer
logic [$clog2(N_MASTER)-1:0] select;

//Multiplexer for ACK, DAT and WE
genvar i;
generate
    for(i = 0; i < N_MASTER;i++)
    begin
        if(select == i)
        begin
            DAT = masters[i].DAT_O;
            ADR = masters[i].ADR;
            WE = masters[i].WE;
            STB = masters[i].STB;
        end
    end
endgenerate


//Connect the outputs of the multiplxer to the corresponfing slave inputs
genvar i;
generate
    for(i = 0; i < N_MASTER;i++)
    begin
        if(select == i)
        begin
            DAT = masters[i].DAT_O;
            ADR = masters[i].ADR;
            WE = masters[i].WE;
            STB = masters[i].STB;
        end
    end
endgenerate




endmodule
