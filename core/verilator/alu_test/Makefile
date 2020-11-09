

all: alu

alu: ../../alu.sv
	verilator -Wall -cc ../../alu.sv --exe alu_test.cpp
	make -C obj_dir/ -j12 -f Valu.mk

test:
	./obj_dir/Valu