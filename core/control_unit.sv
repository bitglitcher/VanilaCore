
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
    output logic imm_t
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
parameter ECALL = 12'b000000000000;
parameter EBREAK = 12'b000000000001;

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
                    sr2_src = I_IMM_SRC;
                    regfile_src = ALU_INPUT;
                    regfile_wr = 1'b1;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b1;
                    //$display("OPIMM dest %x, rs1 %x, rs2 %x, imm %x", rd, rs1, rs2, i_imm);
                end
                OP:
                begin
                    sr2_src = REG_SRC;
                    regfile_src = ALU_INPUT;
                    regfile_wr = 1'b1;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b0;
                end
                LUI:
                begin
                    //$display("LUI dest %b, imm %b", rd, U_IMM_SRC);
                    sr2_src = I_IMM_SRC;
                    regfile_src = U_IMM_SRC;
                    regfile_wr = 1'b1;
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    busy = 1'b0;
                    memory_operation = MEM_NONE;
                    imm_t = 1'b0;
                end
                AUIPC:
                begin
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
                end

                //Unconditional JUMPS
                JAL:
                begin
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
                end
                JARL:
                begin
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
                end
                //Conditional jumps
                BRANCH:
                begin
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
                end
                //Memory Access
                STORE:
                begin
                    regfile_wr = 1'b0;
                    sr2_src = I_IMM_SRC;
                    regfile_src = ALU_INPUT;
                    memory_operation = STORE_DATA;
                    //$display("STORE base: r%d, src: r%d, offset: %d", rs1, rs2, 32'(signed'(s_imm)));
                    jmp_target_src = J_IMM;
                    enable_branch = 1'b0;
                    jump = 1'b0;
                    imm_t = 1'b0;
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
                    sr2_src = I_IMM_SRC;
                    regfile_src = LOAD_SRC;
                    jump = 1'b0;
                    imm_t = 1'b0;
                    //$display("LOAD base: r%d, dest: r%d, offset: %d", rs1, rd, 32'(signed'(i_imm)));
                    jmp_target_src = J_IMM;
                    memory_operation = LOAD_DATA;
                    enable_branch = 1'b0;
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
                            unique case(decode_bus.i_imm)
                                ECALL:
                                begin
                                    //Do nothing for now
                                end
                                EBREAK:
                                begin
                                    //Stop simulation
                                    $stop;
                                end
                            endcase
                        end
                        //CSR Instructions
                        CSRRW:
                        begin
                            
                        end
                        CSRRS:
                        begin
                            
                        end
                        CSRRC:
                        begin
                            
                        end
                        CSRRWI:
                        begin
                            
                        end
                        CSRRSI:
                        begin
                            
                        end
                        CSRRCI:
                        begin
                            
                        end
                    endcase
                end
                default:
                begin
                //$display("Illegal Instruction");
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