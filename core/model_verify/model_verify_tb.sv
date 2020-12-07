

module model_verify();

//Import important C functions
//import "DPI-C" function void riscv_initialise();
//import "DPI-C" function void memory_initialise();
//import "DPI-C" function void riscv_run();
//import "DPI-C" function void riscv_dump();
//import "DPI-C" function void memory_run();
//import "DPI-C" function void riscv_finish();
//import "DPI-C" function void memory_finish();

logic clk;
logic rst;

WB4 inst_bus(clk, rst);
WB4 data_bus(clk, rst);


ram_wb MEMORY_INST(.wb(inst_bus));
ram_wb MEMORY_DATA(.wb(data_bus));

logic [31:0] debug_registers [31:0];
logic pre_execution;
logic post_execution;
logic [31:0] pc_debug;

core CORE_0
    (
        .inst_bus(inst_bus),
        .data_bus(data_bus),
        //Debug port
        .debug_registers(debug_registers),
        .pre_execution(pre_execution),
        .post_execution(post_execution),
        .pc_debug(pc_debug)
    );

task automatic print_registers();
    $display("----------REGISTER DEBUG BEGIN----------");
    for (int i = 0; i < 32;i++) begin
        $display("R%02d: 0x%08x", i, debug_registers[i]);
    end
    $display("PC: 0x%08x", pc_debug);
    $display("----------REGISTER DEBUG END----------");
endtask//Probe

always@(posedge clk)
begin
    if(pre_execution)
    begin
        $display("--------------------PRE EXECUTION--------------------");
        print_registers();
    end
    else if(post_execution)
    begin
        $display("--------------------POST EXECUTION--------------------");
        print_registers();
    end
end

initial begin
    //Begin of reset secuence
    $display("----------BEGIN RESET SEQUENCE----------");
    clk <= 0;
    rst <= 0;
    #10
    clk <= 1;
    rst <= 1;
    #10
    clk <= 0;
    #10
    clk <= 1;
    rst <= 0;
    $display("----------END RESET SEQUENCE----------");
    //End of reset secuence
    forever begin
        #10 clk = ~clk;
    end
end


endmodule