`timescale 1ns/1ps

module if_id_seg(
    input   clk,
    input   resetn,

    input   stall,      // *暂停
    input   refresh,    // *刷新

    input           id_branch,  // 前一条指令是否为分支
    input [`EXBITS] if_ex,
    input [31:0]    if_pc,
    // input [31:0]    if_inst,
    
    output reg              id_bd,  // * branch delay slot
    output reg  [`EXBITS]   id_ex,
    output reg  [31:0]      id_pc
    // output reg  [31:0]      id_inst
);

always @(posedge clk) begin
    if(!resetn || refresh) begin
        id_bd   <= 1'b0;
        id_ex   <= `NUM_EX'b0;
        id_pc   <= 32'h0;
        // id_inst <= 32'h0;
    end
    else if(!stall) begin
        id_bd   <= id_branch;
        id_ex   <= if_ex;
        id_pc   <= if_pc;
        // id_inst <= if_inst;
    end
end

// // inst update at negedge clk, because pc updates at posedge
// always @(negedge clk) begin
//     if(!resetn || refresh)  id_inst <= 32'h0;
//     else if(!stall)         id_inst <= if_inst;
// end


endmodule