#include "updi_phy.hpp"
#include <string>
#include <vector>
#include <chrono>
#include <thread>
#include <stdio.h>

using namespace std::this_thread;
using namespace std::chrono;

#define BAUD_RATE BaudRate::BAUD_57600
#define BREAK_BAUD_RATE BaudRate::BAUD_300

// Constructor for updi_phy class
updi_phy::updi_phy(std::string port)
{
	// open and configure serial port
	this->port = port;
	this->open_serial(BAUD_RATE);

	// instantiate RX/TX FIFO queues
	this->rx_fifo = std::queue<uint8_t>();
	this->tx_fifo = std::queue<uint8_t>();
}

// Destructor for updi_phy class
updi_phy::~updi_phy()
{
	this->ser->Close();
	delete this->ser;
}

// Opens and configures a serial port at a given baud rate
void updi_phy::open_serial(BaudRate baud)
{
	if (this->ser != nullptr)
	{
		delete this->ser;
	}

	this->ser = new SerialPort(
		this->port,
		baud,
		CharacterSize::CHAR_SIZE_DEFAULT,
		FlowControl::FLOW_CONTROL_DEFAULT,
		Parity::PARITY_EVEN,
		StopBits::STOP_BITS_2
	);
}

// Scans top module ports and updates FIFOs accordingly. Also performs serial operations, if necessary.
// Returns number of clock cycles until next tick should be, to simulate delays due to double breaks etc.
uint64_t updi_phy::tick(Vtop* top)
{
	// these are used to figure out when to flush the TX buffer
	static uint64_t ticks = 0;
	static uint64_t last_tx_mod_tick = 0;
	ticks++;

	// handle interfaces
	if (top->double_break_start)
	{
		// start a double break
		this->ser->Close();
		this->open_serial(BREAK_BAUD_RATE);

		sleep_for(milliseconds(50));

		this->ser->WriteByte((uint8_t)0x00);

		sleep_for(milliseconds(50));

		this->ser->Close();
		this->open_serial(BAUD_RATE);

		top->double_break_busy = 1;
		return 1000;
	}
	else if (top->double_break_busy)
	{
		// indicate end of double break
		top->double_break_busy = 0;
		top->double_break_done = 1;
	}
	else if (top->double_break_done)
	{
		// reset done flag
		top->double_break_done = 0;
	}
	else
	{
		// handle TX FIFO interface
		top->uart_tx_fifo_full = (this->tx_fifo.size() >= 16);

		if (top->uart_tx_fifo_wr_en && !top->uart_tx_fifo_full)
		{
			uint8_t tx_val = (uint8_t)top->uart_tx_fifo_data_in;
			last_tx_mod_tick = ticks;
			this->tx_fifo.push(tx_val);
		}

		// handle RX FIFO interface
		top->uart_rx_fifo_empty = (this->rx_fifo.size() == 0);

		if (top->uart_rx_fifo_rd_en && !top->uart_rx_fifo_empty)
		{
			uint8_t rx_val = this->rx_fifo.front();
			this->rx_fifo.pop();

			top->uart_rx_fifo_data_out = rx_val;
		}

		// handle TX writes
		if (this->tx_fifo.size() > 0 && (ticks - last_tx_mod_tick) >= 100)
		{
			// fill array with FIFO values
			std::vector<uint8_t> tx_bytes;

			printf("Writing bytes: [");

			while (this->tx_fifo.size() > 0)
			{
				uint8_t tx_val = this->tx_fifo.front();
				tx_bytes.push_back(tx_val);

				this->tx_fifo.pop();

				printf(" %02X", tx_val);
			}

			printf(" ]\n");

			// write values
			this->ser->Write(tx_bytes);

			// read echo
			std::vector<uint8_t> tx_echo_bytes;
			this->ser->Read(tx_echo_bytes, tx_bytes.size());
		}

		// handle RX reads
		while (this->ser->IsDataAvailable())
		{
			uint8_t rx_val;
			this->ser->ReadByte(rx_val, 100);

			printf("Read 0x%02X\n", rx_val);

			this->rx_fifo.push(rx_val);
		}
	}

	return 1;
}
