
//Memory MAP

//Address Usecase  Read Write
//0x0000  DATA     Y    N
//0x0001  Count    Y    N

//Count hold the number of available bytes to read

module uart_slave
(
    WB4.slave wb
    input logic rx
);

parameter FREQUENCY = 25000000;
parameter BAUD_RATE = 115200;
parameter DELAY_CLOCKS = FREQUENCY/BAUD_RATE;
parameter DATA_WIDTH = 7; //-1

typedef enum logic [3:0] { IDDLE, START, BIT_S, STOP, DONE } states;

states current_state;

reg [DATA_WIDTH:0] data;
reg [2:0] n_bit;
reg [31:0] delay_count;
reg [2:0] shamnt;

assign wb.DAT_I = {24'h0, data [7:0]};

reg [7:0] write_pointer;
//buffer mem
reg [7:0] buffer [(2**8)-1:0];

//Wishbone ack signal


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
                delay_count = 0;
                shamnt = 0;

                if(rx == 0)
                begin
                    current_state = START;
                end
            end
            START:
            begin
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
                data = {data [DATA_WIDTH-1:0], rx};

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
                    current_state = IDDLE;
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