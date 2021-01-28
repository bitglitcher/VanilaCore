
module minfo
(
    //Control signals
    input logic [11:0] addr,
    output logic [31:0] dout,
    output logic illegal_address
);

//0xF11 MRO mvendorid Vendor ID.
logic [31:0] mvendorid;
assign mvendorid = 32'hdeadbeef; //Not implemented

//0xF12 MRO marchid Architecture ID.
logic [31:0] marchid;
assign marchid = 32'hbeefeaea; //Not implemented

//0xF13 MRO mimpid Implementation ID.
logic [31:0] mimpid;
assign mimpid = 32'hfaabaaaa; //Not implemented

//0xF14 MRO mhartid Hardware thread ID.
logic [31:0] mhartid;
assign mhartid = 32'h0; //This must be unique ID. For now 0 because of the single core implementation




/////////////////////////////////////////////////////////////////////
//                     Read  Logic                                 //
/////////////////////////////////////////////////////////////////////

/*Read only registers*/

//Read
always_comb
begin
    case(addr)
        //0xF11 MRO mvendorid Vendor ID.
        12'hf11: begin dout = mvendorid; illegal_address = 1'b0; end
        //0xF12 MRO marchid Architecture ID.
        12'hf12: begin dout = marchid; illegal_address = 1'b0; end
        //0xF13 MRO mimpid Implementation ID.
        12'hf13: begin dout = mimpid; illegal_address = 1'b0; end
        //0xF14 MRO mhartid Hardware thread ID.
        12'hf14: begin dout = mhartid; illegal_address = 1'b0; end
        default:
        begin
            dout = 32'b0;
            illegal_address = 1'b1; 
        end
    endcase
end





endmodule