all: test

# for converting Intel hex file to a file readable by Verilog
PROG_HEX := res/program.hex
PROG_MEM := src/generated/program.mem
generated_objects += $(PROG_MEM)
$(PROG_MEM): $(PROG_HEX)
	mkdir -p src/generated
	python3 src/util/program_convert.py $(PROG_HEX) $(PROG_MEM)

# for building all generated files
generated: $(generated_objects)

VERILATOR_FLAGS += -DROM_NAME=\"$(PROG_MEM)\"
VERILATOR_FLAGS += -DROM_SIZE=$(shell stat -L -c %s $(PROG_MEM))

# lint all verilog
lint:
	verilator \
		$(VERILATOR_FLAGS) \
		-y src/rtl \
		src/*/*.sv \
		-sv \
		--lint-only \
		--top-module top

# generate simulation binary
sim: obj_dir/Vtop
sim_run: sim
	mkdir -p trace
	./obj_dir/Vtop

obj_dir/Vtop: generated
	verilator \
		$(VERILATOR_FLAGS) \
		-y src/rtl \
		-sv \
		--cc \
		--build \
		--exe \
		--no-unlimited-stack \
		--trace-fst \
		--top-module top \
		src/rtl/*.sv \
		src/sim/main.cpp

# build testbench simulation programs w/ matching
obj_dir/Vtb_%: generated src/test/tb_%.sv src/rtl/%.sv
	mkdir -p trace
	verilator \
		$(VERILATOR_FLAGS) \
		-y src/rtl \
		src/*/*.sv \
		-sv \
		--cc \
		--main \
		--build \
		--exe \
		--timing \
		--trace-fst \
		--top-module tb_$* \
		--main-top-name tb_$*

test_%: obj_dir/Vtb_%
	@: # make doesn't recognize this unless there's something in the body for some ungodly reason

test_run_%: obj_dir/Vtb_%
	mkdir -p trace
	obj_dir/Vtb_$*

# for building and running all testbenches
test_srcs := $(wildcard src/test/*.sv)
test_names := $(patsubst src/test/%.sv,%,$(test_srcs))
test_objects := $(patsubst %,obj_dir/V%,$(test_names))

test: $(test_objects)

test_run: test
	mkdir -p trace
	$(foreach name,$(test_names),echo Running test $(name): ; obj_dir/V$(name) ;)
	
# remove obj_dir (build) folder
clean:
	rm -rf obj_dir src/generated trace
