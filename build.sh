yosys -D LEDS_NR=6 -D OSC_TYPE_OSC -D INV_BTN=1 -D CPU_FREQ=27 -D BAUD_RATE=115200 -D NUM_HCLK=5 -D RISCV_MEM_88K -p "read_verilog alu.v control_unit.v core.v instr_mem.v led_driver.v logger.v pc.v regfile.v top.v uart_tx.v; synth_gowin -json rv32i.json -family gw2a"
nextpnr-himbaechel --json rv32i.json --write pnr_rv32i.json --device GW2AR-LV18QN88C8/I7 --vopt cst=tangnano20k.cst --vopt family=GW2A-18C
gowin_pack -d GW2A-18C -o rv32i.fs pnr_rv32i.json
sudo openFPGALoader -b tangnano20k rv32i.fs
