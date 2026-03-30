// 数据转发单元（旁路）
// 解决数据冒险，将前级结果直接转发到EX级ALU输入
module forward(
    input       [4:0]   id_ex_rs1_i,      // ID/EX 阶段 rs1 地址
    input       [4:0]   id_ex_rs2_i,      // ID/EX 阶段 rs2 地址
    input       [4:0]   ex_mem_rd_i,      // EX/MEM 阶段 rd 地址
    input       [4:0]   mem_wb_rd_i,      // MEM/WB 阶段 rd 地址
    input               ex_mem_reg_write_i, // EX/MEM 阶段写寄存器使能
    input               mem_wb_reg_write_i, // MEM/WB 阶段写寄存器使能
    output reg  [1:0]   forward_a_o,      // rs1 转发选择
    output reg  [1:0]   forward_b_o       // rs2 转发选择
);

// 转发选择编码
`define FORWARD_NONE 2'b00   // 不转发，使用译码阶段读出的原始值
`define FORWARD_EXMEM 2'b01  // 从 EX/MEM 转发
`define FORWARD_MEMWB 2'b10  // 从 MEM/WB 转发

// 转发优先级：EX/MEM > MEM/WB，因为EX/MEM结果更新
always @(*) begin
    // rs1 转发判断
    if (ex_mem_reg_write_i && (ex_mem_rd_i != 5'd0) && (ex_mem_rd_i == id_ex_rs1_i)) begin
        forward_a_o = `FORWARD_EXMEM;
    end else if (mem_wb_reg_write_i && (mem_wb_rd_i != 5'd0) && (mem_wb_rd_i == id_ex_rs1_i)) begin
        forward_a_o = `FORWARD_MEMWB;
    end else begin
        forward_a_o = `FORWARD_NONE;
    end

    // rs2 转发判断
    if (ex_mem_reg_write_i && (ex_mem_rd_i != 5'd0) && (ex_mem_rd_i == id_ex_rs2_i)) begin
        forward_b_o = `FORWARD_EXMEM;
    end else if (mem_wb_reg_write_i && (mem_wb_rd_i != 5'd0) && (mem_wb_rd_i == id_ex_rs2_i)) begin
        forward_b_o = `FORWARD_MEMWB;
    end else begin
        forward_b_o = `FORWARD_NONE;
    end
end

endmodule
