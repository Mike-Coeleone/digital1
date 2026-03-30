// 分支跳转测试: beq bne jal jalr
`timescale 1ns/1ps

module top;

reg clk;
reg rstn;

// 指令存储器
reg [31:0] imem[0:63];
wire [31:0] imem_addr;
wire [31:0] imem_rdata = imem[imem_addr >> 2];

// 数据存储器
reg [31:0] dmem[0:63];
wire [31:0] dmem_addr;
wire [31:0] dmem_wdata;
wire         dmem_we;
wire [31:0] dmem_rdata = dmem[dmem_addr >> 2];

always @(posedge clk) begin
    if (dmem_we) begin
        dmem[dmem_addr >> 2] <= dmem_wdata;
    end
end

// 例化CPU
cpu_top #(.RESET_PC(32'h0000_0000)) cpu_inst(
    .clk(clk),
    .rstn(rstn),
    .imem_addr_o(imem_addr),
    .imem_data_i(imem_rdata),
    .dmem_addr_o(dmem_addr),
    .dmem_wdata_o(dmem_wdata),
    .dmem_we_o(dmem_we),
    .dmem_rdata_i(dmem_rdata)
);

// 生成时钟
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// 测试程序：
// 0: addi x1, x0, 1      x1 = 1
// 4: addi x2, x0, 1      x2 = 1
// 8: beq  x1, x2, 8       相等，跳转到 8+4+(8<<2) = 44 = 0x2c → x1 = x1 + 1 → 最终 x1=2
// c: addi x1, x1, 100
// 10: bne x1, x2, 8      不相等，跳转 → 循环
initial begin
    imem[0] = 32'h00100093;  // addi x1, x0, 1
    imem[1] = 32'h00100113;  // addi x2, x0, 1
    imem[2] = 32'h00208463;  // beq x1, x2, 8
    imem[3] = 32'h06408093;  // addi x1, x1, 100 (不跳才会执行)
    imem[4] = 32'h00111463;  // bne x1, x2, 8
    imem[5] = 32'h00000013;  // nop
    $dumpfile("jump_test_branches.vcd");
    $dumpvars(0, top);
end

// 复位和运行
initial begin
    rstn = 0;
    #20 rstn = 1;
    #300 $display("=== Branch Jump Testing Done ===");
    $display("Expected final x1 = 2");
    #300 $finish;
end

endmodule
