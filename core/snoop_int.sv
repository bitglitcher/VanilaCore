
interface SNOOP_INT;
    logic [31:0] address;
    logic [31:0] data;
    logic wr; //Write
    logic ack;
endinterface //SNOOP_INT