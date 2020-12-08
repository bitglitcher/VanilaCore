

all:
	riscv64-unknown-elf-gcc -Wl,--print-memory-usage -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -Wall -pedantic -Wextra crt0.s bootloader.c -O0 -S
	riscv64-unknown-elf-gcc -Wl,--print-memory-usage -T script.ld -lm -lgcc -static -march=rv32i -mabi=ilp32 -nostartfiles -ffreestanding -Wall -pedantic -Wextra crt0.s bootloader.c -O0 -o boot.o
	riscv64-unknown-elf-objcopy -F elf32-littleriscv boot.o -O binary ROM.bin
	python3 generate_rom.py > ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/modelsim/ROM.hex
	cp ROM.hex /mnt/c/Users/camin/Documents/VanilaCore/core/c_code/ROM.hex