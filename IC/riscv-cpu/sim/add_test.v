// 简单加法测试：add x1, x2, x3
`timescale 1ns/1ps

module top;

reg clk;
reg rstn;

// 指令存储器（简单模型，放几条测试指令）
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

// 测试指令：
// 0: addi x2, x0, 10   (x2 = 10)
// 4: addi x3, x0, 20   (x3 = 20)
// 8: add  x1, x2, x3    (x1 = 10 + 20 = 30)
// c: nop
initial begin
    imem[0] = 32'h00a00113;  // addi x2, x0, 10
    imem[1] = 32'h01400193;  // addi x3, x0, 20
    imem[2] = 32'h003100b3;  // add  x1, x2, x3
    imem[3] = 32'h00000013;  // nop
    imem[4] = 32'h00000000;
    $dumpfile("add_test.vcd");
    $dumpvars(0, top);
end

// 复位和运行
initial begin
    rstn = 0;
    #20 rstn = 1;
    #100 $display("Testing done. Check x1 should be 30");
    #100 $finish;
end

endmodule
