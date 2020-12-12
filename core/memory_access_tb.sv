
import global_pkg::*

module memory_access_tb();


//Only two entries to check for unaligned access
reg [31:0] memory [1:0];

typedef enum int { BYTE, HALF_WORD, WORD } write_size_t;
typedef enum int { SBYTE, UBYTE, SHALF_WORD, UHALF_WORD, RWORD } read_size_t;

task automatic write(write_size_t size, unsigned int data, unsigned int address);
    
endtask //automatic

task automatic read(read_size_t size, unsigned int address, unsigned int expected);
    
endtask //automatic

logic clk;
logic rst;

WB4 wb(clk, rst);

memory_access memory_access_0
(
    //Syscon
    .clk(clk),
    .rst(rst),

    //Control signals
    .memory_operation(memory_operation),
    .cyc(cyc),
    .ack(ack),
    .data_valid(data_valid), //This is needed for the load instruction
    .funct3(funct3),

    //Data
    .store_data(),
    .address(),
    .load_data(),

    //Wishbone interface
    .data_bus()
);

initial begin
    clk = 0;
    rst = 0;

end

//Fake wishbone memory





//Clock generation
always #10 clk = ~clk;



endmodule