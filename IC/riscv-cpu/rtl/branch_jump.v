// 分支跳转控制单元
// 在ID级计算跳转地址，判断是否跳转，输出flush信号冲刷流水线
module branch_jump(
    input       [31:0]  id_pc_i,        // ID阶段PC
    input       [31:0]  id_imm_i,       // ID阶段扩展后的立即数
    input       [31:0]  id_rs1_data_i,  // ID阶段rs1数据（jalr用）
    input               branch_i,       // 是否是分支指令
    input               jump_i,         // 是否是跳转指令
    input               jalr_i,         // 是否是jalr
    input               alu_zero_i,     // ALU比较结果zero（beq/bne用）
    input               funct3_1_i,     // bne标志（funct3[0]）
    output reg  [31:0]  target_addr_o,  // 跳转目标地址
    output reg          flush_o        // 需要冲刷流水线
);

// 地址计算
always @(*) begin
    if (jump_i && jalr_i) begin
        // jalr: 目标 = rs1 + 立即数，低比特清零
        target_addr_o = (id_rs1_data_i + id_imm_i) & 32'hfffffffe;
        flush_o = 1'b1;
    end else if (jump_i) begin
        // jal: 目标 = PC + 立即数
        target_addr_o = id_pc_i + id_imm_i;
        flush_o = 1'b1;
    end else if (branch_i) begin
        // 分支: beq/bne，判断是否跳转
        // beq: zero=1跳转，bne: zero=0跳转
        if ((alu_zero_i && !funct3_1_i) || (!alu_zero_i && funct3_1_i)) begin
            target_addr_o = id_pc_i + id_imm_i;
            flush_o = 1'b1;
        end else begin
            // 不跳转
            target_addr_o = id_pc_i + 32'd4;
            flush_o = 1'b0;
        end
    end else begin
        // 不跳转
        target_addr_o = id_pc_i + 32'd4;
        flush_o = 1'b0;
    end
end

endmodule
