



module store_window_tb();

logic clk;

//56bit access window
reg [31:0] data_1;
reg [31:0] data_2; //Only used on unaligned access

reg [1:0] wr_addr_bus;

wire [7:0] access_window [7:0];
assign access_window [0] = data_1 [7:0];
assign access_window [1] = data_1 [15:8];
assign access_window [2] = data_1 [23:16];
assign access_window [3] = data_1 [31:24];
assign access_window [4] = data_2 [7:0];
assign access_window [5] = data_2 [15:8];
assign access_window [6] = data_2 [23:16];
assign access_window [7] = data_1 [31:24];

wire [31:0] aligned_data;
assign aligned_data [7:0] = access_window [wr_addr_bus [1:0] + 0];
assign aligned_data [15:8] = access_window [wr_addr_bus [1:0] + 1];
assign aligned_data [23:16] = access_window [wr_addr_bus [1:0] + 2];
assign aligned_data [31:24] = access_window [wr_addr_bus [1:0] + 3];


wire [31:0] mask_size_1 = 32'h000000ff;
wire [31:0] mask_size_2 = 32'h0000ffff;
wire [31:0] mask_size_4 = 32'hffffffff;

wire [4:0] shift_amount = {wr_addr_bus [1:0], 3'b000};

wire [63:0] masked_window_1 = mask_size_1 << shift_amount;
wire [63:0] masked_window_2 = mask_size_2 << shift_amount;
wire [63:0] masked_window_4 = mask_size_4 << shift_amount;

reg [31:0] new_data;
wire [63:0] new_data_window = new_data << shift_amount;



wire [7:0] modified_window_1 [7:0];
assign modified_window_1 [0] = ((~(masked_window_1 [7:0]) & access_window [0]) | new_data_window [7:0]);
assign modified_window_1 [1] = ((~(masked_window_1 [15:8]) & access_window [1]) | new_data_window [15:8]);
assign modified_window_1 [2] = ((~(masked_window_1 [23:16]) & access_window [2]) | new_data_window [23:16]);
assign modified_window_1 [3] = ((~(masked_window_1 [31:24]) & access_window [3]) | new_data_window [31:24]);
assign modified_window_1 [4] = ((~(masked_window_1 [39:32]) & access_window [4]) | new_data_window [39:32]);
assign modified_window_1 [5] = ((~(masked_window_1 [47:40]) & access_window [5]) | new_data_window [47:40]);
assign modified_window_1 [6] = ((~(masked_window_1 [55:48]) & access_window [6]) | new_data_window [55:48]);
assign modified_window_1 [7] = ((~(masked_window_1 [63:56]) & access_window [7]) | new_data_window [63:56]);
wire [7:0] modified_window_2 [7:0];
assign modified_window_2 [0] = ((~(masked_window_2 [7:0]) & access_window [0]) | new_data_window [7:0]);
assign modified_window_2 [1] = ((~(masked_window_2 [15:8]) & access_window [1]) | new_data_window [15:8]);
assign modified_window_2 [2] = ((~(masked_window_2 [23:16]) & access_window [2]) | new_data_window [23:16]);
assign modified_window_2 [3] = ((~(masked_window_2 [31:24]) & access_window [3]) | new_data_window [31:24]);
assign modified_window_2 [4] = ((~(masked_window_2 [39:32]) & access_window [4]) | new_data_window [39:32]);
assign modified_window_2 [5] = ((~(masked_window_2 [47:40]) & access_window [5]) | new_data_window [47:40]);
assign modified_window_2 [6] = ((~(masked_window_2 [55:48]) & access_window [6]) | new_data_window [55:48]);
assign modified_window_2 [7] = ((~(masked_window_2 [63:56]) & access_window [7]) | new_data_window [63:56]);
wire [7:0] modified_window_4 [7:0];
assign modified_window_4 [0] = ((~(masked_window_4 [7:0]) & access_window [0]) | new_data_window [7:0]);
assign modified_window_4 [1] = ((~(masked_window_4 [15:8]) & access_window [1]) | new_data_window [15:8]);
assign modified_window_4 [2] = ((~(masked_window_4 [23:16]) & access_window [2]) | new_data_window [23:16]);
assign modified_window_4 [3] = ((~(masked_window_4 [31:24]) & access_window [3]) | new_data_window [31:24]);
assign modified_window_4 [4] = ((~(masked_window_4 [39:32]) & access_window [4]) | new_data_window [39:32]);
assign modified_window_4 [5] = ((~(masked_window_4 [47:40]) & access_window [5]) | new_data_window [47:40]);
assign modified_window_4 [6] = ((~(masked_window_4 [55:48]) & access_window [6]) | new_data_window [55:48]);
assign modified_window_4 [7] = ((~(masked_window_4 [63:56]) & access_window [7]) | new_data_window [63:56]);


initial begin
    data_1 = 32'hffffffff;
    data_2 = 32'hffffffff;
    new_data = 32'hbeef;
    wr_addr_bus = 0;
    clk = 0;
    //
    repeat(200) #10 clk = ~clk;
end

always@(posedge clk)
begin
    wr_addr_bus = wr_addr_bus + 1;
end
endmodule