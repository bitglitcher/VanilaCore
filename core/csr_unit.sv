

module csr_unit
(
    //Syscon
    input clk,
    input rst,

    //Commands
    input [11:0] i_imm,
    input [2:0] funct3,
    input [4:0] rd,
    input [4:0] rs_1,
    input csr_unit_enable,

    //Data buses
    input [31:0] din,
    output [31:0] dout,

    //Register file control signals
    output logic wr,

    //Exeption or trap signal to jump
    output logic trap,
    output logic [31:0] address,

    //Used by internally by registers
    //Instruction execute
    input logic execute,
    input logic [31:0] PC
);


//Braking down the i_imm bus
wire priv_mode_bus = i_imm [9:8];
wire rw_access = i_mm [11:0];

///////////////////////////////////////////
//          Privilege Logic              //
///////////////////////////////////////////
//Current Privilege Mode register logic
reg [2:0] cpm;
always@(posedge clk)
begin
    if(rst)
    begin
        cpm = M_MODE;
    end
end

//Privilege modes
parameter M_MODE = 3; //Support for now
parameter U_MODE = 0; //Support for now
parameter S_MODE = 1;

//Illegal privilege access signal
logic illegal_priv_acs;
//Illegal privilege access when tring to access csrs with higher privilege
assign illegal_priv_acs = priv_mode_bus > cpm;

///////////////////////////////////////////
//           Access Decoder              //
///////////////////////////////////////////
//These are only from the immediate side
wire csr_read  = (((rw_access == 00) | (rw_access == 01) | (rw_access == 10) | (rw_access == 11)) & (rd != 0)) ? 1 : 0;
wire csr_read_only = ((rw_access == 11) & rd != 0) ? 1 : 0;
wire csr_write = (((rw_access == 00) | (rw_access == 01) | (rw_access == 10)) & (rs_1 != 0)) ? 1 : 0;


parameter CSRRW = 3'b001; //Read and Write
parameter CSRRS = 3'b010; //Read and Set
parameter CSRRC = 3'b011; //Read and Clear
parameter CSRRWI = 3'b101;
parameter CSRRSI = 3'b110;
parameter CSRRCI = 3'b111;

//The side effects mentioned in the manual mean illegal instructions exeptions
//Caused by a csr write on a read only csr.


logic csrwr_s = ((fuct3 == CSRRW) & (fuct3 == CSRRWI))? 1 : 0;
logic csrrs_s = ((fuct3 == CSRRS) & (fuct3 == CSRRSI))? 1 : 0;
logic csrrc_s = ((fuct3 == CSRRC) & (fuct3 == CSRRCI))? 1 : 0;

//Comamnd write signal 
logic write_cmd_s = csrwr_s | csrrs_s | csrrc_s;
logic read_cmd_s = csrwr_s | csrrs_s | csrrc_s;

//Line logic declared on the Address Decoder section
logic illegal_address;
logic illegal_access;
assign illegal_access = (write_cmd_s & csr_read_only);

/////Register file control logic
//Enable line for register file write signal
assign wr = ((~(illegal_access | illegal_address | illegal_priv_acs) & csr_unit_enable) & csr_write)? 1 : 0;

//Csr write signal valid with no illegal Accesses
assign csr_write_valid = ((~(illegal_access | illegal_address | illegal_priv_acs) & csr_unit_enable) & csr_read)? 1 : 0;


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
assign mvendorid = 0; //Not implemented

//0xF12 MRO marchid Architecture ID.
logic [31:0] marchid;
assign marchid = 0; //Not implemented

//0xF13 MRO mimpid Implementation ID.
logic [31:0] mimpid;
assign mimpid = 0; //Not implemented

//0xF14 MRO mhartid Hardware thread ID.
logic [31:0] mhartid;
assign mhartid = 0; //This must be unique ID. For now 0 because of the single core implementation

////////////////////////
// Machine Trap Setup //
////////////////////////

//0x300 MRW mstatus Machine status register.
logic [31:0] mstatus;



//0x301 MRW misa ISA and extensions
logic [31:0] misa;
//MXL XLEN
//1   32
//2   64
//3   128
//MXL LEN Field
assign misa [31:30] = 1; //Meaning 32bits
//Misa supported exetentions
assign misa [25:0] = 26'b00000000100000000000000000;

//Not supported for now because we only have usermode
//0x302 MRW medeleg Machine exception delegation register.
//0x303 MRW mideleg Machine interrupt delegation register.

//Interrupts not supported for now
//0x304 MRW mie Machine interrupt-enable register.

//0x305 MRW mtvec Machine trap-handler base address.
logic [31:0] mtvec;
parameter MTVEC_RESET_VECTOR = 29'h8000;
parameter MTVEC_RESET_MODE = 2'h0;

//0x306 MRW mcounteren Machine counter enable.

////////////Not defined

/////////////////////////////////////////////////////
//            Machine Trap Handling                //
/////////////////////////////////////////////////////

//0x340 MRW mscratch Scratch register for machine trap handlers.
//0x341 MRW mepc Machine exception program counter.
logic [31:0] mepc;
//0x342 MRW mcause Machine trap cause.

logic [31:0] mcause_din; //Data input bus for mcause
logic mcause_wr;
logic [31:0] mcause;
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

//0x344 MRW mip Machine interrupt pending.

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
//0xB03 MRW mhpmcounter3 Machine performance-monitoring counter.
//0xB04 MRW mhpmcounter4 Machine performance-monitoring counter.
//0xB1F MRW mhpmcounter31 Machine performance-monitoring counter.
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
        12'hf11:
        begin
            dout = mvendorid;
            illegal_address = 1'b0;
        end
        //0xF12 MRO marchid Architecture ID.
        12'hf12:
        begin
            dout = marchid;
            illegal_address = 1'b0;
        end
        //0xF13 MRO mimpid Implementation ID.
        12'hf13:
        begin
            dout = mimpid;
            illegal_address = 1'b0;
        end
        //0xF14 MRO mhartid Hardware thread ID.
        12'hf14:
        begin
            dout = mhartid;
            illegal_address = 1'b0;
        end
        //0x301 MRW misa ISA and extensions
        12'h301:
        begin
            dout = misa;
            illegal_address = 1'b0;
        end
        default:
        begin
            illegal_address = 1'b1;
            //Raise Illegal Instruction exeption, because csr not implemented
        end
    endcase
end

//////////////////////////////////////////
// CSR Write address decoder            //
//////////////////////////////////////////

always@(posedge clk)
begin
    rst
end










////////////////////////////////
// Machine Counter And Timers //
////////////////////////////////

csr_insret m_insret
(
     .clk(clk),
     .rst(rst),
     .ins_exe(ins_exe_minsret), //Instruction execute signal
     .data_i(data_i_minsret),
     .data_o(data_o_minsret)
);











endmodule