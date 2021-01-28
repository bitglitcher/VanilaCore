
import global_pkg::*;
`include "debug_def.sv"

module csr_unit
(
    //Syscon
    input logic clk,
    input logic rst,

    //Read/Write Address
    input logic [11:0] i_imm,

    //Write Control
    input logic wr,
    input write_mode_t write_mode,

    //Data buses
    input logic [31:0] din, 
    output logic [31:0] dout, 

    //Control Unit interface
    TRAP_INT trap_int,

    //Event signals
    EVENT_INT.in event_bus,

    //Interrupt input signals
    input logic timer_irq,

    //Signals that are needed on the trap unit
    input logic [31:0] mepc_bus,
    input logic [31:0] mtval_bus,

    //Signals that are needed to return from trap handler(Restore PC)
    output logic [31:0] mepc_bus_o,

    //Buses for jumping into trap handlers
    output logic [31:0] trap_address
);

logic [31:0] dout_mcount;
logic [31:0] dout_minfo;
logic [31:0] dout_mtrap;

logic illegal_address_mcount;
logic illegal_address_minfo;
logic illegal_address_mtrap;
assign trap_int.illegal_address = illegal_address_mcount | illegal_address_minfo | illegal_address_mtrap;

mcounters mcounters_0
(
    //Syscon
    .clk(clk),
    .rst(rst),

    //Control signals
    .addr(i_imm),
    .wr(wr),
    .write_mode(write_mode), //Chose the mode in which to write to the CSR
    .din(din),
    .dout(dout_mcount),
    .illegal_address(illegal_address_mcount),

    //Event signal interface for the performance counters
    .event_bus(event_bus)
);


minfo minfo_0
(
    //Control signals
    .addr(i_imm),
    .dout(dout_minfo),
    .illegal_address(illegal_address_minfo)
);

trap_unit trap_unit_0
(
    //Syscon
    .clk(clk),
    .rst(rst),

    //Control signals
    .addr(i_imm),
    .wr(wr),
    .write_mode(write_mode), //Chose the mode in which to write to the CSR
    .din(din),
    .dout(dout_mtrap),
    .illegal_address(illegal_address_mtrap),

    //Control Unit interface
    .trap_int(trap_int),
    
    //Interrupt input signals
    .timer_irq(timer_irq),

    //Signals that must be accessed concurrently
    .mepc_bus(mepc_bus),
    .mtval_bus(mtval_bus),

    //Buses that are needed for storing instruction information on a trap or exeption
    .mepc_bus_o(mepc_bus_o),

    //Buses for jumping into trap handlers
    .trap_address(trap_address)
);


/////////////////////////////////////////////////////////
//     Multiplexer to choose from which unit to read   //
/////////////////////////////////////////////////////////


always_comb begin : yay_using_blocks
    //Machine info CSR unit
    if((i_imm >= 12'hf12) && (i_imm <= 12'hf14))
    begin
        dout = dout_minfo;
    end
    //Machine Trap Setup
    else if(((i_imm >= 12'h300) && (i_imm <= 12'h306)) || ((i_imm >= 12'h340) && (i_imm <= 12'h344)))
    begin
        dout = dout_mtrap;
    end
    //Machine Counters/Timers
    else if(((i_imm >= 12'hB00) && (i_imm <= 12'hB9F)) || ((i_imm >= 12'h320) && (i_imm <= 12'h33F)))
    begin
        dout = dout_mcount;
    end
	else
	begin
	    dout = 32'b0;
	end

end

endmodule
