lint:
	verilator \
		-y src \
		src/*/*.sv \
		-sv \
		--lint-only \
		--top-module top

obj_dir/Vtb_%: src/test/tb_%.sv src/rtl/%.sv
	verilator \
		-y src \
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

test_srcs := $(wildcard src/test/*.sv)
test_names := $(patsubst src/test/%.sv,%,$(test_srcs))
test_objects := $(patsubst %,obj_dir/V%,$(test_names))

test: $(test_objects)

test_run: test
	mkdir -p trace
	$(foreach name,$(test_names),obj_dir/V$(name))
	
clean:
	rm -rf obj_dir
