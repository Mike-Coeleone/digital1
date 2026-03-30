// ALU 算术逻辑单元
// 支持add/sub/and/or/sll/srl 操作
module alu(
    input       [31:0]  a_i,        // 操作数A
    input       [31:0]  b_i,        // 操作数B
    input       [3:0]   op_i,       // 操作码
    output reg  [31:0]  result_o,   // 结果输出
    output              zero_o      // 结果为零标志，给beq/bne使用
);

// ALU 操作码定义
`define ALU_ADD   4'b0000
`define ALU_SUB   4'b0001
`define ALU_AND   4'b0010
`define ALU_OR    4'b0011
`define ALU_SLL   4'b0100
`define ALU_SRL   4'b0101
`define ALU_PCADD 4'b0110  // PC + 立即数，用于跳转地址计算

always @(*) begin
    case (op_i)
        `ALU_ADD: begin
            result_o = a_i + b_i;
        end
        `ALU_SUB: begin
            result_o = a_i - b_i;
        end
        `ALU_AND: begin
            result_o = a_i & b_i;
        end
        `ALU_OR: begin
            result_o = a_i | b_i;
        end
        `ALU_SLL: begin
            // 逻辑左移，shamt在b_i[4:0]
            result_o = a_i << b_i[4:0];
        end
        `ALU_SRL: begin
            // 逻辑右移
            result_o = a_i >> b_i[4:0];
        end
        `ALU_PCADD: begin
            // PC + 立即数，用于跳转地址计算
            result_o = a_i + b_i;
        end
        default: begin
            result_o = 32'h0000_0000;
        end
    endcase
end

// 零标志
assign zero_o = (result_o == 32'h0000_0000);

endmodule
