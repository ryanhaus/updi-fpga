# updi-fpga
Programming an ATtiny816 via UPDI using an FPGA.

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
