#include "Valu.h"
#include "verilated.h"
#include "stdint.h"


#define ADD  0b0000000000
#define SUB  0b0100000000
#define SLL  0b0000000001
#define SLT  0b0000000010
#define SLTU 0b0000000011
#define XOR  0b0000000100
#define SRL  0b0000000101
#define SRA  0b0100000101
#define OR   0b0000000110
#define AND  0b0000000111
struct TestCase 
{
    char* name;
    uint32_t rs1;
    uint32_t rs2;
    uint32_t expected;
    uint8_t func3;
    uint8_t func7;
};

TestCase test_cases[] {
    { .name = "add", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b000, .func7 = 0b0000000},
        { .name = "sub", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b000, .func7 = 0b0100000}, 
        { .name = "sll", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b001, .func7 = 0b0000000}, 
        { .name = "slt", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b010, .func7 = 0b0000000}, 
        { .name = "sltu", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b011, .func7 = 0b0000000}, 
        { .name = "xor", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b100, .func7 = 0b0000000}, 
        { .name = "srl", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b101, .func7 = 0b0000000}, 
        { .name = "sra", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b101, .func7 = 0b0100000}, 
        { .name = "or", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b110, .func7 = 0b0000000}, 
        { .name = "and", .rs1 = 0, .rs2 = 0, .expected = 0, .func3 = 0b111, .func7 = 0b0000000}
};

int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc, argv);
    Valu* alu = new Valu;
    alu->eval();

    printf("Testing ALU: test cases %u\n", UINT16_MAX);
    printf("Testing signed addition\n");
    //Testing ADD
    TestCase *test_case = &test_cases[0];
    for(uint32_t i = 0; i < UINT16_MAX;i += 512)
    {
        for(uint32_t x = 0; x < UINT16_MAX;x += 512)
        {

            alu->ra_d  = i;
            alu->rb_d  = x;	
            alu->func3  = test_case->func3;  	
            alu->func7  = test_case->func7;  	
            alu->eval();

            if (alu->rd_d != (i + x)) {
                printf("%s: fail (expected %04X but was %04X)\n",
                        test_case->name, (i + x),
                        alu->rd_d);
            }
        }
    }
    printf("ADD: pass\n");
    //Testing SUB
    test_case = &test_cases[1];
    for(uint32_t i = 0; i < UINT16_MAX;i += 512)
    {
        for(uint32_t x = 0; x < UINT16_MAX;x += 512)
        {

            alu->ra_d  = i;
            alu->rb_d  = x;	
            alu->func3  = test_case->func3;  	
            alu->func7  = test_case->func7;  	
            alu->eval();

            if (alu->rd_d != (i - x)) {
                printf("%s: fail (expected %04X but was %04X)\n",
                        test_case->name, (i + x),
                        alu->rd_d);
            }
        }
    }
    printf("SUB: pass\n");
    //Testing SSL
    test_case = &test_cases[2];
    for(uint32_t i = 0; i < 10;i += 1)
    {
        for(uint32_t x = 0; x < 10;x += 1)
        {

            alu->ra_d  = i;
            alu->rb_d  = x;	
            alu->func3  = test_case->func3;  	
            alu->func7  = test_case->func7;  	
            alu->eval();

            if (alu->rd_d != (i << (x & 0b11111))) {
                printf("%s: fail (expected %04X but was %04X)\n",
                        test_case->name, (i + x),
                        alu->rd_d);
            }
        }
    }
    printf("SSL: pass\n");
    // while (!Verilated::gotFinish()) { 
    //int num_test_cases = sizeof(test_cases)/sizeof(TestCase);
//
    //for(int k = 0; k < num_test_cases; k++) {
    //    TestCase *test_case = &test_cases[k];
//
    //    alu->ra_d  = test_case->rs1;
    //    alu->rb_d  = test_case->rs2;	
    //    alu->func3  = test_case->func3;  	
    //    alu->func7  = test_case->func7;  	
    //    alu->eval();
//
    //    if (alu->rd_d == test_case->expected) {
    //        printf("%s: passed\n", test_case->name);
    //    } else {
    //        printf("%s: fail (expected %04X but was %04X)\n",
    //                test_case->name, test_case->expected,
    //                alu->rd_d);
    //    }
    //}
    alu->final();
    delete alu;
    exit(0);
}
