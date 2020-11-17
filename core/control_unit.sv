
import global_pkg::*;

module control_unit
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

parameter OP_IMM =  7'b0010011;
parameter LUI =     7'b0110111;
parameter AUIPC =   7'b0010111;
parameter LOAD =    7'b0000011;
parameter JAL =     7'b1101111;
parameter STORE =   7'b0100011;
parameter JARL =    7'b1100111;
parameter BRANCH =  7'b1100011;
parameter OP =      7'b0110011;

always_comb
begin
    if(execute)
    begin        
        case(decode_bus.opcode)
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
            OP:
            begin
                sr2_src <= REG_SRC;
                regfile_src <= ALU_INPUT;
                regfile_wr <= 1'b1;
                load_data <= 1'b0;
                store_data <= 1'b0;
                jmp_target_src <= J_IMM;
                jump <= 1'b0;
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
                //$display("LOAD base: r%d, dest: r%d, offset: %d", rs1, rd, 32'(signed'(i_imm)));
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
                regfile_wr <= 1'b1;
                sr2_src <= I_IMM_SRC;
                regfile_src <= PC_SRC;
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
                //$display("STORE base: r%d, src: r%d, offset: %d", rs1, rs2, 32'(signed'(s_imm)));
                jmp_target_src <= J_IMM;
                jump <= 1'b0;
            end
            JARL:
            begin
                regfile_wr <= 1'b1;
                sr2_src <= I_IMM_SRC;
                regfile_src <= PC_SRC;
                load_data <= 1'b0;
                store_data <= 1'b0;
                //$display("JARL dest %b, rs1 %b, imm %d", rd, rs1, 32'(signed'(i_imm)));
                jmp_target_src <= I_IMM;
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




endmodule