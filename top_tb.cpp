// top_tb.cpp
#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdint>
#include <iostream>

// Simulation time in picoseconds
static vluint64_t sim_time = 0;
// half‑period for 27 MHz clock: T = 1e12/27e6 ≈ 37037 ps, so half ≈ 18518 ps
static const vluint64_t CLK_HALF = 18518;

// period per UART bit at 115200 baud: ~8.68 μs ⇒ ~8.68e-6 s ⇒ 8.68e-6*1e12 ps
static const vluint64_t BAUD_PS = 1000000000000ULL / 115200;

struct UartRx
{
    Vtop *dut;
    bool last_txd = true;
    bool sampling = false;
    vluint64_t next_ps = 0;
    int bits = 0;
    uint16_t shift = 0;

    void maybe_start()
    {
        bool txd = dut->TXD;
        if (!sampling && last_txd && !txd)
        {
            // saw falling edge ⇒ schedule mid‑bit sampling
            sampling = true;
            next_ps = sim_time + BAUD_PS / 2;
            bits = 0;
            shift = 0;
        }
        last_txd = txd;
    }

    void tick()
    {
        if (sampling && sim_time >= next_ps)
        {
            bool txd = dut->TXD;
            shift |= (txd ? 1 : 0) << bits;
            bits++;
            next_ps += BAUD_PS;
            if (bits == 10)
            {
                // bit0=start, bits1–8=data, bit9=stop
                char c = (shift >> 1) & 0xFF;
                std::cout << c << std::flush;
                sampling = false;
            }
        }
    }
};

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    auto *dut = new Vtop;

#if VM_TRACE
    Verilated::traceEverOn(true);
    auto *tfp = new VerilatedVcdC;
    dut->trace(tfp, 10);
    tfp->open("sim.vcd");
#endif

    // Drive reset & clock
    dut->rst_i = 1;
    dut->clk = 0;

    // Pulse external reset for a few cycles
    for (int i = 0; i < 4; i++)
    {
        dut->clk = !dut->clk;
        sim_time += CLK_HALF;
        dut->eval();
#if VM_TRACE
        tfp->dump(sim_time);
#endif
    }
    dut->rst_i = 0;

    UartRx uart{dut};

    // run for ~10 ms: 10e-3 s ⇒ 10e-3*1e12 ps = 1e10 ps
    const vluint64_t SIM_END = 10000000000ULL;
    while (sim_time < SIM_END && !Verilated::gotFinish())
    {
        // clock toggle
        dut->clk = !dut->clk;
        sim_time += CLK_HALF;
        dut->eval();

        uart.maybe_start();
        uart.tick();

#if VM_TRACE
        tfp->dump(sim_time);
#endif
    }

#if VM_TRACE
    tfp->close();
#endif

    delete dut;
    return 0;
}
