`timescale 1ns/1ps

module mem_wb_seg (
    input           clk,
    input           resetn,
    input [31:0]    mem_pc,

    input           mem_regwen,
    input [5 :0]    mem_wreg,
    input [1 :0]    mem_whilo,

    output reg          wb_regwen,
    output reg [5 :0]   wb_wreg,
    output reg [1 :0]   wb_whilo
);

always @(posedge clk) begin
    if(!resetn) begin
        wb_regwen   <= 1'b0;
        wb_wreg     <= 6'b0;
        wb_whilo    <= 2'b0;
    end
    else begin
        
    end
end

endmodule