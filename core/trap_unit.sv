import global_pkg::*;
`include "debug_def.sv"
//Author: Benjamin Herrera Navarro
//Date:1/20/2021
//6:01PM



//This module is the Trap Unit, which has all registers required to handle traps and privilege modes.
//This unit wont hanlde any illegal CSR access, because that will be the work of the control unit, which will
//be in change of detecting weird behavior.

module trap_unit
(
    //Syscon
    input clk,
    input rst,


    //Control signals
    input logic [11:0] addr,
    input logic wr,
    input write_mode_t write_mode, //Chose the mode in which to write to the CSR
    input logic [31:0] din,
    output logic [31:0] dout,

    output logic illegal_address,

    //Control Unit interface
    TRAP_INT.csru trap_int,

    //Interrupt input signals
    input logic timer_irq,

    //Buses that are needed for storing instruction information on a trap or exeption
    input logic [31:0] mepc_bus,
    input logic [31:0] mtval_bus,

    //Signals that must be accessed concurrently
    output logic [31:0] mepc_bus_o,

    //Buses for jumping into trap handlers
    output logic [31:0] trap_address
);


//Privilege modes
parameter M_MODE = 3; //Support for now
parameter U_MODE = 0; //Support for now
parameter S_MODE = 1;

//Current Privilege Mode Register
logic [1:0] CPM;
assign trap_int.cpm = CPM;


//Machine Trap Setup
//0x300 MRW mstatus Machine status register.
//0x301 MRW misa ISA and extensions
//0x302 MRW medeleg Machine exception delegation register.
//0x303 MRW mideleg Machine interrupt delegation register.
//0x304 MRW mie Machine interrupt-enable register.
//0x305 MRW mtvec Machine trap-handler base address.
//0x306 MRW mcounteren Machine counter enable.

logic [31:0] mstatus;
logic [31:0] misa;
logic [31:0] medeleg;
logic [31:0] mideleg;
logic [31:0] mie;
logic [31:0] mtvec;
logic [31:0] mcounteren; //Will not be implemented for now, because there is no S_MODE

//Machine Trap Handling
//0x340 MRW mscratch Scratch register for machine trap handlers.
//0x341 MRW mepc Machine exception program counter.
//0x342 MRW mcause Machine trap cause.
//0x343 MRW mtval Machine bad address or instruction.
//0x344 MRW mip Machine interrupt pending.

//Machine Trap Handling
logic [31:0] mscratch; //Used by the trap handler when it doesn't  want to modify general purpose registers
logic [31:0] mepc;
logic [31:0] mcause;
logic [31:0] mtval;
logic [31:0] mip;

`ifdef sim
initial begin 
    mstatus = 32'b0;
    misa = 32'b0;
    medeleg = 32'b0;
    mideleg = 32'b0;
    mie = 32'b0;
    mtvec = 32'b0;
    mcounteren = 32'b0;
    mscratch = 32'b0;
    mepc = 32'b0;
    mcause = 32'b0;
    mtval = 32'b0;
    mip [6:0] = 0;
    mip [10:8] = 0;
    mip [31:12] = 0;
end
`endif

assign mepc_bus_o = mepc;

parameter DIRECT = 0;
parameter VECTORED = 1;

always_comb begin : vect_mode_mux
    if(trap_int.interrupt)
    begin
        if(mtvec [1:0] == DIRECT) trap_address = {mtvec [31:2], 2'b0};
        else if(mtvec [1:0] ==  VECTORED) trap_address = {mtvec [31:2], 2'b0} + (4 * trap_int.cause);
        else trap_address = {mtvec [31:2], 2'b0};
    end
    else
    begin
        trap_address = mtvec;
    end
end

//Interrupt pending bus for the control unit
assign trap_int.ip [11:11] = ((mie [11:11] & mip [11:11]) & mstatus [3:3]) ? 1'b1 : 1'b0; //External Interrupt
assign trap_int.ip [3:3] = ((mie [3:3] & mip [3:3]) & mstatus [3:3]) ? 1'b1 : 1'b0; //Software Interrupt
assign trap_int.ip [7:7] = ((mie [7:7] & mip [7:7]) & mstatus [3:3]) ? 1'b1 : 1'b0; //Timer Interrupt 

//Other bits are not implemented, so just set them to zero
assign trap_int.ip [2:0] = 0;
assign trap_int.ip [6:4] = 0;
assign trap_int.ip [10:8] = 0;
assign trap_int.ip [31:12] = 0;


/////////////////////////////////////////////////////////////////////
//                     Read and Write Logic                        //
/////////////////////////////////////////////////////////////////////

//Multiplexer to choose the write data
logic [31:0] mux_o_bus;
always_comb begin : csr_din_mux
    unique case(write_mode)
        CSR_SET: mux_o_bus = dout | din;
        CSR_CLEAR: mux_o_bus = dout | ~din;
        CSR_WRITE: mux_o_bus = din;
    endcase
end

assign mip [11:11] = 0; //Not implemented
//assign mip [3:3] //Writtable through software
assign mip [7:7] = timer_irq;

//Interrupts are more important than all synchronomous exeptions
//Write
always@(posedge clk)
begin
    if(rst) //When on reset, disable interrupt and setup the current privilege mode to the highest(M_MODE)
    begin
        CPM = M_MODE;
        //Dissable all global interrupts on mstatus
        mstatus [3:3] = 1'b0;  
    end
    else
    begin
        //First check if there is an interrupt, if so. Take the current state of the instruction
        //Interrupts will be only taken if they are enabled by the current privilege mode.
        if(trap_int.trap_return)
        begin
            //CPM = MPP
            CPM = mstatus[12:11];
            //MIE = MPIE
            mstatus[3:3] = mstatus[7:7];
            //MPIE = 1
            mstatus[7:7] = 1;
        end
        else if(trap_int.exeption)
        begin
            //MPP = CPM
            mstatus[12:11] = CPM;
            //MPIE = MIE
            mstatus[7:7] = mstatus[3:3];
            //MIE = 0
            mstatus[3:3] = 0;
            //Set mcause, mtval, and mepc
            mcause = trap_int.cause;
            mepc = mepc_bus;
            mtval = mtval_bus;
        end
        //Write/Execute instruction if there is no interrupts
        else if(wr)
        begin
            unique case(addr)
                //Machine Trap Setup
                12'h300: mstatus = mux_o_bus;
                12'h301: misa = mux_o_bus;
                12'h302: medeleg = mux_o_bus;
                12'h303: mideleg = mux_o_bus;
                12'h304: mie = mux_o_bus;
                12'h305: mtvec = mux_o_bus;
                //Machine Trap Handling
                12'h340: mscratch = mux_o_bus;
                12'h341: mepc = mux_o_bus;
                12'h342: mcause = mux_o_bus; 
                12'h343: mtval = mux_o_bus;
                12'h344:
                begin
                    mip [6:0] = mux_o_bus [6:0];
                    mip [10:8] = mux_o_bus [10:8];
                    mip [31:12] = mux_o_bus [31:12];
                end 
            endcase
        end
    end
end


//Read
always_comb
begin
    case(addr)
        12'h300: begin dout = mstatus; illegal_address = 1'b0; end
        12'h301: begin dout = misa; illegal_address = 1'b0; end
        12'h302: begin dout = medeleg; illegal_address = 1'b0; end
        12'h303: begin dout = mideleg; illegal_address = 1'b0; end
        12'h304: begin dout = mie; illegal_address = 1'b0; end
        12'h305: begin dout = mtvec; illegal_address = 1'b0; end
        12'h340: begin dout = mscratch; illegal_address = 1'b0; end
        12'h341: begin dout = mepc; illegal_address = 1'b0; end
        12'h342: begin dout = mcause; illegal_address = 1'b0; end 
        12'h343: begin dout = mtval; illegal_address = 1'b0; end
        12'h344: begin dout = mip; illegal_address = 1'b0; end 
        default: begin dout = 32'b0; illegal_address = 1'b1; end
    endcase
end




endmodule