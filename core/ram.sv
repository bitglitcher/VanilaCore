// Quartus Prime Verilog Template
// Single port RAM with single read/write address 

module ram 
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=20)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1):0] q
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	always @ (negedge clk)
	begin
		// Write
		if (we)
			ram[addr [(ADDR_WIDTH-1):2]] <= data;

		addr_reg <= addr [(ADDR_WIDTH-1):2];
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];

	initial begin
		$display("Init memory");
		$readmemh("C:/Users/camin/Documents/VanilaCore/core/c_code/ROM.hex", ram);
		//$readmemh("ROM.hex", ram);
//		ram[0] = 32'h00008093;
//		ram[1] = 32'h00000013;
//		ram[2] = 32'h00008023;
//		ram[3] = 32'h00108093;
//		ram[4] = 32'hff5ff0ef;
//		ram[5] = 32'h00010433;
//		ram[6] = 32'h008000ef;
//		ram[7] = 32'h00100073;
//		ram[8] = 32'hff010113;
//		ram[9] = 32'h00812623;
//		ram[10] = 32'h01010413;
//		ram[11] = 32'h000107b7;
//		ram[12] = 32'hfff78793;
//		ram[13] = 32'h00078513;
//		ram[14] = 32'h00c12403;
//		ram[15] = 32'h01010113;
//		ram[16] = 32'h00008067;
	end
endmodule
