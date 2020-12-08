// Quartus Prime Verilog Template
// Single port RAM with single read/write address 

module ram 
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=20)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH+1):0] addr,
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
			ram[addr [(ADDR_WIDTH+1):2]] <= data;

		addr_reg <= addr [(ADDR_WIDTH+1):2];
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];

	initial begin
		$display("Init memory");
		for (int i = 0;i < 2**ADDR_WIDTH-1; i++ ) begin
			ram[i] = 32'h0;
		end
		$readmemh("C:/Users/camin/Documents/VanilaCore/core/c_code/ROM.hex", ram);
		//$readmemh("ROM.hex", ram); 
	end
endmodule
