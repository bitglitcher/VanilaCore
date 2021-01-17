

//Coherent Snoopy Cache protocol

module cache #(parameter ADDR_SIZE = 8)
(
    WB4.master master_bus,
    WB4.slave slave_bus,
    logic [31:0] snoop_bus,
);

logic [ADDR_SIZE-1:0] index;
logic [] tag;
logic 


logic [31:0] data [($clog(ADDR_SIZE)-1):0]
logic [31:0] tag [($clog(ADDR_SIZE)-1):0]
logic valid [($clog(ADDR_SIZE)-1):0]



typedef enum logic[3:0] { IDDLE, HIT, MISS, WRITE_BACK } cache_states_t;
cache_states_t state;

always_ff@(posedge clk)
begin
    if(wb.rst)
    begin
        state = IDDLE;
    end
    else
    begin
        case(state)
            IDDLE:
            begin
                
            end
            default:
            begin
                state = IDDLE;
            end
        endcase    
    end
end


endmodule