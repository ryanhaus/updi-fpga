#include "updi_phy.hpp"
#include <string>

#define BAUD_RATE BaudRate::BAUD_57600
#define BREAK_BAUD_RATE BaudRate::BAUD_300

// Constructor for updi_phy class
updi_phy::updi_phy(std::string port)
{
	// open and configure serial port
	this->ser.Open(port);
	this->ser.SetBaudRate(BAUD_RATE);
	this->ser.SetParity(LibSerial::Parity::PARITY_EVEN);
	this->ser.SetStopBits(LibSerial::StopBits::STOP_BITS_2);

	// instantiate RX/TX FIFO queues
	this->rx_fifo = std::queue<uint8_t>();
	this->tx_fifo = std::queue<uint8_t>();
}

// Destructor for updi_phy class
updi_phy::~updi_phy()
{
	this->ser.Close();
}

// Scans top module ports and updates FIFOs accordingly. Also performs serial operations, if necessary.
// Returns number of clock cycles until next tick should be, to simulate delays due to double breaks etc.
uint64_t updi_phy::tick(Vtop* top)
{
	if (top->double_break_start)
	{
		// start a double break
		this->ser.SetBaudRate(BREAK_BAUD_RATE);
		this->ser.WriteByte((uint8_t)0x00);
		this->ser.SetBaudRate(BAUD_RATE);

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
		while (this->tx_fifo.size() > 0)
		{
			uint8_t tx_val = this->tx_fifo.front();
			this->ser.WriteByte(tx_val);

			this->tx_fifo.pop();
		}

		// handle RX reads
		while (this->ser.IsDataAvailable())
		{
			uint8_t rx_val;
			this->ser.ReadByte(rx_val, 100);

			this->rx_fifo.push(rx_val);
		}
	}

	return 1;
}
