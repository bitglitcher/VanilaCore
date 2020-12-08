

module model_verify();

//Import important C functions
import "DPI-C" function int riscv_initialise();
import "DPI-C" function int memory_initialise();
import "DPI-C" function void riscv_run();
import "DPI-C" function void riscv_reset();
import "DPI-C" function void riscv_dump();
import "DPI-C" function void memory_run();
import "DPI-C" function void riscv_finish();
import "DPI-C" function void memory_finish();
import "DPI-C" function int riscv_reg(int);
import "DPI-C" function int riscv_pc();
import "DPI-C" function void run_cycle();
import "DPI-C" function int get_cycle();

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
    for (int i = 0; i < 8;i++) begin
        $display("R%02d: 0x%08x\tR%02d: 0x%08x\tR%02d: 0x%08x\tR%02d: 0x%08x", i, debug_registers[i], i + 8, debug_registers[i + 8], i + 16, debug_registers[i + 16], i + 24, debug_registers[i + 24]);
    end
    $display("PC: 0x%08x", pc_debug);
    $display("----------REGISTER DEBUG END----------");
endtask//Probe

task automatic VerifyRegisterStates();
    $display("--------------------CHECKING REGISTER STATE--------------------");
    $display("Cycle: %d", get_cycle());
    riscv_dump();
    print_registers();
    //First the zero register
    assert(debug_registers [0] == 0)
    $display("Checking registers...");
    else $display("Error: Register R0 is not zero");
    for (int i = 0;i < 32;i++) begin
        //$display("Checking registers R%02d -> 0x%08x", i, debug_registers [i]);
        if(debug_registers [i] != riscv_reg(i))
        begin
            $display("Error: Incorrect Register R%02d Value. Got: 0x%08x, Expected: 0x%08x", i, debug_registers [i], riscv_reg(i));
            $stop;
        end
    end
endtask //automatic

int current_cycle = 0;
always@(posedge pre_execution or posedge post_execution)
begin
    if(pre_execution)
    begin
        $display("=========================================================================================================");
        $display("--------------------PRE EXECUTION--------------------");
        $display("Time: ", $time);
        $display("Checking Program Counter...");
        if(riscv_pc() != pc_debug)
        begin
            $display("Error: Wrong Program Counter Value. Got: 0x%08x, Expected 0x%08x",pc_debug , riscv_pc());
            $stop;
        end
        VerifyRegisterStates();
    end
    else if(post_execution)
    begin
        $display("--------------------POST EXECUTION--------------------");
        run_cycle();
        current_cycle = get_cycle();
        VerifyRegisterStates();
    end
end


initial begin
    $display("----------INITIALIZE C EMULATOR----------");
    if(memory_initialise())
    begin
        $display("Memory Initialized Correctly");
    end
    if(riscv_initialise())
    begin
        $display("RISCV Initalized Correctly");
    end
    $display("----------RESETING RISCV EMULATOR----------");
    riscv_reset();
    $display("----------FINISH RESETING RISCV EMULATOR----------");

    //Begin of reset secuence
    $display("----------BEGIN HARDWARE RESET SEQUENCE----------");
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
    $display("----------END HARDWARE RESET SEQUENCE----------");
    //End of reset secuence
    forever begin
        #10 clk = ~clk;
    end
end


endmodule