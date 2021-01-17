//3:51AM Arithmetic Logic Unit for the RISC V RV32I implementation

module alu
(
    input  logic [31:0] ra_d,
    input  logic [31:0] rb_d,
    output logic [31:0] rd_d,
    input  logic [2:0] func3,
    input  logic [6:0] func7,
    input  logic imm_t
);

wire signed [31:0] signed_ra = ra_d; 
wire signed [31:0] signed_rb = rb_d; 

//R type
parameter ADD =  10'b0000000000;
parameter SUB =  10'b0100000000;
parameter SLL =  10'b0000000001;
parameter SLT =  10'b0000000010;
parameter SLTU = 10'b0000000011;
parameter XOR =  10'b0000000100;
parameter SRL =  10'b0000000101;
parameter SRA =  10'b0100000101;
parameter OR =   10'b0000000110;
parameter AND =  10'b0000000111;
//I type
parameter ADDI =  10'b???????000;
parameter SLTI =  10'b???????010;
parameter SLTIU = 10'b???????011;
parameter XORI =  10'b???????100;
parameter ORI =   10'b???????110;
parameter ANDI =  10'b???????111;
parameter SLLI =  10'b???????001;
parameter SRLI =  10'b0000000101;
parameter SRAI =  10'b0100000101;

always_comb
begin
    if(imm_t)
    begin
        casez({func7, func3})
            ADDI: rd_d = signed_ra + signed_rb;
            SLTI: rd_d = (signed_ra < signed_rb) ? 32'h00000001 : 32'h00000000;
            SLTIU: rd_d = (ra_d < rb_d) ? 32'h00000001 : 32'h00000000;
            XORI: rd_d = ra_d ^ rb_d;
            ORI: rd_d = ra_d | rb_d;
            ANDI: rd_d = ra_d & rb_d;
            SLLI: rd_d = ra_d << rb_d [4:0];
            SRLI: rd_d = ra_d >> rb_d [4:0];
            SRAI: rd_d = signed'(ra_d) >>> rb_d [4:0];
            default: rd_d = 32'h00000000;
        endcase
    end
    else
    begin
        case({func7, func3})
            ADD: rd_d = signed_ra + signed_rb;
            SUB: rd_d = signed_ra - signed_rb;
            SLL: rd_d = ra_d << rb_d [4:0];
            SLT: rd_d = (signed_ra < signed_rb) ? 32'h00000001 : 32'h00000000;
            SLTU: rd_d = (ra_d < rb_d) ? 32'h00000001 : 32'h00000000;
            XOR: rd_d = ra_d ^ rb_d;
            SRL: rd_d = ra_d >> rb_d [4:0];
            SRA: rd_d = signed'(ra_d) >>> rb_d [4:0];
            OR: rd_d = ra_d | rb_d;
            AND: rd_d = ra_d & rb_d;
            default: rd_d = 32'h00000000;
        endcase
    end
end

endmodule


module branch_unit
(
    input [31:0] rs1_d,
    input [31:0] rs2_d,
    input [2:0] funct3,
    input enable,
    output logic branch
);

logic BEQ_S;
logic BNE_S;
logic BLT_S;
logic BGE_S;
logic BLTU_S;
logic BGEU_S;

parameter BEQ = 3'b000;
parameter BNE = 3'b001;
parameter BLT = 3'b100;
parameter BGE = 3'b101;
parameter BLTU = 3'b110;
parameter BGEU = 3'b111;

//Branch logic
assign BEQ_S = ((32'(signed'(rs1_d)) == 32'(signed'(rs2_d))) & (funct3 == BEQ))? 1 : 0;
assign BNE_S = ((32'(signed'(rs1_d)) != 32'(signed'(rs2_d))) & (funct3 == BNE))? 1 : 0;
assign BLT_S = ((32'(signed'(rs1_d)) < 32'(signed'(rs2_d))) & (funct3 == BLT))? 1 : 0;
assign BGE_S = ((32'(signed'(rs1_d)) >= 32'(signed'(rs2_d))) & (funct3 == BGE))? 1 : 0;
assign BLTU_S = ((rs1_d < rs2_d) & funct3 == BLTU)? 1 : 0;
assign BGEU_S = ((rs1_d >= rs2_d) & funct3 == BGEU)? 1 : 0;
assign branch = ((BEQ_S | BNE_S | BLT_S | BGE_S | BLTU_S | BGEU_S) & enable)? 1 : 0;


endmodule//6:12PM Wishbone compatible RAM wrapper
//Author: Benjamin Herrera Navarro
//11/05/2020


//All wishbone modules have to be reseted on the positive edge of the clock

module console
(
    WB4.slave wb,
    output logic tx,
    input logic rx
);

parameter FREQUENCY = 25000000;
parameter BAUD_RATE = 115200;
parameter DELAY_CLOCKS = FREQUENCY/BAUD_RATE;

//Logic for the wishbone interface

logic wr;
logic rd;
logic empty;
logic full;
logic [6:0] dout;
logic [$clog2(32)-1:0] count;

fifo #(.DATA_WIDTH(7), .MEMORY_DEPTH(32)) fifo_0
(
    //Syscon
    .clk(wb.clk),
    .rst(wb.rst),

    //Status
    .empty(empty),
    .full(full),
    .count(count),

    //Read
    .rd(rd),
    .dout(dout),

    //Write
    .wr(wr),
    .din(wb.DAT_O [7:0]) //Data from wishbone
);

logic ACK_S;

typedef enum logic [3:0] { IDDLE_WB, TAKE_WB } wishbone_states_t;

wishbone_states_t wb_states;

//To push data into the fifo
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        wb_states = IDDLE_WB;
    end
    else
    begin
        case(wb_states)
            IDDLE_WB:
            begin
                if(wb.STB & wb.CYC)
                begin
                    if(!full)
                    begin
                        wr = 1'b1;
                        ACK_S = 1'b1;
                        wb_states = TAKE_WB;
                        $display("DATA CONSOLE: %s", wb.DAT_O [7:0]);
                    end
                    else
                    begin
                        wr = 1'b0;
                        ACK_S = 1'b0;
                        wb_states = wb_states;
                    end
                end
                else
                begin
                    wr = 1'b0;
                    ACK_S = 1'b0;
                    wb_states = wb_states;
                end
            end
            TAKE_WB:
            begin
                wr = 1'b0;
                ACK_S = 1'b0;
                wb_states = IDDLE_WB;
            end
            default:
            begin
                wr = 1'b0;
                ACK_S = 1'b0;
                wb_states = IDDLE_WB;
            end
        endcase
    end
end

assign wb.ACK = ACK_S & wb.CYC & wb.STB;


typedef enum logic [3:0] { IDDLE, START, BIT_S, STOP, DONE } states;

states current_state;

reg [7:0] data;
reg [2:0] n_bit;
reg [31:0] delay_count;
reg [2:0] shamnt;

assign wb.DAT_I = {24'h0, data [7:0]};

//Sample signals at the rising edge
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        current_state = IDDLE;
        delay_count = 0;
        shamnt = 0;
        rd = 1'b0;
        tx = 1;
    end
    else
    begin
        case(current_state)
            IDDLE:
            begin
                delay_count = 0;
                shamnt = 0;
                tx = 1;

                if(!empty)
                begin
                    rd = 1'b1;
                    current_state = START;   
                end
                else
                begin
                    rd = 1'b0;
                    current_state = IDDLE;
                end
            end
            START:
            begin
                data = dout;                 
                rd = 1'b0;
                shamnt = 0;
                tx = 1'b0;
                if(delay_count == DELAY_CLOCKS)
                begin
                    current_state = BIT_S;
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
            end
            BIT_S:
            begin
                rd = 1'b0;
                tx = data >> shamnt;
                if(delay_count == DELAY_CLOCKS)
                begin
                    if(shamnt == 6)
                    begin
                        current_state = STOP;
                        shamnt = 0;                    
                    end
                    else
                    begin
                        shamnt = shamnt + 1;
                        current_state = BIT_S;                
                    end
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
            end
            STOP:
            begin
                rd = 1'b0;
                shamnt = 0;
                tx = 1'b1;
                if(delay_count == DELAY_CLOCKS)
                begin
                    current_state = IDDLE;
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
            end
        endcase
    end
end

endmodule


module console_tb();

logic clk;
logic rst;
logic tx;

WB4 wb(clk, rst);



//Reset
initial begin
    //Begin of reset secuence
    clk <= 0;
    rst <= 0;
    #10
    clk <= 1;
    rst <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    rst <= 0;
    //End of reset secuence
    repeat(10000000) #10 clk = ~clk;
end


console console_0(.wb(wb), .tx(tx));
console_test console_test_0(wb);

endmodule
module console_test(WB4.master wb);

//Master
typedef enum logic [3:0] { iddle, write_cycle, none } state;


//Use as address also
reg [31:0] data;
logic [31:0] data_next;

//state machine 
state next_state, current_state;

always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        current_state = iddle;
        data = 41;
    end
    else
    begin
        current_state = next_state; 
        data = data_next;
    end
end

always_comb
begin
    unique case(current_state)
        iddle:
        begin
            next_state = write_cycle;
            wb.CYC <= 1'b0; //Begin transaction
            wb.STB <= 1'b0;
            wb.WE <= 1'b0; //Read 
            wb.ADR <= data;
            wb.DAT_O <= 32'b0; 
            data_next <= data;          
        end
        none:
        begin
            next_state = none;
            wb.CYC <= 1'b0; //Begin transaction
            wb.STB <= 1'b0;
            wb.WE <= 1'b0; //Read 
            wb.ADR <= data;
            wb.DAT_O <= 32'b0; 
            data_next <= data;          
        end
        write_cycle:
        begin
            data_next = data;
            $display("data write -> %b", data);
            if(wb.ACK)
            begin
                next_state = none;
                wb.CYC <= 1'b0; //Begin transaction
                wb.STB <= 1'b0;
                wb.WE <= 1'b1; //Write
            end
            else
            begin
                wb.CYC <= 1'b1; //Begin transaction
                wb.STB <= 1'b1;
                wb.WE <= 1'b1; //Write
                wb.ADR <= data;
                wb.DAT_O <= data;
            end
        end
    endcase
end

endmodule
import global_pkg::*;

module control_unit
(
    input clk,
    input rst,

    input logic execute,
    output logic busy, //Meaning that an instructions is not done

    //Multiplexer signals
    output sr2_src_t sr2_src,
    output regfile_src_t regfile_src,
    output jmp_target_src_t jmp_target_src,

    output logic regfile_wr,
    decode decode_bus,

    //This signal is for unconditional jumps like JAL and JALR
    output logic jump, //Jump signal
    
    output logic enable_branch, //Signal to enable branching 

    //Load and store control bus
    output memory_operation_t memory_operation,

    //Load and store control signals
    output  logic cyc,
    input   logic ack,
    input   logic data_valid,

    //ALU immediate instruction signal
    output logic imm_t,

    //CSR Unit control signals
    output logic csr_unit_enable,
    output logic illegal_ins,

    //Instruction Events
    output logic arithmetic_event,

    //Branches
    output logic unconditional_branch,
    output logic conditional_branch
);

parameter OP_IMM =  7'b0010011;
parameter LUI =     7'b0110111;
parameter AUIPC =   7'b0010111;
parameter LOAD =    7'b0000011;
parameter JAL =     7'b1101111;
parameter STORE =   7'b0100011;
parameter JARL =    7'b1100111;
parameter BRANCH =  7'b1100011;
parameter OP =      7'b0110011;
parameter SYSTEM =  7'b1110011;

parameter ENVIROMENT = 3'b000;
parameter PRIV = 3'b000;

parameter ECALL = 12'b000000000000;
parameter EBREAK = 12'b000000000001;

parameter URET = 12'b000000000000;
parameter SRET = 12'b000100000000;
parameter MRET = 12'b001100000000;

parameter CSRRW = 3'b001;
parameter CSRRS = 3'b010;
parameter CSRRC = 3'b011;
parameter CSRRWI = 3'b101;
parameter CSRRSI = 3'b110;
parameter CSRRCI = 3'b111;

//Load instruction states
typedef enum logic [3:0] { SEND_CMD, RECIEVE_DATA } LOAD_STATES;
LOAD_STATES load_state;

//All instruction are decoded in a negedge clk
always@(negedge clk)
begin
    if(rst)
    begin
        load_state = SEND_CMD;
    end
    else
    begin
        if(execute)
        begin       
            case(decode_bus.opcode)
                OP_IMM:
                begin
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b0;
                    unconditional_branch = 1'b0;
                    arithmetic_event = 1'b1;
                    sr2_src = I_IMM_SRC;
                    regfile_src = ALU_INPUT;
                    regfile_wr = 1'b1;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b1;
                    csr_unit_enable = 1'b0;
                    //$display("OPIMM dest %x, rs1 %x, rs2 %x, imm %x", rd, rs1, rs2, i_imm);
                end
                OP:
                begin
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b0;
                    unconditional_branch = 1'b0;
                    arithmetic_event = 1'b1;
                    sr2_src = REG_SRC;
                    regfile_src = ALU_INPUT;
                    regfile_wr = 1'b1;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b0;
                    csr_unit_enable = 1'b0;
                end
                LUI:
                begin
                    //$display("LUI dest %b, imm %b", rd, U_IMM_SRC);
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b0;
                    unconditional_branch = 1'b0;
                    arithmetic_event = 1'b0;
                    sr2_src = I_IMM_SRC;
                    regfile_src = U_IMM_SRC;
                    regfile_wr = 1'b1;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b0;
                    csr_unit_enable = 1'b0;
                end
                AUIPC:
                begin
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b0;
                    unconditional_branch = 1'b0;
                    arithmetic_event = 1'b0;
                    //$display("AUIPC dest %b, imm %b", rd, U_IMM_SRC + PC);
                    sr2_src = I_IMM_SRC;
                    regfile_src = AUIPC_SRC;
                    regfile_wr = 1'b1;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b0;
                    csr_unit_enable = 1'b0;
                end

                //Unconditional JUMPS
                JAL:
                begin
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b0;
                    unconditional_branch = 1'b1;
                    arithmetic_event = 1'b0;
                    //$display("JAL address %h", jump_target);
                    regfile_wr = 1'b1;
                    sr2_src = I_IMM_SRC;
                    regfile_src = PC_SRC;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b1;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b0;
                    csr_unit_enable = 1'b0;
                end
                JARL:
                begin
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b0;
                    unconditional_branch = 1'b1;
                    arithmetic_event = 1'b0;
                    regfile_wr = 1'b1;
                    sr2_src = I_IMM_SRC;
                    regfile_src = PC_SRC;
                    //$display("JARL dest %b, rs1 %b, imm %d", rd, rs1, 32'(signed'(i_imm)));
                    jmp_target_src = I_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b1;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b0;
                    csr_unit_enable = 1'b0;
                end
                //Conditional jumps
                BRANCH:
                begin
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b1;
                    unconditional_branch = 1'b0;
                    arithmetic_event = 1'b0;
                    //$display("BRANCH Instruction");
                    regfile_wr = 1'b0;
                    sr2_src = I_IMM_SRC;
                    regfile_src = PC_SRC;
                    jmp_target_src = B_IMM; //
                    enable_branch = 1'b1;
                    jump = 1'b0;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b0;
                    csr_unit_enable = 1'b0;
                end
                //Memory Access
                STORE:
                begin
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b0;
                    unconditional_branch = 1'b0;
                    arithmetic_event = 1'b0;
                    regfile_wr = 1'b0;
                    sr2_src = I_IMM_SRC;
                    regfile_src = ALU_INPUT;
                    memory_operation = STORE_DATA;
                    //$display("STORE base: r%d, src: r%d, offset: %d", rs1, rs2, 32'(signed'(s_imm)));
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    imm_t = 1'b0;
                    csr_unit_enable = 1'b0;
                    if(ack)
                    begin
                        cyc = 1'b0;
                        busy = 1'b0;
                    end
                    else
                    begin
                        busy = 1'b1;
                        cyc = 1'b1;
                    end
                end
                LOAD:
                begin
                    illegal_ins = 1'b0;
                    conditional_branch = 1'b0;
                    unconditional_branch = 1'b0;
                    arithmetic_event = 1'b0;
                    sr2_src = I_IMM_SRC;
                    regfile_src = LOAD_SRC;
                    jump = 1'b0;
                    imm_t = 1'b0;
                    //$display("LOAD base: r%d, dest: r%d, offset: %d", rs1, rd, 32'(signed'(i_imm)));
                    jmp_target_src = J_IMM;
                    memory_operation = LOAD_DATA;
                    enable_branch = 1'b0;
                    csr_unit_enable = 1'b0;
                    unique case(load_state)
                        SEND_CMD:
                        begin
                            //Communication protocol between the decode logic and the store/load logic
                            //Request data load
                            busy = 1'b1;
                            if(ack)
                            begin
                                cyc = 1'b0;
                                load_state = RECIEVE_DATA;
                            end
                            else
                            begin
                                cyc = 1'b1;
                            end
                        end
                        RECIEVE_DATA:
                        begin
                            //Wait for data valid
                            if(data_valid)
                            begin
                                busy = 1'b0;
                                regfile_wr = 1'b1;
                                load_state = SEND_CMD; //For next instructions
                            end
                            else
                            begin
                                busy = 1'b1;
                                regfile_wr = 1'b0;
                            end
                        end
                    endcase
                end
                //System instructions
                SYSTEM:
                begin
                    unique case(decode_bus.funct3)
                        ENVIROMENT:
                        begin
                            illegal_ins = 1'b0;
                            unique case(decode_bus.i_imm)
                                ECALL:
                                begin
                                    //Do nothing for now
                                    //This should make a software interrupt
                                end
                                EBREAK:
                                begin
                                    //Stop simulation, for now.
                                    //This should make a software interrupt
                                    $stop;
                                end
                            endcase
                            csr_unit_enable = 1'b0;
                        end
                        //CSR Instructions
                        CSRRW: //Read and write
                        begin
                            illegal_ins = 1'b0;
                            regfile_wr = 1'b0;
                            regfile_src = CSR_SRC;
                            csr_unit_enable = 1'b1;
                        end
                        CSRRS:
                        begin
                            illegal_ins = 1'b0;
                            csr_unit_enable = 1'b1;
                            regfile_wr = 1'b0;
                            regfile_src = CSR_SRC;
                        end
                        CSRRC:
                        begin                            
                            illegal_ins = 1'b0;
                            csr_unit_enable = 1'b1;
                            regfile_wr = 1'b0;
                            regfile_src = CSR_SRC;
                        end
                        CSRRWI:
                        begin
                            illegal_ins = 1'b0;
                            regfile_wr = 1'b0;
                            regfile_src = CSR_SRC;
                            csr_unit_enable = 1'b1;
                        end
                        CSRRSI:
                        begin
                            illegal_ins = 1'b0;
                            regfile_wr = 1'b0;
                            regfile_src = CSR_SRC;
                            csr_unit_enable = 1'b1;
                        end
                        CSRRCI:
                        begin
                            illegal_ins = 1'b0;
                            regfile_wr = 1'b0;
                            regfile_src = CSR_SRC;
                            csr_unit_enable = 1'b1;
                        end
                        PRIV:
                        begin
                            unique case(decode_bus.i_imm)
                                URET:
                                begin
                                    illegal_ins = 1'b1;
                                    $display("Privilege Mode Not Supported"); 
                                end
                                SRET:
                                begin
                                    illegal_ins = 1'b1;
                                    $display("Privilege Mode Not Supported"); 
                                end 
                                MRET:
                                begin
                                    illegal_ins = 1'b0;
                                    
                                end
                            endcase
                        end
                    endcase
                    illegal_ins = 1'b1;
                    conditional_branch = 1'b0;
                    imm_t = 1'b0;
                    sr2_src = I_IMM_SRC;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    cyc = 1'b0;
                    memory_operation = MEM_NONE;
                    busy = 1'b0;
                    arithmetic_event = 1'b0;
                    unconditional_branch = 1'b0;
                end
                default:
                begin
                    unconditional_branch = 1'b0;
                    conditional_branch = 1'b0;
                    csr_unit_enable = 1'b1;
                    arithmetic_event = 1'b0;
                //$display("Illegal Instruction");
                    illegal_ins = 1'b1;
                    imm_t = 1'b0;
                    regfile_wr = 1'b0;
                    regfile_src = ALU_INPUT;
                    sr2_src = I_IMM_SRC;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    cyc = 1'b0;
                    memory_operation = MEM_NONE;
                    busy = 1'b0;
                end
            endcase
        end
        else
        begin
            unconditional_branch = 1'b0;
            conditional_branch = 1'b0;
            arithmetic_event = 1'b0;
            illegal_ins = 1'b0;
            csr_unit_enable = 1'b0;
            imm_t = 1'b0;
            regfile_wr = 1'b0;
            regfile_src = ALU_INPUT;
            sr2_src = I_IMM_SRC;
            jmp_target_src = J_IMM;
            enable_branch = 1'b0;
            jump = 1'b0;
            cyc = 1'b0;
            memory_operation = MEM_NONE;
            busy = 1'b0;
        end
    end
end

endmodule
import global_pkg::*;

`include "debug_def.sv"

module core
(
    WB4.master inst_bus,
    WB4.master data_bus
`ifdef DEBUG_PORT
    ,
    output logic [31:0] debug_registers [31:0],
    output logic pre_execution,
    output logic post_execution,
    output logic [31:0] pc_debug
    //output [4:0] debug_rd,
    //output [4:0] debug_rs1,
    //output [4:0] debug_rs2,
    //output [6:0] debug_opcode
`endif

);


logic [31:0] PC;
logic [31:0] IR;
logic execute;
logic [31:0] jump_target;
logic jump;
logic busy; //Instruction busy
//Fetch state machine
fetch_stm fetch_stm_0
(
    .inst_bus(inst_bus),
    .PC_O(PC),
    .IR_O(IR),
    .execute(execute), //Wire to signal the execute cycle
    .jump_target(jump_target),
    .jump(jump), //Jump signal
    .ins_busy(busy)
    `ifdef DEBUG_PORT
    ,.post_execution(post_execution),
    .pre_execution(pre_execution)
    `endif
);

`ifdef DEBUG_PORT
    assign pc_debug = PC;
`endif

decode decode_bus();

decoder decoder_0
(
    .IR(IR),
    .decode_bus(decode_bus)
);

//Register file write line
logic regfile_wr;

//Mux select bus for the register file input bus
regfile_src_t regfile_src;
//Mux select bus for the input sr2 bus for the ALU
sr2_src_t sr2_src; 
//Jump target src bus for multiplexor select bus
jmp_target_src_t jmp_target_src;

//Signal to enable the branch unit
logic enable_branch;

//Uncoditional JUMP signal
logic uncoditional_jump;

//Memory access unit control lines
memory_operation_t memory_operation;
logic cyc;
logic ack;
logic data_valid;

//ALU immediate instructions signal
logic imm_t;

//CSR Unit control signals
logic csr_unit_enable;

//MISC Signals to the CSR unit
logic illegal_ins;
logic arithmetic_event;
logic unconditional_branch;
logic conditional_branch;

control_unit control_unit_0
(
    .clk(inst_bus.clk),
    .rst(inst_bus.rst),
    .execute(execute),
    .busy(busy), ///<-
    .sr2_src(sr2_src),
    .regfile_src(regfile_src),
    .jmp_target_src(jmp_target_src),
    .regfile_wr(regfile_wr),
    .decode_bus(decode_bus),
    .jump(uncoditional_jump),
    .enable_branch(enable_branch), //Signal to enable branching 
    .memory_operation(memory_operation),
    .cyc(cyc),
    .ack(ack),
    .data_valid(data_valid),
    .imm_t(imm_t),
    .csr_unit_enable(csr_unit_enable),
    .illegal_ins(illegal_ins),
    .arithmetic_event(arithmetic_event),
    .unconditional_branch(unconditional_branch),
    .conditional_branch(conditional_branch)
);

//Data buses that come from the register file
logic [31:0] rs1_d;
logic [31:0] rs2_d;
logic [31:0] rd_d; //Register file input bus

//Output signals of the ALU
logic [31:0] rd_alu;
//ALU Src2 Bus
logic [31:0] alu_src2;

//Load data from memory access unit
logic [31:0] load_data;

//Input and Output Data BUSes to the CSR unit
logic [31:0] csr_dout;

//CSR Register file write enable
logic csr_regfile_write;

//Multiplexer for the Registerfile input
always_comb
begin
    unique case(regfile_src)
        ALU_INPUT: rd_d <=  rd_alu;
        U_IMM_SRC: rd_d <= decode_bus.u_imm;
        AUIPC_SRC: rd_d <= decode_bus.u_imm + PC;
        PC_SRC: rd_d <= PC + 4;
        LOAD_SRC: rd_d <= load_data;
        CSR_SRC: rd_d <= csr_dout;
    endcase
end

regfile regfile_0
(
    .clk(inst_bus.clk),
    .rst(inst_bus.rst),
    .ra(decode_bus.rs1), 
    .rb(decode_bus.rs2),
    .rd(decode_bus.rd),
    .ra_d(rs1_d), 
    .rb_d(rs2_d),
    .rd_d(rd_d),
    .wr(regfile_wr | csr_regfile_write)
    `ifdef DEBUG_PORT
    ,.reg_debug(debug_registers)
    `endif
);

//Multiplexer for the sr2 alu input bus
always_comb
begin
    unique case(sr2_src)
        REG_SRC: alu_src2 <= rs2_d; //From register file
        I_IMM_SRC: alu_src2 <= 32'(signed'(decode_bus.i_imm)); //I IMM extended
    endcase
end

alu alu_0
(
    .ra_d(rs1_d),
    .rb_d(alu_src2),
    .rd_d(rd_alu),
    .func3(decode_bus.funct3),
    .func7(decode_bus.funct7),
    .imm_t(imm_t)
);

//Signal that says if the branch will be taken
logic branch;
//Branch unit
branch_unit branch_unit_0
(
    .rs1_d(rs1_d),
    .rs2_d(rs2_d),
    .funct3(decode_bus.funct3),
    .enable(enable_branch),
    .branch(branch)
);

//Exeptions and interrupts signal
logic exp_int;
assign exp_int = illegal_ins;

//Exeption address
logic [31:0] exeption_addr;

//Jump signal is true if branch or JAL is true
assign jump = branch | uncoditional_jump | exp_int;

//Calculate the target address when taking jump or branch
//This is just a multiplexer
always_comb
begin
    if(exp_int)
    begin
        jump_target = exeption_addr;
    end
    else
    begin
        unique case(jmp_target_src)
            //JAL
            J_IMM: jump_target = PC + 32'(signed'(decode_bus.j_imm));
            //BRANCH instructions
            B_IMM: jump_target = PC + 32'(signed'(decode_bus.b_imm));
            //JALR. Base rs1 + imm sign extended
            I_IMM: jump_target = rs1_d + 32'(signed'(decode_bus.i_imm));
        endcase
    end
end

//Address bus for the load and store operations
logic [31:0] address_ld;

//Multiplexer to choose between the load or store address
always_comb
begin
    unique case(memory_operation)
        //Address = rs1 + imm_i sign extended to 32bits
        LOAD_DATA: address_ld <= rs1_d + 32'(signed'(decode_bus.i_imm));
        STORE_DATA: address_ld <= rs1_d + 32'(signed'(decode_bus.s_imm));
        MEM_NONE: address_ld <= 32'b0;
    endcase
end

//This is the memory access module
memory_access memory_access_0
(
    //Syscon
    .clk(inst_bus.clk),
    .rst(inst_bus.rst),

    //Control signals
    .memory_operation(memory_operation),
    .cyc(cyc),
    .ack(ack),
    .data_valid(data_valid),
    .funct3(decode_bus.funct3),

    //Data
    .store_data(rs2_d),
    .address(address_ld),
    .load_data(load_data),

    //Wishbone interface
    .data_bus(data_bus)
);




//CSR Unit
csr_unit csr_unit_0
(
    //Syscon
    .clk(inst_bus.clk),
    .rst(inst_bus.rst),

    //Commands
    .i_imm(decode_bus.i_imm),
    .funct3(decode_bus.funct3),
    .rd(decode_bus.rd),
    .rs1(decode_bus.rs1),
    .csr_unit_enable(csr_unit_enable),

    //Data buses
    .rs1_d(rs1_d),
    .dout(csr_dout),

    //Register file control signals
    .wr(csr_regfile_write),

    //Exeption or trap signal to jump
    .trap(),
    .address(exeption_addr),

    //Used by internally by registers
    //Instruction execute
    .execute(execute),
    .PC(PC),
    .IR(IR),
    .illegal_ins(illegal_ins),
    .memory_operation(memory_operation),
    .cyc_memory_operation(cyc),
    .arithmetic_event(arithmetic_event),
    .address_ld(address_ld),
    .unconditional_branch(unconditional_branch),
    .conditional_branch(conditional_branch),
    .external_interrupt(),
    .branch(jump)

);

endmodule 


module cross_bar
(
    //Define master
    WB4.slave cpu,
    WB4.master memory, //New masters
    WB4.master uart, //New masters
    //WB4.master seven_segments,
    WB4.master uart_rx,
    WB4.master timer_dev    
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
parameter TIMER_END =    32'h0010003c;


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
            memory.STB <= 0; //Strobe 0 on other devices
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




endmodule

//This unit counts clock cycles 
module csr_cycle 
#(
    parameter LOW_ADDR = 0;
    parameter HIGH_ADDR = 1;
)
(
    //Interface
    csr_int.slave sys_con,

    //Data output bus
    output logic [31:0] data
);

//64bit counter
reg [63:0] counter;

always@(posedge sys_con.clk)
begin
    //Reset
    if(sys_con.rst)
    begin
        counter = 64'b0;
    end
    else
    begin
        //These are read only
        counter = counter + 64'b1;        
    end
end




endmodule
//This counter counts the number of instructions
module csr_insret
(
    //Syscon
    input logic clk,
    input logic rst,

    //Ins count
    input logic ins_exe, //Instruction execute signal

    //Data buses
    input logic sel, //Word selection High = 1, LOW = 0
    output logic [31:0] data_o,
);

//64bit counter
reg [63:0] counter;

always@(posedge clk)
begin
    //Reset
    if(rst)
    begin
        counter = 64'b0;
    end
    else
    begin
        if(ins_exe)
        begin
            counter = counter + 64'b1;        
        end
        else
        begin
            counter = counter;        
        end
    end
end











endmodule//Interface to commmunicate with each CSR
interface csr_int(input clk, input rst);
    //Data
    logic [31:0] data;
    //Control signals
    logic cyc;
    logic sel; //Used to select the low and high parts

    modport slave
    (
        input clk,
        input rst,
        //Data
        input [31:0] data_i,
        //Control signals
        input wr,
        input cyc,
        input sel
    );
    modport master
    (
        input clk,
        input rst,
        //Data
        input  [31:0] data_i,
        //Control signals
        output wr,
        output cy,
        output sel
    );
endinterface //csr_int
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
    input csr_unit_enable,
    input logic [31:0] rs1_d,

    //Data buses
    output logic [31:0] dout,

    //Register file control signals
    output logic wr,

    //Exeption or trap signal to jump
    output logic trap,
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

    //Jump signal to know when a branch is taken
    input logic branch,

    //Output buses for registers that are needed concurrently.
);


//Braking down the i_imm bus
wire [1:0] priv_mode_bus = i_imm [9:8];
wire [1:0] rw_access = i_imm [11:10];

///////////////////////////////////////////
//          Privilege Logic              //
///////////////////////////////////////////

//Privilege modes
parameter M_MODE = 3; //Support for now
parameter U_MODE = 0; //Support for now
parameter S_MODE = 1;

//Current Privilege Mode register logic
reg [2:0] cpm;
always@(posedge clk)
begin
    if(rst)
    begin
        cpm = M_MODE;
    end
end

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

//Interrupts not supported for now
//0x304 MRW mie Machine interrupt-enable register.

//0x305 MRW mtvec Machine trap-handler base address.

logic [31:0] mtvec;
parameter MTVEC_RESET_VECTOR = 29'h8000;
parameter MTVEC_RESET_MODE = 2'h0;

parameter MTVEC_DIRECT = 0;
parameter MTVEC_VECTORED = 1;

//Defined here because mtvec uses it
logic [31:0] mcause;

always_comb
begin
    if(mtvec[1:0] == MTVEC_DIRECT) address = {mtvec [31:2], 2'b00};
    else if(mtvec[1:0] == MTVEC_VECTORED) address = {mtvec [31:2], 2'b00} + (mcause << 2);
	 else address = {mtvec [31:2], 2'b00};
end

//0x306 MRW mcounteren Machine counter enable.

////////////Not defined

/////////////////////////////////////////////////////
//            Machine Trap Handling                //
/////////////////////////////////////////////////////

//0x340 MRW mscratch Scratch register for machine trap handlers.
//0x341 MRW mepc Machine exception program counter.

logic mepc_wr;
logic [31:0] mepc_din;
logic [31:0] mepc;

assign mepc_wr = illegal_ins;

always_comb
begin
    if(illegal_ins)
    begin
        mepc_din = PC;
    end
    else
    begin
        mepc_din = 32'b0;
    end
end

always@(posedge clk)
begin
    if(mepc_wr)
    begin
        mepc = mepc_din;
    end
    else
    begin
        mepc = mepc;
    end
end
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
                    if(trap | illegal_ins)
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
    //0xF11 MRO mvendorid Vendor ID.
    if(i_imm == 12'hf11)
    begin
        dout = mvendorid;
        illegal_address = 1'b0;
    end
    //0xF12 MRO marchid Architecture ID.
    else if(i_imm == 12'hf12)
    begin
        dout = marchid;
        illegal_address = 1'b0;
    end
    //0xF13 MRO mimpid Implementation ID.
    else if(i_imm == 12'hf13)
    begin
        dout = mimpid;
        illegal_address = 1'b0;
    end
    //0xF14 MRO mhartid Hardware thread ID.
    else if(i_imm == 12'hf14)
    begin
        dout = mhartid;
        illegal_address = 1'b0;
    end
    //0x300 MRW mstatus Machine status register.
    else if(i_imm == 12'h300)
    begin
        dout = mstatus;
        illegal_address = 1'b0;
    end
    //0x301 MRW misa ISA and extensions
    else if(i_imm == 12'h301)
    begin
        dout = misa;
        illegal_address = 1'b0;
    end
    else if(i_imm == 12'h306)
    begin
        dout = misa;
        illegal_address = 1'b0;
    end
    //0xB00 MRW mcycle Machine cycle counter.
    else if(i_imm == 12'hB00)
    begin
        dout = mcycle[31:0];
        illegal_address = 1'b0;
    end
    //0xB02 MRW minstret Machine instructions-retired counter.
    else if(i_imm == 12'hB02)
    begin
        dout = minstret[31:0];
        illegal_address = 1'b0;
    end
    //0xB80 MRW mcycleh Upper 32 bits of mcycle, RV32I only.
    else if(i_imm == 12'hB80)
    begin
        dout = minstret[63:32];
        illegal_address = 1'b0;
    end
    //0xB82 MRW minstreth Upper 32 bits of minstret, RV32I only.
    else if(i_imm == 12'hB82)
    begin
        dout = minstret[63:32];
        illegal_address = 1'b0;
    end
    //Event thingy 
    //0x323 MRW mhpmcounter3-31 Machine performance-monitoring event selector.
    else if((i_imm >= 12'hB03) && (i_imm <= 12'hB1F))
    begin
        dout = mhpmcounter [i_imm] [31:0];
        illegal_address  = 1'b0;
    end
    else if((i_imm >= 12'h323) && (i_imm <= 12'h33F))
    begin
        dout = mhpmevent [i_imm] [31:0];
        illegal_address  = 1'b0;
    end
    else if((i_imm >= 12'hB83) && (i_imm <= 12'hB84))
    begin
            dout = mhpmcounter [i_imm] [63:32];
            illegal_address  = 1'b0;
    end		  
    else
    begin
        illegal_address = 1'b0;
        dout = 32'h0;
        //Raise Illegal Instruction exeption, because csr not implemented
    end
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


//////////////////////////////////////////
// CSR Write address decoder            //
//////////////////////////////////////////

always@(posedge clk)
begin
    if(rst)
    begin
        
    end
    else
    begin
        if(csr_write & csr_write_valid)
        begin
            //0x300 MRW mstatus Machine status register.
            if(i_imm == 12'h300)
            begin
                mstatus = regin_bus;
            end
            //0x305 MRW mtvec Machine trap-handler base address.
            else if(i_imm == 12'h305)
            begin
                mtvec = regin_bus;
            end
            //Event thingy 
            //0x323 MRW mhpmevent3-31 Machine performance-monitoring event selector.
            else if((i_imm >= 12'h323) && (i_imm <= 12'h33F))
            begin
                mhpmevent [i_imm] [31:0] = regin_bus;            
            end
        end
    end
end

////////////////////////////////////////////////////
//           Calculate address to jump to         //
////////////////////////////////////////////////////

always_comb
begin
    
end











endmodule

//Author: Benjamin Herrera Navarro
//9:05PM
//11/08/2020
//If only buttons didn't bounce fuckingbouhe ufbsad

module debounce
(
    input clk,
    input debounce,
    output debounced
);


logic [31:0] new_slow_clock;

reg dff_1;
reg dff_2;

always@(posedge clk)
begin
    new_slow_clock = new_slow_clock + 1;
    if(new_slow_clock == 32'hfffff)
    begin
        dff_1 = debounce;
        dff_2 = dff_1;
        new_slow_clock = 32'h0;
    end
end

assign debounced = dff_2;


endmodule
`ifndef __DEBUG__PORT__SV__
`define __DEBUG__PORT__SV__

`ifndef ALTERA_RESERVED_QIS
    `define sim
    `define DEBUG_PORT
    `define MEMORY_DEBUG_MSGS
`endif

`endifmodule decoder
(
    input logic [31:0] IR,
    decode decode_bus
);



assign decode_bus.opcode = IR [6:0];
assign decode_bus.rd = IR [11:7];
assign decode_bus.funct3 = IR [14:12];
assign decode_bus.rs1 = IR [19:15];
assign decode_bus.rs2 = IR [24:20];
assign decode_bus.funct7 = IR [31:25];
assign decode_bus.i_imm = IR [31:20];
assign decode_bus.s_imm = {IR [31:25], IR[11:7]};
assign decode_bus.b_imm [0:0] = 1'b0;
assign decode_bus.b_imm [11:11] = IR [7:7];
assign decode_bus.b_imm [4:1] = IR [11:8];
assign decode_bus.b_imm [10:5] = IR [30:25];
assign decode_bus.b_imm [12:12] = IR [31:31];
assign decode_bus.u_imm = {IR [31:12], 12'b000000000000};
assign decode_bus.j_imm [0:0] = 1'b0;
assign decode_bus.j_imm [19:12] = IR [19:12];
assign decode_bus.j_imm [11:11] = IR [20:20];
assign decode_bus.j_imm [10:1] = IR [31:21];
assign decode_bus.j_imm [20:20] = IR [31:31];


endmodule//Author: Benjamin Herrera Navarro
//Testbench to test the decoder
//6:23PM
//11/16/2020

module decoder_tb();

decode decoder_int();

reg [31:0] RAM [(16**2)-1:0];

reg [31:0] PC = 0;
logic clk = 0;

initial begin
    $readmemh("C:/Users/camin/Documents/VanilaCore/core/c_code/ROM.hex", RAM);
    repeat(1000000000) #10 clk = ~clk;
end

always@(posedge clk)
begin
    PC = PC + 1;
end

decoder decoder_0
(
    .IR(RAM[PC]),
    .decode_bus(decoder_int)
);



endmodule
interface decode;
    logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;
    logic [11:0] i_imm;
    logic [11:0] s_imm;
    logic [12:0] b_imm;
    logic [31:0] u_imm;
    logic [20:0] j_imm;
endinterface //interfacename//Author: Benjamin Herrera Navarro
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


//Interface that contains all event signals
interface EVENT_INT;
    logic load;
    logic store;
    logic unaligned;
    logic arithmetic;
    logic trap;
    logic interrupt;
    logic conditional_branch;
    logic uncoditional_branch;
    logic branch;
    modport in
    (
        input load;
        input store;
        input unaligned;
        input arithmetic;
        input trap;
        input interrupt;
        input conditional_branch;
        input uncoditional_branch;
        input branch;
    );
    modport out
    (

        output load;
        output store;
        output unaligned;
        output arithmetic;
        output trap;
        output interrupt;
        output conditional_branch;
        output uncoditional_branch;
        output branch;
    );
endinterface //EVENT_INT

`include "debug_def.sv"

module fetch_stm
(
    WB4.master inst_bus,
    output logic [31:0] PC_O,
    output logic [31:0] IR_O,
    output logic execute, //Wire to signal the execute cycle
    input logic [31:0] jump_target,
    input logic jump,
    input logic ins_busy //Instructions busy
    `ifdef DEBUG_PORT
    ,output logic post_execution,
    output logic pre_execution
    `endif
);

reg [31:0] PC; //Program Counter
reg [31:0] IR; //Instruction register
assign PC_O = PC;
assign IR_O = IR;
parameter PC_RESET_VECTOR = 32'h00000000;

//Wishbone memory read state machine 
typedef enum  logic [3:0] { READ, INC, EXEC, EXEC_2 } INS_BUS_STATE;

INS_BUS_STATE state;


always@(posedge inst_bus.clk)
begin
    //$display("PC: %x", PC);
    if(inst_bus.rst)
    begin
        PC = PC_RESET_VECTOR;
        state = READ;            
    end
    else
    begin
        if(ins_busy)
        begin
            state = state;
            PC = PC;
            IR = IR;            
        end
        else
        begin
            unique case(state)
                EXEC:
                begin
                    if(jump)
                    begin
                        PC = jump_target;
                        state = READ;
                    end
                    else
                    begin
                        PC = PC;
                        state = INC;
                    end
                    //PC = PC + 4;
                    inst_bus.CYC = 1'b0; //Begin transaction
                    inst_bus.STB = 1'b0;
                    inst_bus.WE = 1'b0; //Read
                    inst_bus.ADR = PC [31:0];
                    inst_bus.DAT_O = 32'b0; //Always 0 because we don't write to this memory
                    IR = IR;
                end    
                INC:
                begin
                    PC = PC + 4;
                    inst_bus.CYC = 1'b0; //Begin transaction
                    inst_bus.STB = 1'b0;
                    inst_bus.WE = 1'b0; //Read
                    inst_bus.ADR = PC [31:0];
                    inst_bus.DAT_O = 32'b0; //Always 0 because we don't write to this memory
                    state = READ;
                    IR = IR;
                end
                READ:
                begin
                    if(inst_bus.ACK)
                    begin
                        PC = PC;
                        inst_bus.CYC = 1'b0; //Begin transaction
                        inst_bus.STB = 1'b0;
                        inst_bus.WE = 1'b0; //Read
                        inst_bus.ADR = PC [31:0];
                        inst_bus.DAT_O = 32'b0; //Always 0 because we don't write to this memory
                        IR = inst_bus.DAT_I;
                        //$display("data read -> A: %x, D: %x", PC, inst_bus.DAT_I);
                        state = EXEC;
                    end
                    else
                    begin
                        PC = PC;
                        inst_bus.CYC = 1'b1; //Begin transaction
                        inst_bus.STB = 1'b1;
                        inst_bus.WE = 1'b0; //Read
                        inst_bus.ADR = PC [31:0];
                        inst_bus.DAT_O = 32'b0; //Always 0 because we don't write to this memory
                        state = READ;
                        IR = IR;
                    end
                end
            endcase
        end
    end
end

always_comb
begin
    unique case(state)
        EXEC:
        begin
            execute = 1'b1;
        end    
        INC:
        begin
            execute = 1'b0;
        end
        READ:
        begin
            execute = 1'b0;
        end
    endcase
end

`ifdef DEBUG_PORT
    //Flip Flop to hold a pulse from the jump signal
    logic jump_hold_s;

    always@(posedge inst_bus.clk)
    begin
        //$display("PC: %x", PC);
        if(inst_bus.rst)
        begin
                 
        end
        else
        begin
            if(ins_busy)
            begin         
            end
            else
            begin
                unique case(state)
                    EXEC:
                    begin
                        if(jump)
                        begin
                            jump_hold_s = 1'b1;
                        end
                        else
                        begin
                            jump_hold_s = 1'b0;
                        end
                    end    
                    INC:
                    begin
                            jump_hold_s = 1'b0;
                    end
                    READ:
                    begin
                            jump_hold_s = 1'b0;
                    end
                endcase
            end
        end
    end
    always_comb
    begin
        unique case(state)
            EXEC:
            begin
                pre_execution = 1'b1;
                post_execution = 1'b0;
            end    
            INC:
            begin
                pre_execution = 1'b0;
                post_execution = 1'b1;
            end
            READ:
            begin
                pre_execution = 1'b0;
                post_execution = jump_hold_s;
            end
        endcase
    end
`endif

endmodule 

module fetch_stm_tb();




fetch_stm fetch_stm_0
(
    .inst_bus(inst_bus),
    .PC_O(PC_O),
    .IR_O(IR_O),
    .execute(execute), //Wire to signal the execute cycle
    .jump_target(jump_target),
    .jump(jump),
    .stop_cycle(stop_cycle),
    .exit_ignore(exit_ignore)
);






endmodule//Author: Benjamin Herrera Navarro
//12/4/2020 12:55AM


module fifo
    #(parameter DATA_WIDTH = 32,
    parameter MEMORY_DEPTH = 32)
(
    //Syscon
    input logic clk,
    input logic rst,

    //Status
    output logic empty,
    output logic full,
    output logic [$clog2(MEMORY_DEPTH)-1:0] count,

    //Read
    input logic rd,
    output logic [DATA_WIDTH-1:0] dout,

    //Write
    input logic wr,
    input logic [DATA_WIDTH-1:0] din
);


//FIFO Memory
reg [DATA_WIDTH-1:0] buffer [MEMORY_DEPTH-1:0];

//Read and write pointers
reg [$clog2(MEMORY_DEPTH)-1:0] write_ptr;
reg [$clog2(MEMORY_DEPTH)-1:0] read_ptr;

//Status
logic [$clog2(MEMORY_DEPTH)-1:0] buff_cnt;


assign empty = (buff_cnt == 0);
assign full = (buff_cnt == (MEMORY_DEPTH-1));


assign count = buff_cnt;

//Counter decremenet and increment
always @(posedge clk)
begin
   if( rst )
   begin
       buff_cnt <= 0;
   end
   else if((!full && wr) && (!empty && rd))
   begin
       buff_cnt <= buff_cnt;
   end
   else if(!full && wr)
   begin
       buff_cnt <= buff_cnt + 1;
   end
   else if(!empty && rd)
   begin
       buff_cnt <= buff_cnt - 1;
   end
   else
   begin
      buff_cnt <= buff_cnt;
   end
end

//Pointer Logic
always@(posedge clk)
begin
    if(rst)
    begin
        write_ptr = 0;
        read_ptr = 0;
    end
    else
    begin
        if(wr & !full)
        begin
            write_ptr = write_ptr + 1;
        end
        else
        begin
            write_ptr = write_ptr;
        end
        if(rd & !empty)
        begin
            read_ptr = read_ptr + 1;
        end
        else
        begin
            read_ptr = read_ptr;
        end
    end
end

//Write ptr
always@(negedge clk)
begin
    if(wr & !full)
    begin
        buffer [write_ptr] <= din;
    end
    else
    begin
        buffer [write_ptr] <= buffer [write_ptr];
    end
end

//Read ptr
always@(negedge clk)
begin
    if(rd & !empty)
    begin
        dout <= buffer [read_ptr];
    end
    else
    begin
        dout <= dout;
    end
end


endmodule

module fifo_tb();


logic clk;
logic rst;
logic empty;
logic full;
logic [$clog2(32)-1:0] count;
logic rd;
logic wr;
logic [31:0] dout;
logic [31:0] din;

fifo #(32, 32) fifo_0 
(
    //Syscon
    .clk(clk),
    .rst(rst),

    //Status
    .empty(empty),
    .full(full),
    .count(count),

    //Read
    .rd(rd),
    .dout(dout),

    //Write
    .wr(wr),
    .din(din)
);

task automatic push(int data);
    if(full)
    begin
        $display("Cant push fifo full");
    end
    else
    begin
        $display("Pushing ",data );
        wr = 1'b1;
        din = data;
        @(posedge clk);
        begin
            $display("Pushed ",data );
                wr = 0;
        end
    end
endtask //automatic

task automatic push_full(int size);
    $display("------------FILLING BUFFER------------");
    $display("DEEPTH %d", size);

    for (int i = 0; i < size -1; i++) begin
        push(i);  
        if(size == (i+1) & (count == size-1)) assert (full == 1) 
        else   $display("Error: Exepexcting full signal to be true");
    end

    $display("------------FILLING BUFFER TASK COMPLETED------------");
endtask

//On pop assert that the parameter num is equal to the returned data 
task automatic pop_assert(int num);
    if(empty)
    begin
        $display("Cant pop fifo empty");
    end
    else
    begin
        $display("Expecting %d", num);
        rd = 1;
        @(posedge clk);
        begin
            rd = 0;    
            $display("Poped %d", dout);
            assert (dout == num) 
            else   $display("Error Incorrect Data Poped", dout);
        end
    end
endtask //automatic

task automatic pop_empty_assert_inc(int size);
    @(posedge clk) assert (full == 1) 
    else  $display("Error: Expecting full buffer", $time);
    $display("------------EMPTYING BUFFER------------");
    $display("DEEPTH %d", size);

    for (int i = 0; i < size -1; i++) begin
        pop_assert(i);  
        if(size == (i+1) & (count == 0)) assert (empty == 1) 
        else $display("Error: Exepexcting empty signal to be true");
    end

    $display("------------EMPTYING BUFFER TASK COMPLETED------------");
endtask


initial begin
    clk = 0;
    rst = 0;
    empty = 0;
    full = 0;
    count = 0;
    rd = 0;
    wr = 0;
    dout = 0;
    din = 0;

    //Reset Signal
    #10
    rst = 1;
    #30
    rst = 0;

    push_full(32);
    pop_empty_assert_inc(32);
    push_full(32);
    pop_empty_assert_inc(32);
    push_full(32);
    //pop_empty_assert_inc(32);
    //push(30);
    //push(230);
    //push(210);
    //push(213);
    //push(113);
    //push(143);
    //pop_assert(30);
    //pop_assert(230);
    //pop_assert(210);
    //pop_assert(213);
    //pop_assert(113);
    //pop_assert(143);

    $stop;
end

always #10 clk = ~clk;



endmodule



logic execute;
sr2_src_t sr2_src;
regfile_src_t regfile_src;
logic regfile_wr;

control_unit control_unit_0
(
    .execute(execute),
    .sr2_src(sr2_src),
    .regfile_src(regfile_src),
    .regfile_wr(regfile_wr)
);


control_unit 
(
    input logic execute,
    output sr2_src_t sr2_src,
    output regfile_src_t regfile_src,
    output logic regfile_wr,
    decode decode_bus,
    //memory_operation mem_op //This seta a command to the memory_stm
    output logic load_data,
    output logic store_data,
    output jmp_target_src_t jmp_target_src,
    output logic jump,
    input stop_cycle,
    output BRANCH_S //Signal to enable branching 
);

logic load_data;
logic store_data;


jmp_target_src_t jmp_target_src;

logic BRANCH_S;

logic [31:0] rs1_d; //This comes from the register file
logic [31:0] rs2_d; //This comes from the register file
logic [31:0] rd_d; //Directly to the register file
logic [31:0] alu_z; //ALU output
logic [31:0] ra_d; //This bus goes to the ALU
logic [31:0] rb_d; //This bus goes to the ALU
logic [31:0] load_data_src;



always_comb
begin
    unique case(jmp_target_src)
        J_IMM: jump_target <= 32'(signed'(j_imm)) + PC;
        I_IMM: jump_target <= (32'(signed'(i_imm)) + rs1_d) & 32'h7fffffff;
        B_IMM: jump_target <= 32'(signed'(b_imm)) + PC;
    endcase
end


branch_unit branch_unit_0
(
    .rs1_d(rs1_d),
    .rs2_d(rs2_d),
    .funct3(funct3),
    .branch(BRANCH_S)
);

//Register file data input multiplexer
always_comb
begin
    unique case(regfile_src)
        ALU_INPUT: rd_d <= alu_z;
        U_IMM_SRC: rd_d <= u_imm;
        AUIPC_SRC: rd_d <= u_imm + PC;
        LOAD_SRC: rd_d <= load_data_src;
        PC_SRC: rd_d <= PC + 4;
    endcase
end
regfile regfile_0
(
    .clk(inst_bus.clk),
    .rst(inst_bus.rst),
    .ra(rs1), 
    .rb(rs2),
    .rd(rd),
    .ra_d(rs1_d), 
    .rb_d(rs2_d),
    .rd_d(rd_d),
    .wr(regfile_wr)
);

//ALU input multiplexer
always_comb
begin
    unique case(sr2_src)
        I_IMM_SRC: rb_d <= 32'(signed'(i_imm));
        REG_SRC: rb_d <= rs2_d;
    endcase
end

alu ALU_0
(
    .ra_d(ra_d),
    .rb_d(rb_d),
    .rd_d(alu_z),
    .func3(funct3),
    .func7(funct7)
);

interface #(
        parameter I_LEN = 32,
        parameter NRET = 1,
        parameter XLEN = 32

    ) FORMAL;
    //Instruction Metadata
    logic [NRET        - 1 : 0] rvfi_valid,
    logic [NRET *   64 - 1 : 0] rvfi_order,
    logic [NRET * ILEN - 1 : 0] rvfi_insn,
    logic [NRET        - 1 : 0] rvfi_trap,
    logic [NRET        - 1 : 0] rvfi_halt,
    logic [NRET        - 1 : 0] rvfi_intr,
    logic [NRET * 2    - 1 : 0] rvfi_mode,
    logic [NRET * 2    - 1 : 0] rvfi_ixl,

    //Integer read and write
    logic [NRET *    5 - 1 : 0] rvfi_rs1_addr,
    logic [NRET *    5 - 1 : 0] rvfi_rs2_addr,
    logic [NRET * XLEN - 1 : 0] rvfi_rs1_rdata,
    logic [NRET * XLEN - 1 : 0] rvfi_rs2_rdata,

    //Program Counter
    logic [NRET * XLEN - 1 : 0] rvfi_pc_rdata,
    logic [NRET * XLEN - 1 : 0] rvfi_pc_wdata,

    //Memory Access
    logic [NRET * XLEN   - 1 : 0] rvfi_mem_addr,
    logic [NRET * XLEN/8 - 1 : 0] rvfi_mem_rmask,
    logic [NRET * XLEN/8 - 1 : 0] rvfi_mem_wmask,
    logic [NRET * XLEN   - 1 : 0] rvfi_mem_rdata,
    logic [NRET * XLEN   - 1 : 0] rvfi_mem_wdata

endinterface //FORMAL
package global_pkg;


typedef enum logic[3:0] { REG_SRC, I_IMM_SRC } sr2_src_t;
typedef enum logic[3:0] { ALU_INPUT, U_IMM_SRC, AUIPC_SRC, LOAD_SRC, PC_SRC, CSR_SRC } regfile_src_t;
typedef enum logic[3:0] { J_IMM, B_IMM, I_IMM } jmp_target_src_t;

typedef enum logic[3:0] { MEM_NONE, LOAD_DATA, STORE_DATA} memory_operation_t;

endpackage



module load_window();

logic clk;

//54bit access window
reg [31:0] data_1;
reg [31:0] data_2; //Only used on unaligned access

reg [1:0] wr_addr_bus;

wire [7:0] access_window [7:0];
assign access_window [0] = data_1 [7:0];
assign access_window [1] = data_1 [15:8];
assign access_window [2] = data_1 [23:16];
assign access_window [3] = data_1 [31:24];
assign access_window [4] = data_2 [7:0];
assign access_window [5] = data_2 [15:8];
assign access_window [6] = data_2 [23:16];
assign access_window [7] = data_2 [31:24];

wire [31:0] aligned_data;
assign aligned_data [7:0] = access_window [wr_addr_bus [1:0] + 0];
assign aligned_data [15:8] = access_window [wr_addr_bus [1:0] + 1];
assign aligned_data [23:16] = access_window [wr_addr_bus [1:0] + 2];
assign aligned_data [31:24] = access_window [wr_addr_bus [1:0] + 3];

wire [31:0] ALIGNED_BYTE = 32'(signed'(aligned_data [7:0]));
wire [31:0] ALIGNED_U_BYTE = {24'h0, aligned_data [7:0]};
wire [31:0] ALIGNED_HALF_WORD = 32'(signed'(aligned_data [15:0]));
wire [31:0] ALIGNED_U_HALF_WORD = {16'h0, aligned_data [15:0]};
wire [31:0] ALIGNED_WORD_BUS = aligned_data;



initial begin
    data_1 = 32'h12345678;
    data_2 = 32'habcdefee;
    wr_addr_bus = 0;
    clk = 0;
    //
    repeat(200) #10 clk = ~clk;
end

always@(posedge clk)
begin
    wr_addr_bus = wr_addr_bus + 1;
end
endmodule
import global_pkg::*;

module memory_access_stm
(
    input clk,
    input rst,

    //Command
    input memory_operation_t memory_operation,
    
    output ACK, //Acknowledge operation
    output BUSY, //Busy or operation in proccess
    input CYC, //Begin operation

    input [31:0] wr_addr_bus,
    input [31:0] data,
    output [31:0] data_out,

    //External interface
    WB4.master data_bus,
    
    //Operation code
    input [2:0] funct3
);

//Memory access 
parameter LB = 3'b000;
parameter LH = 3'b001;
parameter LW = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;

//64bit access window
reg [31:0] data_1;
reg [31:0] data_2; //Only used on unaligned access

logic [31:0] wr_addr_bus;
always_comb
begin
    if(load_data)
    begin
        wr_addr_bus = rs1_d + 32'(signed'(i_imm));
    end
    else //Store
    begin
        wr_addr_bus = rs1_d + 32'(signed'(s_imm));
    end
end

wire [7:0] access_window [7:0];
assign access_window [0] = data_1 [7:0];
assign access_window [1] = data_1 [15:8];
assign access_window [2] = data_1 [23:16];
assign access_window [3] = data_1 [31:24];
assign access_window [4] = data_2 [7:0];
assign access_window [5] = data_2 [15:8];
assign access_window [6] = data_2 [23:16];
assign access_window [7] = data_2 [31:24];

wire [31:0] aligned_data;
assign aligned_data [7:0] = access_window [wr_addr_bus [1:0] + 0];
assign aligned_data [15:8] = access_window [wr_addr_bus [1:0] + 1];
assign aligned_data [23:16] = access_window [wr_addr_bus [1:0] + 2];
assign aligned_data [31:24] = access_window [wr_addr_bus [1:0] + 3];

wire [31:0] ALIGNED_BYTE = 32'(signed'(aligned_data [7:0]));
wire [31:0] ALIGNED_U_BYTE = {24'h0, aligned_data [7:0]};
wire [31:0] ALIGNED_HALF_WORD = 32'(signed'(aligned_data [15:0]));
wire [31:0] ALIGNED_U_HALF_WORD = {16'h0, aligned_data [15:0]};
wire [31:0] ALIGNED_WORD_BUS = aligned_data;


//Output bus, data that goes into register file
assign data_out = aligned_data;

//Store decode mask
logic [31:0] mask;
always_comb
begin
    unique case(funct3)
        SB: mask = 32'h000000ff;
        SH: mask = 32'h0000ffff;
        SW: mask = 32'hffffffff;
    endcase
end
//Shift amount
wire [4:0] shift_amount = {wr_addr_bus [1:0], 3'b000};
wire [63:0] masked_window = mask << shift_amount;

//Create new data, this shift the data to the desired bytes 
wire [63:0] new_data_window = data << shift_amount;

//New bus bus the new data
wire [7:0] modified_window [7:0];
assign modified_window [0] = ((~(masked_window [7:0]) & access_window [0]) | new_data_window [7:0]);
assign modified_window [1] = ((~(masked_window [15:8]) & access_window [1]) | new_data_window [15:8]);
assign modified_window [2] = ((~(masked_window [23:16]) & access_window [2]) | new_data_window [23:16]);
assign modified_window [3] = ((~(masked_window [31:24]) & access_window [3]) | new_data_window [31:24]);
assign modified_window [4] = ((~(masked_window [39:32]) & access_window [4]) | new_data_window [39:32]);
assign modified_window [5] = ((~(masked_window [47:40]) & access_window [5]) | new_data_window [47:40]);
assign modified_window [6] = ((~(masked_window [55:48]) & access_window [6]) | new_data_window [55:48]);
assign modified_window [7] = ((~(masked_window [63:56]) & access_window [7]) | new_data_window [63:56]);

wire [31:0] new_data_1;
assign new_data_1 [7:0] = modified_window [0];
assign new_data_1 [15:8] = modified_window [1];
assign new_data_1 [23:16] = modified_window [2];
assign new_data_1 [31:24] = modified_window [3];
wire [31:0] new_data_2;
assign new_data_2 [7:0] = modified_window [4];
assign new_data_2 [15:8] = modified_window [5];
assign new_data_2 [23:16] = modified_window [6];
assign new_data_2 [31:24] = modified_window [7];

//Multiplexer to choose between the load bus
always_comb
begin
    unique case(funct3)
        LB: load_data_src = ALIGNED_BYTE;
        LH: load_data_src = ALIGNED_HALF_WORD;
        LW: load_data_src = ALIGNED_WORD_BUS;
        LBU: load_data_src = ALIGNED_U_BYTE;
        LHU: load_data_src = ALIGNED_U_HALF_WORD;
    endcase
end

typedef enum logic [1:0] { BYTE, HALF_WORD, WORD } access_size_t;
access_size_t access_size; 
always_comb
begin
    unique case(funct3)
        LB: access_size = BYTE;
        LH: access_size = HALF_WORD;
        LW: access_size = WORD;
        LBU: access_size = BYTE;
        LHU: access_size = HALF_WORD;
    endcase
end

wire unaligned = ((wr_addr_bus [1:0] >= 3) & (access_size != BYTE))? 1 : 0;

always_comb
begin
    if(((wr_addr_bus [1:0] >= 3) & (access_size != BYTE)))
    begin
        //$display("Unaligned data access");
    end
end

assign ra_d = rs1_d; //Always from register

///////////////////////////////////////////////////////////


typedef enum logic [3:0] { NO_CMD, READ1, READ2, READ_W1, READ_W2, UWRITE1, UWRITE2, IGNORE } DATA_BUS_STATE;
DATA_BUS_STATE data_bus_state, data_bus_next_state;

logic [31:0] next_read_data_1, next_read_data_2;

always@(posedge clk)
begin
    if(rst)
    begin
        data_bus_state = NO_CMD;
        data_1 = 32'h00000000;
        data_2 = 32'h00000000;
    end
    else
    begin
        data_bus_state = data_bus_next_state;
        data_1 = next_read_data_1;
        data_2 = next_read_data_2;
    end
end

//This is the state machine that accesses the data memory
//This state machine has to be able to read and write data and also handle
//Unaligned data access. On write command it will have to read the required
//data size, and if its unaligned it will have to read the required memory blocks
//update the byte and write back the data.
//In the case of an unaligned load, it has to read the required data and align it,
//So it can be store in the registers 
//                       READ2 => NO_CMD
//                      /
// NO_CMD => READ (!unaligned)? => NO_CMD
//        \
//         => WRITE (size > 1)? => READW1 => WRITE1 => NO_CMD
//                  \
//                  READW1
//                    \
//                      => READW2 DATA & UPDATE BYTE or BYTES
//                                  |
//                                 \ /
//                                  UWRITE1 -> UWRITE2 -> NO_CMD
//FINALU -> final unaligned
always_comb
begin
    case(data_bus_state)
        NO_CMD:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            next_read_data_1 <= data_1;
            next_read_data_2 <= data_2;
            if(memory_operation == LOAD_DATA) //Load data from memory
            begin
                stop_cycle <= 1'b1;
                data_bus_next_state <= READ1;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
            end
            else if(memory_operation == STORE_DATA) //Store data from memory
            begin
                stop_cycle <= 1'b1;
                if(unaligned) //If unaligned read first bytes
                begin
                    data_bus_next_state <= READ_W1; //Read to update bytes                
                end
                else //Not unaligned
                begin
                    if(access_size != WORD) //Unaligned and WORD access overwrites the whole word on memory
                    begin //Read bytes because we need to read, change data and write back
                        data_bus_next_state <= READ_W1; //Read to update bytes                
                    end
                    else
                    begin
                        data_bus_next_state <= UWRITE1; //Read to update bytes                 
                    end
                end
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
            end
            else
            begin
                stop_cycle <= 1'b0;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                data_bus_next_state <= NO_CMD;
            end
        end
        READ1:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            stop_cycle <= 1'b1; //Stop the CPU from executing another instruction
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_bus.DAT_I;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                if(unaligned)
                begin
                    data_bus_next_state <= READ2;
                end
                else
                begin
                    data_bus_next_state <= IGNORE;
                end
            end
            else
            begin
                data_bus_next_state <= READ1;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b0;
            end
        end
        READ2:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0] + 32'b100;
            stop_cycle <= 1'b1;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_bus.DAT_I;
                data_bus_next_state <= IGNORE;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
            end
            else
            begin
                data_bus_next_state = READ2;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b0;
            end
        end
        READ_W1:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            stop_cycle <= 1'b1;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_bus.DAT_I;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                if(unaligned)
                begin
                    data_bus_next_state <= READ_W2;
                end
                else
                begin
                    data_bus_next_state <= UWRITE1;
                end
            end
            else
            begin
                data_bus_next_state <= READ_W1;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b0;
            end
        end
        READ_W2:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0] + 32'b100;
            stop_cycle <= 1'b1;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_bus.DAT_I;
                next_read_data_2 <= data_2;
                //data_bus.DAT_O <= da;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                data_bus_next_state <= UWRITE1;
            end
            else
            begin
                data_bus_next_state <= READ_W2;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b0;
            end
        end
        UWRITE1:
        begin
            data_bus.ADR <= wr_addr_bus [31:0];
            stop_cycle <= 1'b1;
            data_bus.DAT_O <= new_data_1;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                if(unaligned)
                begin
                    data_bus_next_state <= UWRITE2;
                end
                else
                begin
                    data_bus_next_state <= IGNORE;
                end
            end
            else
            begin
                data_bus_next_state <= UWRITE1;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b1;
            end
        end
        UWRITE2:
        begin
            data_bus.ADR <= wr_addr_bus [31:0] + 32'b100;
            stop_cycle <= 1'b1;
            data_bus.DAT_O <= new_data_2;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                data_bus_next_state <= IGNORE;
            end
            else
            begin
                data_bus_next_state <= UWRITE2;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b1;
            end
        end
        IGNORE:
		  begin
            if(exit_ignore)
            begin
                data_bus_next_state <= IGNORE;
            end
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            next_read_data_1 <= data_1;
            next_read_data_2 <= data_2;
            stop_cycle <= 1'b0;
            data_bus.STB <= 1'b0;
            data_bus.CYC <= 1'b0;
            data_bus.WE <= 1'b0;
            data_bus_next_state <= NO_CMD;
        end
		  default:
		  begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            next_read_data_1 <= data_1;
            next_read_data_2 <= data_2;
            stop_cycle <= 1'b0;
            data_bus.STB <= 1'b0;
            data_bus.CYC <= 1'b0;
            data_bus.WE <= 1'b0;
            data_bus_next_state <= NO_CMD;
        end
    endcase
end




endmoduleimport global_pkg::*;

module memory_access
(
    //Syscon
    input logic clk,
    input logic rst,

    //Control signals
    input  memory_operation_t memory_operation,
    input  logic cyc,
    output logic ack,
    output logic data_valid, //This is needed for the load instruction
    input  logic [2:0] funct3,

    //Data
    input  logic [31:0] store_data,
    input  logic [31:0] address,
    output logic [31:0] load_data,

    //Wishbone interface
    WB4 data_bus
);

//Registers to latch the address, data buses and funct3 bus
reg [31:0] store_data_reg;
reg [31:0] address_reg;

logic [2:0] funct3_ff;

//Load and store cycles are atomic so its fine to allow the execution of another
//instruction instead of halting the whole CPU, but when the CPU wants to load or store
//again and the state machine will not acknowledge the request until its done with the operation
//No need for busy signal because the CPU will need to wait until the ACK signal is true.

//Memory access, these are the opcodes of the load and store instructions
parameter LB = 3'b000;
parameter LH = 3'b001;
parameter LW = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;

//Unaligned access is true if accessing more than a byte and unaligned address
typedef enum logic [1:0] { BYTE, HALF_WORD, WORD } access_size_t;
access_size_t access_size; 
always_comb
begin
    case(funct3)
        LB: access_size = BYTE;
        LH: access_size = HALF_WORD;
        LW: access_size = WORD;
        LBU: access_size = BYTE;
        LHU: access_size = HALF_WORD;
        default: access_size = WORD; //Just so modelsim stops bitching
    endcase
end

wire unaligned = ((address [1:0] >= 3) & (access_size != BYTE))? 1 : 0;
logic unaligned_ff;
////////////////////////////////////////////////////////
// Most of the following logic is used to align data  //
////////////////////////////////////////////////////////

//64bit access window
reg [31:0] data_1;
reg [31:0] data_2; //Only used on unaligned access

//Access window
wire [7:0] access_window [7:0];
assign access_window [0] = data_1 [7:0];
assign access_window [1] = data_1 [15:8];
assign access_window [2] = data_1 [23:16];
assign access_window [3] = data_1 [31:24];
assign access_window [4] = data_2 [7:0];
assign access_window [5] = data_2 [15:8];
assign access_window [6] = data_2 [23:16];
assign access_window [7] = data_2 [31:24];

//Aligned data bus
wire [31:0] aligned_data;
assign aligned_data [7:0] = access_window [address_reg [1:0] + 0];
assign aligned_data [15:8] = access_window [address_reg [1:0] + 1];
assign aligned_data [23:16] = access_window [address_reg [1:0] + 2];
assign aligned_data [31:24] = access_window [address_reg [1:0] + 3];

//Signed and unsigned new data buses
wire [31:0] ALIGNED_BYTE = 32'(signed'(aligned_data [7:0]));
wire [31:0] ALIGNED_U_BYTE = {24'h0, aligned_data [7:0]};
wire [31:0] ALIGNED_HALF_WORD = 32'(signed'(aligned_data [15:0]));
wire [31:0] ALIGNED_U_HALF_WORD = {16'h0, aligned_data [15:0]};
wire [31:0] ALIGNED_WORD_BUS = aligned_data;

////////////////////////////////////////////////////////////
// STORE logic                                           //
///////////////////////////////////////////////////////////

//Store decode mask
logic [31:0] mask;
always_comb
begin
    case(funct3_ff)
        SB: mask = 32'h000000ff;
        SH: mask = 32'h0000ffff;
        SW: mask = 32'hffffffff;
        default: mask = 32'h00000000;
    endcase
end
//Shift amount
wire [4:0] shift_amount = {address_reg [1:0], 3'b000};
wire [63:0] masked_window = mask << shift_amount;

//Create new data, this shifts the data to the desired bytes 
wire [63:0] new_data_window = store_data_reg << shift_amount;

//Modified window contains the new data that will be stored
wire [7:0] modified_window [7:0];
assign modified_window [0] = ((~masked_window [7:0] & access_window [0]) | (new_data_window [7:0] & masked_window [7:0]));
assign modified_window [1] = ((~masked_window [15:8] & access_window [1]) | (new_data_window [15:8] & masked_window [15:8]));
assign modified_window [2] = ((~masked_window [23:16] & access_window [2]) | (new_data_window [23:16] & masked_window [23:16]));
assign modified_window [3] = ((~masked_window [31:24] & access_window [3]) | (new_data_window [31:24] & masked_window [31:24]));
assign modified_window [4] = ((~masked_window [39:32] & access_window [4]) | (new_data_window [39:32] & masked_window [39:32]));
assign modified_window [5] = ((~masked_window [47:40] & access_window [5]) | (new_data_window [47:40] & masked_window [47:40]));
assign modified_window [6] = ((~masked_window [55:48] & access_window [6]) | (new_data_window [55:48] & masked_window [55:48]));
assign modified_window [7] = ((~masked_window [63:56] & access_window [7]) | (new_data_window [63:56] & masked_window [63:56]));

//These replace the data registers on a store operation, these are not registers but contain the information
//That needs to be stored
wire [31:0] new_data_1;
assign new_data_1 [7:0] = modified_window [0];
assign new_data_1 [15:8] = modified_window [1];
assign new_data_1 [23:16] = modified_window [2];
assign new_data_1 [31:24] = modified_window [3];
wire [31:0] new_data_2;
assign new_data_2 [7:0] = modified_window [4];
assign new_data_2 [15:8] = modified_window [5];
assign new_data_2 [23:16] = modified_window [6];
assign new_data_2 [31:24] = modified_window [7];

////////////////////////////////////////////////////
// Load logic to choose the correct data bus      //
////////////////////////////////////////////////////

//Multiplexer to choose between the load bus
always_comb
begin
    case(funct3_ff)
        LB: load_data = ALIGNED_BYTE;
        LH: load_data = ALIGNED_HALF_WORD;
        LW: load_data = ALIGNED_WORD_BUS;
        LBU: load_data = ALIGNED_U_BYTE;
        LHU: load_data = ALIGNED_U_HALF_WORD;
        default: load_data = 32'h00000000;
    endcase
end


////////////////////////////////////////////////////////////////////////////////////
// State machine that drives the Wishbone interface and store and load operations //
////////////////////////////////////////////////////////////////////////////////////

//This is the state machine that accesses the data memory
//This state machine has to be able to read and write data and also handle
//Unaligned data access. On write command it will have to read the required
//data size, and if its unaligned it will have to read the required memory blocks
//update the byte and write back the data.
//In the case of an unaligned load, it has to read the required data and align it,
//So it can be store in the registers 
//                       READ2 => NO_CMD
//                      /
// NO_CMD => READ (!unaligned)? => NO_CMD
//        \
//         => WRITE (size > 1)? => READW1 => WRITE1 => NO_CMD
//                  \
//                  READW1
//                    \
//                      => READW2 DATA & UPDATE BYTE or BYTES
//                                  |
//                                 \ /
//                                  UWRITE1 -> UWRITE2 -> NO_CMD
//FINALU -> final unaligned

//If unaligned access then the state machine has to read the current data block and the next
//data block, each data block is 32bits wide.

//States
typedef enum logic [3:0] { NO_CMD, READ1, READ2, READ_W1, READ_W2, UWRITE1, UWRITE2 } DATA_BUS_STATE;

//State register and next state bus
DATA_BUS_STATE data_bus_state;

//Synchronous logic for the state machine
always@(posedge clk)
begin
    if(rst)
    begin
        data_bus_state = NO_CMD;
        data_1 = 32'h00000000;
        data_2 = 32'h00000000;
        store_data_reg = 32'h00000000;
        address_reg = 32'h00000000;
    end
    else
    begin
        case(data_bus_state)
            NO_CMD:
            begin
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address_reg [31:0];
                data_1 <= data_1;
                data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                data_valid = 1'b0;
                if(cyc)
                begin
                    ack = 1'b1; //Acknowledge the request
                    //Latch data and address
                    store_data_reg = store_data;
                    address_reg = address;
                    funct3_ff = funct3;
                    unaligned_ff = unaligned;
                    unique case(memory_operation)
                        LOAD_DATA:
                        begin
                            //Go to read1 to read first block
                            data_bus_state <= READ1;                    
                        end
                        STORE_DATA:
                        begin
                            if(unaligned) //If unaligned read first bytes
                            begin
                                data_bus_state <= READ_W1; //Read to update bytes                
                            end
                            else //Not unaligned
                            begin
                                if(access_size != WORD) //Unaligned and WORD access overwrites the whole word on memory
                                begin //Read bytes because we need to read, change data and write back
                                    data_bus_state <= READ_W1; //Read to update bytes                
                                end
                                else
                                begin
                                    data_bus_state <= UWRITE1; //Update bytes, because the write a whole block                 
                                end
                            end
                        end
                    endcase
                end
                else
                begin
                    ack = 1'b0;
                    data_bus_state <= NO_CMD;
                    store_data_reg = store_data_reg;
                    address_reg = address_reg;
                    funct3_ff = funct3_ff;
                end

            end
            READ1:
            begin
                    store_data_reg = store_data_reg;
                    address_reg = address_reg;
                    funct3_ff = funct3_ff;
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address_reg [31:0];
                if(data_bus.ACK)
                begin
                    data_1 <= data_bus.DAT_I;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    if(unaligned_ff)
                    begin
                        data_bus_state <= READ2;
                        data_valid = 1'b0;
                    end
                    else
                    begin
                        //Done with the read operation. The data is valid now
                        data_valid = 1'b1; 
                        data_bus_state <= NO_CMD;
                    end
                end
                else
                begin
                    data_bus_state <= READ1;
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b1;
                    data_bus.CYC <= 1'b1;
                    data_bus.WE <= 1'b0;
                    data_valid = 1'b0;
                end
            end
            READ2:
            begin
                    store_data_reg = store_data_reg;
                    address_reg = address_reg;
                    funct3_ff = funct3_ff;
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address_reg [31:0] + 32'b100;
                if(data_bus.ACK)
                begin
                    data_1 <= data_1;
                    data_2 <= data_bus.DAT_I;
                    data_bus_state <= NO_CMD;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    //Done with the read operation. The data is valid now
                    data_valid = 1'b1; 
                end
                else
                begin
                    data_valid = 1'b0; 
                    data_bus_state = READ2;
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b1;
                    data_bus.CYC <= 1'b1;
                    data_bus.WE <= 1'b0;
                end
            end
            READ_W1:
            begin
                    store_data_reg = store_data_reg;
                    address_reg = address_reg;
                    funct3_ff = funct3_ff;
                data_valid = 1'b0;
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address_reg [31:0];
                if(data_bus.ACK)
                begin
                    data_1 <= data_bus.DAT_I;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    if(unaligned_ff)
                    begin
                        data_bus_state <= READ_W2;
                    end
                    else
                    begin
                        data_bus_state <= UWRITE1;
                    end
                end
                else
                begin
                    data_bus_state <= READ_W1;
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b1;
                    data_bus.CYC <= 1'b1;
                    data_bus.WE <= 1'b0;
                end
            end
            READ_W2:
            begin
                    store_data_reg = store_data_reg;
                    address_reg = address_reg;
                    funct3_ff = funct3_ff;
                data_valid = 1'b0;
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address_reg [31:0] + 32'b100;
                if(data_bus.ACK)
                begin
                    data_1 <= data_1;
                    data_2 <= data_bus.DAT_I;
                    //data_bus.DAT_O <= da;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    data_bus_state <= UWRITE1;
                end
                else
                begin
                    data_bus_state <= READ_W2;
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b1;
                    data_bus.CYC <= 1'b1;
                    data_bus.WE <= 1'b0;
                end
            end
            UWRITE1:
            begin
                    store_data_reg = store_data_reg;
                    address_reg = address_reg;
                    funct3_ff = funct3_ff;
                data_valid = 1'b0;
                ack = 1'b0;
                data_bus.ADR <= address_reg [31:0];
                data_bus.DAT_O <= new_data_1;
                if(data_bus.ACK)
                begin
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    if(unaligned_ff)
                    begin
                        data_bus_state <= UWRITE2;
                    end
                    else
                    begin
                        data_bus_state <= NO_CMD;
                    end
                end
                else
                begin
                    data_bus_state <= UWRITE1;
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b1;
                    data_bus.CYC <= 1'b1;
                    data_bus.WE <= 1'b1;
                end
            end
            UWRITE2:
            begin
                    store_data_reg = store_data_reg;
                    address_reg = address_reg;
                    funct3_ff = funct3_ff;
                data_valid = 1'b0;
                ack = 1'b0;
                data_bus.ADR <= address_reg [31:0] + 32'b100;
                data_bus.DAT_O <= new_data_2;
                if(data_bus.ACK)
                begin
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    data_bus_state <= NO_CMD;
                end
                else
                begin
                    data_bus_state <= UWRITE2;
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b1;
                    data_bus.CYC <= 1'b1;
                    data_bus.WE <= 1'b1;
                end
            end
    		default:
    		  begin
                store_data_reg = store_data_reg;
                address_reg = address_reg;
                funct3_ff = funct3_ff;
                data_valid = 1'b0;
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address_reg [31:0];
                data_1 <= data_1;
                data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                data_bus_state <= NO_CMD;
            end
        endcase
    end
end

endmodule
import global_pkg::*

module memory_access_tb();


//Only two entries to check for unaligned access
reg [31:0] memory [1:0];

typedef enum int { BYTE, HALF_WORD, WORD } write_size_t;
typedef enum int { SBYTE, UBYTE, SHALF_WORD, UHALF_WORD, RWORD } read_size_t;

task automatic write(write_size_t size, unsigned int data, unsigned int address);
    
endtask //automatic

task automatic read(read_size_t size, unsigned int address, unsigned int expected);
    
endtask //automatic

logic clk;
logic rst;

WB4 wb(clk, rst);

memory_access memory_access_0
(
    //Syscon
    .clk(clk),
    .rst(rst),

    //Control signals
    .memory_operation(memory_operation),
    .cyc(cyc),
    .ack(ack),
    .data_valid(data_valid), //This is needed for the load instruction
    .funct3(funct3),

    //Data
    .store_data(),
    .address(),
    .load_data(),

    //Wishbone interface
    .data_bus()
);

initial begin
    clk = 0;
    rst = 0;

end

//Fake wishbone memory





//Clock generation
always #10 clk = ~clk;



endmodule// Quartus Prime Verilog Template
// Single port RAM with single read/write address 

`include "debug_def.sv"

module ram 
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=20)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH+1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1):0] q

	`ifdef DEBUG_PORT
		,output logic [31:0] debug_data,
		output logic [31:0] debug_address
	`endif
);
	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	always @ (negedge clk)
	begin
		// Write
		if (we)
			ram[addr [(ADDR_WIDTH+1):2]] <= data;

		addr_reg <= addr [(ADDR_WIDTH+1):2];
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];

	initial begin
		$display("Init memory");
		`ifdef DEBUG_PORT
			for (int i = 0;i < 2**ADDR_WIDTH-1; i++ ) begin
				ram[i] = 32'h0;
			end
		`endif
		$readmemh("C:/Users/camin/Documents/VanilaCore/core/c_code/ROM.hex", ram);
		//$readmemh("ROM.hex", ram); 
	end
	//Data probe
	`ifdef DEBUG_PORT
		assign debug_data = ram[debug_address];
	`endif

endmodule
//8:48AM Wishbone compatible RAM wrapper
//Author: Benjamin Herrera Navarro
//10/31/2020

`include "debug_def.sv"

module ram_wb #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 20)(WB4.slave wb);

ram #(DATA_WIDTH, ADDR_WIDTH) RAM_0
(
    .clk(wb.clk),
	.we(wb.WE & wb.STB & wb.CYC),
	.data(wb.DAT_O),
	.addr(wb.ADR),
	.q(wb.DAT_I)
    //DEBUG PORT probes
    `ifdef DEBUG_PORT
    ,.debug_data(debug_data),
    .debug_address(debug_address)
    `endif
);

//All wishbone modules have to be reseted on the positive edge of the clock
//Sample signals at the rising edge
logic ack_s; //Signal for the ack line

always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        ack_s = 1'b0;
    end
    else
    begin
        if(wb.CYC & wb.STB)
        begin
            ack_s = 1'b1;
        end
        else
        begin
            ack_s = 1'b0;
        end
    end
end

//Only valid if CYC.
assign wb.ACK = ack_s & wb.CYC;

`ifdef MEMORY_DEBUG_MSGS
always@(posedge wb.clk & wb.ACK)
begin
    if(wb.ADR [1:0] != 2'b0) $display("Memory Warning: Unaligned Memory Access");
    if(wb.WE) $display("Memory Write: Address 0x%08x, Data 0x%08x", wb.ADR [(ADDR_WIDTH+1):2], wb.DAT_O);
    else $display("Memory Read: Address 0x%08x, Data 0x%08x", wb.ADR [(ADDR_WIDTH+1):2], wb.DAT_I);
end
`endif

endmodule//3:23AM Implementation of a simple single cycle RISC V RV32I core
//Author: Benjamin Herrera Navarro
//10/31/2020
`include "debug_def.sv"

module regfile
(
    input clk,
    input rst,
    input  [4:0] ra, 
    input  [4:0] rb,
    input  [4:0] rd,
    output [31:0] ra_d, 
    output [31:0] rb_d,
    input [31:0] rd_d,
    input wr
    `ifdef DEBUG_PORT
    ,output logic [31:0] reg_debug [31:0]
    `endif
);

//32, 32bit registers
reg [31:0] REGS [31:0]; 

`ifdef DEBUG_PORT
    assign reg_debug = REGS;
`endif

always@(posedge clk)
begin
    if(rst) //Reset
    begin
        for(int i = 0;i < 32;i++)
        begin
            REGS[i] = 32'h00000000;
        end
    end 
    else if(wr && (rd > 0)) //Write
    begin
        REGS[rd] = rd_d; 
    end
    else
    begin
        REGS[rd] = REGS[rd];
    end
end

//Register file output
assign ra_d = REGS[ra];
assign rb_d = REGS[rb];


endmodulemodule seven_segment
(
    WB4.slave wb,
    output logic [6:0] display_data,
    output logic [3:0] select
);

reg [31:0] data;

assign wb.DAT_I = data; 
//Wishbone interface
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        data = 32'h00000000;
    end
    else
    begin
        if(wb.STB & wb.CYC)
        begin
            if(wb.WE)
            begin
                data = wb.DAT_O; 
                $display("Seven Segment Display %x", data);
            end
            else
            begin
                data = data; 
            end
            wb.ACK = 1;
        end
        else
        begin
            data = data; 
            wb.ACK = 0;
        end
    end
end


logic [6:0] display_bus;


//Clock divider
reg [31:0] cnt; //To devide the clock
always@(posedge wb.clk)
begin
    cnt = cnt + 1;
end

//Select counter
reg [1:0] sel_n;
always@(posedge cnt[15:15])
begin
    sel_n = sel_n + 1;
end

initial begin
    cnt = 0;
    sel_n = 0;
end

always_comb
begin
    case(sel_n)
        0: select = 4'b1110;
        1: select = 4'b1101;
        2: select = 4'b1011;
        3: select = 4'b0111;
    endcase
end

//Data to display
logic [3:0] dattd;
//Multiplexer to select data
always_comb
begin
    unique case(sel_n)
        0: dattd <= data [3:0];
        1: dattd <= data [7:4];
        2: dattd <= data [11:8];
        3: dattd <= data [15:12];
    endcase
end

always_comb
begin
    case(dattd)
                            /// GFEDCBA
        4'h0: display_bus <= 7'h3f;//0
        4'h1: display_bus <= 7'h06;//1
        4'h2: display_bus <= 7'h5b;//2
        4'h3: display_bus <= 7'h4f;//3
        4'h4: display_bus <= 7'h66;//4
        4'h5: display_bus <= 7'h6d;//5
        4'h6: display_bus <= 7'h7d;//6
        4'h7: display_bus <= 7'h07;//7
        4'h8: display_bus <= 7'h7f;//8
        4'h9: display_bus <= 7'h6f;//9
        4'hA: display_bus <= 7'h77;//A
        4'hB: display_bus <= 7'h7c;//B
        4'hC: display_bus <= 7'h39;//C
        4'hD: display_bus <= 7'h5e;//D
        4'hE: display_bus <= 7'h79;//E
        4'hF: display_bus <= 7'h71;//F
    endcase
end


assign display_data = ~display_bus;


endmodule


module seven_segment_tb();

logic clk;
logic rst;

logic new_clock;
logic new_rst;

initial begin
    new_clock = 0;
end
always@(posedge clk)
begin
    new_clock = ~new_clock;
    new_rst = ~rst;
end

WB4 seven_segment_wb(new_clock, ~new_rst);

seven_segment seven_segment_0(
    .wb(seven_segment_wb), 
    .display_data(display_data),
    .select(select)
    );


    
initial begin
    //Begin of reset secuence
    clk <= 0;
    rst <= 0;
    #10
    clk <= 1;
    rst <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    rst <= 0;
    //End of reset secuence
    repeat(100000000) #10 clk = ~clk;
end


endmodule
interface SNOOP_INT;
    logic [31:0] address;
    logic [31:0] data;
    logic wr; //Write
    logic ack;
endinterface //SNOOP_INT
//`define sim

module soc
(
    `ifndef sim
	input logic clk,
	input logic rst,
    output logic uart_tx,
    input  logic uart_rx,
    output [6:0] display_data,
    output [3:0] select
    `endif
);


logic new_clock;
logic new_rst;

`ifdef sim
logic clk;
logic rst;
logic uart_tx;
logic uart_rx;
logic [6:0] display_data;
logic [3:0] select;
assign new_rst = rst;
`endif

initial begin
    new_clock = 0;
end
always@(posedge clk)
begin
    new_clock = ~new_clock;
end

debounce debounce_rst
(
    .clk(clk),
    .debounce(~rst),
    .debounced(new_rst)
);

//Buses from CPU
WB4 inst_bus(new_clock, new_rst);
WB4 data_bus(new_clock, new_rst);

//Bus to access memory from data bus
WB4 memory_wb(new_clock, new_rst);

//Bus to access RAM directly
WB4 memory_mater_wb(new_clock, new_rst);

//Devices
WB4 uart_wb(new_clock, new_rst);
WB4 uart_rx_wb(new_clock, new_rst);
WB4 seven_segment_wb(new_clock, new_rst);

cross_bar cross_bar_0 
(
    //Define master
    .cpu(data_bus),
    .memory(memory_wb),
    .uart(uart_wb),
    .uart_rx(uart_rx_wb),
    .seven_segments(seven_segment_wb)
);

wishbone_arbitrer wishbone_arbitrer_0
(
    .master_wb(memory_mater_wb),
    .inst_wb(inst_bus),
    .data_wb(memory_wb)
);


//Memory and devices
ram_wb #(32, 12) MEMORY_RAM(.wb(memory_mater_wb));
uart_slave uart_slave_0
(
    .wb(uart_rx_wb),
    .rx(uart_rx)
);
console console_0(.wb(uart_wb), .tx(uart_tx));
seven_segment seven_segment_0(
    .wb(seven_segment_wb), 
    .display_data(display_data),
    .select(select)
    );



core CORE_0
    (
        .inst_bus(inst_bus),
        .data_bus(data_bus)
    );

`ifdef sim   
initial begin
    //Begin of reset secuence
    clk <= 0;
    rst <= 0;
    #10
    clk <= 1;
    rst <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    rst <= 0;
    //End of reset secuence
    repeat(100000000) #10 clk = ~clk;
end

`endif

endmodule
interface SPI;
    logic MISO;
    logic MOSI;
    logic SCLK;
endinterface //SPI//Benjamin Herrera Navarro.
//11:15PM
//12/17/2020



module spi_controller(WB4.slave wb);




//Memory Map
//0x00 DATA  
//0x01 Count
//0x02 Config

//Config Register Bits
// Bit N   ON State         OFF STATE       Description
// Bit 0   1 - LSB First    0 - MSB First    
// Bit 1   1 - 8Bit Data    0 - 16Bit Data
// Bit 2   x                x               CPOL
// Bit 3   x                x               CPHA

typedef enum logic [3:0] { IDDLE, SEND_DATA } states_t;

states_t SPI_MASTE_STATES;

always@(posedge clk)
begin
    unique case(SPI_MASTE_STATES)
        IDDLE:
        begin
            
        end
        SEND_DATA:
        begin
            
        end
    endcase
end


endmodule//Store state machine module

module store_stm
(

);


//54bit access window
reg [31:0] data_1;
reg [31:0] data_2; //Only used on unaligned access

logic [31:0] wr_addr_bus;
always_comb
begin
    if(load_data)
    begin
        wr_addr_bus = rs1_d + 32'(signed'(i_imm));
    end
    else //Store
    begin
        wr_addr_bus = rs1_d + 32'(signed'(s_imm));
    end
end

wire [7:0] access_window [7:0];
assign access_window [0] = data_1 [7:0];
assign access_window [1] = data_1 [15:8];
assign access_window [2] = data_1 [23:16];
assign access_window [3] = data_1 [31:24];
assign access_window [4] = data_2 [7:0];
assign access_window [5] = data_2 [15:8];
assign access_window [6] = data_2 [23:16];
assign access_window [7] = data_2 [31:24];

wire [31:0] aligned_data;
assign aligned_data [7:0] = access_window [wr_addr_bus [1:0] + 0];
assign aligned_data [15:8] = access_window [wr_addr_bus [1:0] + 1];
assign aligned_data [23:16] = access_window [wr_addr_bus [1:0] + 2];
assign aligned_data [31:24] = access_window [wr_addr_bus [1:0] + 3];

wire [31:0] ALIGNED_BYTE = 32'(signed'(aligned_data [7:0]));
wire [31:0] ALIGNED_U_BYTE = {24'h0, aligned_data [7:0]};
wire [31:0] ALIGNED_HALF_WORD = 32'(signed'(aligned_data [15:0]));
wire [31:0] ALIGNED_U_HALF_WORD = {16'h0, aligned_data [15:0]};
wire [31:0] ALIGNED_WORD_BUS = aligned_data;

//Store decode mask
logic [31:0] mask;
always_comb
begin
    unique case(funct3)
        SB: mask = 32'h000000ff;
        SH: mask = 32'h0000ffff;
        SW: mask = 32'hffffffff;
    endcase
end
//Shift amount
wire [4:0] shift_amount = {wr_addr_bus [1:0], 3'b000};
wire [63:0] masked_window = mask << shift_amount;

//Create new data, this shift the data to the desired bytes 
wire [63:0] new_data_window = rs2_d << shift_amount;

//New bus bus the new data
wire [7:0] modified_window [7:0];
assign modified_window [0] = ((~(masked_window [7:0]) & access_window [0]) | new_data_window [7:0]);
assign modified_window [1] = ((~(masked_window [15:8]) & access_window [1]) | new_data_window [15:8]);
assign modified_window [2] = ((~(masked_window [23:16]) & access_window [2]) | new_data_window [23:16]);
assign modified_window [3] = ((~(masked_window [31:24]) & access_window [3]) | new_data_window [31:24]);
assign modified_window [4] = ((~(masked_window [39:32]) & access_window [4]) | new_data_window [39:32]);
assign modified_window [5] = ((~(masked_window [47:40]) & access_window [5]) | new_data_window [47:40]);
assign modified_window [6] = ((~(masked_window [55:48]) & access_window [6]) | new_data_window [55:48]);
assign modified_window [7] = ((~(masked_window [63:56]) & access_window [7]) | new_data_window [63:56]);

wire [31:0] new_data_1;
assign new_data_1 [7:0] = modified_window [0];
assign new_data_1 [15:8] = modified_window [1];
assign new_data_1 [23:16] = modified_window [2];
assign new_data_1 [31:24] = modified_window [3];
wire [31:0] new_data_2;
assign new_data_2 [7:0] = modified_window [4];
assign new_data_2 [15:8] = modified_window [5];
assign new_data_2 [23:16] = modified_window [6];
assign new_data_2 [31:24] = modified_window [7];

//Multiplexer to choose between the load bus
always_comb
begin
    unique case(funct3)
        LB: load_data_src = ALIGNED_BYTE;
        LH: load_data_src = ALIGNED_HALF_WORD;
        LW: load_data_src = ALIGNED_WORD_BUS;
        LBU: load_data_src = ALIGNED_U_BYTE;
        LHU: load_data_src = ALIGNED_U_HALF_WORD;
    endcase
end

typedef enum logic [1:0] { BYTE, HALF_WORD, WORD } access_size_t;
access_size_t access_size; 
always_comb
begin
    unique case(funct3)
        LB: access_size = BYTE;
        LH: access_size = HALF_WORD;
        LW: access_size = WORD;
        LBU: access_size = BYTE;
        LHU: access_size = HALF_WORD;
    endcase
end

wire unaligned = ((wr_addr_bus [1:0] >= 3) & (access_size != BYTE))? 1 : 0;

always_comb
begin
    if(((wr_addr_bus [1:0] >= 3) & (access_size != BYTE)))
    begin
        //$display("Unaligned data access");
    end
end


typedef enum logic [3:0] { NO_CMD, READ1, READ2, READ_W1, READ_W2, UWRITE1, UWRITE2, IGNORE } DATA_BUS_STATE;
DATA_BUS_STATE data_bus_state, data_bus_next_state;

logic [31:0] next_read_data_1, next_read_data_2;

always@(posedge inst_bus.clk)
begin
    if(inst_bus.rst)
    begin
        data_bus_state = NO_CMD;
        data_1 = 32'h00000000;
        data_2 = 32'h00000000;
    end
    else
    begin
        data_bus_state = data_bus_next_state;
        data_1 = next_read_data_1;
        data_2 = next_read_data_2;
    end
end

//This is the state machine that accesses the data memory
//This state machine has to be able to read and write data and also handle
//Unaligned data access. On write command it will have to read the required
//data size, and if its unaligned it will have to read the required memory blocks
//update the byte and write back the data.
//In the case of an unaligned load, it has to read the required data and align it,
//So it can be store in the registers 
//                       READ2 => NO_CMD
//                      /
// NO_CMD => READ (!unaligned)? => NO_CMD
//        \
//         => WRITE (size > 1)? => READW1 => WRITE1 => NO_CMD
//                  \
//                  READW1
//                    \
//                      => READW2 DATA & UPDATE BYTE or BYTES
//                                  |
//                                 \ /
//                                  UWRITE1 -> UWRITE2 -> NO_CMD
//FINALU -> final unaligned
always_comb
begin
    case(data_bus_state)
        NO_CMD:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            next_read_data_1 <= data_1;
            next_read_data_2 <= data_2;
            if(load_data) //Load data from memory
            begin
                stop_cycle <= 1'b1;
                data_bus_next_state <= READ1;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
            end
            else if(store_data) //Store data from memory
            begin
                stop_cycle <= 1'b1;
                if(unaligned) //If unaligned read first bytes
                begin
                    data_bus_next_state <= READ_W1; //Read to update bytes                
                end
                else //Not unaligned
                begin
                    if(access_size != WORD) //Unaligned and WORD access overwrites the whole word on memory
                    begin //Read bytes because we need to read, change data and write back
                        data_bus_next_state <= READ_W1; //Read to update bytes                
                    end
                    else
                    begin
                        data_bus_next_state <= UWRITE1; //Read to update bytes                 
                    end
                end
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
            end
            else
            begin
                stop_cycle <= 1'b0;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                data_bus_next_state <= NO_CMD;
            end
        end
        READ1:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            stop_cycle <= 1'b1; //Stop the CPU from executing another instruction
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_bus.DAT_I;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                if(unaligned)
                begin
                    data_bus_next_state <= READ2;
                end
                else
                begin
                    data_bus_next_state <= IGNORE;
                end
            end
            else
            begin
                data_bus_next_state <= READ1;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b0;
            end
        end
        READ2:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0] + 32'b100;
            stop_cycle <= 1'b1;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_bus.DAT_I;
                data_bus_next_state <= IGNORE;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
            end
            else
            begin
                data_bus_next_state = READ2;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b0;
            end
        end
        READ_W1:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            stop_cycle <= 1'b1;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_bus.DAT_I;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                if(unaligned)
                begin
                    data_bus_next_state <= READ_W2;
                end
                else
                begin
                    data_bus_next_state <= UWRITE1;
                end
            end
            else
            begin
                data_bus_next_state <= READ_W1;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b0;
            end
        end
        READ_W2:
        begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0] + 32'b100;
            stop_cycle <= 1'b1;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_bus.DAT_I;
                next_read_data_2 <= data_2;
                //data_bus.DAT_O <= da;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                data_bus_next_state <= UWRITE1;
            end
            else
            begin
                data_bus_next_state <= READ_W2;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b0;
            end
        end
        UWRITE1:
        begin
            data_bus.ADR <= wr_addr_bus [31:0];
            stop_cycle <= 1'b1;
            data_bus.DAT_O <= new_data_1;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                if(unaligned)
                begin
                    data_bus_next_state <= UWRITE2;
                end
                else
                begin
                    data_bus_next_state <= IGNORE;
                end
            end
            else
            begin
                data_bus_next_state <= UWRITE1;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b1;
            end
        end
        UWRITE2:
        begin
            data_bus.ADR <= wr_addr_bus [31:0] + 32'b100;
            stop_cycle <= 1'b1;
            data_bus.DAT_O <= new_data_2;
            if(data_bus.ACK)
            begin
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                data_bus_next_state <= IGNORE;
            end
            else
            begin
                data_bus_next_state <= UWRITE2;
                next_read_data_1 <= data_1;
                next_read_data_2 <= data_2;
                data_bus.STB <= 1'b1;
                data_bus.CYC <= 1'b1;
                data_bus.WE <= 1'b1;
            end
        end
        IGNORE:
		  begin
            if(exit_ignore)
            begin
                data_bus_next_state <= IGNORE;
            end
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            next_read_data_1 <= data_1;
            next_read_data_2 <= data_2;
            stop_cycle <= 1'b0;
            data_bus.STB <= 1'b0;
            data_bus.CYC <= 1'b0;
            data_bus.WE <= 1'b0;
            data_bus_next_state <= NO_CMD;
        end
		  default:
		  begin
            data_bus.DAT_O <= 32'h0;
            data_bus.ADR <= wr_addr_bus [31:0];
            next_read_data_1 <= data_1;
            next_read_data_2 <= data_2;
            stop_cycle <= 1'b0;
            data_bus.STB <= 1'b0;
            data_bus.CYC <= 1'b0;
            data_bus.WE <= 1'b0;
            data_bus_next_state <= NO_CMD;
        end
    endcase
end





endmodule//Author: Benjamin Herrera Navarro
//6:49
//11/5/2020

module store_window
(
    input [31:0] wr_addr_bus,
    input [31:0] rs2_d, //Data that we want to store
    input [2:0] funct3,
    output [31:0] new_data_1, //How we want to align it
    output [31:0] new_data_2 //How we want to align it
);

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;


//Store decode mask
logic [31:0] mask;
always_comb
begin
    unique case(funct3)
        SB: mask = 32'h000000ff;
        SH: mask = 32'h0000ffff;
        SW: mask = 32'hffffffff;
    endcase
end
//Shift amount
wire [4:0] shift_amount = {wr_addr_bus [1:0], 3'b000};
wire [63:0] masked_window = mask << shift_amount;

//Create new data, this shift the data to the desired bytes 
wire [63:0] new_data_window = rs2_d << shift_amount;

//New bus bus the new data
wire [7:0] modified_window [7:0];
assign modified_window [0] = ((~(masked_window [7:0]) & access_window [0]) | new_data_window);
assign modified_window [1] = ((~(masked_window [15:8]) & access_window [1]) | new_data_window);
assign modified_window [2] = ((~(masked_window [23:16]) & access_window [2]) | new_data_window);
assign modified_window [3] = ((~(masked_window [31:24]) & access_window [3]) | new_data_window);
assign modified_window [4] = ((~(masked_window [39:32]) & access_window [4]) | new_data_window);
assign modified_window [5] = ((~(masked_window [47:40]) & access_window [5]) | new_data_window);
assign modified_window [6] = ((~(masked_window [55:48]) & access_window [6]) | new_data_window);
assign modified_window [7] = ((~(masked_window [63:56]) & access_window [7]) | new_data_window);

wire [31:0] new_data_1;
assign new_data_1 [7:0] = modified_window [0];
assign new_data_1 [15:8] = modified_window [1];
assign new_data_1 [23:16] = modified_window [2];
assign new_data_1 [31:24] = modified_window [3];
wire [31:0] new_data_2;
assign new_data_2 [7:0] = modified_window [4];
assign new_data_2 [15:8] = modified_window [5];
assign new_data_2 [23:16] = modified_window [6];
assign new_data_2 [31:24] = modified_window [7];



endmodule



module store_window_tb();

logic clk;

//56bit access window
reg [31:0] data_1;
reg [31:0] data_2; //Only used on unaligned access

reg [1:0] wr_addr_bus;

wire [7:0] access_window [7:0];
assign access_window [0] = data_1 [7:0];
assign access_window [1] = data_1 [15:8];
assign access_window [2] = data_1 [23:16];
assign access_window [3] = data_1 [31:24];
assign access_window [4] = data_2 [7:0];
assign access_window [5] = data_2 [15:8];
assign access_window [6] = data_2 [23:16];
assign access_window [7] = data_2 [31:24];

wire [31:0] aligned_data;
assign aligned_data [7:0] = access_window [wr_addr_bus [1:0] + 0];
assign aligned_data [15:8] = access_window [wr_addr_bus [1:0] + 1];
assign aligned_data [23:16] = access_window [wr_addr_bus [1:0] + 2];
assign aligned_data [31:24] = access_window [wr_addr_bus [1:0] + 3];


wire [31:0] mask_size_1 = 32'h000000ff;
wire [31:0] mask_size_2 = 32'h0000ffff;
wire [31:0] mask_size_4 = 32'hffffffff;

wire [4:0] shift_amount = {wr_addr_bus [1:0], 3'b000};

wire [63:0] masked_window_1 = mask_size_1 << shift_amount;
wire [63:0] masked_window_2 = mask_size_2 << shift_amount;
wire [63:0] masked_window_4 = mask_size_4 << shift_amount;

reg [31:0] new_data;
wire [63:0] new_data_window = new_data << shift_amount;



wire [7:0] modified_window_1 [7:0];
assign modified_window_1 [0] = ((~(masked_window_1 [7:0]) & access_window [0]) | (new_data_window [7:0] & masked_window_1 [7:0]));
assign modified_window_1 [1] = ((~(masked_window_1 [15:8]) & access_window [1]) | (new_data_window [15:8] & masked_window_1 [15:8]));
assign modified_window_1 [2] = ((~(masked_window_1 [23:16]) & access_window [2]) | (new_data_window [23:16] & masked_window_1 [23:16]));
assign modified_window_1 [3] = ((~(masked_window_1 [31:24]) & access_window [3]) | (new_data_window [31:24] & masked_window_1 [31:24]));
assign modified_window_1 [4] = ((~(masked_window_1 [39:32]) & access_window [4]) | (new_data_window [39:32] & masked_window_1 [39:32]));
assign modified_window_1 [5] = ((~(masked_window_1 [47:40]) & access_window [5]) | (new_data_window [47:40] & masked_window_1 [47:40]));
assign modified_window_1 [6] = ((~(masked_window_1 [55:48]) & access_window [6]) | (new_data_window [55:48] & masked_window_1 [55:48]));
assign modified_window_1 [7] = ((~(masked_window_1 [63:56]) & access_window [7]) | (new_data_window [63:56] & masked_window_1 [63:56]));
wire [7:0] modified_window_2 [7:0];
assign modified_window_2 [0] = ((~masked_window_2 [7:0] & access_window [0]) | (new_data_window [7:0] & masked_window_2 [7:0]));
assign modified_window_2 [1] = ((~masked_window_2 [15:8] & access_window [1]) | (new_data_window [15:8] & masked_window_2 [15:8]));
assign modified_window_2 [2] = ((~masked_window_2 [23:16] & access_window [2]) | (new_data_window [23:16] & masked_window_2 [23:16]));
assign modified_window_2 [3] = ((~masked_window_2 [31:24] & access_window [3]) | (new_data_window [31:24] & masked_window_2 [31:24]));
assign modified_window_2 [4] = ((~masked_window_2 [39:32] & access_window [4]) | (new_data_window [39:32] & masked_window_2 [39:32]));
assign modified_window_2 [5] = ((~masked_window_2 [47:40] & access_window [5]) | (new_data_window [47:40] & masked_window_2 [47:40]));
assign modified_window_2 [6] = ((~masked_window_2 [55:48] & access_window [6]) | (new_data_window [55:48] & masked_window_2 [55:48]));
assign modified_window_2 [7] = ((~masked_window_2 [63:56] & access_window [7]) | (new_data_window [63:56] & masked_window_2 [63:56]));
wire [7:0] modified_window_4 [7:0];
assign modified_window_4 [0] = ((~masked_window_4 [7:0] & access_window [0]) | (new_data_window [7:0] & masked_window_4 [7:0]));
assign modified_window_4 [1] = ((~masked_window_4 [15:8] & access_window [1]) | (new_data_window [15:8] & masked_window_4 [15:8]));
assign modified_window_4 [2] = ((~masked_window_4 [23:16] & access_window [2]) | (new_data_window [23:16] & masked_window_4 [23:16]));
assign modified_window_4 [3] = ((~masked_window_4 [31:24] & access_window [3]) | (new_data_window [31:24] & masked_window_4 [31:24]));
assign modified_window_4 [4] = ((~masked_window_4 [39:32] & access_window [4]) | (new_data_window [39:32] & masked_window_4 [39:32]));
assign modified_window_4 [5] = ((~masked_window_4 [47:40] & access_window [5]) | (new_data_window [47:40] & masked_window_4 [47:40]));
assign modified_window_4 [6] = ((~masked_window_4 [55:48] & access_window [6]) | (new_data_window [55:48] & masked_window_4 [55:48]));
assign modified_window_4 [7] = ((~masked_window_4 [63:56] & access_window [7]) | (new_data_window [63:56] & masked_window_4 [63:56]));

wire [31:0] new_data_1;
assign new_data_1 [7:0] = modified_window_2 [0];
assign new_data_1 [15:8] = modified_window_2 [1];
assign new_data_1 [23:16] = modified_window_2 [2];
assign new_data_1 [31:24] = modified_window_2 [3];
wire [31:0] new_data_2;
assign new_data_2 [7:0] = modified_window_2 [4];
assign new_data_2 [15:8] = modified_window_2 [5];
assign new_data_2 [23:16] = modified_window_2 [6];
assign new_data_2 [31:24] = modified_window_2 [7];

initial begin
    data_1 = 32'h0400c9bf;
    data_2 = 32'h00000000;
    new_data = 32'hffff8b70;
    wr_addr_bus = 0;
    clk = 0;
    //
    repeat(200) #10 clk = ~clk;
end

always@(posedge clk)
begin
    wr_addr_bus = wr_addr_bus + 1;
end
endmodule

module timer
(
    WB4.slave wb,
    output logic interrupt
);

//Address       Register
//0x0000        timecmp low
//0x0004        timecmp high
//0x0008        time low
//0x000c        time high

reg [63:0] mtimecmp;
reg [63:0] mtime;

logic ack_s;

//reading from the timers
always_comb
begin
    case(wb.ADR[3:0])
        4'h0: wb.DAT_I = mtimecmp [31:0];
        4'h4: wb.DAT_I = mtimecmp [63:32];
        4'h8: wb.DAT_I = mtime [31:0];
        4'hc: wb.DAT_I = mtime [63:0];
        default: wb.DAT_I = 32'b0;
    endcase
end

always@(posedge wb.clk)
begin
    if(wb.STB & wb.CYC)
    begin
        ack_s = 1'b1;
        if(wb.WE)
        begin
            unique case(wb.ADR[3:0])
                4'h0: mtimecmp [31:0] = wb.DAT_O;
                4'h4: mtimecmp [63:32] = wb.DAT_O;
                4'h8: mtime [31:0] = wb.DAT_O;
                4'hc: mtime [63:0] = wb.DAT_O;
            endcase
        end
    end
    else
    begin
        ack_s = 1'b0;
    end
end

assign wb.ACK = (ack_s & wb.STB & wb.CYC);

assign interrupt = (mtimecmp >= mtime)? 1 : 0;


endmodule


class trace_packet;
    mailbox mbx;

    bit [6:0] opcode;
    bit [4:0] rd;
    bit [4:0] rs1;
    bit [4:0] rs2;


    function new(mailbox mbx);
        this.mbx = mbx;
    endfunction //new()

     
endclass //trace_packet
//Memory MAP

//Address Usecase  Read Write
//0x000  DATA     Y    N
//0x004  Count    Y    N

//Count hold the number of available bytes to read

module uart_slave
(
    WB4.slave wb,
    input logic rx
);

parameter FREQUENCY = 25000000;
parameter BAUD_RATE = 115200;
parameter DELAY_CLOCKS = FREQUENCY/BAUD_RATE;
parameter DATA_WIDTH = 7; //-1

typedef enum logic [3:0] { IDDLE, START, BIT_S, STOP, DONE } states;

states current_state;

reg [DATA_WIDTH-1:0] data;
reg [2:0] n_bit;
reg [31:0] delay_count;
reg [2:0] shamnt;


logic wr;
logic rd;
logic empty;
logic full;
logic [6:0] dout;
logic [$clog2(32)-1:0] count;

fifo #(.DATA_WIDTH(7), .MEMORY_DEPTH(32)) fifo_0
(
    //Syscon
    .clk(wb.clk),
    .rst(wb.rst),

    //Status
    .empty(empty),
    .full(full),
    .count(count),

    //Read
    .rd(rd),
    .dout(dout),

    //Write
    .wr(wr),
    .din(data)
);

//Wishbone address decoder
always_comb
begin
    casez (wb.ADR)
        32'b????_????_????_????_????_????_????_?000: wb.DAT_I = dout;
        32'b????_????_????_????_????_????_????_?100: wb.DAT_I = count;
        default: wb.DAT_I = 32'b0;
    endcase
end

//Wishbone control logic
logic ack_s;

always@(posedge wb.clk)
begin
    if(wb.STB & wb.CYC)
    begin
        casez (wb.ADR)
            32'b????_????_????_????_????_????_????_?000:
            begin
                rd = 1;
                ack_s = 1'b1;
                $display("READING DATA FROM UART RECIEVER");
            end
            32'b????_????_????_????_????_????_????_?100:
            begin
                rd = 0;
                ack_s = 1'b1;
            end
            default:
            begin
                rd = 0;
                ack_s = 1'b1;
            end
        endcase
    end
    else
    begin
        rd = 0;
        ack_s = 1'b0;
    end
end

assign wb.ACK = ack_s & wb.CYC & wb.STB;

//Sample signals at the rising edge
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        current_state = IDDLE;
        delay_count = 0;
        shamnt = 0;
    end
    else
    begin
        case(current_state)
            IDDLE:
            begin
                wr = 1'b0;
                delay_count = 0;
                shamnt = 0;

                if(rx == 0)
                begin
                    current_state = START;
                end
            end
            START:
            begin
                wr = 1'b0;
                shamnt = 0;
                if(delay_count == DELAY_CLOCKS)
                begin
                    current_state = BIT_S;
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
            end
            BIT_S:
            begin
                wr = 1'b0;
                if(delay_count == (DELAY_CLOCKS/2))
                begin
                    data <= {rx, data [DATA_WIDTH-1:1]}; 
                end
                if(delay_count == DELAY_CLOCKS)
                begin
                    if(shamnt == DATA_WIDTH-1)
                    begin
                        current_state = STOP;
                        shamnt = 0;                    
                    end
                    else
                    begin
                        shamnt = shamnt + 1;
                        current_state = BIT_S;                
                    end
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
            end
            STOP:
            begin
                shamnt = 0;
                if(delay_count == DELAY_CLOCKS)
                begin
                    wr = 1'b1;
                    if(!full)
                    begin
                        current_state = IDDLE;                    
                    end
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
                //PUSH data into buffer
            end
        endcase
    end
end


endmodulemodule vga_controller
(
    WB4.slave wb,
    VGA.output_int vga
);
parameter FREQ = 50000000;
parameter HEIGHT = 640;
parameter WIDTH = 480;
parameter ADDR_WIDTH = $clog2(HEIGHT*WIDTH)-1;

reg [7:0] frame_buffer [2**ADDR_WIDTH-1:0];

assign wb.DAT_I = 32'h0;

always@(negedge wb.clk)
begin
  if(wb.STB & wb.CYC)
  begin
      wb.ACK = 1'b1;
      if(wb.WE)
      begin
          frame_buffer [wb.ADR[15:2]] = wb.DAT_O;
          $display("VGA WRITE %x", wb.DAT_O);
      end
  end
  else
  begin
      wb.ACK = 1'b0;
  end
end


//Horizontal Timing
//Scanline part	    Pixels	Time [µs]
//Visible area	    640	    25.422045680238
//Front porch	    16	    0.63555114200596
//Sync pulse	    96	    3.8133068520357
//Back porch	    48	    1.9066534260179
//Whole line	    800	    31.777557100298
//640x480

//Vertical timing (frame)
//Polarity of vertical sync pulse is negative.
//Frame part	Lines	Time [ms]
//Visible area	480	    15.253227408143
//Front porch	10	    0.31777557100298
//Sync pulse	2	    0.063555114200596
//Back porch	33	    1.0486593843098
//Whole frame	525	    16.683217477656

reg [9:0] horizontal_counter;
reg [9:0] vertical_counter;

//always@(negedge wb.clk)
//begin
//    {vga.r, vga.g, vga.b} = frame_buffer [horizontal_counter*vertical_counter];
//end
assign {vga.r, vga.g, vga.b} = 3'b000;


//Increment counter
always@(posedge wb.clk)
begin
    if(horizontal_counter == 800)
    begin
        horizontal_counter = 0;
        if(vertical_counter == 525)
        begin
            vertical_counter = 0;
        end
        else
        begin
            vertical_counter = vertical_counter + 1;        
        end
    end
    else
    begin
        horizontal_counter = horizontal_counter + 1;    
    end
end

always_comb
begin
    if((horizontal_counter >= 656) & (horizontal_counter <= 656 + 96))
    begin
        vga.h_sync = 1'b0;
    end
    else
    begin
        vga.h_sync = 1'b1;
    end
end

always_comb
begin
    if((vertical_counter >= 480 + 10) & (vertical_counter <= 480 + 10 + 2))
    begin
        vga.v_sync = 1'b0;
    end
    else
    begin
        vga.v_sync = 1'b1;
    end
end


endmoduleinterface VGA();
    logic v_sync;
    logic h_sync;
    logic r;
    logic g;
    logic b;
    modport output_int(
        output v_sync,
        output h_sync,
        output r,
        output g,
        output b
        );

endinterface //VGA
module wishbone_arbitrer
(
    WB4.master master_wb,
    WB4.slave inst_wb,
    WB4.slave data_wb
);

//Data from ram to inst and data buses
assign inst_wb.DAT_I = master_wb.DAT_I;
assign data_wb.DAT_I = master_wb.DAT_I;

//Prioritize DATA bus
assign master_wb.ADR = (data_wb.CYC & data_wb.STB)? data_wb.ADR : inst_wb.ADR;
assign master_wb.DAT_O = (data_wb.CYC & data_wb.STB)? data_wb.DAT_O : inst_wb.DAT_O;
assign master_wb.WE = (data_wb.CYC & data_wb.STB)? data_wb.WE : inst_wb.WE;
assign master_wb.CYC = (data_wb.CYC)? data_wb.CYC : inst_wb.CYC;
assign master_wb.STB = (data_wb.CYC & data_wb.STB)? data_wb.STB : inst_wb.STB;

//Ack signal
assign data_wb.ACK = (data_wb.CYC & data_wb.STB)? master_wb.ACK : 0;
assign inst_wb.ACK = (~(data_wb.CYC & data_wb.STB))? master_wb.ACK : 0;

endmodule interface WB4(input clk, input rst);
    logic ACK;
    logic STB;
    logic [31:0] ADR;
    logic CYC;
    logic [31:0] DAT_I;
    logic [31:0] DAT_O;
    logic WE;
    modport slave(input clk, rst,
    input STB,
    input ADR,
    input CYC,
    output DAT_I,
    input  DAT_O,
    output ACK,
    input WE);
    modport master(input clk, rst,
    output STB,
    output ADR,
    output CYC,
    input  DAT_I,
    output DAT_O,
    input ACK,
    output WE);
endinterface //WB4
`include "debug_def.sv"

module ZeltaSoC
(
    `ifndef sim
	input logic clk,
	input logic rst,
    output logic uart_tx,
    input  logic uart_rx
    `endif
);

logic new_rst;

`ifdef sim
logic clk;
logic rst;
logic uart_tx;
logic uart_rx;
assign new_rst = rst;
`endif

debounce debounce_rst
(
    .clk(clk),
    .debounce(~rst),
    .debounced(new_rst)
);

//Buses from CPU
WB4 inst_bus(clk, new_rst);
WB4 data_bus(clk, new_rst);

//Bus to access memory from data bus
WB4 memory_wb(clk, new_rst);

//Bus to access RAM directly
WB4 memory_mater_wb(clk, new_rst);

//Devices
WB4 uart_wb(clk, new_rst);
WB4 uart_rx_wb(clk, new_rst);

//Timer for timer interrupts
WB4 timer_dev(clk, new_rst);

//Interrupt
logic interrupt;

cross_bar cross_bar_0 
(
    //Define master
    .cpu(data_bus),
    .memory(memory_wb),
    .uart(uart_wb),
    .uart_rx(uart_rx_wb),
    .timer_dev(timer_dev)
);

wishbone_arbitrer wishbone_arbitrer_0
(
    .master_wb(memory_mater_wb),
    .inst_wb(inst_bus),
    .data_wb(memory_wb)
);

//Timer for timer interrupts
timer timer_0
(
    .wb(timer_dev),
    .interrupt(interrupt)
);

//Memory and devices
ram_wb #(32, 16) MEMORY_RAM(.wb(memory_mater_wb));
uart_slave uart_slave_0
(
    .wb(uart_rx_wb),
    .rx(uart_rx)
);
console console_0(.wb(uart_wb), .tx(uart_tx));

core CORE_0
    (
        .inst_bus(inst_bus),
        .data_bus(data_bus)
    );

`ifdef sim   
initial begin
    //Begin of reset secuence
    clk <= 0;
    rst <= 0;
    #10
    clk <= 1;
    rst <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    rst <= 0;
    //End of reset secuence
    repeat(100000000) #10 clk = ~clk;
end

`endif

endmodule