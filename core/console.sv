//6:12PM Wishbone compatible RAM wrapper
//Author: Benjamin Herrera Navarro
//11/05/2020


//All wishbone modules have to be reseted on the positive edge of the clock

module console
(
    WB4.slave wb,
    output logic tx,
    input logic rx
);

parameter FREQUENCY = 25000000;
parameter BAUD_RATE = 115200;
parameter DELAY_CLOCKS = 1;//FREQUENCY/BAUD_RATE;

//Logic for the wishbone interface

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
    .din(wb.DAT_O [7:0]) //Data from wishbone
);

logic ACK_S;

typedef enum logic [3:0] { IDDLE_WB, TAKE_WB } wishbone_states_t;

wishbone_states_t wb_states;

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
                    if(!full)
                    begin
                        wr = 1'b1;
                        ACK_S = 1'b1;
                        wb_states = TAKE_WB;
                        $display("DATA CONSOLE: %s", wb.DAT_O [7:0]);
                    end
                    else
                    begin
                        wr = 1'b0;
                        ACK_S = 1'b0;
                        wb_states = wb_states;
                    end
                end
                else
                begin
                    wr = 1'b0;
                    ACK_S = 1'b0;
                    wb_states = wb_states;
                end
            end
            TAKE_WB:
            begin
                wr = 1'b0;
                ACK_S = 1'b0;
                wb_states = IDDLE_WB;
            end
            default:
            begin
                wr = 1'b0;
                ACK_S = 1'b0;
                wb_states = IDDLE_WB;
            end
        endcase
    end
end

assign wb.ACK = ACK_S & wb.CYC & wb.STB;


typedef enum logic [3:0] { IDDLE, START, BIT_S, STOP, DONE } states;

states current_state;

reg [7:0] data;
reg [2:0] n_bit;
reg [31:0] delay_count;
reg [2:0] shamnt;

assign wb.DAT_I = {24'h0, data [7:0]};

//Sample signals at the rising edge
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        current_state = IDDLE;
        delay_count = 0;
        shamnt = 0;
        rd = 1'b0;
        tx = 1;
    end
    else
    begin
        case(current_state)
            IDDLE:
            begin
                delay_count = 0;
                shamnt = 0;
                tx = 1;

                if(!empty)
                begin
                    rd = 1'b1;
                    current_state = START;   
                end
                else
                begin
                    rd = 1'b0;
                    current_state = IDDLE;
                end
            end
            START:
            begin
                data = dout;                 
                rd = 1'b0;
                shamnt = 0;
                tx = 1'b0;
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
                rd = 1'b0;
                tx = data >> shamnt;
                if(delay_count == DELAY_CLOCKS)
                begin
                    if(shamnt == 6)
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
                rd = 1'b0;
                shamnt = 0;
                tx = 1'b1;
                if(delay_count == DELAY_CLOCKS)
                begin
                    current_state = IDDLE;
                    delay_count = 0;    
                end
                else
                begin
                    delay_count = delay_count + 1;
                end
            end
        endcase
    end
end

endmodule