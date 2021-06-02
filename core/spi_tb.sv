

module spi_tb();


logic clk;
logic rst;

WB4 wb(clk, rst);
SPI spi();

spi_controller spi_controller_0
(
    .wb(wb),
    .spi(spi)
);

task automatic wishbone_bus_write(int address, int data);   
    wb.CYC = 1'b1;
    wb.WE = 1'b1;
    wb.STB = 1'b1;
    wb.DAT_O = data;
    wb.ADR = address;
    @(posedge clk & wb.ACK);
    begin
        @(posedge clk);
        if(wb.ACK)
        begin
            wb.CYC = 1'b0;
            wb.WE = 1'b0;
            wb.STB = 1'b0;
        end
    end
    if(wb.ACK) $display("Successful write");
    if(wb.ERR) $display("Unsucessful write");
    @(posedge clk);
endtask //automatic

task automatic wishbone_bus_read_test(int address, int data);
    @(negedge wb.ACK);   
    wb.CYC = 1'b1;
    wb.WE = 1'b0;
    wb.STB = 1'b1;
    wb.ADR = address;
    @(posedge clk & wb.ACK);
    begin
        assert(wb.DAT_I == data) else $display("Error: Incorrect data read");
        wb.CYC = 1'b0;
        wb.WE = 1'b0;
        wb.STB = 1'b0;
    end
    if(wb.ACK) $display("Successful write");
    if(wb.ERR) $display("Unsucessful write");
    @(negedge wb.ACK);   
endtask //automatic

assign spi.MISO = spi.MOSI;

initial begin
    clk = 0;
    //Reset Signal
    #10
    rst = 1;
    #30
    rst = 0;
    //Begin write
    #40
    for(int i = 0; i < 8'hff;i++) wishbone_bus_write(0, i); //Write data
end

always #10 clk = ~clk;

typedef enum logic [3:0] { IDDLE, WRITE, READ } name;

endmodule