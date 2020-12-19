

int read_csr(int csr_num) {
    int result;
    asm("csrr %0, %1" : "=r"(result) : "I"(csr_num));
    return result; }

int main()
{
    int result = read_csr(123);
    *((int*)0x00100000) = result;
    return result;
}