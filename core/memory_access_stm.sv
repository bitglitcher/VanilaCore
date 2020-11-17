
module memory_access_stm
(

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

assign ra_d = rs1_d; //Always from register


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




endmodule