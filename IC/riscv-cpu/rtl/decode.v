// 指令译码模块
// 提取字段、生成控制信号、扩展立即数
module decode(
    input       [31:0]  inst_i,         // 输入指令
    output      [4:0]   rs1_o,          // rs1 寄存器地址
    output      [4:0]   rs2_o,          // rs2 寄存器地址
    output      [4:0]   rd_o,           // rd 寄存器地址
    output reg  [31:0]  imm_o,          // 扩展后的立即数
    output reg              reg_write_o,    // 是否写寄存器
    output reg              mem_read_o,     // 是否读数据存储器
    output reg              mem_write_o,    // 是否写数据存储器
    output reg              branch_o,       // 是否分支
    output reg              jump_o,         // 是否跳转
    output reg              jalr_o,         // 是否jalr
    output reg  [3:0]   alu_op_o,       // ALU 操作码
    output reg              alu_src_o       // ALU 输入选择：1=立即数，0=寄存器
);

// RISC-V 指令编码字段提取
wire [6:0] opcode = inst_i[6:0];
wire [2:0] funct3 = inst_i[14:12];
wire [6:0] funct7 = inst_i[31:25];
wire [4:0] shamt = inst_i[24:20];

// 字段提取
assign rs1_o = inst_i[19:15];
assign rs2_o = inst_i[24:20];
assign rd_o  = inst_i[11:7];

//  opcode 定义
`define OP_R_TYPE   7'b0110011  // add/sub/and/or/sll/srl
`define OP_I_TYPE   7'b0010011  // addi/ori
`define OP_LOAD     7'b0000011  // lw
`define OP_STORE    7'b0100011  // sw
`define OP_BRANCH   7'b1100011  // beq/bne
`define OP_JAL      7'b1101111  // jal
`define OP_JALR     7'b1100111  // jalr

// ALU 操作码定义包含在alu.v中
`define ALU_ADD   4'b0000
`define ALU_SUB   4'b0001
`define ALU_AND   4'b0010
`define ALU_OR    4'b0011
`define ALU_SLL   4'b0100
`define ALU_SRL   4'b0101
`define ALU_PCADD 4'b0110

always @(*) begin
    // 默认值
    reg_write_o = 1'b0;
    mem_read_o  = 1'b0;
    mem_write_o = 1'b0;
    branch_o    = 1'b0;
    jump_o      = 1'b0;
    jalr_o      = 1'b0;
    alu_op_o    = `ALU_ADD;
    alu_src_o   = 1'b0;
    imm_o       = 32'h0000_0000;

    case (opcode)
        `OP_R_TYPE: begin
            // R-type: add/sub/and/or/sll/srl
            reg_write_o = 1'b1;
            alu_src_o   = 1'b0;  // 两个寄存器
            case (funct3)
                3'b000: begin
                    if (funct7 == 7'b0000000) begin
                        alu_op_o = `ALU_ADD;  // add
                    end else if (funct7 == 7'b0100000) begin
                        alu_op_o = `ALU_SUB;  // sub
                    end
                end
                3'b111: alu_op_o = `ALU_AND;  // and
                3'b110: alu_op_o = `ALU_OR;   // or
                3'b001: alu_op_o = `ALU_SLL;  // sll
                3'b101: alu_op_o = `ALU_SRL;  // srl
                default: alu_op_o = `ALU_ADD;
            endcase
        end

        `OP_I_TYPE: begin
            // I-type: addi/ori
            reg_write_o = 1'b1;
            alu_src_o   = 1'b1;  // 立即数
            // 符号扩展立即数
            imm_o       = {{20{inst_i[31]}}, inst_i[31:20]};
            case (funct3)
                3'b000: alu_op_o = `ALU_ADD;  // addi
                3'b110: alu_op_o = `ALU_OR;   // ori, 零扩展
                default: alu_op_o = `ALU_ADD;
            endcase
            // ori 需要零扩展
            if (funct3 == 3'b110) begin
                imm_o = {20'h0, inst_i[31:20]};  // 零扩展
            end
        end

        `OP_LOAD: begin
            // lw: 基址寻址，load
            reg_write_o = 1'b1;
            mem_read_o  = 1'b1;
            alu_src_o   = 1'b1;  // 基址+立即数
            alu_op_o    = `ALU_ADD;
            imm_o       = {{20{inst_i[31]}}, inst_i[31:20]};  // 符号扩展
        end

        `OP_STORE: begin
            // sw: 基址寻址，store
            mem_write_o = 1'b1;
            alu_src_o   = 1'b1;  // 基址+立即数
            alu_op_o    = `ALU_ADD;
            imm_o       = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};  // S-type
        end

        `OP_BRANCH: begin
            // beq/bne: PC相对寻址
            branch_o    = 1'b1;
            alu_op_o    = `ALU_SUB;  // 比较相等用减法，看zero标志
            alu_src_o   = 1'b0;
            // B-type 立即数
            imm_o       = {{19{inst_i[31]}}, inst_i[31], inst_i[7], 
                          inst_i[30:25], inst_i[11:8], 1'b0};
        end

        `OP_JAL: begin
            // jal: 伪直接寻址
            jump_o      = 1'b1;
            reg_write_o = 1'b1;
            // J-type 立即数
            imm_o       = {{12{inst_i[31]}}, inst_i[31], inst_i[19:12], 
                          inst_i[20], inst_i[30:21], 1'b0};
            alu_op_o    = `ALU_ADD;
        end

        `OP_JALR: begin
            // jalr: 基址寻址跳转
            jump_o      = 1'b1;
            jalr_o      = 1'b1;
            reg_write_o = 1'b1;
            alu_src_o   = 1'b1;  // 寄存器+立即数
            alu_op_o    = `ALU_ADD;
            imm_o       = {{20{inst_i[31]}}, inst_i[31:20]};
        end

        default: begin
            // 保持默认值
        end
    endcase
end

endmodule
