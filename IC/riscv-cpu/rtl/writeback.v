// 写回阶段
// 选择结果（ALU结果 或 存储器读出结果，写回寄存器堆
module writeback(
    input               clk,
    input               rstn,

    // 来自MEM/WB
    input       [31:0]  mem_wb_result_i,
    input       [31:0]  mem_wb_rdata_i,
    input               mem_wb_mem_read_i,
    input               mem_wb_reg_write_i,
    input       [4:0]   mem_wb_rd_i,

    // 输出到寄存器堆
    output reg  [31:0] wb_data_o,
    output      [4:0]  wb_rd_o,
    output              wb_en_o
);

// 选择结果：lw读内存就是内存数据，否则就是ALU结果
always @(*) begin
    if (mem_wb_mem_read_i) begin
        wb_data_o = mem_wb_rdata_i;
    end else begin
        wb_data_o = mem_wb_result_i;
    end
end

// 这里不需要额外寄存器打拍，因为已经在mem_access阶段打过了
assign wb_rd_o  = mem_wb_rd_i;
assign wb_en_o  = mem_wb_reg_write_i;

endmodule
