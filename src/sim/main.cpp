#include "verilated.h"
#include "Vtb_updi_interface.h"

int main(int argc, char** argv)
{
    Verilated::debug(0);
    // const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
	VerilatedContext ctx = new VerilatedContext;
    ctx->traceEverOn(true);
    ctx->commandArgs(argc, argv);

    //const std::unique_ptr<Vtb_updi_interface> topp{new Vtb_updi_interface{contextp.get(), "tb_updi_interface"}};
	Vupdi_programmer top = new Vupdi_programmer;

    // Simulate until $finish
    top->final();
    ctx->statsPrintSummary();

    return 0;
}
