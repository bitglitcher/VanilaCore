//Author: Benjamin Herrera Navarro
//Date: 2/28/2020
//11:28AM

`timescale 1ps/1ps

/*
module cross_bar_tb();

parameter MEMORY_START = 32'h00000000;
parameter MEMORY_END =   32'h000fffff;

//Device Region
parameter UART_START =   32'h00100000;
parameter UART_END =     32'h00100000;
parameter DISPLAY_START =32'h00100010;
parameter DISPLAY_END =  32'h00100010;
parameter UART_RX_START =32'h00100020;
parameter UART_RX_END =  32'h00100024;
parameter TIMER_START =  32'h00100030;
parameter TIMER_END =    32'h0010003f;
parameter SPI_START =    32'h00100030;
parameter SPI_END =      32'h0010003f;

logic clk;
logic rst;

WB4 cpu_wb(clk, rst);
WB4 dma_wb(clk, rst);
WB4 memory_wb(clk, rst);
WB4 uart_wb(clk, rst);
WB4 uart_rx_wb(clk, rst);
WB4 timer_dev_wb(clk, rst);
WB4 spi_wb(clk, rst);

cross_bar cross_bar_0
(
    .cpu(cpu_wb),
    .dma(dma_wb),

    .memory(memory_wb),
    .uart(uart_wb),
    .uart_rx(uart_rx_wb),
    .timer_dev(timer_dev_wb),
    .spi(spi_wb)
);

typedef enum int { DMA, CPU } master_t;

//Wishbone write task
task automatic wb_write(int addess, int data, master_t master);
    if(master == CPU)
    begin
        cpu_wb.ADR = addess;
        cpu_wb.DAT_O = data;    
        //Assert STB and CYC
        cpu_wb.STB = 1'b1;
        cpu_wb.CYC = 1'b1;
        //Wait for ACK signal
        @(posedge cpu_wb.clk)
        begin
            //@(posedge cpu_wb.ACK)
            //begin
            //    @(negedge cpu_wb.clk)
            //    begin
            //        cpu_wb.STB = 1'b0;
            //        cpu_wb.CYC = 1'b0; 
            //    end
            //end
        end
    end
    else if(master == DMA)
    begin
        dma_wb.ADR = addess;
        dma_wb.DAT_O = data;    
        //Assert STB and CYC
        dma_wb.STB = 1'b1;
        dma_wb.CYC = 1'b1;
        //Wait for ACK signal
        @(posedge cpu_wb.clk)
        begin
            @(posedge dma_wb.ACK)
            begin
                @(negedge cpu_wb.clk)
                begin
                    dma_wb.STB = 1'b0;
                    dma_wb.CYC = 1'b0; 
                end
            end
        end
    end
    else
    begin
        $display("Master type not recognized");
        $stop;
    end
endtask

//Wishbone write task
task automatic wb_read(int addess);
    
endtask

initial begin
    clk = 0;
    rst = 0;
    dma_wb.STB = 1'b0;
    dma_wb.CYC = 1'b0;
    cpu_wb.STB = 1'b0;
    cpu_wb.CYC = 1'b0;
    //bus
    wb_write(MEMORY_START, 0, CPU);
    wb_write(UART_START, 0, DMA);
end

always #10 clk = ~clk;
    
reg MEMORY_WB_ACK_S;
reg UART_WB_ACK_S;
reg UART_RX_WB_ACK_S;
reg TIMER_DEV_WB_ACK_S;
reg SPI_WB_ACK_S;
//Generate Dummy wishbone slave
always_ff @( posedge cpu_wb.clk )
begin
    if(memory_wb.STB & memory_wb.CYC)
    begin
        MEMORY_WB_ACK_S = 1'b1;
    end
    else
    begin
        MEMORY_WB_ACK_S = 1'b0;
    end
    if(uart_wb.STB & uart_wb.CYC)
    begin
        UART_WB_ACK_S = 1'b1;
    end
    else
    begin
        UART_WB_ACK_S = 1'b0;
    end
    if(uart_rx_wb.STB & uart_rx_wb.CYC)
    begin
        UART_RX_WB_ACK_S = 1'b1;
    end
    else
    begin
        UART_RX_WB_ACK_S = 1'b0;
    end
    if(timer_dev_wb.STB & timer_dev_wb.CYC)
    begin
        TIMER_DEV_WB_ACK_S = 1'b1;
    end
    else
    begin
        TIMER_DEV_WB_ACK_S = 1'b0;
    end
    if(spi_wb.STB & spi_wb.CYC)
    begin
        SPI_WB_ACK_S = 1'b1;
    end
    else
    begin
        SPI_WB_ACK_S = 1'b0;
    end
end

assign memory_wb.ACK = MEMORY_WB_ACK_S & memory_wb.STB & memory_wb.CYC;
assign uart_wb.ACK = UART_WB_ACK_S & uart_wb.STB & uart_wb.CYC;
assign uart_rx_wb.ACK = UART_RX_WB_ACK_S & uart_rx_wb.STB & uart_rx_wb.CYC;
assign timer_dev_wb.ACK = TIMER_DEV_WB_ACK_S & timer_dev_wb.STB & timer_dev_wb.CYC;
assign spi_wb.ACK = SPI_WB_ACK_S & spi_wb.STB & spi_wb.CYC;

endmodule*/