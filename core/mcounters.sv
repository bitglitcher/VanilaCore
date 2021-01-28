import global_pkg::*;
`include "debug_def.sv"

//This unit contains machine counters and machine event selectors, this is the performance monitor
module mcounters
(
    //Syscon
    input logic clk,
    input logic rst,

    //Control signals
    input wire [11:0] addr,
    input logic wr,
    input write_mode_t write_mode, //Chose the mode in which to write to the CSR
    input  logic [31:0] din,
    output logic [31:0] dout,
    output logic illegal_address,

    //Event signal interface for the performance counters
    EVENT_INT.in event_bus
);


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

//This is the true counter enable signal for the performance counters
//0x320 MRW mcountinhibit Machine counter-inhibit register.
logic [31:0] mcountinhibit;

//0x323 MRW mhpmevent3 Machine performance-monitoring event selector.
//0x324 MRW mhpmevent4 Machine performance-monitoring event selector.
//0x33F MRW mhpmevent31 Machine performance-monitoring event selector.
logic [31:0] mhpmevent [12'h33F:12'h323];
 
/////////////////////////////////////////////////////////////////////
//                     Machine Counters                            //
/////////////////////////////////////////////////////////////////////

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
        if(~mcountinhibit[0:0])
        begin
            mcycle = mcycle + 64'h1;        
        end
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
        if(event_bus.execute & ~mcountinhibit[2:2])
        begin
            minstret = minstret + 64'h1;
        end
    end
end

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
        for(int i = 12'h323; i <= 12'h33F;i++)
        begin
            mhpmevent [i] = 0;
        end
        mcountinhibit = 32'b0;
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
                    if(event_bus.load & ~mcountinhibit[(i-12'hB00)])
                    begin
                        mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                STORE_INSTRUCTIONS:
                begin
                    if(event_bus.store & ~mcountinhibit[(i-12'hB00)])
                    begin
                        mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                UNALIGNED_ACCESSES:
                begin
                    if(event_bus.unaligned & ~mcountinhibit[(i-12'hB00)])
                    begin
                        mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                ARITHMETIC_INSTRUCTIONS:
                begin
                    if(event_bus.arithmetic & ~mcountinhibit[(i-12'hB00)])
                    begin
                        mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                NUMBER_OF_TRAPS:
                begin
                    if(event_bus.trap & ~mcountinhibit[(i-12'hB00)])
                    begin
                    mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                INTERRUPT_COUNT:
                begin
                    if(event_bus.interrupt & ~mcountinhibit[(i-12'hB00)])
                    begin
                    mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                UNCONDITIONAL_BRANCH:
                begin
                    if(event_bus.unconditional_branch & ~mcountinhibit[(i-12'hB00)])
                    begin
                    mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                CODITIONAL_BRANCH:
                begin
                    if(event_bus.conditional_branch & ~mcountinhibit[(i-12'hB00)])
                    begin
                    mhpmcounter [i] = mhpmcounter [i] + 1;
                    end
                end
                TAKEN_BRANCHS:
                begin
                    if(event_bus.branch & ~mcountinhibit[(i-12'hB00)])
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

//Write
always@(posedge clk)
begin
    if(wr)
    begin
        if(((addr >= 12'h323) && (addr <= 12'h33F)))
        begin  
            mhpmevent [addr] [31:0] = mux_o_bus;
        end
        else if(addr == 12'h320)
        begin
            mcountinhibit = mux_o_bus;    
        end
    end
end


//Read
always_comb
begin
    if((addr >= 12'hB03) && (addr <= 12'hB1F))
    begin 
        illegal_address = 1'b0; 
        dout = mhpmcounter [addr] [31:0];
    end
    else if((addr >= 12'hB83) && (addr <= 12'hB84))
    begin 
        illegal_address = 1'b0; 
        dout = mhpmcounter [addr] [63:32];
    end		  
    else if((addr >= 12'h323) && (addr <= 12'h33F))
    begin 
        illegal_address = 1'b0; 
        dout = mhpmevent [addr] [31:0];
    end
    else if(addr == 12'h320)
    begin
        dout = mcountinhibit;    
        illegal_address = 1'b0; 
    end
    //0xB00 MRW mcycle Machine cycle counter.
    else if(addr == 12'hB00) begin dout = mcycle[31:0]; illegal_address = 1'b0; end
    //0xB02 MRW minstret Machine instructions-retired counter.
    else if(addr == 12'hB02) begin dout = minstret[31:0]; illegal_address = 1'b0; end
    //0xB80 MRW mcycleh Upper 32 bits of mcycle, RV32I only.
    else if(addr == 12'hB80) begin dout = mcycle[63:32]; illegal_address = 1'b0; end
    //0xB82 MRW minstreth Upper 32 bits of minstret, RV32I only.
    else if(addr == 12'hB82) begin dout = minstret[63:32]; illegal_address = 1'b0; end
    else begin
        dout = 32'b0;
        illegal_address = 1'b1; 
    end

end


endmodule