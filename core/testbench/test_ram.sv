
module test_ram(WB4.master wb);

//Master
typedef enum logic [3:0] { iddle, read_cycle, write_cycle } state;


//Use as address also
reg [31:0] data;
logic [31:0] data_next;

//state machine 
state next_state, current_state;

always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        current_state = iddle;
        data = 32'b0;
    end
    else
    begin
        current_state = next_state; 
        data = data_next;
    end
end

always_comb
begin
    unique case(current_state)
        iddle:
        begin
            next_state = write_cycle;
            wb.CYC <= 1'b0; //Begin transaction
            wb.STB <= 1'b0;
            wb.WE <= 1'b0; //Read 
            wb.ADR <= data;
            wb.DAT_O <= 32'b0; 
            data_next <= data;          
        end
        read_cycle:
        begin
            $display("data read -> %b", data);
            if(wb.ACK)
            begin
                next_state = write_cycle;
                wb.CYC <= 1'b0; //Begin transaction
                wb.STB <= 1'b0;
                wb.WE <= 1'b0; //Read
                wb.ADR = data;
                wb.DAT_O <= 32'b0;
                data_next <= data + 1;
                if(wb.DAT_I == data)
                begin
                    $display("read passed! data readed -> %b", wb.DAT_I);
                end
                else
                begin
                    $display("read failed! data readed -> %b, expected %b", wb.DAT_I, data);
                end
            end
            else
            begin
                wb.CYC <= 1'b1; //Begin transaction
                wb.STB <= 1'b1;
                wb.WE <= 1'b0; //Read
                wb.ADR = data;
                wb.DAT_O <= 32'b0;
                data_next <= data;
            end
        end
        write_cycle:
        begin
            data_next = data;
            $display("data write -> %b", data);
            if(wb.ACK)
            begin
                next_state = read_cycle;
                wb.CYC <= 1'b0; //Begin transaction
                wb.STB <= 1'b0;
                wb.WE <= 1'b1; //Write
            end
            else
            begin
                wb.CYC <= 1'b1; //Begin transaction
                wb.STB <= 1'b1;
                wb.WE <= 1'b1; //Write
                wb.ADR <= data;
                wb.DAT_O <= data;
            end
        end
    endcase
end

endmodule