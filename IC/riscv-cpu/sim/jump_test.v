// 简单跳转测试
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

// 加载测试程序
initial begin
    $readmemh("jump_test.hex", imem);
    $dumpfile("jump_test.vcd");
    $dumpvars(0, top);
end

// 复位和运行
initial begin
    rstn = 0;
    #20 rstn = 1;
    #1000 $finish;
end

endmodule
