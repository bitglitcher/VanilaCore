all: terminal.o core.o memory.o device.o bus.o moxie_emu




terminal.o: terminal/terminal.cpp terminal/terminal.h
	g++ terminal/terminal.cpp -c

core.o: core/core.cpp core/core.h core/inset.h
	g++ core/core.cpp -c

memory.o: memory/memory.cpp memory/memory.h
	g++ memory/memory.cpp -c

bus.o: bus/bus.cpp bus/bus.h
	g++ bus/bus.cpp -c

device.o: device/device.cpp device/device.h
	g++ device/device.cpp -c

moxie_emu: main.cpp terminal.o memory.o core.o bus.o device.o
	g++ main.cpp terminal.o memory.o core.o bus.o device.o -o moxie_emu

clean:
	rm *.o
	rm ROM.bin

ROM.bin: script.ld test.s 
	moxiebox-as test.s -o test.o
	moxiebox-ld test.o --oformat=binary -T script.ld 

test: ROM.bin
	xxd ROM.bin
	./moxie_emu