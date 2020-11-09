//Author: Benjamin Herrera Navarro
//6:49
//11/5/2020

module store_window
(
    input [31:0] wr_addr_bus,
    input [31:0] rs2_d, //Data that we want to store
    input [2:0] funct3,
    output [31:0] new_data_1, //How we want to align it
    output [31:0] new_data_2 //How we want to align it
);

parameter SB = 3'b000;
parameter SH = 3'b001;
parameter SW = 3'b010;


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
assign modified_window [0] = ((~(masked_window [7:0]) & access_window [0]) | new_data_window);
assign modified_window [1] = ((~(masked_window [15:8]) & access_window [1]) | new_data_window);
assign modified_window [2] = ((~(masked_window [23:16]) & access_window [2]) | new_data_window);
assign modified_window [3] = ((~(masked_window [31:24]) & access_window [3]) | new_data_window);
assign modified_window [4] = ((~(masked_window [39:32]) & access_window [4]) | new_data_window);
assign modified_window [5] = ((~(masked_window [47:40]) & access_window [5]) | new_data_window);
assign modified_window [6] = ((~(masked_window [55:48]) & access_window [6]) | new_data_window);
assign modified_window [7] = ((~(masked_window [63:56]) & access_window [7]) | new_data_window);

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



endmodule