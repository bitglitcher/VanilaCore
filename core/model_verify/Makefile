COPTS=-Wall -pedantic -O3 -g -shared
LOPTS=-lncurses

main : main.o memorymap.o ram.o riscv.o memory.o
	gcc -o main main.o memorymap.o ram.o riscv.o memory.o $(LOPTS) 

main.o : main.c memory.h riscv.h
	gcc -c main.c $(COPTS)

riscv.o : riscv.c riscv.h memorymap.h
	gcc -c riscv.c $(COPTS)

memory.o : memory.c memory.h
	gcc -c memory.c $(COPTS)

memorymap.o : memorymap.c memorymap.h region.h ram.h
	gcc -c memorymap.c $(COPTS)


ram.o : ram.c ram.h region.h
	gcc -c ram.c $(COPTS)

clean:
	rm -f *.o main events.log
