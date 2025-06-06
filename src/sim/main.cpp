#include <stdint.h>
#include "verilated.h"
#include "Vtop.h"
#include "verilated_fst_c.h"

#define MAX_TIME_PS 1000000

VerilatedContext* ctx;
VerilatedFstC* m_trace;
Vtop* top;
uint64_t time_ps = 0;

// does a clock cycle
void clk()
{
	top->clk = 0;
	top->eval();
	m_trace->dump(time_ps += 10);

	top->clk = 1;
	top->eval();
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

	// reset
	top->rst = 1;
	clk();

	top->rst = 0;
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
