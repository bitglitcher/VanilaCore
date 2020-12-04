

interface #(
        parameter I_LEN = 32,
        parameter NRET = 1,
        parameter XLEN = 32

    ) FORMAL;
    //Instruction Metadata
    logic [NRET        - 1 : 0] rvfi_valid,
    logic [NRET *   64 - 1 : 0] rvfi_order,
    logic [NRET * ILEN - 1 : 0] rvfi_insn,
    logic [NRET        - 1 : 0] rvfi_trap,
    logic [NRET        - 1 : 0] rvfi_halt,
    logic [NRET        - 1 : 0] rvfi_intr,
    logic [NRET * 2    - 1 : 0] rvfi_mode,
    logic [NRET * 2    - 1 : 0] rvfi_ixl,

    //Integer read and write
    logic [NRET *    5 - 1 : 0] rvfi_rs1_addr,
    logic [NRET *    5 - 1 : 0] rvfi_rs2_addr,
    logic [NRET * XLEN - 1 : 0] rvfi_rs1_rdata,
    logic [NRET * XLEN - 1 : 0] rvfi_rs2_rdata,

    //Program Counter
    logic [NRET * XLEN - 1 : 0] rvfi_pc_rdata,
    logic [NRET * XLEN - 1 : 0] rvfi_pc_wdata,

    //Memory Access
    logic [NRET * XLEN   - 1 : 0] rvfi_mem_addr,
    logic [NRET * XLEN/8 - 1 : 0] rvfi_mem_rmask,
    logic [NRET * XLEN/8 - 1 : 0] rvfi_mem_wmask,
    logic [NRET * XLEN   - 1 : 0] rvfi_mem_rdata,
    logic [NRET * XLEN   - 1 : 0] rvfi_mem_wdata

endinterface //FORMAL