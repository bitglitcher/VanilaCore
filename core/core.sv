
module core
(
    WB4.master inst_bus,
    WB4.master data_bus
);



logic [31:0] next_pc;
logic [31:0] next_ir;
reg [31:0] PC; //Program Counter
reg [31:0] IR; //Instruction register
logic execute; //Wire to signal the execute cycle
parameter PC_RESET_VECTOR = 32'h00000000;

logic jump;
logic [31:0] jump_target;

//Wishbone memory read state machine 
typedef enum  logic [3:0] { READ, INC, EXEC, EXEC_2 } INS_BUS_STATE;

INS_BUS_STATE state, next_state;
logic stop_cycle;
logic exit_ignore;
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
        if(stop_cycle)
        begin
            state = state;
            PC = PC;
            IR = IR;            
        end
        else
        begin
            state = next_state;
            PC = next_pc;
            IR = next_ir;
        end
    end
end

always_comb
begin
    unique case(state)
        EXEC:
        begin
            if(jump)
            begin
                next_pc <= jump_target;
                next_state <= READ;
            end
            else
            begin
                next_pc <= PC;
                next_state <= INC;
            end
            //next_pc <= PC + 4;
            exit_ignore <= 0;
            inst_bus.CYC <= 1'b0; //Begin transaction
            inst_bus.STB <= 1'b0;
            inst_bus.WE <= 1'b0; //Read
            inst_bus.ADR <= PC [31:0];
            execute <= 1'b1;
            inst_bus.DAT_O <= 32'b0; //Always 0 because we don't write to this memory
            next_ir <= IR;
        end    
        INC:
        begin
            next_pc <= PC + 4;
            exit_ignore <= 0;
            inst_bus.CYC <= 1'b0; //Begin transaction
            inst_bus.STB <= 1'b0;
            inst_bus.WE <= 1'b0; //Read
            inst_bus.ADR <= PC [31:0];
            execute <= 1'b0;
            inst_bus.DAT_O <= 32'b0; //Always 0 because we don't write to this memory
            next_state <= READ;
            next_ir <= IR;
        end
        READ:
        begin
            exit_ignore <= 1;
            execute <= 1'b0;
            if(inst_bus.ACK)
            begin
                next_pc <= PC;
                inst_bus.CYC <= 1'b0; //Begin transaction
                inst_bus.STB <= 1'b0;
                inst_bus.WE <= 1'b0; //Read
                inst_bus.ADR <= PC [31:0];
                inst_bus.DAT_O <= 32'b0; //Always 0 because we don't write to this memory
                next_ir = inst_bus.DAT_I;
                //$display("data read -> A: %x, D: %x", PC, inst_bus.DAT_I);
                next_state <= EXEC;
            end
            else
            begin
                next_pc <= PC;
                inst_bus.CYC <= 1'b1; //Begin transaction
                inst_bus.STB <= 1'b1;
                inst_bus.WE <= 1'b0; //Read
                inst_bus.ADR <= PC [31:0];
                inst_bus.DAT_O <= 32'b0; //Always 0 because we don't write to this memory
                next_state <= READ;
                next_ir <= IR;
            end
        end
    endcase
end

//These are not sign extended
////Here we decode each instruction
wire [6:0] opcode = IR [6:0];
wire [4:0] rd = IR [11:7];
wire [2:0] funct3 = IR [14:12];
wire [4:0] rs1 = IR [19:15];
wire [4:0] rs2 = IR [24:20];
wire [6:0] funct7 = IR [31:25];
wire [11:0] i_imm = IR [31:20];
wire [11:0] s_imm = {IR [31:25], IR[11:7]};
wire [12:0] b_imm;
assign b_imm [0:0] = 1'b0;
assign b_imm [11:11] = IR [7:7];
assign b_imm [4:1] = IR [11:8];
assign b_imm [10:5] = IR [30:25];
assign b_imm [12:12] = IR [31:31];
wire [31:0] u_imm = {IR [31:12], 12'b000000000000};
wire [20:0] j_imm;
assign j_imm [0:0] = 1'b0;
assign j_imm [19:12] = IR [19:12];
assign j_imm [11:11] = IR [20:20];
assign j_imm [10:1] = IR [31:21];
assign j_imm [20:20] = IR [31:31];

parameter OP_IMM =  7'b0010011;
parameter LUI =     7'b0110111;
parameter AUIPC =   7'b0010111;
parameter LOAD =    7'b0000011;
parameter JAL =     7'b1101111;
parameter STORE =   7'b0100011;
parameter JARL =    7'b1100111;
parameter BRANCH =  7'b1100011;


typedef enum logic[3:0] { REG_SRC, I_IMM_SRC } sr2_src_t;
typedef enum logic[3:0] { ALU_INPUT, U_IMM_SRC, AUIPC_SRC, LOAD_SRC, PC_SRC } regfile_src_t;

sr2_src_t sr2_src;
regfile_src_t regfile_src;

logic regfile_wr;

//typedef enum  logic [3:0] { NO_CMD, LOAD_B, LOAD_H, LOAD_W, STORE_B, STORE_H, STORE_W } access_cmd_t;
//Memory access 
parameter LB = 3'b000;
parameter LH = 3'b001;
parameter LW = 3'b010;
parameter LBU = 3'b100;
parameter LHU = 3'b101;

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;


logic load_data;
logic store_data;

typedef enum logic[3:0] { J_IMM, B_IMM } jmp_target_src_t;
jmp_target_src_t jmp_target_src;

logic BRANCH_S;



always_comb
begin
    if(execute)
    begin        
        case(opcode)
            OP_IMM:
            begin
                sr2_src <= I_IMM_SRC;
                regfile_src <= ALU_INPUT;
                regfile_wr <= 1'b1;
                load_data <= 1'b0;
                store_data <= 1'b0;
                jmp_target_src <= J_IMM;
                jump <= 1'b0;
                //$display("OPIMM dest %x, rs1 %x, rs2 %x, imm %x", rd, rs1, rs2, i_imm);
            end
            LUI:
            begin
                //$display("LUI dest %b, imm %b", rd, U_IMM_SRC);
                sr2_src <= I_IMM_SRC;
                regfile_src <= U_IMM_SRC;
                regfile_wr <= 1'b1;
                load_data <= 1'b0;
                store_data <= 1'b0;
                jmp_target_src <= J_IMM;
                jump <= 1'b0;
            end
            AUIPC:
            begin
                //$display("AUIPC dest %b, imm %b", rd, U_IMM_SRC + PC);
                sr2_src <= I_IMM_SRC;
                regfile_src <= AUIPC_SRC;
                regfile_wr <= 1'b1;
                load_data <= 1'b0;
                store_data <= 1'b0;
                jmp_target_src <= J_IMM;
                jump <= 1'b0;
            end
            LOAD:
            begin
                sr2_src <= I_IMM_SRC;
                load_data = 1'b1;
                regfile_src <= LOAD_SRC;
                store_data = 1'b0;
                //$display("STORE dest %b, rs1 %b, imm %d", rd, rs1, 32'(signed'(i_imm)));
                jmp_target_src = J_IMM;
                jump = 1'b0;
                if(!stop_cycle)
                begin
                    regfile_wr = 1'b1;
                end
                else
                begin
                    regfile_wr = 1'b0;
                end
            end
            JAL:
            begin
                //$display("JAL address %h", jump_target);
                regfile_wr <= 1'b0;
                sr2_src <= I_IMM_SRC;
                regfile_src <= U_IMM_SRC;
                load_data <= 1'b0;
                store_data <= 1'b0;
                jump <= 1'b1;
                jmp_target_src <= J_IMM;
            end
            STORE:
            begin
                regfile_wr <= 1'b0;
                sr2_src <= I_IMM_SRC;
                regfile_src <= ALU_INPUT;
                load_data <= 1'b0;
                store_data <= 1'b1;
                //$display("STORE base: %x, src: %x, offset: %x", rs1, rs2, s_imm);
                jmp_target_src <= J_IMM;
                jump <= 1'b0;
            end
            JARL:
            begin
                regfile_wr <= 1'b0;
                sr2_src <= I_IMM_SRC;
                regfile_src <= PC_SRC;
                load_data <= 1'b0;
                store_data <= 1'b0;
                //$display("JARL dest %b, rs1 %b, imm %d", rd, rs1, 32'(signed'(i_imm)));
                jmp_target_src <= J_IMM;
                jump <= 1'b1;
            end
            BRANCH:
            begin
                //$display("BRANCH Instruction");
                regfile_wr <= 1'b0;
                sr2_src <= I_IMM_SRC;
                regfile_src <= PC_SRC;
                load_data <= 1'b0;
                store_data <= 1'b0;
                jmp_target_src <= B_IMM; //
                if(BRANCH_S)
                begin
                    jump <= 1'b1;
                end
                else
                begin
                    jump <= 1'b0;
                end
            end
            default:
            begin
            //$display("Illegal Instruction");
                regfile_wr <= 1'b0;
                regfile_src <= ALU_INPUT;
                sr2_src <= I_IMM_SRC;
                load_data <= 1'b0;
                store_data <= 1'b0;
                jmp_target_src <= J_IMM;
                jump <= 1'b0;
            end
        endcase
    end
    else
    begin
        regfile_wr <= 1'b0;
        regfile_src <= ALU_INPUT;
        sr2_src <= I_IMM_SRC;
        load_data <= 1'b0;
        store_data <= 1'b0;
        jmp_target_src <= J_IMM;
        jump <= 1'b0;
    end
end

always_comb
begin
    unique case(jmp_target_src)
        J_IMM: jump_target <= 32'(signed'(j_imm)) + PC;
        B_IMM: jump_target <= 32'(signed'(b_imm)) + PC;
    endcase
end

logic [31:0] rs1_d; //This comes from the register file
logic [31:0] rs2_d; //This comes from the register file
logic [31:0] rd_d; //Directly to the register file
logic [31:0] alu_z; //ALU output
logic [31:0] ra_d; //This bus goes to the ALU
logic [31:0] rb_d; //This bus goes to the ALU
logic [31:0] load_data_src;

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
        PC_SRC: rd_d <= PC;
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
        LH: load_data_src = ALIGNED_U_BYTE;
        LW: load_data_src = ALIGNED_HALF_WORD;
        LBU: load_data_src = ALIGNED_U_HALF_WORD;
        LHU: load_data_src = ALIGNED_WORD_BUS;
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

alu ALU_0
(
    .ra_d(ra_d),
    .rb_d(rb_d),
    .rd_d(alu_z),
    .func3(funct3),
    .func7(funct7)
);

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
            if(load_data)
            begin
                stop_cycle <= 1'b1;
                data_bus_next_state <= READ1;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
            end
            else if(store_data)
            begin
                stop_cycle <= 1'b1;
                if(unaligned)
                begin
                    data_bus_next_state <= READ_W1; //Read to update bytes                
                end
                else
                begin
                    data_bus_next_state <= UWRITE1; //Read to update bytes                
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

endmodule 