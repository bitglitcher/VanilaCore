
package global_pkg;


typedef enum logic[3:0] { REG_SRC, I_IMM_SRC } sr2_src_t;
typedef enum logic[3:0] { ALU_INPUT, U_IMM_SRC, AUIPC_SRC, LOAD_SRC, PC_SRC } regfile_src_t;
typedef enum logic[3:0] { J_IMM, B_IMM, I_IMM } jmp_target_src_t;

typedef enum logic[3:0] { MEM_NONE, LOAD_DATA, STORE_DATA} memory_operation_t;


endpackage