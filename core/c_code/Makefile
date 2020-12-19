all:
	#riscv64-unknown-elf-as test.s  -march=rv32i -o test.o
	#riscv64-unknown-elf-ld -L="/mnt/c/Users/camin/Documents/opt/riscv/lib/gcc/riscv64-unknown-elf/10.2.0/rv32i/ilp32" -b elf32-littleriscv -m elf32lriscv -T script.ld test.o crt0.o -o test_linked.o
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align counter.s -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

test_calls:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding  crt0.s load_store_test.c -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

test:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align crt0.s test.c -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

soft_multiply:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align crt0.s soft_multiply.c -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

soft_div:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align crt0.s soft_div.c -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

soft_mod:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align crt0.s soft_mod.c -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

alu_test:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align alu_test.s -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

test_itoa:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align crt0.s test_itoa.c -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

calculate_pi:
	riscv64-unknown-elf-gcc -Wl,--print-memory-usage -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align crt0.s calculate_pi.c -O3 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

store_byte:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align store_byte.s -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex

csr_read:
	riscv64-unknown-elf-gcc -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -mstrict-align csr.s -O0 -o test_linked.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv test_linked.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex