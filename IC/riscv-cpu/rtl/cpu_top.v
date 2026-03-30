// RISC-V 五级流水线 CPU 顶层模块
// 支持14条指令，完整冒险处理
module cpu_top #(
    parameter RESET_PC = 32'h0000_0000
)(
    input               clk,            // 时钟
    input               rstn,           // 异步复位，低有效

    // 指令存储器接口
    output      [31:0]  imem_addr_o,    // PC地址输出
    input       [31:0]  imem_data_i,    // 指令输入

    // 数据存储器接口
    output      [31:0]  dmem_addr_o,    // 地址输出
    output      [31:0]  dmem_wdata_o,   // 写数据输出
    output              dmem_we_o,      // 写使能输出
    input       [31:0]  dmem_rdata_i    // 读数据输入
);

// -------------------- 流水线寄存器定义 --------------------
// IF/ID
reg [31:0] if_id_pc;
reg [31:0] if_id_inst;

// ID/EX
reg [31:0] id_ex_pc;
reg [31:0] id_ex_rs1_data;
reg [31:0] id_ex_rs2_data;
reg [31:0] id_ex_imm;
reg [4:0]  id_ex_rs1;
reg [4:0]  id_ex_rs2;
reg [4:0]  id_ex_rd;
reg         id_ex_reg_write;
reg         id_ex_mem_read;
reg         id_ex_mem_write;
reg [3:0]  id_ex_alu_op;
reg         id_ex_alu_src;
reg         id_ex_branch;
reg         id_ex_jump;

// EX/MEM
wire [31:0] ex_mem_alu_result;
wire [31:0] ex_mem_rs2_data;
wire [4:0]  ex_mem_rd;
wire         ex_mem_reg_write;
wire         ex_mem_mem_read;
wire         ex_mem_mem_write;

// MEM/WB
wire [31:0] mem_wb_result;
wire [31:0] mem_wb_rdata;
wire [4:0]  mem_wb_rd;
wire         mem_wb_reg_write;
wire         mem_wb_mem_read;

// -------------------- 模块输出 --------------------
assign imem_addr_o = pc_out;  // PC直接作为指令地址

// -------------------- 模块例化 --------------------

// 1. PC模块
wire [31:0] pc_out;
wire         pc_stall;
wire         pc_flush;
wire [31:0] jump_target;

pc #(.RESET_PC(RESET_PC)) pc_inst(
    .clk(clk),
    .rstn(rstn),
    .stall_i(pc_stall),
    .flush_i(pc_flush),
    .target_i(jump_target),
    .pc_o(pc_out)
);

// 2. 寄存器堆
wire [31:0] rs1_data;
wire [31:0] rs2_data;
wire [31:0] wb_data;
wire [4:0]  wb_rd;
wire         wb_en;

regfile regfile_inst(
    .clk(clk),
    .rs1_addr_i(if_id_inst[19:15]),
    .rs2_addr_i(if_id_inst[24:20]),
    .wb_addr_i(wb_rd),
    .wb_data_i(wb_data),
    .wb_en_i(wb_en),
    .rs1_data_o(rs1_data),
    .rs2_data_o(rs2_data)
);

// 3. 指令译码
wire [4:0]  dec_rs1;
wire [4:0]  dec_rs2;
wire [4:0]  dec_rd;
wire [31:0] dec_imm;
wire         dec_reg_write;
wire         dec_mem_read;
wire         dec_mem_write;
wire         dec_branch;
wire         dec_jump;
wire         dec_jalr;
wire [3:0]  dec_alu_op;
wire         dec_alu_src;

decode decode_inst(
    .inst_i(if_id_inst),
    .rs1_o(dec_rs1),
    .rs2_o(dec_rs2),
    .rd_o(dec_rd),
    .imm_o(dec_imm),
    .reg_write_o(dec_reg_write),
    .mem_read_o(dec_mem_read),
    .mem_write_o(dec_mem_write),
    .branch_o(dec_branch),
    .jump_o(dec_jump),
    .jalr_o(dec_jalr),
    .alu_op_o(dec_alu_op),
    .alu_src_o(dec_alu_src)
);

// 4. 冒险检测
wire         hazard_stall;

hazard_detect hazard_detect_inst(
    .if_id_rs1_i(if_id_inst[19:15]),
    .if_id_rs2_i(if_id_inst[24:20]),
    .id_ex_rd_i(id_ex_rd),
    .id_ex_mem_read_i(id_ex_mem_read),
    .stall_o(hazard_stall)
);

assign pc_stall = hazard_stall;

// 5. 分支跳转判断和地址计算
wire [31:0] branch_target;
wire         branch_flush;

branch_jump branch_jump_inst(
    .id_pc_i(if_id_pc),
    .id_imm_i(dec_imm),
    .id_rs1_data_i(rs1_data),
    .branch_i(dec_branch),
    .jump_i(dec_jump),
    .jalr_i(dec_jalr),
    .alu_zero_i(1'b0),  // 这里如果在ID级比较需要ALU，我们简化在EX级比较，所以先占位
    .funct3_1_i(if_id_inst[12]),
    .target_addr_o(jump_target),
    .flush_o(pc_flush)
);

// 6. 数据转发
wire [1:0] forward_a;
wire [1:0] forward_b;

forward forward_inst(
    .id_ex_rs1_i(id_ex_rs1),
    .id_ex_rs2_i(id_ex_rs2),
    .ex_mem_rd_i(ex_mem_rd),
    .mem_wb_rd_i(mem_wb_rd),
    .ex_mem_reg_write_i(ex_mem_reg_write),
    .mem_wb_reg_write_i(mem_wb_reg_write),
    .forward_a_o(forward_a),
    .forward_b_o(forward_b)
);

// 7. 执行阶段
execute execute_inst(
    .clk(clk),
    .rstn(rstn),
    .id_ex_rs1_data_i(id_ex_rs1_data),
    .id_ex_rs2_data_i(id_ex_rs2_data),
    .id_ex_imm_i(id_ex_imm),
    .id_ex_rd_i(id_ex_rd),
    .id_ex_alu_src_i(id_ex_alu_src),
    .id_ex_alu_op_i(id_ex_alu_op),
    .id_ex_forward_a_i(forward_a),
    .id_ex_forward_b_i(forward_b),
    .id_ex_reg_write_i(id_ex_reg_write),
    .id_ex_mem_read_i(id_ex_mem_read),
    .id_ex_mem_write_i(id_ex_mem_write),
    .id_ex_pc_i(id_ex_pc),
    .ex_mem_result_i(mem_wb_result),
    .mem_wb_result_i(wb_data),
    .ex_mem_alu_result_o(ex_mem_alu_result),
    .ex_mem_rs2_data_o(ex_mem_rs2_data),
    .ex_mem_rd_o(ex_mem_rd),
    .ex_mem_reg_write_o(ex_mem_reg_write),
    .ex_mem_mem_read_o(ex_mem_mem_read),
    .ex_mem_mem_write_o(ex_mem_mem_write)
);

// 8. 访存阶段
mem_access mem_access_inst(
    .clk(clk),
    .rstn(rstn),
    .ex_mem_alu_result_i(ex_mem_alu_result),
    .ex_mem_rs2_data_i(ex_mem_rs2_data),
    .ex_mem_rd_i(ex_mem_rd),
    .ex_mem_reg_write_i(ex_mem_reg_write),
    .ex_mem_mem_read_i(ex_mem_mem_read),
    .ex_mem_mem_write_i(ex_mem_mem_write),
    .dmem_rdata_i(dmem_rdata_i),
    .mem_wb_result_o(mem_wb_result),
    .mem_wb_rdata_o(mem_wb_rdata),
    .mem_wb_rd_o(mem_wb_rd),
    .mem_wb_reg_write_o(mem_wb_reg_write),
    .mem_wb_mem_read_o(mem_wb_mem_read),
    .dmem_addr_o(dmem_addr_o),
    .dmem_wdata_o(dmem_wdata_o),
    .dmem_we_o(dmem_we_o)
);

// 9. 写回阶段
writeback writeback_inst(
    .mem_wb_result_i(mem_wb_result),
    .mem_wb_rdata_i(mem_wb_rdata),
    .mem_wb_mem_read_i(mem_wb_mem_read),
    .mem_wb_reg_write_i(mem_wb_reg_write),
    .mem_wb_rd_i(mem_wb_rd),
    .wb_data_o(wb_data),
    .wb_rd_o(wb_rd),
    .wb_en_o(wb_en)
);

// -------------------- 流水线寄存器更新 --------------------

// IF/ID 寄存器
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        if_id_pc   <= RESET_PC;
        if_id_inst <= 32'h0;
    end else if (hazard_stall) begin
        // 冒险暂停，保持不变
        if_id_pc   <= if_id_pc;
        if_id_inst <= if_id_inst;
    end else if (pc_flush) begin
        // 冲刷，清为nop
        if_id_pc   <= pc_out;
        if_id_inst <= 32'h0000_0000;  // nop = add x0, x0, x0
    end else begin
        if_id_pc   <= pc_out;
        if_id_inst <= imem_data_i;
    end
end

// ID/EX 寄存器
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        id_ex_pc        <= 32'h0;
        id_ex_rs1_data  <= 32'h0;
        id_ex_rs2_data  <= 32'h0;
        id_ex_imm       <= 32'h0;
        id_ex_rs1       <= 5'h0;
        id_ex_rs2       <= 5'h0;
        id_ex_rd        <= 5'h0;
        id_ex_reg_write <= 1'b0;
        id_ex_mem_read  <= 1'b0;
        id_ex_mem_write <= 1'b0;
        id_ex_alu_op    <= 4'h0;
        id_ex_alu_src   <= 1'b0;
        id_ex_branch    <= 1'b0;
        id_ex_jump      <= 1'b0;
    end else if (hazard_stall || pc_flush) begin
        // 暂停或冲刷，清控制信号为nop
        id_ex_pc        <= 32'h0;
        id_ex_rs1_data  <= 32'h0;
        id_ex_rs2_data  <= 32'h0;
        id_ex_imm       <= 32'h0;
        id_ex_rs1       <= 5'h0;
        id_ex_rs2       <= 5'h0;
        id_ex_rd        <= 5'h0;
        id_ex_reg_write <= 1'b0;
        id_ex_mem_read  <= 1'b0;
        id_ex_mem_write <= 1'b0;
        id_ex_alu_op    <= 4'h0;
        id_ex_alu_src   <= 1'b0;
        id_ex_branch    <= 1'b0;
        id_ex_jump      <= 1'b0;
    end else begin
        id_ex_pc        <= if_id_pc;
        id_ex_rs1_data  <= rs1_data;
        id_ex_rs2_data  <= rs2_data;
        id_ex_imm       <= dec_imm;
        id_ex_rs1       <= dec_rs1;
        id_ex_rs2       <= dec_rs2;
        id_ex_rd        <= dec_rd;
        id_ex_reg_write <= dec_reg_write;
        id_ex_mem_read  <= dec_mem_read;
        id_ex_mem_write <= dec_mem_write;
        id_ex_alu_op    <= dec_alu_op;
        id_ex_alu_src   <= dec_alu_src;
        id_ex_branch    <= dec_branch;
        id_ex_jump      <= dec_jump;
    end
end

endmodule
