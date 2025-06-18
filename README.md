# updi-fpga
Programming an ATtiny816 via UPDI using an FPGA.

## Overview
The top-level module has two modules contained inside of it, `updi_programmer` and `updi_phy`.<br/>
The `updi_programmer` module is responsible for all of the logic involved in programming the UPDI-capable microcontroller.<br/>
The `updi_phy` module is responsible for taking the input/output bytes from the programmer module and converting it into a half-duplex UART stream (i.e., UPDI). In addition, this module is responsible for performing 'double breaks', which effectively reset the UPDI chip.<br/>
The two modules interface with each other via FIFOs. A block diagram showing the design with a max depth of 2 is shown below:<br/>
![Block Diagram Image](images/block_diagram.png)

## Simulating
Verilator is used to simulate the design.<br/>
Run `make sim` to compile the simulation binary, or `make sim_run` to compile and run the simulation.<br/>
The assumptions of the simulation are that a USB to UART converter is plugged in on `/dev/ttyUSB0`, and a UART to UPDI cable is attached to the output of this.

## Running Tests
Each individual test will be compiled to its own binary using Verilator.<br/>
Run `make test` to build the binaries, or `make test_run` to build and run all binaries.<br/>
For building/running individual tests, use `make test_NAME` and `make test_run_NAME`, respectively.

## Hardware
TBD
