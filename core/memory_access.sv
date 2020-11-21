import global_pkg::*;

module memory_access
(
    //Syscon
    input logic clk,
    input logic rst,

    //Control signals
    input  memory_operation_t memory_operation,
    input  logic cyc,
    output logic ack,
    input  logic [2:0] funct3,

    //Data
    input  logic [31:0] store_data,
    input  logic [31:0] address,
    output logic [31:0] load_data,

    //Wishbone interface
    WB4 data_bus
);

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
    unique case(funct3)
        LB: access_size = BYTE;
        LH: access_size = HALF_WORD;
        LW: access_size = WORD;
        LBU: access_size = BYTE;
        LHU: access_size = HALF_WORD;
    endcase
end

wire unaligned = ((address [1:0] >= 3) & (access_size != BYTE))? 1 : 0;

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
assign aligned_data [7:0] = access_window [address [1:0] + 0];
assign aligned_data [15:8] = access_window [address [1:0] + 1];
assign aligned_data [23:16] = access_window [address [1:0] + 2];
assign aligned_data [31:24] = access_window [address [1:0] + 3];

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
    case(funct3)
        SB: mask = 32'h000000ff;
        SH: mask = 32'h0000ffff;
        SW: mask = 32'hffffffff;
        default: mask = 32'h00000000;
    endcase
end
//Shift amount
wire [4:0] shift_amount = {address [1:0], 3'b000};
wire [63:0] masked_window = mask << shift_amount;

//Create new data, this shifts the data to the desired bytes 
wire [63:0] new_data_window = store_data << shift_amount;

//Modified window contains the new data that will be stored
wire [7:0] modified_window [7:0];
assign modified_window [0] = ((~(masked_window [7:0]) & access_window [0]) | new_data_window [7:0]);
assign modified_window [1] = ((~(masked_window [15:8]) & access_window [1]) | new_data_window [15:8]);
assign modified_window [2] = ((~(masked_window [23:16]) & access_window [2]) | new_data_window [23:16]);
assign modified_window [3] = ((~(masked_window [31:24]) & access_window [3]) | new_data_window [31:24]);
assign modified_window [4] = ((~(masked_window [39:32]) & access_window [4]) | new_data_window [39:32]);
assign modified_window [5] = ((~(masked_window [47:40]) & access_window [5]) | new_data_window [47:40]);
assign modified_window [6] = ((~(masked_window [55:48]) & access_window [6]) | new_data_window [55:48]);
assign modified_window [7] = ((~(masked_window [63:56]) & access_window [7]) | new_data_window [63:56]);

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
    case(funct3)
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
    end
    else
    begin
        case(data_bus_state)
            NO_CMD:
            begin
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address [31:0];
                data_1 <= data_1;
                data_2 <= data_2;
                data_bus.STB <= 1'b0;
                data_bus.CYC <= 1'b0;
                data_bus.WE <= 1'b0;
                if(cyc)
                begin
                    ack = 1'b1; //Acknowledge the request
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
                end

            end
            READ1:
            begin
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address [31:0];
                if(data_bus.ACK)
                begin
                    data_1 <= data_bus.DAT_I;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    if(unaligned)
                    begin
                        data_bus_state <= READ2;
                    end
                    else
                    begin
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
                end
            end
            READ2:
            begin
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address [31:0] + 32'b100;
                if(data_bus.ACK)
                begin
                    data_1 <= data_1;
                    data_2 <= data_bus.DAT_I;
                    data_bus_state <= NO_CMD;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                end
                else
                begin
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
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address [31:0];
                if(data_bus.ACK)
                begin
                    data_1 <= data_bus.DAT_I;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    if(unaligned)
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
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address [31:0] + 32'b100;
                if(data_bus.ACK)
                begin
                    data_1 <= data_bus.DAT_I;
                    data_2 <= data_2;
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
                ack = 1'b0;
                data_bus.ADR <= address [31:0];
                data_bus.DAT_O <= new_data_1;
                if(data_bus.ACK)
                begin
                    data_1 <= data_1;
                    data_2 <= data_2;
                    data_bus.STB <= 1'b0;
                    data_bus.CYC <= 1'b0;
                    data_bus.WE <= 1'b0;
                    if(unaligned)
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
                ack = 1'b0;
                data_bus.ADR <= address [31:0] + 32'b100;
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
                ack = 1'b0;
                data_bus.DAT_O <= 32'h0;
                data_bus.ADR <= address [31:0];
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