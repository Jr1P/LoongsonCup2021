`timescale 1ns/1ps

module if_id_seg(
    input               clk,
    input               resetn,

    input       [31:0]  if_pc,
    input       [31:0]  if_inst,
    
    output reg  [31:0]  id_pc,
    output reg  [31:0]  id_inst
);

always @(posedge clk) begin
    if(!resetn) begin
        id_pc   <= 32'h0;
        id_inst <= 32'h0;
    end
    else begin
        id_pc   <= if_pc;
        id_inst <= id_inst;
    end
end

endmodule