// lw/sw 测试：sw 存储 then lw 加载
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
// 0: addi x1, x0, 100    x1 = 100
// 4: addi x2, x0, 200    x2 = 200
// 8: sw   x1, 0(x0)    存储 x1 到地址 0
// c: sw   x2, 4(x0)    存储 x2 到地址 4
// 10: lw   x3, 0(x0)    加载 x3 = 地址 0 = 100
// 14: lw   x4, 4(x0)    加载 x4 = 地址 4 = 200
// 18: add  x5, x3, x4    x5 = 100 + 200 = 300
initial begin
    imem[0] = 32'h06400093;  // addi x1, x0, 100
    imem[1] = 32'h0c800113;  // addi x2, x0, 200
    imem[2] = 32'h00102023;  // sw x1, 0(x0)
    imem[3] = 32'h00202223;  // sw x2, 4(x0)
    imem[4] = 32'h00002183;  // lw x3, 0(x0)
    imem[5] = 32'h00402203;  // lw x4, 4(x0)
    imem[6] = 32'h003102b3;  // add x5, x3, x4
    imem[7] = 32'h00000013;  // nop
    $dumpfile("lw_sw_test.vcd");
    $dumpvars(0, top);
end

// 复位和运行
initial begin
    rstn = 0;
    #20 rstn = 1;
    #200 $display("=== Testing done ===");
    #200 $display("Expected: x1=100, x2=200, x3=100, x4=200, x5=300");
    #200 $finish;
end

endmodule
