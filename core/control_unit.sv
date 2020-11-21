
import global_pkg::*;

module control_unit
(
    input clk,

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
    input   logic ack
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

//All instruction are decoded in a rising neg clk
always@(negedge clk)
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
                //$display("LOAD base: r%d, dest: r%d, offset: %d", rs1, rd, 32'(signed'(i_imm)));
                jmp_target_src = J_IMM;
                memory_operation = LOAD_DATA;
                //Communication protocol between the decode logic and the store/load logic
                if(ack)
                begin
                    regfile_wr = 1'b1;
                    cyc = 1'b0;
                    busy = 1'b0;
                end
                else
                begin
                    busy = 1'b1;
                    cyc = 1'b1;
                    regfile_wr = 1'b0;
                end
                enable_branch = 1'b0;
            end
            default:
            begin
            //$display("Illegal Instruction");
                regfile_wr = 1'b0;
                regfile_src = ALU_INPUT;
                sr2_src = I_IMM_SRC;
                jmp_target_src = J_IMM;
                enable_branch = 1'b0;
                jump = 1'b0;
                busy = 1'b0;
                memory_operation = MEM_NONE;
            end
        endcase
    end
    else
    begin
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

endmodule