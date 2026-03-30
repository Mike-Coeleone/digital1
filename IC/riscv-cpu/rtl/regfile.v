// 32 × 32位 寄存器堆
// 双端口异步读，单端口同步写
// x0 固定为0，写x0被忽略
module regfile(
    input               clk,        // 时钟
    input       [4:0]   rs1_addr_i, // rs1 读地址
    input       [4:0]   rs2_addr_i, // rs2 读地址
    input       [4:0]   wb_addr_i,  // 写回地址
    input       [31:0]  wb_data_i,  // 写回数据
    input               wb_en_i,    // 写使能
    output reg  [31:0]  rs1_data_o, // rs1 读数据
    output reg  [31:0]  rs2_data_o  // rs2 读数据
);

// 32个32位寄存器
reg [31:0] rf[31:0];

// x0 恒为0，所以不存储，直接输出0
always @(*) begin
    if (rs1_addr_i == 5'd0) begin
        rs1_data_o = 32'h0000_0000;
    end else begin
        rs1_data_o = rf[rs1_addr_i];
    end
end

always @(*) begin
    if (rs2_addr_i == 5'd0) begin
        rs2_data_o = 32'h0000_0000;
    end else begin
        rs2_data_o = rf[rs2_addr_i];
    end
end

// 同步写，忽略写x0
always @(posedge clk) begin
    if (wb_en_i && wb_addr_i != 5'd0) begin
        rf[wb_addr_i] <= wb_data_i;
    end
end

endmodule
