
import global_pkg::*;

module core
(
    WB4.master inst_bus,
    WB4.master data_bus
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
);


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

control_unit control_unit_0
(
    .clk(inst_bus.clk),
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
    .ack(ack)
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

//Multiplexer for the Registerfile input
always_comb
begin
    unique case(regfile_src)
        ALU_INPUT: rd_d <=  rd_alu;
        U_IMM_SRC: rd_d <= decode_bus.u_imm;
        AUIPC_SRC: rd_d <= decode_bus.u_imm + PC;
        PC_SRC: rd_d <= PC;
        LOAD_SRC: rd_d <= load_data;
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
    .wr(regfile_wr)
);

//Multiplexer for the sr2 alu input bus
always_comb
begin
    unique case(sr2_src)
        REG_SRC: alu_src2 <= rd_d; //From register file
        I_IMM_SRC: alu_src2 <= 32'(signed'(decode_bus.i_imm)); //I IMM extended
    endcase
end

alu alu_0
(
    .ra_d(rs1_d),
    .rb_d(alu_src2),
    .rd_d(rd_alu),
    .func3(decode_bus.funct3),
    .func7(decode_bus.funct7)
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

//Jump signal is true if branch or JAL is true
assign jump = branch | uncoditional_jump;

//Calculate the target address when taking jump or branch
//This is just a multiplexer
always_comb
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
    .funct3(decode_bus.funct3),

    //Data
    .store_data(rs2_d),
    .address(address_ld),
    .load_data(load_data),

    //Wishbone interface
    .data_bus(data_bus)
);

endmodule 