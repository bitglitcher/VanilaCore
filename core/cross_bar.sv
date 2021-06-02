

//This device assumes that the clock of every master and slave is the same.
module cross_bar
(
    //Master Devices
    WB4.slave master_1,
    WB4.slave master_2,

    //Slave Devices
    WB4.master slave_0,
    WB4.master slave_1,
    WB4.master slave_2,
    WB4.master slave_3,
    WB4.master slave_4,
    WB4.master slave_5
);

parameter MEMORY_START = 32'h00000000;
parameter MEMORY_END =   32'h000fffff;

//Device Region
parameter SLAVE_0_BASE   = 32'h00100000;
parameter SLAVE_0_LENGHT = 32'h00100000;
parameter SLAVE_1_BASE   = 32'h00100000;
parameter SLAVE_1_LENGHT = 32'h00100000;
parameter SLAVE_2_BASE   = 32'h00100010;
parameter SLAVE_2_LENGHT = 32'h00100010;
parameter SLAVE_3_BASE   = 32'h00100010;
parameter SLAVE_3_LENGHT = 32'h00100010;
parameter SLAVE_4_BASE   = 32'h00100020;
parameter SLAVE_4_LENGHT = 32'h00100020;
parameter SLAVE_5_BASE   = 32'h00100024;
parameter SLAVE_5_LENGHT = 32'h00100024;

wire [31:0] addr_buses [1:0] = {master_1.ADR, master_2.ADR};
logic [2:0] slave_index [1:0]; //Slave that the master wants to communicate with

//Arbiter
genvar i;
generate
    for (i = 0; i < 2; i++) begin : arbiter_logic
        always_comb begin
            if(addr_buses [i] >= SLAVE_0_BASE && addr_buses [i] <= SLAVE_0_LENGHT)
            begin
                slave_index [i] = 0;
            end
            else if(addr_buses [i] >= SLAVE_1_BASE && addr_buses [i] <= SLAVE_1_LENGHT)
            begin
                slave_index [i] = 1;
            end
            else if(addr_buses [i] >= SLAVE_2_BASE && addr_buses [i] <= SLAVE_2_LENGHT)
            begin
                slave_index [i] = 2;
            end
            else if(addr_buses [i] >= SLAVE_3_BASE && addr_buses [i] <= SLAVE_3_LENGHT)
            begin
                slave_index [i] = 3;
            end
            else if(addr_buses [i] >= SLAVE_4_BASE && addr_buses [i] <= SLAVE_4_LENGHT)
            begin
                slave_index [i] = 4;
            end
            else if(addr_buses [i] >= SLAVE_5_BASE && addr_buses [i] <= SLAVE_5_LENGHT)
            begin
                slave_index [i] = 5;
            end
        end        
    end
endgenerate


//These are used to choose the slave device
reg [2:0] master_mux_sel_0;
reg [2:0] master_mux_sel_1;

reg CYC_0;
reg CYC_1;

always @(posedge master_1.clk ) begin
    if(master_1.CYC)
    begin
        if(master_1.CYC) //Check that the other master doesnt want to use the same bus
        begin
            if(slave_index[0] != slave_index[1])
            begin
                //Other Master device using a different bus
                CYC_0 = 1'b1;
                master_mux_sel_0 = slave_index[0];
            end
            else
            begin
                //Wait until it uses another bus
                CYC_0 = 1'b0;
            end
        end
        else
        begin
            //Use any bus because the other master is not using any device
            CYC_0 = 1'b0;
        end
    end
    else
    begin
        CYC_0 = 1'b0;
    end
end


WB4 master_1_out();
WB4 master_2_out();

wb_bus_ctrl_cmb wb_bus_ctrl_cmb_0_0
(
    .CYC(), //This signals that a cycle will begin
    .en(),
    
    //Wishbone bus
    .wb_in(master_1),
    .wb_out(master_1_out)
);

wb_bus_ctrl_cmb wb_bus_ctrl_cmb_0_1
(
    .CYC(), //This signals that a cycle will begin
    .en(),
    
    //Wishbone bus
    .wb_in(master_2),
    .wb_out(master_2_out)
);

WB4 slave0_m_1();
WB4 slave1_m_1();
WB4 slave2_m_1();
WB4 slave3_m_1();
WB4 slave4_m_1();
WB4 slave5_m_1();

wb_master_mux wb_master_mux_0
(
    .sel(master_mux_sel_0),
    .slave0(slave0_m_1), //Slave BUS 0
    .slave1(slave1_m_1), //Slave BUS 1
    .slave2(slave2_m_1), //Slave BUS 2
    .slave3(slave3_m_1), //Slave BUS 3
    .slave4(slave4_m_1), //Slave BUS 4
	.slave5(slave5_m_1), //Slave BUS 5
    .muxed_out(master_1_out) //This bus is the output of the multiplexer
);

WB4 slave0_m_2();
WB4 slave1_m_2();
WB4 slave2_m_2();
WB4 slave3_m_2();
WB4 slave4_m_2();
WB4 slave5_m_2();

wb_master_mux wb_master_mux_1
(
    .sel(master_mux_sel_1),
    .slave0(slave0_m_2), //Slave BUS 0
    .slave1(slave1_m_2), //Slave BUS 1
    .slave2(slave2_m_2), //Slave BUS 2
    .slave3(slave3_m_2), //Slave BUS 3
    .slave4(slave4_m_2), //Slave BUS 4
	.slave5(slave5_m_2), //Slave BUS 5
    .muxed_out(master_2_out) //This bus is the output of the multiplexer
);




wb_mux wb_mux_0
(
    .sel(),
    .master0(slave0_m_1), //Master BUS 0
    .master1(slave0_m_2), //Master BUS 1
    .muxed_out(slave_0) //This bus is the output of the multiplexer
);

wb_mux wb_mux_1
(
    .sel(),
    .master0(slave1_m_1), //Master BUS 0
    .master1(slave1_m_2), //Master BUS 1
    .muxed_out(slave_1) //This bus is the output of the multiplexer
);

wb_mux wb_mux_2
(
    .sel(),
    .master0(slave2_m_1), //Master BUS 0
    .master1(slave2_m_2), //Master BUS 1
    .muxed_out(slave_2) //This bus is the output of the multiplexer
);

wb_mux wb_mux_3
(
    .sel(),
    .master0(slave3_m_1), //Master BUS 0
    .master1(slave3_m_2), //Master BUS 1
    .muxed_out(slave_3) //This bus is the output of the multiplexer
);

wb_mux wb_mux_4
(
    .sel(),
    .master0(slave4_m_1), //Master BUS 0
    .master1(slave4_m_2), //Master BUS 1
    .muxed_out(slave_4) //This bus is the output of the multiplexer
);

wb_mux wb_mux_5
(
    .sel(),
    .master0(slave5_m_1), //Master BUS 0
    .master1(slave5_m_2), //Master BUS 1
    .muxed_out(slave_5) //This bus is the output of the multiplexer
);

endmodule