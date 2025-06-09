#include <cstdint>
#include "verilated.h"
#include "Vtop.h"
#include "verilated_fst_c.h"

#include "updi_phy.hpp"

#define MAX_TIME_PS 1000000
#define SERIAL_PORT "/dev/ttyUSB0"

VerilatedContext* ctx;
VerilatedFstC* m_trace;
Vtop* top;
updi_phy* phy;
uint64_t time_ps = 0;

// does a clock cycle
void clk()
{
	static int64_t phy_ctr = 0; // holds # of clock cycles until next PHY tick

	// low clock pulse
	top->clk = 0;
	top->eval();
	m_trace->dump(time_ps += 10);

	// high clock pulse
	top->clk = 1;
	top->eval();

	// handle PHY tick, if necessary
	if (--phy_ctr <= 0)
	{
		phy_ctr = (int64_t)phy->tick(top);
	}

	m_trace->dump(time_ps += 10);
}

int main(int argc, char** argv)
{
    Verilated::debug(0);
	ctx = new VerilatedContext;
    ctx->traceEverOn(true);
    ctx->commandArgs(argc, argv);

	top = new Vtop;

	m_trace = new VerilatedFstC;
	top->trace(m_trace, 99);
	m_trace->open("trace/top.fst");

	phy = new updi_phy(SERIAL_PORT);

	// reset
	top->rst = 1;
	clk();

	top->rst = 0;
	clk();

	// start
	top->start = 1;
	clk();

	top->start = 0;
	clk();

	while (time_ps < MAX_TIME_PS)
	{
		clk();
	}

    // Simulate until $finish
    top->final();
	m_trace->close();
    ctx->statsPrintSummary();

    return 0;
}
