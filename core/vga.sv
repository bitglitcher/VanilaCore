interface VGA();
    logic v_sync;
    logic h_sync;
    logic r;
    logic g;
    logic b;
    modport output_int(
        output v_sync,
        output h_sync,
        output r,
        output g,
        output b
        );

endinterface //VGA