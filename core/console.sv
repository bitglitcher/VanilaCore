//6:12PM Wishbone compatible RAM wrapper
//Author: Benjamin Herrera Navarro
//11/05/2020


//All wishbone modules have to be reseted on the positive edge of the clock

module console(WB4.slave wb, output logic tx);
parameter FREQUENCY = 25000000;
parameter BAUD_RATE = 115200;
parameter DELAY_CLOCKS = FREQUENCY/BAUD_RATE;

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
    end
    else
    begin
        case(current_state)
            IDDLE:
            begin
                delay_count = 0;
                shamnt = 0;
                tx = 1;
                if(wb.CYC & wb.STB)
                begin
                    wb.ACK = 1'b1;
                    data = wb.DAT_O [7:0];
                    if(wb.WE)
                    begin
                        current_state = START;                    
                    end
                    else
                    begin
                        current_state = IDDLE;                    
                    end
                    $display("DATA CONSOLE: %d", wb.DAT_O [7:0]);
                end
                else
                begin
                    wb.ACK = 1'b0;
                end 
            end
            START:
            begin
                shamnt = 0;
                wb.ACK = 1'b0;
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
                tx = data >> shamnt;
                wb.ACK = 1'b0;
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
                shamnt = 0;
                wb.ACK = 1'b0;
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