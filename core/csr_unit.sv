
import global_pkg::*;
`include "debug_def.sv"

module csr_unit
(
    //Syscon
    input clk,
    input rst,

    //Commands
    input [11:0] i_imm,
    input [2:0] funct3,
    input [4:0] rd,
    input [4:0] rs1,
    input csr_unit_enable, //Enable signal for write and reads
    input logic [31:0] rs1_d,
    input trap_return,

    //Data buses
    output logic [31:0] dout,

    //Register file control signals
    output logic wr,

    //Exeption or trap signal to jump
    output logic jmp_handler,
    output logic [31:0] address,

    //Used by internally by registers
    //Instruction execute
    input logic execute,
    input logic [31:0] PC,
    input logic [31:0] IR,
    input logic illegal_ins,

    //Mcause
    //input logic [31:0] mcause_din,
    //input logic mcause_wr

    //Event signal interface for the performance counters
    input memory_operation_t memory_operation,
    input logic cyc_memory_operation,
    input logic arithmetic_event,
    input wire [31:0] address_ld,
    input logic unconditional_branch,
    input logic conditional_branch,

    //Interrupt signals
    input logic external_interrupt,
    input logic timer_irq,

    //Jump signal to know when a branch is taken
    input logic branch,

    //Signal to tell the Control Unit to ignore next instruction
    output logic ignore_next

    //Output buses for registers that are needed concurrently.
);


//Braking down the i_imm bus
wire [1:0] priv_mode_bus = i_imm [9:8];
wire [1:0] rw_access = i_imm [11:10];


//Privilege modes
parameter M_MODE = 3; //Support for now
parameter U_MODE = 0; //Support for now
parameter S_MODE = 1;

//Current Privilege Mode register logic
reg [2:0] cpm;

//Illegal privilege access signal
logic illegal_priv_acs;
//Illegal privilege access when tring to access csrs with higher privilege
assign illegal_priv_acs = priv_mode_bus > cpm;

///////////////////////////////////////////
//           Access Decoder              //
///////////////////////////////////////////
//These are only from the immediate side
wire csr_read  = (((rw_access == 2'b00) | (rw_access == 2'b01) | (rw_access == 2'b10) | (rw_access == 2'b11)) & (rd != 0)) ? 1 : 0;
wire csr_read_only = ((rw_access == 2'b11) & (rd != 0)) ? 1 : 0;
wire csr_write = (((rw_access == 2'b00) | (rw_access == 2'b01) | (rw_access == 2'b10)) & (rs1 != 0)) ? 1 : 0;


parameter CSRRW = 3'b001; //Read and Write
parameter CSRRS = 3'b010; //Read and Set
parameter CSRRC = 3'b011; //Read and Clear
parameter CSRRWI = 3'b101;
parameter CSRRSI = 3'b110;
parameter CSRRCI = 3'b111;

//The side effects mentioned in the manual mean illegal instructions exeptions
//Caused by a csr write on a read only csr.


wire csrwr_s = ((funct3 == CSRRW) | (funct3 == CSRRWI))? 1 : 0;
wire csrrs_s = ((funct3 == CSRRS) | (funct3 == CSRRSI))? 1 : 0;
wire csrrc_s = ((funct3 == CSRRC) | (funct3 == CSRRCI))? 1 : 0;

//Comamnd write signal 
wire write_cmd_s = csrwr_s | csrrs_s | csrrc_s;
wire read_cmd_s = csrwr_s | csrrs_s | csrrc_s;

//Line logic declared on the Address Decoder section
logic illegal_address;
logic illegal_access;
assign illegal_access = (write_cmd_s & csr_read_only);

/////Register file control logic
//Enable line for register file write signal
logic csr_write_valid;
assign csr_write_valid = ((~(illegal_access | illegal_address | illegal_priv_acs) & csr_unit_enable) & csr_write)? 1 : 0;

//Csr write signal valid with no illegal Accesses
assign wr = ((~(illegal_access | illegal_address | illegal_priv_acs) & csr_unit_enable) & csr_read)? 1 : 0;


//////////////////////////////////////////////
//    Machine Mode CSR Registers Addresses  //
//////////////////////////////////////////////

//0xF11 MRO mvendorid Vendor ID.
//0xF12 MRO marchid Architecture ID.
//0xF13 MRO mimpid Implementation ID.
//0xF14 MRO mhartid Hardware thread ID.
//Machine Trap Setup
//0x300 MRW mstatus Machine status register.
//0x301 MRW misa ISA and extensions
//0x302 MRW medeleg Machine exception delegation register.
//0x303 MRW mideleg Machine interrupt delegation register.
//0x304 MRW mie Machine interrupt-enable register.
//0x305 MRW mtvec Machine trap-handler base address.
//0x306 MRW mcounteren Machine counter enable.
//Machine Trap Handling
//0x340 MRW mscratch Scratch register for machine trap handlers.
//0x341 MRW mepc Machine exception program counter.
//0x342 MRW mcause Machine trap cause.
//0x343 MRW mtval Machine bad address or instruction.
//0x344 MRW mip Machine interrupt pending.

//0xF11 MRO mvendorid Vendor ID.
logic [31:0] mvendorid;
assign mvendorid = 32'hdeadbeef; //Not implemented

//0xF12 MRO marchid Architecture ID.
logic [31:0] marchid;
assign marchid = 32'hbeefeaea; //Not implemented

//0xF13 MRO mimpid Implementation ID.
logic [31:0] mimpid;
assign mimpid = 32'hfaabaaaa; //Not implemented

//0xF14 MRO mhartid Hardware thread ID.
logic [31:0] mhartid;
assign mhartid = 32'haeaeaeae; //This must be unique ID. For now 0 because of the single core implementation

////////////////////////
// Machine Trap Setup //
////////////////////////

//////////////////////////MSTATUS BITS//////////////////////////
//
//SD WPRI TSR TW TVM MXR SUM MPRV
//1   8    1  1   1   1   1   1
//
//XS[1:0] FS[1:0] MPP[1:0] WPRI SPP MPIE WPRI SPIE UPIE MIE WPRI SIE UIE
//2        2          2     2    1    1   1    1     1  1    1    1   1


//0x300 MRW mstatus Machine status register.
logic [31:0] mstatus;

//Global interrupt enable signal for machine mode
logic m_mode_global_int_e;
assign m_mode_global_int_e = mstatus [3:3];

//0x301 MRW misa ISA and extensions
logic [31:0] misa;
//MXL XLEN
//1   32
//2   64
//3   128
//MXL LEN Field
assign misa [31:30] = 1; //Meaning 32bits
assign misa [29:26] = 0; //IDK
//Misa supported exetentions
assign misa [25:0] = 26'b00000000100000000000000000;

//Not supported for now because we only have usermode
//0x302 MRW medeleg Machine exception delegation register.
//0x303 MRW mideleg Machine interrupt delegation register.

//Interrupts not supported for now (Fuck it, support interrupts now >:(   ...)
//0x304 MRW mie Machine interrupt-enable register.

//MXLEN-1 12  11    10    9    8    7   6   5     4    3    2    1    0
// WPRI       MEIP WPRI SEIP UEIP MTIP WPRI STIP UTIP MSIP WPRI SSIP USIP
//MXLEN-12    1    1    1    1    1    1    1    1    1    1    1    1


// Basically interrupts will be taken when the interrupt is enabled on the mie register;
// if the global interrupt enable bit is set on mstatus, and if the appropiate interrup is on
// the mip register

logic [31:0] mie;


//0x305 MRW mtvec Machine trap-handler base address.

logic [31:0] mtvec;
parameter MTVEC_RESET_VECTOR = 29'h8000;
parameter MTVEC_RESET_MODE = 2'h0;

parameter MTVEC_DIRECT = 0;
parameter MTVEC_VECTORED = 1;

//Defined here because mtvec uses it
logic [31:0] mcause;



//0x306 MRW mcounteren Machine counter enable.

////////////Not defined

/////////////////////////////////////////////////////
//            Machine Trap Handling                //
/////////////////////////////////////////////////////

//0x340 MRW mscratch Scratch register for machine trap handlers.
logic [31:0] mscratch;

//0x341 MRW mepc Machine exception program counter.
logic [31:0] mepc;

//0x342 MRW mcause Machine trap cause.

logic [31:0] mcause_din; //Data input bus for mcause
logic mcause_wr;
//logic [31:0] mcause;

parameter INS_ADDR_BRKPT = 3;
parameter INS_PAGE_FAULT = 12;
parameter INS_ACCESS_FAULT = 1;  
parameter ILLEGAL_INS = 2;  
parameter INS_ADDR_MISALIGNED = 0;
parameter ENV_CALL_8 = 8;
parameter ENV_CALL_9 = 9; 
parameter ENV_CALL_11 = 11;
parameter ENV_BREAK = 3;
parameter LS_ADDR_BRKPT = 3;
parameter STORE_ADDR_MISALIGNED = 6; 
parameter LOAD_ADDRESS_MISALIGNED = 4;
parameter STORE_PAGE_FAULT = 15;
parameter LOAD_PAGE_FAULT = 13;
parameter STORE_ACCESS_FAULT = 7;
parameter LOAD_ACCESS_FAULT = 5;

//1  Supervisor software interrupt
//3  Machine software interrupt
//4  User timer interrupt
//5  Supervisor timer interrupt
//7  Machine timer interrupt
//8  User external interrupt
//9  Supervisor external interrupt
//11 Machine external interrupt
//
//
//0 0 Instruction address misaligned
//0 1 Instruction access fault
//0 2 Illegal instruction
//0 3 Breakpoint
//0 4 Load address misaligned
//0 5 Load access fault
//0 6 Store/AMO address misaligned
//0 7 Store/AMO access fault
//0 8 Environment call from U-mode
//0 9 Environment call from S-mode
//0 11 Environment call from M-mode
//0 12 Instruction page fault
//0 13 Load page fault
//0 15 Store/AMO page fault

always_comb
begin
    if(illegal_ins) mcause_din = ILLEGAL_INS;
    else mcause_din = 32'b000000000000;
end

assign mcause_wr = illegal_ins;

always@(posedge clk)
begin
    if(rst)
    begin
        mcause = 31'b0;
    end
    else
    begin
        if(mcause_wr)
        begin
            mcause = mcause_din;
        end
    end
end
//0x343 MRW mtval Machine bad address or instruction.

logic [31:0] mtval;
always@(posedge clk)
begin
    if(rst)
    begin
        mtval =  32'b0;
    end
    else
    begin
        if(illegal_ins)
        begin
            mtval = IR;
        end
        else
        begin
            mtval = mtval;
        end
    end

end

//0x344 MRW mip Machine interrupt pending.
//MXLEN-1 12 11   10   9     8   7    6    5    4    3    2    1    0
//WPRI       MEIP WPRI SEIP UEIP MTIP WPRI STIP UTIP MSIP WPRI SSIP USIP
//MXLEN-12   1    1    1     1   1    1    1    1    1    1    1    1

//There are some bits of the mip register and some of the interrupt register, to have both, signals from the mip register
//and signals from interrupt signals. There is a bit of memory and then and OR gate in between the interrupt signal. The result
//of that OR gate is the actual value of the "MIP" register that will be taken.

logic [31:0] mip; //MIP register
logic [31:0] mip_int_bus; //Interrup bus that cotains all interrup signal

wire [31:0] virtual_mip = mip [31:0] | mip_int_bus [31:0];



/////////////////////////////////////////////////////
//         Machine Mode Counters and Timers        //
/////////////////////////////////////////////////////

//0xB00 MRW mcycle Machine cycle counter.
logic [63:0] mcycle; 
always@(posedge clk) //This is read only register
begin
    if(rst)
    begin
        mcycle = 64'b0;
    end
    else
    begin
        //Increment counter
        mcycle = mcycle + 64'h1;
    end
end

//0xB02 MRW minstret Machine instructions-retired counter.
logic [63:0] minstret;
always@(posedge clk) //Read only instruction counter
begin
    if(rst)
    begin
        minstret = 64'h0;
    end
    else
    begin
        if(execute)
        begin
            minstret = minstret + 64'h1;
        end
    end
end

/////////////////////////////////////////////////////////////////////
//                     Machine Counter Setup                       //
/////////////////////////////////////////////////////////////////////


parameter LOAD_INSTRUCTIONS = 1;
parameter STORE_INSTRUCTIONS = 2;
parameter UNALIGNED_ACCESSES = 3;
parameter ARITHMETIC_INSTRUCTIONS = 4;
parameter NUMBER_OF_TRAPS = 5;
parameter INTERRUPT_COUNT = 6;
parameter UNCONDITIONAL_BRANCH = 7;
parameter CODITIONAL_BRANCH = 8;
parameter TAKEN_BRANCHS = 9;


//0x320 MRW mcountinhibit Machine counter-inhibit register.

//0x323 MRW mhpmevent3 Machine performance-monitoring event selector.
//0x324 MRW mhpmevent4 Machine performance-monitoring event selector.
//0x33F MRW mhpmevent31 Machine performance-monitoring event selector.
logic [31:0] mhpmevent [12'h33F:12'h323];
 
//0xB03 MRW mhpmcounter3 Machine performance-monitoring counter.
//0xB04 MRW mhpmcounter4 Machine performance-monitoring counter.
//0xB1F MRW mhpmcounter31 Machine performance-monitoring counter.

logic [63:0] mhpmcounter [12'hB1F:12'hB03];

`ifdef sim
    initial begin
        for(int i = 12'hB03; i <= 12'hB1F;i++)
        begin
            mhpmcounter [i] = 0;
        end
        for(int i = 12'h33F; i <= 12'h323;i++)
        begin
            mhpmevent [i] = 0;
        end
    end
`endif

genvar i;
generate
    //Maybe
    for(i = 12'hB03; i <= 12'hB1F;i++)
    begin : performance_counter_logic
        always@(posedge clk)
        begin
            case(mhpmevent [(i-12'hB03)+12'h323])
                LOAD_INSTRUCTIONS:
                begin
                   if((memory_operation == LOAD_DATA) & cyc_memory_operation)
                   begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                   end
                end
                STORE_INSTRUCTIONS:
                begin
                    if((memory_operation == STORE_DATA) & cyc_memory_operation)
                    begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                UNALIGNED_ACCESSES:
                begin
                    if(address_ld[1:0] != 2'b00)
                    begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                ARITHMETIC_INSTRUCTIONS:
                begin
                    if(arithmetic_event)
                    begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                NUMBER_OF_TRAPS:
                begin
                    if(jmp_handler | illegal_ins)
                    begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                INTERRUPT_COUNT:
                begin
                    if(external_interrupt)
                    begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                UNCONDITIONAL_BRANCH:
                begin
                    if(unconditional_branch)
                    begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                CODITIONAL_BRANCH:
                begin
                    if(conditional_branch)
                    begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                TAKEN_BRANCHS:
                begin
                    if(unconditional_branch)
                    begin
                       mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                default:
                begin
                    mhpmcounter [i] = mhpmcounter [i];
                end
            endcase
        end
    end
endgenerate

//0xB80 MRW mcycleh Upper 32 bits of mcycle, RV32I only.
//0xB82 MRW minstreth Upper 32 bits of minstret, RV32I only.


//0xB83 MRW mhpmcounter3h Upper 32 bits of mhpmcounter3, RV32I only.
//0xB84 MRW mhpmcounter4h Upper 32 bits of mhpmcounter4, RV32I only.
//0xB9F MRW mhpmcounter31h Upper 32 bits of mhpmcounter31, RV32I only.




//////////////////////////////////////////////
//              Address decoder             //
//////////////////////////////////////////////
//Only to  read a csr
always_comb
begin
    case(i_imm)
        //0xF11 MRO mvendorid Vendor ID.
        12'hf11: begin dout = mvendorid; illegal_address = 1'b0; end
        //0xF12 MRO marchid Architecture ID.
        12'hf12: begin dout = marchid; illegal_address = 1'b0; end
        //0xF13 MRO mimpid Implementation ID.
        12'hf13: begin dout = mimpid; illegal_address = 1'b0; end
        //0xF14 MRO mhartid Hardware thread ID.
        12'hf14: begin dout = mhartid; illegal_address = 1'b0; end
        //0x300 MRW mstatus Machine status register.
        12'h300: begin dout = mstatus; illegal_address = 1'b0; end
        //0x301 MRW misa ISA and extensions
        12'h301: begin dout = misa; illegal_address = 1'b0; end
        //0x304 MRW mie Machine interrupt-enable register.
        12'h304: begin dout = mie; illegal_address = 1'b0; end
        //0x340 MRW mscratch Scratch register for machine trap handlers.
        12'h340: begin dout = mscratch; illegal_address = 1'b0; end
        //0x341 MRW mepc Machine exception program counter.
        12'h341: begin dout = mepc; illegal_address = 1'b0; end
        //0x344 MRW mip Machine interrupt pending.
        12'h344: begin dout = virtual_mip; illegal_address = 1'b0; end
        //0xB00 MRW mcycle Machine cycle counter.
        12'hB00: begin dout = mcycle[31:0]; illegal_address = 1'b0; end
        //0xB02 MRW minstret Machine instructions-retired counter.
        12'hB02: begin dout = minstret[31:0]; illegal_address = 1'b0; end
        //0xB80 MRW mcycleh Upper 32 bits of mcycle, RV32I only.
        12'hB80: begin dout = minstret[63:32]; illegal_address = 1'b0; end
        //0xB82 MRW minstreth Upper 32 bits of minstret, RV32I only.
        12'hB82: begin dout = minstret[63:32]; illegal_address = 1'b0; end
        //Event thingy 
        //0x323 MRW mhpmcounter3-31 Machine performance-monitoring event selector.
        default:
        begin
            if((i_imm >= 12'hB03) && (i_imm <= 12'hB1F))
            begin 
                illegal_address = 1'b0; 
                dout = mhpmcounter [i_imm] [31:0];
            end
            else if((i_imm >= 12'h323) && (i_imm <= 12'h33F))
            begin 
                illegal_address = 1'b0; 
                dout = mhpmevent [i_imm] [31:0];
            end
            else if((i_imm >= 12'hB83) && (i_imm <= 12'hB84))
            begin 
                illegal_address = 1'b0; 
                dout = mhpmcounter [i_imm] [63:32];
            end		  
            else
            begin
                illegal_address = 1'b0; 
                dout = 32'h0;
                //Raise Illegal Instruction exeption, because csr not implemented
            end
        end
    endcase
end


/////////////////////////////////////////////////
//    Multiplexer for the registers write bus  //
/////////////////////////////////////////////////

logic [31:0] regin_bus;
always_comb
begin
    unique case(funct3)
        CSRRW: regin_bus = rs1_d;
        CSRRS: regin_bus = (rs1_d | dout);
        CSRRC: regin_bus = (rs1_d & ~dout);
        CSRRWI: regin_bus = {20'b0,i_imm};
        CSRRSI: regin_bus = ({20'b0,i_imm} | dout);
        CSRRCI: regin_bus = ({20'b0,i_imm} & ~dout);
    endcase
end


//////////////////////////////////////////////////////////////////////////
// CSR Write address decoder  and   Privilege Logic and Trap Handling   //
//////////////////////////////////////////////////////////////////////////
always@(posedge clk)
begin
    if(rst)
    begin
        cpm = M_MODE;
    end
    else
    begin
        //If trap, exeption or interrupt set mstatus.MPP = Current Mode
        if(jmp_handler)
        begin
            //MPP <- current privilege mode
            mstatus[12:11] = cpm;    
            //Set cmp = M_MODE
            cpm = M_MODE;
            //Set MPIE = MIE
            mstatus[7:7] = mstatus[3:3];    
            //MIE = 0
            mstatus[3:3] = 0;
            //mepc to PC
            mepc = PC;
        end else if(trap_return)
        begin
            //current privilege mode = MPP
            cpm = mstatus[12:11];
            //Set MPIE = MIE
            mstatus[3:3] = mstatus[7:7];    
            //MPIE = 1
            mstatus[7:7] = 1;
            //mepc to PC
            //PC = mepc;
        end
        else if(csr_write_valid)
        begin
            case(i_imm)
                //0x300 MRW mstatus Machine status register.
                12'h300: mstatus = regin_bus;
                //0x304 MRW mie Machine interrupt-enable register.
                12'h304: mie = regin_bus;
                //0x305 MRW mtvec Machine trap-handler base address.
                12'h305: mtvec = regin_bus;
                //0x340 MRW mscratch Scratch register for machine trap handlers.
                12'h340: mscratch = regin_bus;
                //0x344 MRW mip Machine interrupt pending.
                12'h344: mip = regin_bus;
                //Event thingy 
                //0x323 MRW mhpmevent3-31 Machine performance-monitoring event selector.
                default:
                begin
                    if((i_imm >= 12'h323) && (i_imm <= 12'h33F))
                    begin
                        mhpmevent [i_imm] [31:0] = regin_bus;            
                    end
                end
            endcase
        end
    end
end


////////////////////////////////////////////////////
//        Trap signal logic                      //
////////////////////////////////////////////////////

assign jmp_handler = ((illegal_access | illegal_access | illegal_priv_acs) & csr_unit_enable);


////////////////////////////////////////
//  Machine Trap Vector Multiplexer   //
////////////////////////////////////////

always_comb
begin
    if(trap_return)
    begin
        address = mepc;
    end
    else
    begin
        if(mtvec[1:0] == MTVEC_DIRECT) address = {mtvec [31:2], 2'b00};
        else if(mtvec[1:0] == MTVEC_VECTORED) address = {mtvec [31:2], 2'b00} + (mcause << 2);
        else address = {mtvec [31:2], 2'b00};
    end
end



endmodule