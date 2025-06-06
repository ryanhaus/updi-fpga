#include <stdint.h>
#include "verilated.h"
#include "Vtop.h"
#include "verilated_fst_c.h"

int main(int argc, char** argv)
{
    Verilated::debug(0);
	VerilatedContext* ctx = new VerilatedContext;
    ctx->traceEverOn(true);
    ctx->commandArgs(argc, argv);

	Vtop* top = new Vtop;

	VerilatedFstC* m_trace = new VerilatedFstC;
	top->trace(m_trace, 99);
	m_trace->open("trace/top.fst");
	uint64_t time_ps = 0;

	for (int i = 0; i < 10000; i++)
	{
		top->clk = ~top->clk;
		top->eval();
		m_trace->dump(time_ps += 10);
	}

    // Simulate until $finish
    top->final();
	m_trace->close();
    ctx->statsPrintSummary();

    return 0;
}
