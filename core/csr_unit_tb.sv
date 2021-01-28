
import global_pkg::*;  


module csr_unit_tb();

logic clk;
logic rst;
logic [11:0] i_imm;
logic wr;
write_mode_t write_mode;
logic  [31:0] din;
logic [31:0] dout; 
EVENT_INT event_bus();

csr_unit csr_unit_0
(
    //Syscon
    .clk(clk),
    .rst(rst),
    .i_imm(i_imm),
    .wr(wr),
    .write_mode(write_mode),
    .din(din), 
    .dout(dout), 
    .event_bus(event_bus)
);


task automatic Write(int address, int data);
    //Set write signal and mode
    $display("Writting %d, into address %d", data, address);
    din = data;
    @(posedge clk)
    begin
        wr = 1;
        write_mode = CSR_WRITE;
        i_imm = address;
    end
    //Wait clock period
    @(posedge clk)
    begin
        wr = 0;
    end
endtask //automatic

task automatic Read_Test(int address, int data);
    wr = 0;
    i_imm = address;
    //Wait clock period
    @(posedge clk)
    begin
        if(din != data)
        begin
            $display("Data read failed: received 0x%x, expected 0x%x", din, data);
        end
    end
endtask //automatic

initial begin
    clk = 0;
    i_imm = 12'hb00;
    //Begin of reset secuence
    $display("----------BEGIN HARDWARE RESET SEQUENCE----------");
    clk <= 0;
    rst <= 0;
    #10
    clk <= 1;
    rst <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    rst <= 0;
    $display("----------END HARDWARE RESET SEQUENCE----------");
    //End of reset secuence
    event_bus.load = 1'b1;
    event_bus.store = 1'b1;
    event_bus.unaligned = 1'b1;
    event_bus.arithmetic = 1'b1;
    event_bus.trap = 1'b1;
    event_bus.interrupt = 1'b1;
    event_bus.conditional_branch = 1'b1;
    event_bus.unconditional_branch = 1'b1;
    event_bus.branch = 1'b1;
    event_bus.execute = 1'b1;
    
    //Set one performance counter event to count on load signal
    Write(12'h323, 1);
    Read_Test(12'h323, 1);
    Write(12'h324, 1);
    Write(12'h325, 1);
    Write(12'h326, 1);
    Write(12'h327, 1);
    Write(12'h328, 1);
    Write(12'h329, 1);
    Write(12'h320, 32'b1000);
end

always #10 clk = ~clk;


endmodule