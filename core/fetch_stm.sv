

module fetch_stm
(
    WB4.master inst_bus,
    output logic [31:0] PC_O,
    output logic [31:0] IR_O,
    output logic execute, //Wire to signal the execute cycle
    input logic [31:0] jump_target,
    input logic jump,
    input logic ins_busy //Instructions busy
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

endmodule 