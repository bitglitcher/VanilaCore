
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

    //Control Unit interface
    TRAP_INT.cu trap_int,

    //ALU immediate instruction signal
    output logic imm_t,

    //To choose which will be the input to mtval
    output val_src_t val_src, 

    //CSR Unit control signals
    output logic csr_unit_wr_enable,
    output write_mode_t write_mode,

    //Multiplexer sel line for the CSR unit data input
    output logic sel_rs1_d_rs1,

    //Events from instructions
    EVENT_INT.out event_bus
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

parameter PRIV = 3'b000;

parameter ECALL = 12'b000000000000;
parameter EBREAK = 12'b000000000001;

parameter URET = 7'b0000000;
parameter SRET = 7'b0001000;
parameter MRET = 7'b0011000;


parameter CSRRW = 3'b001;
parameter CSRRS = 3'b010;
parameter CSRRC = 3'b011;
parameter CSRRWI = 3'b101;
parameter CSRRSI = 3'b110;
parameter CSRRCI = 3'b111;

//MCUASE
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

parameter CAUSE_U_MODE_SOFT_INT = 0;
parameter CAUSE_S_MODE_SOFT_INT = 1;
parameter CAUSE_M_MODE_SOFT_INT = 3;
parameter CAUSE_U_MODE_TIMER_INT = 4;
parameter CAUSE_S_MODE_TIMER_INT = 5;
parameter CAUSE_M_MODE_TIMER_INT = 7;
parameter CAUSE_U_MODE_EXTERNAL_INT = 8;
parameter CAUSE_S_MODE_EXTERNAL_INT = 9;
parameter CAUSE_M_MODE_EXTERNAL_INT = 11;

///////////////////////////////////////////
//           Access Decoder              //
///////////////////////////////////////////
//These are only from the immediate side
wire [1:0] rw_access = decode_bus.i_imm [11:10];
wire csr_read  = (((rw_access == 2'b00) | (rw_access == 2'b01) | (rw_access == 2'b10) | (rw_access == 2'b11)) & (decode_bus.rd != 0)) ? 1 : 0;
wire csr_read_only = ((rw_access == 2'b11)) ? 1 : 0;
wire csr_write = (((rw_access == 2'b00) | (rw_access == 2'b01) | (rw_access == 2'b10)) & (decode_bus.rs1 != 0)) ? 1 : 0;

//Load instruction states
typedef enum logic [3:0] { SEND_CMD, RECIEVE_DATA } LOAD_STATES;
LOAD_STATES load_state;

/*
The scheme in which the interrupts and exeptions work, is that illegal csr access instructions
will be checked on the control unit. Interrupts will be sent to the control unit, and it will decide
what to do next. Instruction state save will  be saved by the CSR unit, and instruction restore logic
will be done in the CSR unit.
*/

//All instruction are decoded in a negedge clk
always@(negedge clk)
begin
    if(rst)
    begin
        write_mode = CSR_WRITE;
        val_src = VAL_IR;
        sel_rs1_d_rs1 = 1'b0;
        trap_int.cause = 32'b0;
        load_state = SEND_CMD;
        trap_int.exeption = 1'b0;
        trap_int.interrupt = 1'b0;
        event_bus.unconditional_branch = 1'b0;
        event_bus.conditional_branch = 1'b0;
        event_bus.arithmetic = 1'b0;
        trap_int.trap_return = 1'b0;
        csr_unit_wr_enable = 1'b0;
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
    else
    begin
        if(execute)
        begin       
            if(| trap_int.ip [31:0]) //This section will be incharge of taking all interrupts
            begin
                $display("-------------------------Executing Exeption-------------------------");
                val_src = VAL_IR;
                write_mode = CSR_WRITE;
                sel_rs1_d_rs1 = 1'b0;
                trap_int.cause = 32'b0;
                event_bus.unconditional_branch = 1'b0;
                event_bus.conditional_branch = 1'b0;
                event_bus.arithmetic = 1'b0;
                trap_int.trap_return = 1'b0;
                csr_unit_wr_enable = 1'b0;
                imm_t = 1'b0;
                regfile_wr = 1'b0;
                regfile_src = ALU_INPUT;
                sr2_src = I_IMM_SRC;
                jmp_target_src = J_IMM;
                enable_branch = 1'b0;
                cyc = 1'b0;
                memory_operation = MEM_NONE;
                busy = 1'b0;
                //Jump to trap handler, mcause will be set automatically by the CSR_UNIT
                //Interrupt order higher -> lower
                //MEI, MSI, MTI
                if(trap_int.ip [11:11])
                begin
                    trap_int.cause = CAUSE_M_MODE_EXTERNAL_INT;
                    trap_int.exeption = 1'b1;
                    trap_int.interrupt = 1'b1;
                    val_src = VAL_IR;
                end
                else if(trap_int.ip [3:3])
                begin
                    trap_int.cause = CAUSE_M_MODE_SOFT_INT;
                    trap_int.exeption = 1'b1;
                    trap_int.interrupt = 1'b1;
                    val_src = VAL_IR;
                end
                else if(trap_int.ip[7:7])
                begin
                    trap_int.cause = CAUSE_M_MODE_TIMER_INT;
                    trap_int.exeption = 1'b1;
                    trap_int.interrupt = 1'b1;
                    val_src = VAL_IR;
                end
            end
            else
            begin                
                case(decode_bus.opcode)
                    OP_IMM:
                    begin
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;    
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        event_bus.unconditional_branch = 1'b0;
                        event_bus.arithmetic = 1'b1;
                        sr2_src = I_IMM_SRC;
                        regfile_src = ALU_INPUT;
                        regfile_wr = 1'b1;
                        jmp_target_src = J_IMM;
                        enable_branch = 1'b0;
                        jump = 1'b0;
                        busy = 1'b0;
                        memory_operation = MEM_NONE;
                        imm_t = 1'b1;
                        csr_unit_wr_enable = 1'b0;
                        //$display("OPIMM dest %x, rs1 %x, rs2 %x, imm %x", rd, rs1, rs2, i_imm);
                    end
                    OP:
                    begin
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;    
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        event_bus.unconditional_branch = 1'b0;
                        event_bus.arithmetic = 1'b1;
                        sr2_src = REG_SRC;
                        regfile_src = ALU_INPUT;
                        regfile_wr = 1'b1;
                        jmp_target_src = J_IMM;
                        enable_branch = 1'b0;
                        jump = 1'b0;
                        busy = 1'b0;
                        memory_operation = MEM_NONE;
                        imm_t = 1'b0;
                        csr_unit_wr_enable = 1'b0;
                    end
                    LUI:
                    begin
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        //$display("LUI dest %b, imm %b", rd, U_IMM_SRC);
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;    
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        event_bus.unconditional_branch = 1'b0;
                        event_bus.arithmetic = 1'b0;
                        sr2_src = I_IMM_SRC;
                        regfile_src = U_IMM_SRC;
                        regfile_wr = 1'b1;
                        jmp_target_src = J_IMM;
                        enable_branch = 1'b0;
                        jump = 1'b0;
                        busy = 1'b0;
                        memory_operation = MEM_NONE;
                        imm_t = 1'b0;
                        csr_unit_wr_enable = 1'b0;
                    end
                    AUIPC:
                    begin
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;    
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        event_bus.unconditional_branch = 1'b0;
                        event_bus.arithmetic = 1'b0;
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
                        csr_unit_wr_enable = 1'b0;
                    end
                    //Unconditional JUMPS
                    JAL:
                    begin
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;    
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        event_bus.unconditional_branch = 1'b1;
                        event_bus.arithmetic = 1'b0;
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
                        csr_unit_wr_enable = 1'b0;
                    end
                    JARL:
                    begin
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;    
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        event_bus.unconditional_branch = 1'b1;
                        event_bus.arithmetic = 1'b0;
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
                        csr_unit_wr_enable = 1'b0;
                    end
                    //Conditional jumps
                    BRANCH:
                    begin
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;    
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b1;
                        event_bus.unconditional_branch = 1'b0;
                        event_bus.arithmetic = 1'b0;
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
                        csr_unit_wr_enable = 1'b0;
                    end
                    //Memory Access
                    STORE:
                    begin
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;    
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        event_bus.unconditional_branch = 1'b0;
                        event_bus.arithmetic = 1'b0;
                        regfile_wr = 1'b0;
                        sr2_src = I_IMM_SRC;
                        regfile_src = ALU_INPUT;
                        memory_operation = STORE_DATA;
                        //$display("STORE base: r%d, src: r%d, offset: %d", rs1, rs2, 32'(signed'(s_imm)));
                        jmp_target_src = J_IMM;
                        enable_branch = 1'b0;
                        jump = 1'b0;
                        imm_t = 1'b0;
                        csr_unit_wr_enable = 1'b0;
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
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;
                        trap_int.trap_return = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        event_bus.unconditional_branch = 1'b0;
                        event_bus.arithmetic = 1'b0;
                        sr2_src = I_IMM_SRC;
                        regfile_src = LOAD_SRC;
                        jump = 1'b0;
                        imm_t = 1'b0;
                        //$display("LOAD base: r%d, dest: r%d, offset: %d", rs1, rd, 32'(signed'(i_imm)));
                        jmp_target_src = J_IMM;
                        memory_operation = LOAD_DATA;
                        enable_branch = 1'b0;
                        csr_unit_wr_enable = 1'b0;
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
                            PRIV:
                            begin
                                unique case(decode_bus.funct7)
                                    URET:
                                    begin
                                        trap_int.trap_return = 1'b0;
                                        $display("Privilege Mode Not Supported"); 
                                        jump = 1'b0;
                                        jmp_target_src = EPC;
                                        //Generate Illegal Instruction
                                        trap_int.cause = ILLEGAL_INS;
                                        trap_int.exeption = 1'b1;
                                        trap_int.interrupt = 1'b0;
                                    end
                                    SRET:
                                    begin
                                        trap_int.trap_return = 1'b0;
                                        $display("Privilege Mode Not Supported"); 
                                        jump = 1'b0;
                                        jmp_target_src = EPC;
                                        //Generate Illegal Instruction
                                        trap_int.cause = ILLEGAL_INS;
                                        trap_int.exeption = 1'b1;
                                        trap_int.interrupt = 1'b0;
                                    end 
                                    MRET:
                                    begin
                                        trap_int.trap_return = 1'b1;
                                        jump = 1'b1;
                                        jmp_target_src = EPC;
                                    end
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
                                    default:
                                    begin
                                        sel_rs1_d_rs1 = 1'b0;
                                        write_mode = CSR_WRITE;
                                        csr_unit_wr_enable = 1'b0;
                                        regfile_src = CSR_SRC;
                                        //Generate Illegal Instruction
                                        trap_int.cause = ILLEGAL_INS;
                                        trap_int.exeption = 1'b1;
                                        trap_int.interrupt = 1'b0;
                                    end
                                endcase
                                sel_rs1_d_rs1 = 1'b0;
                                write_mode = CSR_WRITE;
                                csr_unit_wr_enable = 1'b0;
                                regfile_src = CSR_SRC;
                            end
                            //CSR Instructions
                            CSRRW: //Read and write
                            begin
                                //Check for unprileged access or illegal write
                                if((decode_bus.i_imm[9:8] > trap_int.cpm) | csr_read_only)
                                begin
                                    //Generate illegal instruction exeption
                                    trap_int.exeption = 1'b1;
                                    trap_int.cause = ILLEGAL_INS;
                                    val_src = VAL_IR;
                                end
                                else
                                begin
                                        //Execute normaly
                                        if(csr_write)
                                        begin
                                            csr_unit_wr_enable = 1'b1;
                                        end
                                        if(csr_read) regfile_wr = 1'b1;                            
                                        else regfile_wr = 1'b1;   
                                end
                                sel_rs1_d_rs1 = 1'b0;
                                write_mode = CSR_WRITE;
                                regfile_src = CSR_SRC;
                                trap_int.trap_return = 1'b0;
                            end
                            CSRRS:
                            begin
                                //Check for unprileged access or illegal write
                                if((decode_bus.i_imm[9:8] > trap_int.cpm) | (csr_read_only & csr_write))
                                begin
                                    //Generate illegal instruction exeption
                                    trap_int.exeption = 1'b1;
                                    trap_int.cause = ILLEGAL_INS;
                                    val_src = VAL_IR;
                                end
                                else
                                begin
                                        //Execute normaly
                                        if(csr_write)
                                        begin
                                            csr_unit_wr_enable = 1'b1;
                                        end
                                        if(csr_read) regfile_wr = 1'b1;                            
                                        else regfile_wr = 1'b1;                            
                                end
                                sel_rs1_d_rs1 = 1'b0;
                                write_mode = CSR_SET;
                                regfile_src = CSR_SRC;
                                trap_int.trap_return = 1'b0;
                            end
                            CSRRC:
                            begin
                                //Check for unprileged access or illegal write
                                if((decode_bus.i_imm[9:8] > trap_int.cpm) | (csr_read_only & csr_write))
                                begin
                                    //Generate illegal instruction exeption
                                    trap_int.exeption = 1'b1;
                                    trap_int.cause = ILLEGAL_INS;
                                    val_src = VAL_IR;
                                end
                                else
                                begin
                                        //Execute normaly
                                        if(csr_write)
                                        begin
                                            csr_unit_wr_enable = 1'b1;
                                        end
                                        if(csr_read) regfile_wr = 1'b1;                            
                                        else regfile_wr = 1'b1;                            
                                end
                                sel_rs1_d_rs1 = 1'b0;
                                write_mode = CSR_CLEAR;
                                regfile_src = CSR_SRC;
                                trap_int.trap_return = 1'b0;
                            end
                            CSRRWI:
                            begin
                                //Check for unprileged access or illegal write
                                if((decode_bus.i_imm[9:8] > trap_int.cpm) | csr_read_only)
                                begin
                                    //Generate illegal instruction exeption
                                    trap_int.exeption = 1'b1;
                                    trap_int.cause = ILLEGAL_INS;
                                    val_src = VAL_IR;
                                    trap_int.trap_return = 1'b0;
                                end
                                else
                                begin
                                        //Execute normaly
                                        if(csr_write)
                                        begin
                                            csr_unit_wr_enable = 1'b1;
                                        end
                                        if(csr_read) regfile_wr = 1'b1;                            
                                        else regfile_wr = 1'b1;  
                                end
                                sel_rs1_d_rs1 = 1'b1;
                                write_mode = CSR_WRITE;
                                regfile_src = CSR_SRC;
                                trap_int.trap_return = 1'b0;
                            end
                            CSRRSI:
                            begin
                                //Check for unprileged access or illegal write
                                if((decode_bus.i_imm[9:8] > trap_int.cpm) | (csr_read_only & csr_write))
                                begin
                                    //Generate illegal instruction exeption
                                    trap_int.exeption = 1'b1;
                                    trap_int.cause = ILLEGAL_INS;
                                    val_src = VAL_IR;
                                    trap_int.trap_return = 1'b0;
                                end
                                else
                                begin
                                        //Execute normaly
                                        if(csr_write)
                                        begin
                                            csr_unit_wr_enable = 1'b1;
                                        end
                                        if(csr_read) regfile_wr = 1'b1;                            
                                        else regfile_wr = 1'b1;  
                                end
                                sel_rs1_d_rs1 = 1'b1;
                                write_mode = CSR_SET;
                                regfile_src = CSR_SRC;
                                trap_int.trap_return = 1'b0;
                            end
                            CSRRCI:
                            begin
                                //Check for unprileged access or illegal write
                                if((decode_bus.i_imm[9:8] > trap_int.cpm) | (csr_read_only & csr_write))
                                begin
                                    //Generate illegal instruction exeption
                                    trap_int.exeption = 1'b1;
                                    trap_int.cause = ILLEGAL_INS;
                                    val_src = VAL_IR;
                                end
                                else
                                begin
                                        //Execute normaly
                                        if(csr_write)
                                        begin
                                            csr_unit_wr_enable = 1'b1;
                                        end
                                        if(csr_read) regfile_wr = 1'b1;                            
                                        else regfile_wr = 1'b1;  
                                end
                                sel_rs1_d_rs1 = 1'b1;
                                write_mode = CSR_CLEAR;
                                regfile_src = CSR_SRC;
                                trap_int.trap_return = 1'b0;
                            end
                        endcase
                        write_mode = CSR_WRITE;
                        val_src = VAL_IR;
                        sel_rs1_d_rs1 = 1'b0;
                        trap_int.cause = 32'b0;
                        trap_int.exeption = 1'b0;
                        trap_int.interrupt = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        imm_t = 1'b0;
                        sr2_src = I_IMM_SRC;
                        enable_branch = 1'b0;
                        cyc = 1'b0;
                        memory_operation = MEM_NONE;
                        busy = 1'b0;
                        event_bus.arithmetic = 1'b0;
                        event_bus.unconditional_branch = 1'b0;
                    end
                    default:
                    begin
                        write_mode = CSR_WRITE;
                        sel_rs1_d_rs1 = 1'b0;
                        event_bus.unconditional_branch = 1'b0;
                        event_bus.conditional_branch = 1'b0;
                        csr_unit_wr_enable = 1'b1;
                        event_bus.arithmetic = 1'b0;
                        trap_int.trap_return = 1'b0;
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
                        $display("Illegal Instruction");
                        //Generate Illegal Instruction
                        trap_int.cause = ILLEGAL_INS;
                        trap_int.exeption = 1'b1;
                        trap_int.interrupt = 1'b0;
                        val_src = VAL_IR;
                    end
                endcase
            end
        end
        else
        begin
            write_mode = CSR_WRITE;
            val_src = VAL_IR;
            sel_rs1_d_rs1 = 1'b0;
            trap_int.cause = 32'b0;
            trap_int.trap_return = 1'b0;
            trap_int.exeption = 1'b0;
            trap_int.interrupt = 1'b0;
            event_bus.unconditional_branch = 1'b0;
            event_bus.conditional_branch = 1'b0;
            event_bus.arithmetic = 1'b0;
            csr_unit_wr_enable = 1'b0;
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