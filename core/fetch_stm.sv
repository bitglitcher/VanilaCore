

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

logic [31:0] next_pc;
logic [31:0] next_ir;
reg [31:0] PC; //Program Counter
reg [31:0] IR; //Instruction register
assign PC_O = PC;
assign IR_O = IR;
parameter PC_RESET_VECTOR = 32'h00000000;

//Wishbone memory read state machine 
typedef enum  logic [3:0] { READ, INC, EXEC, EXEC_2 } INS_BUS_STATE;

INS_BUS_STATE state, next_state;

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


endmodule 