// 访存阶段
module mem_access(
    input               clk,
    input               rstn,

    // 来自EX/MEM
    input       [31:0]  ex_mem_alu_result_i,
    input       [31:0]  ex_mem_rs2_data_i,
    input       [4:0]   ex_mem_rd_i,
    input               ex_mem_reg_write_i,
    input               ex_mem_mem_read_i,
    input               ex_mem_mem_write_i,

    // 来自数据存储器
    input       [31:0]  dmem_rdata_i,

    // 输出到MEM/WB
    output reg  [31:0]  mem_wb_result_o,
    output reg  [31:0]  mem_wb_rdata_o,
    output reg  [4:0]   mem_wb_rd_o,
    output reg          mem_wb_reg_write_o,
    output reg          mem_wb_mem_read_o,

    // 输出到数据存储器接口
    output      [31:0]  dmem_addr_o,
    output      [31:0]  dmem_wdata_o,
    output              dmem_we_o
);

// 直接连线输出
assign dmem_addr_o   = ex_mem_alu_result_i;  // ALU计算出来的地址
assign dmem_wdata_o  = ex_mem_rs2_data_i;    // 要写的数据来自rs2
assign dmem_we_o     = ex_mem_mem_write_i;

// MEM/WB流水线寄存器
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        mem_wb_result_o    <= 32'h0;
        mem_wb_rdata_o     <= 32'h0;
        mem_wb_rd_o        <= 5'h0;
        mem_wb_reg_write_o <= 1'b0;
        mem_wb_mem_read_o  <= 1'b0;
    end else begin
        mem_wb_result_o    <= ex_mem_alu_result_i;  // ALU结果
        mem_wb_rdata_o     <= dmem_rdata_i;         // 从存储器读出的数据
        mem_wb_rd_o        <= ex_mem_rd_i;
        mem_wb_reg_write_o <= ex_mem_reg_write_i;
        mem_wb_mem_read_o  <= ex_mem_mem_read_i;
    end
end

endmodule
