module seven_segment
(
    WB4.slave wb,
    output logic [6:0] display_data,
    output logic [3:0] select
);

reg [31:0] data;

assign wb.DAT_I = data; 
//Wishbone interface
always@(posedge wb.clk)
begin
    if(wb.rst)
    begin
        data = 32'h00000000;
    end
    else
    begin
        if(wb.STB & wb.CYC)
        begin
            if(wb.WE)
            begin
                data = wb.DAT_O; 
                $display("Seven Segment Display %x", data);
            end
            else
            begin
                data = data; 
            end
            wb.ACK = 1;
        end
        else
        begin
            data = data; 
            wb.ACK = 0;
        end
    end
end


logic [6:0] display_bus;


//Clock divider
reg [31:0] cnt; //To devide the clock
always@(posedge wb.clk)
begin
    cnt = cnt + 1;
end

//Select counter
reg [1:0] sel_n;
always@(posedge cnt[15:15])
begin
    sel_n = sel_n + 1;
end

initial begin
    cnt = 0;
    sel_n = 0;
end

always_comb
begin
    case(sel_n)
        0: select = 4'b1110;
        1: select = 4'b1101;
        2: select = 4'b1011;
        3: select = 4'b0111;
    endcase
end

//Data to display
logic [3:0] dattd;
//Multiplexer to select data
always_comb
begin
    unique case(sel_n)
        0: dattd <= data [3:0];
        1: dattd <= data [7:4];
        2: dattd <= data [11:8];
        3: dattd <= data [15:12];
    endcase
end

always_comb
begin
    case(dattd)
                            /// GFEDCBA
        4'h0: display_bus <= 7'h3f;//0
        4'h1: display_bus <= 7'h06;//1
        4'h2: display_bus <= 7'h5b;//2
        4'h3: display_bus <= 7'h4f;//3
        4'h4: display_bus <= 7'h66;//4
        4'h5: display_bus <= 7'h6d;//5
        4'h6: display_bus <= 7'h7d;//6
        4'h7: display_bus <= 7'h07;//7
        4'h8: display_bus <= 7'h7f;//8
        4'h9: display_bus <= 7'h6f;//9
        4'hA: display_bus <= 7'h77;//A
        4'hB: display_bus <= 7'h7c;//B
        4'hC: display_bus <= 7'h39;//C
        4'hD: display_bus <= 7'h5e;//D
        4'hE: display_bus <= 7'h79;//E
        4'hF: display_bus <= 7'h71;//F
    endcase
end


assign display_data = ~display_bus;


endmodule
