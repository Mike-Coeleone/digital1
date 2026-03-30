// 执行阶段
// 包含数据转发和ALU
module execute(
    input               clk,
    input               rstn,

    // 来自ID/EX阶段
    input       [31:0]  id_ex_rs1_data_i,
    input       [31:0]  id_ex_rs2_data_i,
    input       [31:0]  id_ex_imm_i,
    input       [4:0]   id_ex_rd_i,
    input               id_ex_alu_src_i,
    input       [3:0]   id_ex_alu_op_i,
    input       [1:0]   id_ex_forward_a_i,
    input       [1:0]   id_ex_forward_b_i,
    input               id_ex_reg_write_i,
    input               id_ex_mem_read_i,
    input               id_ex_mem_write_i,
    input       [31:0]  id_ex_pc_i,

    // 来自前级的转发结果
    input       [31:0]  ex_mem_result_i,
    input       [31:0]  mem_wb_result_i,

    // 输出到EX/MEM
    output reg  [31:0]  ex_mem_alu_result_o,
    output reg  [31:0]  ex_mem_rs2_data_o,
    output reg  [4:0]   ex_mem_rd_o,
    output reg          ex_mem_reg_write_o,
    output reg          ex_mem_mem_read_o,
    output reg          ex_mem_mem_write_o
);

// 转发编码
`define FORWARD_NONE 2'b00
`define FORWARD_EXMEM 2'b01
`define FORWARD_MEMWB 2'b10

reg [31:0] alu_a;
reg [31:0] alu_b;
wire [31:0] alu_result;
wire        alu_zero;

// 数据转发MUX - rs1
always @(*) begin
    case (id_ex_forward_a_i)
        `FORWARD_NONE:   alu_a = id_ex_rs1_data_i;
        `FORWARD_EXMEM:  alu_a = ex_mem_result_i;
        `FORWARD_MEMWB:  alu_a = mem_wb_result_i;
        default:         alu_a = id_ex_rs1_data_i;
    endcase
end

// 数据转发MUX - rs2
always @(*) begin
    case (id_ex_forward_b_i)
        `FORWARD_NONE:   alu_b = id_ex_rs2_data_i;
        `FORWARD_EXMEM:  alu_b = ex_mem_result_i;
        `FORWARD_MEMWB:  alu_b = mem_wb_result_i;
        default:         alu_b = id_ex_rs2_data_i;
    endcase
end

// ALU输入选择：寄存器还是立即数
wire [31:0] alu_final_b = id_ex_alu_src_i ? id_ex_imm_i : alu_b;

// 例化ALU
alu alu_inst(
    .a_i(alu_a),
    .b_i(alu_final_b),
    .op_i(id_ex_alu_op_i),
    .result_o(alu_result),
    .zero_o(alu_zero)
);

// EX/MEM流水线寄存器
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        ex_mem_alu_result_o   <= 32'h0;
        ex_mem_rs2_data_o     <= 32'h0;
        ex_mem_rd_o           <= 5'h0;
        ex_mem_reg_write_o    <= 1'b0;
        ex_mem_mem_read_o     <= 1'b0;
        ex_mem_mem_write_o    <= 1'b0;
    end else begin
        ex_mem_alu_result_o   <= alu_result;
        ex_mem_rs2_data_o     <= alu_b;  // sw需要写回存储器的是rs2的值
        ex_mem_rd_o           <= id_ex_rd_i;
        ex_mem_reg_write_o    <= id_ex_reg_write_i;
        ex_mem_mem_read_o     <= id_ex_mem_read_i;
        ex_mem_mem_write_o    <= id_ex_mem_write_i;
    end
end

endmodule
