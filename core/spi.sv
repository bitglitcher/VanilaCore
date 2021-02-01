//Benjamin Herrera Navarro.
//11:15PM
//12/17/2020



module spi_controller();
// #(parameter BASE_ADDR = 0)
//(
//    WB4.slave wb,
//    SPI spi
//);


//reg [7:0] conf; //Configuration register
//
//wire XSB = conf[0:0];
//wire DW  = conf[1:1];
//wire CPHA = conf[2:2];
//wire CPOL = conf[3:3];
//
////Data for the reciever end
//reg [31-1:0] data;
//reg [2:0] shamt;


//Writes on DATA go to the Write buffer, and Reads are from the read buffer

//8bits address granularity
//Memory Map
//0x00 RW DATA
//0x04 RO Count Reads //Avaliable bytes to recieve
//0x05 RO Count Writes //Avaliable byte to send
//0x06 RW Config
//0x07 RW CS


////////////NOTE///////////
//Most sigmificant bit only supported for now :) well, no good >:(


//Config Register Bits
// Bit N   ON State         OFF STATE       Description
// Bit 0   1 - LSB First    0 - MSB First    
// Bit 1   1 - 8Bit Data    0 - 32Bit Data
// Bit 2   x                x               CPHA
// Bit 3   x                x               CPOL

//Mode   CPOL  CPHA   Clock Polarity
//0     | 0    | 0  | Logic low      | Data sampled on rising edge and shifted out on the falling edge
//1     | 0    | 1  | Logic low      | Data sampled on the falling edge and shifted out on the rising edge
//2     | 1    | 1  | Logic high     | Data sampled on the falling edge and shifted out on the rising edge
//3     | 1    | 0  | Logic high     | Data sampled on the rising edge and shifted out on the falling edge

//The CPOL bit set the state of the clock when transitioning from iddle state

//This is a mask for the CS lines, only one should be activated at a time
reg   [7:0] cs_enable;
logic [7:0] conf;
logic wr_rd_buff;
logic rd_rd_buff;
logic rd_buff_empty;
logic rd_full;
logic [31:0] rd_dout;
logic [$clog2(8'hff)-1:0] rd_count;

//This is the data from the SPI master input data
wire [7;:0] input_data;

//This is the read buffer, data is stored here
fifo #(.DATA_WIDTH(8), .MEMORY_DEPTH(8'hff)) fifo_0
(
    //Syscon
    .clk(wb.clk),
    .rst(wb.rst),

    //Status
    .empty(rd_buff_empty),
    .full(rd_full),
    .count(rd_count),

    //Read
    .rd(rd_rd_buff),
    .dout(rd_dout),

    //Write
    .wr(wr_rd_buff),
    .din(input_data) //Data from wishbone
);

//Wishbone read logic
always_comb begin : wishbone_read
    //0x00 DATA //Because it supports, 32bit mode. But 8bit mode only for now
    if(wb.ADDR == (BASE_ADDR + 0))
    begin
        wb.DAT_I = rd_dout; //Reads come from the read buffer :)
    end
    //0x01 Count Reads //Avaliable bytes to recieve
    else if(wb.ADDR == (BASE_ADDR + 4))
    begin
        wb.DAT_I = rd_count;
    end
    //0x01 Count Writes //Avaliable byte to send
    else if(wb.ADDR == (BASE_ADDR + 5))
    begin
        wb.DAT_I = 0; //No write buffer for now
    end
    //0x02 Config
    else if(wb.ADDR == (BASE_ADDR + 6))
    begin
        wb.DAT_I = conf;
    end
    //0x02 CS
    else if(wb.ADDR == (BASE_ADDR + 7))
    begin
        wb.DAT_I = cs_enable;
    end
    else
    begin
        wb.DAT_I = 32'b0;
    end
end

//Wishbone interface state machine
logic ACK_S;
logic ERR_S;
typedef enum logic [3:0] { IDDLE_WB, TAKE_WB } wishbone_states_t;
//To push data into the fifo
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        wb_states = IDDLE_WB;
    end
    else
    begin
        case(wb_states)
            IDDLE_WB:
            begin
                if(wb.STB & wb.CYC)
                begin
                    if(wb.WE) //Write
                    begin
                        //Write address decoder
                        //0x00 DATA //Because it supports, 32bit mode. But 8bit mode only for now
                        if(wb.ADDR == (BASE_ADDR + 0))
                        begin
                            if(!rd_full) //Write if not full
                            begin
                                rd_rd_buff = 1'b1;
                                ACK_S = 1'b1;
                                ERR_S = 1'b0;
                                wb_states = TAKE_WB;
                            end
                            else //Dont allow to take more writes, because the SPI read buffer is full and data can be lost
                            begin
                                rd_rd_buff = 1'b0; //Post an error
                                ACK_S = 1'b0;
                                ERR_S = 1'b1;
                                wb_states = wb_states; //Stay the same, until the buffer is not full
                            end
                            rd_dout = wb.DAT_I [7:0]; //Reads come from the read buffer :)
                        end
                        //0x02 Config
                        else if(wb.ADDR == (BASE_ADDR + 6))
                        begin
                            conf = wb.DAT_I [7:0];
                        end
                        //0x02 CS
                        else if(wb.ADDR == (BASE_ADDR + 7))
                        begin
                            cs_enable = wb.DAT_I [7:0];
                        end
                        else
                        begin
                            
                        end
                        
                    end
                    //Else read
                    else //Allow all read, it will get garbage if because the buffer is empty, the programmer should check if the buffer is empty
                    begin
                        rd_rd_buff = 1'b1;
                        ACK_S = 1'b0;
                        wb_states = wb_states; //Stay the same, until fully is not full
                    end
                end
                else //No wishbone bus accion
                begin
                    rd_rd_buff = 1'b0;
                    ACK_S = 1'b0;
                    wb_states = IDDLE_WB;
                end
            end
            TAKE_WB:
            begin
                rd_rd_buff = 1'b0;
                ACK_S = 1'b0;
                wb_states = IDDLE_WB;
            end
            default:
            begin
                rd_rd_buff = 1'b0;
                ACK_S = 1'b0;
                wb_states = IDDLE_WB;
            end
        endcase
    end
end
assign wb.ACK = ACK_S & wb.CYC & wb.STB;
assign wb.ERR = ERR_S & wb.CYC & wb.STB;


typedef enum logic [3:0] { IDDLE, START, SEND, STOP } master_states_t;

//state machine register
master_states_t next_state;
master_states_t state;


logic CPOL;
logic CPHA;

logic sclk;
logic CS;
logic MOSI;

logic reset_shamt;
logic clk;
logic rst;
reg [7:0] data;
reg [7:0] shamt_p;
reg [7:0] shamt_n;

initial begin
    shamt_p = 0;
    shamt_n = 0;
    data = 8'b11001011;
    CPOL = 0;
    CPHA = 0;
    CS = 0;
    clk = 0;
    rst = 0;
    sclk = 0;
    state = IDDLE;
    //Reset Signal
    #10
    rst = 1;
    #30
    rst = 0;
end

/////////////////////////////////////////////////////////////////
//                     SPI MASTER LOGIC                        //
/////////////////////////////////////////////////////////////////

//Switch to CPHA 1
always@(posedge clk) if(state == STOP) CPHA = 1;
always #10 clk = ~clk;
always@(posedge clk) if(state == STOP & CPHA)
begin
    CPHA = 0;
    CPOL = 1;
end

always@(posedge clk)
begin
    state = next_state;    
end

always@(*)
begin
   unique case(state) 
        IDDLE:
        begin
            reset_shamt = 1'b1;
            next_state = START;
            wr_rd_buff = 0;
        end
        START:
        begin
            if(CPOL)
            begin
                if(clk == 1)
                begin
                    next_state = SEND;            
                end
            end
            else
            begin
                if(clk == 0)
                begin
                    next_state = SEND;            
                end
            end
            reset_shamt = 1'b0;
            wr_rd_buff = 0;
        end
        SEND:
        begin
            if(CPHA)
            begin
                if(shamt_p == 8)
                begin
                    next_state = STOP;
                end
            end
            else
            begin
                if(shamt_n == 8)
                begin
                    next_state = STOP;
                end
            end
            reset_shamt = 1'b0;
            wr_rd_buff = 0;
        end
        STOP:
        begin
            reset_shamt = 1'b1;
            next_state = IDDLE;
            wr_rd_buff = 1;
        end
   endcase
end

//Generate CS signal
always @(negedge clk)
begin
    if(state == START)
    begin
        CS = 0;
    end
    else if(state == SEND)
    begin
        CS = 0;
    end
    else
    begin
        CS = 1;
    end
end

//Generate Shift ammount
always@(negedge clk)
begin
    if(state == SEND)
    begin
        shamt_n = shamt_n + 1;
    end
    else if(reset_shamt)
    begin
        shamt_n = 0;
    end
end

typedef enum logic { IGNORE, COUNT } shamt_p_state_t;
shamt_p_state_t shamt_p_state;
always@(posedge clk)
begin
    if(shamt_p_state == IGNORE)
    begin
        shamt_p = 0;
        if(state == SEND)
        begin
            shamt_p_state = COUNT;
        end
        else
        begin
            shamt_p_state = IGNORE;
        end
    end
    else if(COUNT)
    begin
        if(reset_shamt)
        begin
            shamt_p = 0;
            shamt_p_state = IGNORE;
        end
        else
        begin
            shamt_p_state = COUNT;        
        end
        if(state == SEND)
        begin
            shamt_p = shamt_p + 1;
        end
    end
    else
    begin
        shamt_p_state = IGNORE;
    end 
end

//Generate Master Data output
always_comb
begin
    if(CPHA)
    begin
        if(state == SEND)
        begin
            MOSI = data >> shamt_p;
        end
        else
        begin
            MOSI = 1'bz;
        end
    end
    else
    begin
        if(state == SEND)
        begin
            MOSI = data >> shamt_n;
        end
        else if((state == IDDLE) | (state == STOP))
        begin
            MOSI = 1'bz;
        end 
        else if((state == START) & (CS == 1))
        begin
            MOSI = 1'bz;
        end
        else
        begin
            MOSI = data >> shamt_n;
        end
    end
end


//Clock generator
always@(*)
begin
    if(state == IDDLE)
    begin
        sclk = CPOL;
    end
    else if(state == SEND)
    begin
        sclk = clk;
    end
    else
    begin
        sclk = CPOL;
    end
end

//Master input logic
parameter DATA_WIDTH = 7; //-1
reg [DATA_WIDTH:0] miso_data_p; //Positive edge sample shift register
reg [DATA_WIDTH:0] miso_data_n; //Negative edge sample shift register

always@(posedge clk)
begin
    if(state == SEND)
    begin
        miso_data_p <= {MOSI, miso_data_p [DATA_WIDTH:1]};    
    end
end

always@(negedge clk)
begin
    if(state == SEND)
    begin
        miso_data_n <= {MOSI, miso_data_n [DATA_WIDTH:1]};
    end
end

//CPOL = 0/Sample on positive edge
assign input_data = (CPOL)? miso_data_n : miso_data_p;


endmodule