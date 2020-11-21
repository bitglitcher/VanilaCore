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

    printf("Testing ALU..\n");

    for (size_t i = 0; i < INT16_MAX; i++)
    {
        //Testing ADD
        TestCase* test_case;
        test_case = &test_cases[0];
        alu->ra_d  = i;
        alu->rb_d  = i;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (i + i))
        {
            printf("ADD: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (i + i));
            printf("ADD: fail\n");
        }

        //Testing ADD
        test_case = &test_cases[0];
        alu->ra_d  = -i;
        alu->rb_d  = i;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (i + (-i)))
        {
            printf("ADD: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (-i + i));
            printf("ADD: fail\n");
        }

        //Testing SUB
        test_case = &test_cases[1];
        alu->ra_d  = i;
        alu->rb_d  = i;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (i - i))
        {
            printf("SUB: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (i - i));
            printf("SUB: fail\n");
        }
        //Testing SUB
        test_case = &test_cases[1];
        alu->ra_d  = -i;
        alu->rb_d  = i;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (-i - i))
        {
            printf("SUB: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (-i - i));
            printf("SUB: fail\n");
        }
        
        //Testing SLL
        test_case = &test_cases[2];
        alu->ra_d  = i;
        alu->rb_d  = i;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (1 << 2))
        {
            printf("SLL: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (i << i));
            printf("SLL: fail\n");
        }

        //Testing SLT
        test_case = &test_cases[3];
        alu->ra_d  = -i;
        alu->rb_d  = 23214;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == 1)
        {
            printf("STL: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, ((-i < 23214) ? 1 : 0));
            printf("STL: fail\n");
        }

        //Testing SLTU
        test_case = &test_cases[4];
        alu->ra_d  = 1;
        alu->rb_d  = 2;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == 1)
        {
            printf("STLU: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, 1);
            printf("STLU: fail\n");
        }

        //Testing XOR
        test_case = &test_cases[5];
        alu->ra_d  = 1;
        alu->rb_d  = 2;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (1 ^ 2))
        {
            printf("XOR: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (1 ^ 2));
            printf("XOR: fail\n");
        }

        //Testing SRL
        test_case = &test_cases[6];
        alu->ra_d  = 1;
        alu->rb_d  = 2;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (1 >> 2))
        {
            printf("SRL: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (1 >> 2));
            printf("SRL: fail\n");
        }

        //Testing SRA
        test_case = &test_cases[7];
        alu->ra_d  = 1;
        alu->rb_d  = 2;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (1 >> 2))
        {
            printf("SRA: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (1 >> 2));
            printf("SRA: fail\n");
        }

        //Testing OR
        test_case = &test_cases[8];
        alu->ra_d  = 1;
        alu->rb_d  = 2;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (1 | 2))
        {
            printf("OR: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (1 | 2));
            printf("OR: fail\n");
        }

        //Testing AND
        test_case = &test_cases[9];
        alu->ra_d  = 1;
        alu->rb_d  = 2;	
        alu->func3  = test_case->func3;  	
        alu->func7  = test_case->func7;  	
        alu->eval();

        if(alu->rd_d == (1 & 2))
        {
            printf("AND: pass\n");
        }
        else
        {
            printf("Got %d expected %d\n", alu->rd_d, (1 & 2));
            printf("AND: fail\n");
        }
    }
    
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
