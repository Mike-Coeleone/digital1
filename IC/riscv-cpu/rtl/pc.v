// PC 程序计数器
// 支持正常增量、跳转、暂停保持
module pc #(
    parameter RESET_PC = 32'h0000_0000
)(
    input               clk,        // 时钟
    input               rstn,       // 异步复位，低有效
    input               stall_i,    // 暂停请求，1=保持PC不变
    input               flush_i,    // 冲刷请求，1=冲刷流水线，PC更新但不增量
    input       [31:0]  target_i,  // 跳转目标地址
    output reg  [31:0]  pc_o        // 当前PC输出
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        pc_o <= RESET_PC;
    end else begin
        if (stall_i) begin
            // 暂停，保持PC不变
            pc_o <= pc_o;
        end else if (flush_i) begin
            // 跳转，更新到目标地址
            pc_o <= target_i;
        end else begin
            // 正常执行，PC+4
            pc_o <= pc_o + 32'd4;
        end
    end
end

endmodule
