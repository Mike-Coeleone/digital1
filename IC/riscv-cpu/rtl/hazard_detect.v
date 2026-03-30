// 流水线冒险检测单元
// 主要检测 load-use 数据冒险，输出暂停信号
module hazard_detect(
    input       [4:0]   if_id_rs1_i,    // ID阶段指令rs1地址
    input       [4:0]   if_id_rs2_i,    // ID阶段指令rs2地址
    input       [4:0]   id_ex_rd_i,     // EX阶段指令目标寄存器地址
    input               id_ex_mem_read_i, // EX阶段是否读内存（lw）
    output reg          stall_o          // 1=需要暂停流水线
);

// load-use 冒险检测:
// 如果当前ID阶段指令要读的寄存器，正好是前一条lw在EX阶段要写的寄存器
// 需要暂停一个周期，等lw读完再执行
always @(*) begin
    if (id_ex_mem_read_i && (id_ex_rd_i != 5'd0) && 
        ((id_ex_rd_i == if_id_rs1_i) || (id_ex_rd_i == if_id_rs2_i))) begin
        stall_o = 1'b1;  // 需要暂停
    end else begin
        stall_o = 1'b0;  // 不需要暂停
    end
end

endmodule
