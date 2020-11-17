

module fetch_stm_tb();




fetch_stm fetch_stm_0
(
    .inst_bus(inst_bus),
    .PC_O(PC_O),
    .IR_O(IR_O),
    .execute(execute), //Wire to signal the execute cycle
    .jump_target(jump_target),
    .jump(jump),
    .stop_cycle(stop_cycle),
    .exit_ignore(exit_ignore)
);






endmodule