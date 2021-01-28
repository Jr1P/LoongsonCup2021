`timescale 1ns/1ps

module id_ex_seg (
    input clk,
    input resetn,
    input [31:0] id_pc,
    input [31:0] id_inst,
    input []

    output reg [31:0] ex_pc,
    output reg [31:0] ex_inst
);

always @(posedge clk) begin
    if(!resetn) begin
        
    end
    else begin
        
    end
end

endmodule