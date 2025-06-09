#include <string>
#include <queue>
#include <cstdint>
#include "Vtop.h"

// https://manpages.ubuntu.com/manpages/focal/man1/LibSerial.1.html
#include "libserial/SerialPort.h"
using namespace LibSerial;

// Acts as a replacement for the updi_phy module, uses libserial to transmit/receive serial data
class updi_phy
{
	public:
		updi_phy(std::string);
		~updi_phy();

		void tick_fifo(Vtop*);
		void tick_fifo_flags(Vtop*);
		void tick_uart(Vtop*);

	private:
		SerialPort* ser;
		std::string port;

		std::queue<uint8_t> rx_fifo;
		std::queue<uint8_t> tx_fifo;
		
		uint64_t ticks;
		uint64_t last_tx_mod_tick;

		void open_serial(BaudRate);
};
