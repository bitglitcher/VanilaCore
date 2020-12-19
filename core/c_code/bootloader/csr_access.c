

inline int read_csr(int csr_num) __attribute__((always_inline)) {
    int result;
    asm("csrr %0, %1" : "=r"(result) : "I"(csr_num));
    return result; 
}
