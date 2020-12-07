
//Memory MAP

//Address Usecase  Read Write
//0x000  DATA     Y    N
//0x004  Count    Y    N

//Count hold the number of available bytes to read

module uart_slave
(
    WB4.slave wb,
    input logic rx
);

parameter FREQUENCY = 25000000;
parameter BAUD_RATE = 115200;
parameter DELAY_CLOCKS = FREQUENCY/BAUD_RATE;
parameter DATA_WIDTH = 7; //-1

typedef enum logic [3:0] { IDDLE, START, BIT_S, STOP, DONE } states;

states current_state;

reg [DATA_WIDTH-1:0] data;
reg [2:0] n_bit;
reg [31:0] delay_count;
reg [2:0] shamnt;


logic wr;
logic rd;
logic empty;
logic full;
logic [6:0] dout;
logic [$clog2(32)-1:0] count;

fifo #(.DATA_WIDTH(7), .MEMORY_DEPTH(32)) fifo_0
(
    //Syscon
    .clk(wb.clk),
    .rst(wb.rst),

    //Status
    .empty(empty),
    .full(full),
    .count(count),

    //Read
    .rd(rd),
    .dout(dout),

    //Write
    .wr(wr),
    .din(data)
);

//Wishbone address decoder
always_comb
begin
    casez (wb.ADR)
        32'b????_????_????_????_????_????_????_?000: wb.DAT_I = dout;
        32'b????_????_????_????_????_????_????_?100: wb.DAT_I = count;
        default: wb.DAT_I = 32'b0;
    endcase
end

//Wishbone control logic
logic ack_s;

always@(posedge wb.clk)
begin
    if(wb.STB & wb.CYC)
    begin
        casez (wb.ADR)
            32'b????_????_????_????_????_????_????_?000:
            begin
                rd = 1;
                ack_s = 1'b1;
                $display("READING DATA FROM UART RECIEVER");
            end
            32'b????_????_????_????_????_????_????_?100:
            begin
                rd = 0;
                ack_s = 1'b1;
            end
            default:
            begin
                rd = 0;
                ack_s = 1'b1;
            end
        endcase
    end
    else
    begin
        rd = 0;
        ack_s = 1'b0;
    end
end

assign wb.ACK = ack_s & wb.CYC & wb.STB;

//Sample signals at the rising edge
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        current_state = IDDLE;
        delay_count = 0;
        shamnt = 0;
    end
    else
    begin
        case(current_state)
            IDDLE:
            begin
                wr = 1'b0;
                delay_count = 0;
                shamnt = 0;

                if(rx == 0)
                begin
                    current_state = START;
                end
            end
            START:
            begin
                wr = 1'b0;
                shamnt = 0;
                if(delay_count == DELAY_CLOCKS)
                begin
                    current_state = BIT_S;
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
            end
            BIT_S:
            begin
                wr = 1'b0;
                if(delay_count == (DELAY_CLOCKS/2))
                begin
                    data <= {rx, data [DATA_WIDTH-1:1]}; 
                end
                if(delay_count == DELAY_CLOCKS)
                begin
                    if(shamnt == DATA_WIDTH-1)
                    begin
                        current_state = STOP;
                        shamnt = 0;                    
                    end
                    else
                    begin
                        shamnt = shamnt + 1;
                        current_state = BIT_S;                
                    end
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
            end
            STOP:
            begin
                shamnt = 0;
                if(delay_count == DELAY_CLOCKS)
                begin
                    wr = 1'b1;
                    if(!full)
                    begin
                        current_state = IDDLE;                    
                    end
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
                //PUSH data into buffer
            end
        endcase
    end
end


endmodule