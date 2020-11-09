



module load_window();

logic clk;

//54bit access window
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



initial begin
    data_1 = 32'h12345678;
    data_2 = 32'habcdefee;
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