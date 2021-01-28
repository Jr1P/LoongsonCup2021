`timescale 1ns/1ps

`define EXEC_ADDR 32'hbfc00380
module pc(
    input       clk,
    input       resetn,

    input       [31:0]  BranchTarget,   // target address of branch
    input               BranchTake,     // 1: take, 0: not take
    input               exeception,     // 1: execption occur, 0: not
    output reg  [31:0]  npc
);

always @(posedge clk) begin
    if(!resetn) npc <= 32'h0;
    else npc <= exeception ? `EXEC_ADDR :
                BranchTake ? BranchTarget :
                npc+32'd4;
end