`timescale 1ns/1ps

`define EXEC_ADDR 32'hbfc00380
module pc(
    input       clk,
    input       resetn,

    //// input               stall,          // 1: pipeline stalled
    input               BranchTake,     // 1: take, 0: not take
    input       [31:0]  BranchTarget,   // target address of branch

    input               exception,      // 1: exception occur, 0: not

    input               eret,           // eret指令
    input       [31:0]  epc,
    output reg  [31:0]  npc
);

always @(posedge clk) begin
    if(!resetn) npc <= 32'h0;
    else npc <= exception ? `EXEC_ADDR :
                BranchTake ? BranchTarget :
                eret ? epc : 
                stall ? npc : npc+32'd4;
end

endmodule