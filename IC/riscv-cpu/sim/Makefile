# RISC-V CPU Simulation Makefile
# iverilog + vvp + gtkwave

RTL_DIR = ../rtl

all: add_test

# 编译运行加法测试
add_test:
	iverilog -o add_test.vvp \
		$(RTL_DIR)/pc.v \
		$(RTL_DIR)/regfile.v \
		$(RTL_DIR)/alu.v \
		$(RTL_DIR)/hazard_detect.v \
		$(RTL_DIR)/forward.v \
		$(RTL_DIR)/decode.v \
		$(RTL_DIR)/execute.v \
		$(RTL_DIR)/mem_access.v \
		$(RTL_DIR)/writeback.v \
		$(RTL_DIR)/branch_jump.v \
		$(RTL_DIR)/cpu_top.v \
		add_test.v
	vvp add_test.vvp

# lw/sw 存储加载测试
lw_sw_test:
	iverilog -o lw_sw_test.vvp \
		$(RTL_DIR)/pc.v \
		$(RTL_DIR)/regfile.v \
		$(RTL_DIR)/alu.v \
		$(RTL_DIR)/hazard_detect.v \
		$(RTL_DIR)/forward.v \
		$(RTL_DIR)/decode.v \
		$(RTL_DIR)/execute.v \
		$(RTL_DIR)/mem_access.v \
		$(RTL_DIR)/writeback.v \
		$(RTL_DIR)/branch_jump.v \
		$(RTL_DIR)/cpu_top.v \
		lw_sw_test.v
	vvp lw_sw_test.vvp

# 跳转测试
jump_test:
	iverilog -o jump_test.vvp \
		$(RTL_DIR)/pc.v \
		$(RTL_DIR)/regfile.v \
		$(RTL_DIR)/alu.v \
		$(RTL_DIR)/hazard_detect.v \
		$(RTL_DIR)/forward.v \
		$(RTL_DIR)/decode.v \
		$(RTL_DIR)/execute.v \
		$(RTL_DIR)/mem_access.v \
		$(RTL_DIR)/writeback.v \
		$(RTL_DIR)/branch_jump.v \
		$(RTL_DIR)/cpu_top.v \
		jump_test.v
	vvp jump_test.vvp

# 分支跳转测试
jump_test_branches:
	iverilog -o jump_test_branches.vvp \
		$(RTL_DIR)/pc.v \
		$(RTL_DIR)/regfile.v \
		$(RTL_DIR)/alu.v \
		$(RTL_DIR)/hazard_detect.v \
		$(RTL_DIR)/forward.v \
		$(RTL_DIR)/decode.v \
		$(RTL_DIR)/execute.v \
		$(RTL_DIR)/mem_access.v \
		$(RTL_DIR)/writeback.v \
		$(RTL_DIR)/branch_jump.v \
		$(RTL_DIR)/cpu_top.v \
		jump_test_branches.v
	vvp jump_test_branches.vvp

# 看波形
wave:
	gtkwave *.vcd &

clean:
	rm -f *.vvp *.vcd *.o

.PHONY: all clean wave jump_test add_test
