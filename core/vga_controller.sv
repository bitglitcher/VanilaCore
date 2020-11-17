module vga_controller
(
    WB4.slave wb,
    VGA.output_int vga
);
parameter FREQ = 50000000;
parameter HEIGHT = 640;
parameter WIDTH = 480;
parameter ADDR_WIDTH = $clog2(HEIGHT*WIDTH)-1;

reg [7:0] frame_buffer [2**ADDR_WIDTH-1:0];

assign wb.DAT_I = 32'h0;

always@(negedge wb.clk)
begin
  if(wb.STB & wb.CYC)
  begin
      wb.ACK = 1'b1;
      if(wb.WE)
      begin
          frame_buffer [wb.ADR[15:2]] = wb.DAT_O;
          $display("VGA WRITE %x", wb.DAT_O);
      end
  end
  else
  begin
      wb.ACK = 1'b0;
  end
end


//Horizontal Timing
//Scanline part	    Pixels	Time [µs]
//Visible area	    640	    25.422045680238
//Front porch	    16	    0.63555114200596
//Sync pulse	    96	    3.8133068520357
//Back porch	    48	    1.9066534260179
//Whole line	    800	    31.777557100298
//640x480

//Vertical timing (frame)
//Polarity of vertical sync pulse is negative.
//Frame part	Lines	Time [ms]
//Visible area	480	    15.253227408143
//Front porch	10	    0.31777557100298
//Sync pulse	2	    0.063555114200596
//Back porch	33	    1.0486593843098
//Whole frame	525	    16.683217477656

reg [9:0] horizontal_counter;
reg [9:0] vertical_counter;

//always@(negedge wb.clk)
//begin
//    {vga.r, vga.g, vga.b} = frame_buffer [horizontal_counter*vertical_counter];
//end
assign {vga.r, vga.g, vga.b} = 3'b000;


//Increment counter
always@(posedge wb.clk)
begin
    if(horizontal_counter == 800)
    begin
        horizontal_counter = 0;
        if(vertical_counter == 525)
        begin
            vertical_counter = 0;
        end
        else
        begin
            vertical_counter = vertical_counter + 1;        
        end
    end
    else
    begin
        horizontal_counter = horizontal_counter + 1;    
    end
end

always_comb
begin
    if((horizontal_counter >= 656) & (horizontal_counter <= 656 + 96))
    begin
        vga.h_sync = 1'b0;
    end
    else
    begin
        vga.h_sync = 1'b1;
    end
end

always_comb
begin
    if((vertical_counter >= 480 + 10) & (vertical_counter <= 480 + 10 + 2))
    begin
        vga.v_sync = 1'b0;
    end
    else
    begin
        vga.v_sync = 1'b1;
    end
end


endmodule