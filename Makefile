# top-level Makefile for Verilator simulation

TOP       := top
VERILATOR := verilator
VER_FLAGS := --cc --build -Mdir obj_dir --top-module $(TOP) \
             -CFLAGS "-std=c++17 -O2" \
             -DCLK_FREQ=27000000 -DBAUD_RATE=115200 -DVM_TRACE -DSIM

# RTL (no tb here)
RTL       := alu.v control_unit.v core.v instr_mem.v \
             led_driver.v logger.v pc.v regfile.v \
             top.v uart_tx.v

.PHONY: all clean sim wave

all: sim

hw:
	yosys -D LEDS_NR=6 -D OSC_TYPE_OSC -D INV_BTN=1 -D CPU_FREQ=27 \
	-D BAUD_RATE=115200 -D NUM_HCLK=5 -D RISCV_MEM_88K -p \
	"read_verilog alu.v control_unit.v core.v instr_mem.v led_driver.v logger.v pc.v regfile.v top.v uart_tx.v; synth_gowin -json rv32i.json -family gw2a"
	nextpnr-himbaechel --json rv32i.json --write pnr_rv32i.json --device GW2AR-LV18QN88C8/I7 --vopt cst=tangnano20k.cst --vopt family=GW2A-18C
	gowin_pack -d GW2A-18C -o rv32i.fs pnr_rv32i.json
	sudo openFPGALoader -b tangnano20k rv32i.fs

sim:
	$(VERILATOR) --trace  $(VER_FLAGS) --exe top_tb.cpp $(RTL)
	./obj_dir/V$(TOP)

wave:
	gtkwave sim.vcd &

clean:
	rm -rf obj_dir *.vcd
