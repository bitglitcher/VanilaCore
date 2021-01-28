//Simple Cache with no replacement policy
module cache #(parameter ADDR_SIZE = 8)
(
    WB4.master master_bus, //This bus goes to the memory controller
    WB4.slave slave_bus, //Bus to slave_bus
    logic [31:0] snoop_bus, //This is just the address, and it invalidates entries
);


logic [127:0] data [($clog(ADDR_SIZE)-1):0]; //To get the most out of those tags
logic [31:0] tag [($clog(ADDR_SIZE)-1):0]; //This entry contains the address of the cache entry
logic valid [($clog(ADDR_SIZE)-1):0]; //Valid means that the date is valid data from main memory
logic dirty [($clog(ADDR_SIZE)-1):0]; //When writting to this entry, this entry will be set to dirty


typedef enum logic[3:0] { IDDLE, MISS, WRITE_BACK } cache_states_t;
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
                if(slave_bus.STB & slave_bus.CYC)
                begin
                    //Check is a valid entry
                    if(valid[ADDR])
                    begin

                    end
                end
            end
            default:
            begin
                state = IDDLE;
            end
        endcase    
    end
end


endmodule