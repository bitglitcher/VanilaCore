
//Author: Benjamin Herrera Navarro
//Date: 2/26/2021
//8:17 PM


module wb_master_mux
(
    input logic [3:0] sel,
    WB4.master slave0, //Slave BUS 0
    WB4.master slave1, //Slave BUS 1
    WB4.master slave2, //Slave BUS 2
    WB4.master slave3, //Slave BUS 3
    WB4.master slave4, //Slave BUS 4
	WB4.master slave5, //Slave BUS 5
    WB4.slave muxed_out //This bus is the output of the multiplexer
);

always_comb begin
    unique case(sel)
        4'h0:
        begin
            slave0.STB = muxed_out.STB;
            slave0.ADR = muxed_out.ADR;
            slave0.CYC = muxed_out.CYC;
            slave0.WE = muxed_out.WE;
            slave0.DAT_O = muxed_out.DAT_O;

            slave1.STB = 0;
            slave1.ADR = 0;
            slave1.CYC = 0;
            slave1.WE =  0;
            slave1.DAT_O = 0;

            slave2.STB = 0;
            slave2.ADR = 0;
            slave2.CYC = 0;
            slave2.WE =  0;
            slave2.DAT_O = 0;

            slave3.STB = 0;
            slave3.ADR = 0;
            slave3.CYC = 0;
            slave3.WE =  0;
            slave3.DAT_O = 0;

            slave4.STB = 0;
            slave4.ADR = 0;
            slave4.CYC = 0;
            slave4.WE =  0;
            slave4.DAT_O = 0;

            slave5.STB = 0;
            slave5.ADR = 0;
            slave5.CYC = 0;
            slave5.WE =  0;
            slave5.DAT_O = 0;

            muxed_out.ACK = slave0.ACK;
            muxed_out.ERR = slave0.ERR;
            muxed_out.RTY = slave0.RTY;
            muxed_out.DAT_I = slave0.DAT_I;
            
        end
        4'h1:
        begin
            slave1.STB = muxed_out.STB;
            slave1.ADR = muxed_out.ADR;
            slave1.CYC = muxed_out.CYC;
            slave1.WE = muxed_out.WE;
            slave1.DAT_O = muxed_out.DAT_O;

            slave0.STB = 0;
            slave0.ADR = 0;
            slave0.CYC = 0;
            slave0.WE =  0;
            slave0.DAT_O = 0;

            slave2.STB = 0;
            slave2.ADR = 0;
            slave2.CYC = 0;
            slave2.WE =  0;
            slave2.DAT_O = 0;

            slave3.STB = 0;
            slave3.ADR = 0;
            slave3.CYC = 0;
            slave3.WE =  0;
            slave3.DAT_O = 0;

            slave4.STB = 0;
            slave4.ADR = 0;
            slave4.CYC = 0;
            slave4.WE =  0;
            slave4.DAT_O = 0;

            slave5.STB = 0;
            slave5.ADR = 0;
            slave5.CYC = 0;
            slave5.WE =  0;
            slave5.DAT_O = 0;

            muxed_out.ACK = slave1.ACK;
            muxed_out.ERR = slave1.ERR;
            muxed_out.RTY = slave1.RTY;
            muxed_out.DAT_I = slave1.DAT_I;
        end
        4'h2:
        begin
            slave2.STB = muxed_out.STB;
            slave2.ADR = muxed_out.ADR;
            slave2.CYC = muxed_out.CYC;
            slave2.WE = muxed_out.WE;
            slave2.DAT_O = muxed_out.DAT_O;

            slave0.STB = 0;
            slave0.ADR = 0;
            slave0.CYC = 0;
            slave0.WE =  0;
            slave0.DAT_O = 0;

            slave1.STB = 0;
            slave1.ADR = 0;
            slave1.CYC = 0;
            slave1.WE =  0;
            slave1.DAT_O = 0;

            slave3.STB = 0;
            slave3.ADR = 0;
            slave3.CYC = 0;
            slave3.WE =  0;
            slave3.DAT_O = 0;

            slave4.STB = 0;
            slave4.ADR = 0;
            slave4.CYC = 0;
            slave4.WE =  0;
            slave4.DAT_O = 0;

            slave5.STB = 0;
            slave5.ADR = 0;
            slave5.CYC = 0;
            slave5.WE =  0;
            slave5.DAT_O = 0;

            muxed_out.ACK = slave2.ACK;
            muxed_out.ERR = slave2.ERR;
            muxed_out.RTY = slave2.RTY;
            muxed_out.DAT_I = slave2.DAT_I;
            
        end
        4'h3:
        begin
            slave3.STB = muxed_out.STB;
            slave3.ADR = muxed_out.ADR;
            slave3.CYC = muxed_out.CYC;
            slave3.WE = muxed_out.WE;
            slave3.DAT_O = muxed_out.DAT_O;

            slave0.STB = 0;
            slave0.ADR = 0;
            slave0.CYC = 0;
            slave0.WE =  0;
            slave0.DAT_O = 0;

            slave2.STB = 0;
            slave2.ADR = 0;
            slave2.CYC = 0;
            slave2.WE =  0;
            slave2.DAT_O = 0;

            slave1.STB = 0;
            slave1.ADR = 0;
            slave1.CYC = 0;
            slave1.WE =  0;
            slave1.DAT_O = 0;

            slave4.STB = 0;
            slave4.ADR = 0;
            slave4.CYC = 0;
            slave4.WE =  0;
            slave4.DAT_O = 0;

            slave5.STB = 0;
            slave5.ADR = 0;
            slave5.CYC = 0;
            slave5.WE =  0;
            slave5.DAT_O = 0;

            muxed_out.ACK = slave3.ACK;
            muxed_out.ERR = slave3.ERR;
            muxed_out.RTY = slave3.RTY;
            muxed_out.DAT_I = slave3.DAT_I;
            
        end
        4'h4:
        begin
            slave4.STB = muxed_out.STB;
            slave4.ADR = muxed_out.ADR;
            slave4.CYC = muxed_out.CYC;
            slave4.WE = muxed_out.WE;
            slave4.DAT_O = muxed_out.DAT_O;

            slave0.STB = 0;
            slave0.ADR = 0;
            slave0.CYC = 0;
            slave0.WE =  0;
            slave0.DAT_O = 0;

            slave2.STB = 0;
            slave2.ADR = 0;
            slave2.CYC = 0;
            slave2.WE =  0;
            slave2.DAT_O = 0;

            slave3.STB = 0;
            slave3.ADR = 0;
            slave3.CYC = 0;
            slave3.WE =  0;
            slave3.DAT_O = 0;

            slave1.STB = 0;
            slave1.ADR = 0;
            slave1.CYC = 0;
            slave1.WE =  0;
            slave1.DAT_O = 0;

            slave5.STB = 0;
            slave5.ADR = 0;
            slave5.CYC = 0;
            slave5.WE =  0;
            slave5.DAT_O = 0;

            muxed_out.ACK = slave4.ACK;
            muxed_out.ERR = slave4.ERR;
            muxed_out.RTY = slave4.RTY;
            muxed_out.DAT_I = slave4.DAT_I;
            
        end
        4'h5:
        begin
            slave5.STB = muxed_out.STB;
            slave5.ADR = muxed_out.ADR;
            slave5.CYC = muxed_out.CYC;
            slave5.WE = muxed_out.WE;
            slave5.DAT_O = muxed_out.DAT_O;

            slave0.STB = 0;
            slave0.ADR = 0;
            slave0.CYC = 0;
            slave0.WE =  0;
            slave0.DAT_O = 0;

            slave2.STB = 0;
            slave2.ADR = 0;
            slave2.CYC = 0;
            slave2.WE =  0;
            slave2.DAT_O = 0;

            slave3.STB = 0;
            slave3.ADR = 0;
            slave3.CYC = 0;
            slave3.WE =  0;
            slave3.DAT_O = 0;

            slave4.STB = 0;
            slave4.ADR = 0;
            slave4.CYC = 0;
            slave4.WE =  0;
            slave4.DAT_O = 0;

            slave1.STB = 0;
            slave1.ADR = 0;
            slave1.CYC = 0;
            slave1.WE =  0;
            slave1.DAT_O = 0;

            muxed_out.ACK = slave5.ACK;
            muxed_out.ERR = slave5.ERR;
            muxed_out.RTY = slave5.RTY;
            muxed_out.DAT_I = slave5.DAT_I;

        end
    endcase
end

endmodule