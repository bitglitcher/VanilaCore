//Benjamin Herrera Navarro.
//11:15PM
//12/17/2020



module spi_controller #(parameter BASE_ADDR = 0)
(
    WB4.slave wb,
    SPI spi
);


//Writes on DATA go to the Write buffer, and Reads are from the read buffer

//8bits address granularity
//Memory Map
//0x00 RW DATA
//0x04 RO Count Reads //Avaliable bytes to recieve
//0x05 RO Count Writes //Avaliable byte to send
//0x06 RW Config
//0x07 RW CS_EN
//0x08 RW DIV 


////////////NOTE///////////
//Most sigmificant bit only supported for now :) well, no good >:(


//Config Register Bits
// Bit N   ON State         OFF STATE       Description
// Bit 0   1 - LSB First    0 - MSB First    
// Bit 1   1 - 32Bit Data   0 - 8Bit Data   DWS
// Bit 2   x                x               CPHA
// Bit 3   x                x               CPOL
// Bit 4   1 - Block Write  0 - Dont Block  BRBF - Block On Read Buffer Full 

//Mode   CPOL  CPHA   Clock Polarity
//0     | 0    | 0  | Logic low      | Data sampled on rising edge and shifted out on the falling edge
//1     | 0    | 1  | Logic low      | Data sampled on the falling edge and shifted out on the rising edge
//2     | 1    | 1  | Logic high     | Data sampled on the falling edge and shifted out on the rising edge
//3     | 1    | 0  | Logic high     | Data sampled on the rising edge and shifted out on the falling edge

//The CPOL bit set the state of the clock when transitioning from iddle state

//This is a mask for the CS_EN lines, only one should be activated at a time
reg   [7:0] cs_mask;
logic [7:0] conf; //Configuration register
logic [31:0] div;

initial begin
    cs_mask = 0;
    conf = 8'b00100;
end

//Split the bus into separate signals
wire XSB = conf[0:0];
wire DWS  = conf[1:1];
wire CPHA = conf[2:2];
wire CPOL = conf[3:3];
wire BRBF = conf[4:4];

//Control and Data signals for the FIFO buffers
logic wr_rd_buff;
logic rd_rd_buff;

logic wr_wr_buff;
logic rd_wr_buff;

logic rd_buff_empty;
logic wr_buff_empty;

logic rd_full;
logic wr_full;

logic [31:0] rd_dout;
logic [31:0] wr_dout;

logic [$clog2(8'hff)-1:0] rd_count;
logic [$clog2(8'hff)-1:0] wr_count;

//This is the data from the SPI master input data
wire [7:0] rd_buff_din;

//This is the read buffer, data is stored here
fifo #(.DATA_WIDTH(8), .MEMORY_DEPTH(8'hff)) spi_read_buffer
(
    //Syscon
    .clk(wb.clk),
    .rst(wb.rst),

    //Status
    .empty(rd_buff_empty),
    .full(rd_full),
    .count(rd_count),

    //Read
    .rd((~BRBF & rd_full) | rd_rd_buff),
    .dout(rd_dout),

    //Write
    .wr(rd_wr_buff),
    .din(rd_buff_din) //Data from wishbone
);

//This is the write buffer, data is stored here before sending it
fifo #(.DATA_WIDTH(8), .MEMORY_DEPTH(8'hff)) spi_write_buffer
(
    //Syscon
    .clk(wb.clk),
    .rst(wb.rst),

    //Status
    .empty(wr_buff_empty),
    .full(wr_full),
    .count(wr_count),

    //Read
    .rd(wr_rd_buff),
    .dout(wr_dout),

    //Write
    .wr(wr_wr_buff),
    .din(wb.DAT_O) //Data from wishbone
);

//Wishbone read logic
always_comb begin : wishbone_read
    //0x00 DATA //Because it supports, 32bit mode. But 8bit mode only for now
    if(wb.ADR == (BASE_ADDR + 0))
    begin
        wb.DAT_I = rd_dout; //Reads come from the read buffer :)
    end
    //0x04 Count Reads //Avaliable bytes to recieve
    else if(wb.ADR == (BASE_ADDR + 4))
    begin
        wb.DAT_I = rd_count;
    end
    //0x05 Count Writes //Avaliable byte to send
    else if(wb.ADR == (BASE_ADDR + 5))
    begin
        wb.DAT_I = wr_count;
    end
    //0x06 Config
    else if(wb.ADR == (BASE_ADDR + 6))
    begin
        wb.DAT_I = conf;
    end
    //0x07 CS Mask
    else if(wb.ADR == (BASE_ADDR + 7))
    begin
        wb.DAT_I = cs_mask;
    end
    //0x08 CS Mask
    else if(wb.ADR == (BASE_ADDR + 8))
    begin
        wb.DAT_I = div;
    end
    else
    begin
        wb.DAT_I = 32'b0;
    end
end

//Wishbone interface state machine
typedef enum logic [3:0] { IDDLE_WB, TAKE_WB } wishbone_states_t;
wishbone_states_t wb_states;

logic ACK_S;
logic ERR_S;

//To push data into the fifo
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        wb_states = IDDLE_WB;
        rd_rd_buff = 1'b0;
        wr_wr_buff = 1'b0;
        ACK_S = 1'b0;
        ERR_S = 1'b0;
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
                        if(wb.ADR == (BASE_ADDR + 0))
                        begin
                            if(BRBF) //Block If Read Buffer Full
                            begin
                                if(!wr_full & !rd_full) //Write if not full and read buffer not full
                                begin
                                    wr_wr_buff = 1'b1;
                                    rd_rd_buff = 1'b0;
                                    ACK_S = 1'b1;
                                    ERR_S = 1'b0;
                                    wb_states = TAKE_WB;
                                end
                                else //Dont allow to take more writes, because the SPI read buffer is full and data can be lost
                                begin
                                    wr_wr_buff = 1'b0;
                                    rd_rd_buff = 1'b0; //Post an error
                                    ACK_S = 1'b0;
                                    ERR_S = 1'b1; //Set error, so the master device doesn't wait for a ACK reply
                                    wb_states = TAKE_WB;
                                end
                            end
                            else
                            begin
                                //Ignore Read buffer
                                if(!wr_full) //Write if write buffer not full
                                begin
                                    wr_wr_buff = 1'b1;
                                    rd_rd_buff = 1'b0;
                                    ACK_S = 1'b1;
                                    ERR_S = 1'b0;
                                    wb_states = TAKE_WB;
                                end
                                else //Else do nothing and wait until buffer is empty
                                begin
                                    wr_wr_buff = 1'b0;
                                    rd_rd_buff = 1'b0;
                                    ACK_S = 1'b0;
                                    ERR_S = 1'b0;
                                    wb_states = IDDLE_WB; //Stay the same, until the buffer is not full
                                end

                            end
                        end
                        //0x02 Config
                        else if(wb.ADR == (BASE_ADDR + 6))
                        begin
                            wr_wr_buff = 1'b0;
                            rd_rd_buff = 1'b0;
                            ACK_S = 1'b1;
                            ERR_S = 1'b0;
                            wb_states = TAKE_WB;
                            conf = wb.DAT_O [7:0];
                        end
                        //0x02 CS Mask
                        else if(wb.ADR == (BASE_ADDR + 7))
                        begin
                            wr_wr_buff = 1'b0;
                            rd_rd_buff = 1'b0;
                            ACK_S = 1'b1;
                            ERR_S = 1'b0;
                            wb_states = TAKE_WB;
                            cs_mask = wb.DAT_O [7:0];
                        end
                        //0x02 DIV
                        else if(wb.ADR == (BASE_ADDR + 8))
                        begin
                            wr_wr_buff = 1'b0;
                            rd_rd_buff = 1'b0;
                            ACK_S = 1'b1;
                            ERR_S = 1'b0;
                            wb_states = TAKE_WB;
                            div = wb.DAT_O [7:0];
                        end
                        else
                        begin
                            wr_wr_buff = 1'b0;
                            rd_rd_buff = 1'b0;
                            ACK_S = 1'b0;
                            ERR_S = 1'b1; //Set error, so the master device doesn't wait for a ACK reply
                            wb_states = TAKE_WB;
                        end
                    end
                    //Else read
                    else //Allow all read, it will get garbage if because the buffer is empty, the programmer should check if the buffer is empty
                    begin
                        if(wb.ADR == (BASE_ADDR + 0))
                        begin
                            if(!rd_buff_empty) //Read if not empty
                            begin
                                rd_rd_buff = 1'b1;
                                wr_wr_buff = 1'b0;
                                ACK_S = 1'b1;
                                ERR_S = 1'b0;
                                wb_states = TAKE_WB;
                            end
                            else //Read error because buffer empty
                            begin
                                rd_rd_buff = 1'b0;
                                wr_wr_buff = 1'b0;
                                ACK_S = 1'b0;
                                ERR_S = 1'b1;
                                wb_states = TAKE_WB;
                            end
                        end
                        else if(wb.ADR <= (BASE_ADDR + 8))
                        begin
                            rd_rd_buff = 1'b1;
                            wr_wr_buff = 1'b0;
                            ACK_S = 1'b1;
                            ERR_S = 1'b0;
                            wb_states = TAKE_WB;
                        end
                        else
                        begin
                            //Read error
                            rd_rd_buff = 1'b0;
                            wr_wr_buff = 1'b0;
                            ACK_S = 1'b0;
                            ERR_S = 1'b1;
                            wb_states = TAKE_WB;
                        end
                    end
                end
                else //No wishbone bus accion
                begin
                    rd_rd_buff = 1'b0;
                    wr_wr_buff = 1'b0;
                    ACK_S = 1'b0;
                    ERR_S = 1'b0;
                    wb_states = IDDLE_WB;
                end
            end
            TAKE_WB:
            begin
                rd_rd_buff = 1'b0;
                wr_wr_buff = 1'b0;
                ACK_S = 1'b0;
                ERR_S = 1'b0;
                wb_states = IDDLE_WB;
            end
            default:
            begin
                rd_rd_buff = 1'b0;
                wr_wr_buff = 1'b0;
                ACK_S = 1'b0;
                ERR_S = 1'b0;
                wb_states = IDDLE_WB;
            end
        endcase
    end
end

assign wb.ACK = ACK_S & wb.STB & wb.CYC;
assign wb.ERR = ERR_S & wb.STB & wb.CYC;

/////////////////////////////////////////////////////////////////////////
//                                SPI Logic                            //
/////////////////////////////////////////////////////////////////////////

typedef enum logic [3:0] { IDDLE, SEND, WAIT } spi_states_t;
spi_states_t spi_state;

logic [31:0] cnt;
logic [3:0] n_pulse;
logic sclk;
logic [7:0] data;
logic hold;
logic CS_EN;

//Master input
parameter DATA_WIDTH = 7; //-1
reg [DATA_WIDTH:0] miso_data; //Positive edge sample shift register
assign rd_buff_din = miso_data;

initial begin
    cnt = 0;
    div = 7;
    n_pulse = 0;
    CS_EN = 1'b0;
end

always @(posedge wb.clk) begin
    if(wb.rst)
    begin
        spi_state = IDDLE;
    end    
    else
    begin
        unique case(spi_state)
            IDDLE:
            begin
                //Setup sclk = CPOL
                sclk = CPOL;

                rd_wr_buff = 1'b0; //Read buffer write signal

                if(BRBF)
                begin
                    //Check if there is data to read
                    if(!wr_buff_empty & !rd_full)
                    begin
                        //Tell write buffer that data was read
                        wr_rd_buff = 1'b1;
                        spi_state = SEND;          
                    end                    
                end
                else
                begin
                    //Check if there is data to read
                    if(!wr_buff_empty)
                    begin
                        //Tell write buffer that data was read
                        wr_rd_buff = 1'b1;
                        spi_state = SEND;          
                    end                    
                end
                CS_EN = 1'b1;
                n_pulse = 0;
                cnt = 0;
                hold = CPHA;
            end
            SEND:
            begin
                rd_wr_buff = 1'b0; //Read buffer write signal

                //Setup data that needs to be send
                data = wr_dout;
                wr_rd_buff = 1'b0;
                //Generate sclk
                if(cnt >= div)
                begin
                    //Negate clock signal
                    sclk = ~sclk;
                    if(CPHA)
                    begin
                        if(hold)
                        begin
                            hold = 1'b0;
                        end
                        else
                        begin
                            if(CPOL)
                            begin
                                if(~sclk)
                                begin
                                    n_pulse = n_pulse + 1;                    
                                end
                            end
                            else
                            begin
                                if(sclk)
                                begin
                                    n_pulse = n_pulse + 1;                    
                                end
                            end
                        end
                    end
                    else
                    begin
                        if(CPOL)
                        begin
                            if(sclk)
                            begin
                                n_pulse = n_pulse + 1;                    
                            end
                        end
                        else
                        begin
                            if(~sclk)
                            begin
                                n_pulse = n_pulse + 1;                    
                            end
                        end
                    end

                    cnt = 0; //Reset counter

                    //CPOL for reading data
                    if(CPOL)
                    begin
                        if(CPHA)
                        begin
                            if(sclk & (n_pulse < 8))
                            begin
                                miso_data <= {spi.MISO, miso_data [DATA_WIDTH:1]};
                            end
                        end
                        else
                        begin
                            if(~sclk & (n_pulse < 8))
                            begin
                                miso_data <= {spi.MISO, miso_data [DATA_WIDTH:1]};
                            end
                        end
                    end
                    else
                    begin
                        if(CPHA)
                        begin
                            if(~sclk & (n_pulse < 8))
                            begin
                                miso_data <= {spi.MISO, miso_data [DATA_WIDTH:1]};
                            end
                        end
                        else
                        begin
                            if(sclk & (n_pulse < 8))
                            begin
                                miso_data <= {spi.MISO, miso_data [DATA_WIDTH:1]};
                            end
                        end
                    end
                end
                else //Keep counting
                begin
                    cnt = cnt + 1;
                end

                //Stop when all bits have been sent
                if(n_pulse == 8)
                begin  
                    if(CPHA)
                    begin
                        //Wait half cycle
                        if(~sclk)
                        begin
                            spi_state = WAIT;
                            CS_EN = 1'b1; 
                            rd_wr_buff = 1'b1; //Read buffer write signal
                        end             
                    end
                    else
                    begin
                        //Wait half cycle
                        if(sclk)
                        begin
                            spi_state = WAIT;
                            CS_EN = 1'b1;   
                            rd_wr_buff = 1'b1; //Read buffer write signal
                        end             
                    end
                end
                else
                begin
                    CS_EN = 1'b0;                
                end
            end
            WAIT:
            begin
                //Setup sclk = CPOL
                sclk = CPOL;

                rd_wr_buff = 1'b0; //Read buffer write signal
                wr_rd_buff = 1'b0;
                if(cnt >= div)
                begin
                    spi_state = IDDLE;          
                    n_pulse = 0;
                    cnt = 0;
                end
                else
                begin
                    cnt = cnt + 1;
                end
                //if CPHA enable CS before first clock pulse
                CS_EN = 1'b1;
                n_pulse = 0;
                //
                hold = CPHA;
            end
        endcase
    end
end

assign spi.SCLK = sclk;

logic [7:0] lsb_dout;
assign lsb_dout = data << n_pulse;

always_comb begin : master_dout
    if(XSB) //Least sigmificant bit
    begin
        spi.MOSI = lsb_dout [7:7];    
    end
    else
    begin //MSB
        spi.MOSI = data >> n_pulse;    
    end
end

assign spi.CS = (CS_EN)? cs_mask : 0;

endmodule