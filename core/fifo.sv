//Author: Benjamin Herrera Navarro
//12/4/2020 12:55AM


module fifo
    #(parameter DATA_WIDTH = 32,
    parameter MEMORY_DEPTH = 32)
(
    //Syscon
    input logic clk,
    input logic rst,

    //Status
    output logic empty,
    output logic full,
    output logic [$clog2(MEMORY_DEPTH)-1:0] count,

    //Read
    input logic rd,
    output logic [DATA_WIDTH-1:0] dout,

    //Write
    input logic wr,
    input logic [DATA_WIDTH-1:0] din
);


//FIFO Memory
reg [DATA_WIDTH-1:0] buffer [MEMORY_DEPTH-1:0];

//Read and write pointers
reg [$clog2(MEMORY_DEPTH)-1:0] write_ptr;
reg [$clog2(MEMORY_DEPTH)-1:0] read_ptr;

//Status
logic [$clog2(MEMORY_DEPTH)-1:0] buff_cnt;


assign empty = (buff_cnt == 0);
assign full = (buff_cnt == (MEMORY_DEPTH-1));


assign count = buff_cnt;

//Counter decremenet and increment
always @(posedge clk)
begin
   if( rst )
   begin
       buff_cnt <= 0;
   end
   else if((!full && wr) && (!empty && rd))
   begin
       buff_cnt <= buff_cnt;
   end
   else if(!full && wr)
   begin
       buff_cnt <= buff_cnt + 1;
   end
   else if(!empty && rd)
   begin
       buff_cnt <= buff_cnt - 1;
   end
   else
   begin
      buff_cnt <= buff_cnt;
   end
end

//Pointer Logic
always@(posedge clk)
begin
    if(rst)
    begin
        write_ptr = 0;
        read_ptr = 0;
    end
    else
    begin
        if(wr & !full)
        begin
            write_ptr = write_ptr + 1;
        end
        else
        begin
            write_ptr = write_ptr;
        end
        if(rd & !empty)
        begin
            read_ptr = read_ptr + 1;
        end
        else
        begin
            read_ptr = read_ptr;
        end
    end
end

//Write ptr
always@(negedge clk)
begin
    if(wr & !full)
    begin
        buffer [write_ptr] <= din;
    end
    else
    begin
        buffer [write_ptr] <= buffer [write_ptr];
    end
end

//Read ptr
always@(negedge clk)
begin
    if(rd & !empty)
    begin
        dout <= buffer [read_ptr];
    end
    else
    begin
        dout <= dout;
    end
end


endmodule