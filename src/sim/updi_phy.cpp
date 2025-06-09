#include "updi_phy.hpp"
#include <string>

// Constructor for updi_phy class
updi_phy::updi_phy(std::string port)
{
	// open serial port
	this->ser.Open(port);
	this->ser.SetBaudRate(BaudRate::BAUD_57600);

	// instantiate RX/TX FIFO queues
	this->rx_fifo = std::queue<uint8_t>();
	this->tx_fifo = std::queue<uint8_t>();
}

// Scans top module ports and updates FIFOs accordingly. Also performs serial operations, if necessary.
void updi_phy::tick(Vtop* top)
{
	// TODO
}
