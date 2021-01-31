`timescale 1ns/1ps

module mem_wb_seg (
    input           clk,
    input           resetn,

    input [31:0]    mem_pc,
    input [31:0]    mem_inst,
    input [31:0]    mem_res,
    input [31:0]    mem_hi,
    input [31:0]    mem_lo,
    input [31:0]    mem_rdata,  // data from data mem
    input           mem_load,
    input           mem_al,
    input           mem_regwen,
    input [5 :0]    mem_wreg,
    input [1 :0]    mem_rhilo,
    input [1 :0]    mem_whilo,

    output reg [31:0]   wb_pc,
    output reg [31:0]   wb_inst,
    output reg [31:0]   wb_res,
    output reg [31:0]   wb_hi,
    output reg [31:0]   wb_lo,
    output reg [31:0]   wb_rdata,
    output reg          wb_load,
    output reg          wb_al,
    output reg          wb_regwen,
    output reg [5 :0]   wb_wreg,
    output reg [1 :0]   wb_rhilo,
    output reg [1 :0]   wb_whilo
);

always @(posedge clk) begin
    if(!resetn) begin
        wb_pc       <= 32'b0;
        wb_inst     <= 32'b0;
        wb_res      <= 32'b0;
        wb_hi       <= 32'b0;
        wb_lo       <= 32'b0;
        wb_rdata    <= 32'b0;
        wb_load     <= 1'b0;
        wb_al       <= 1'b0;
        wb_regwen   <= 1'b0;
        wb_wreg     <= 6'b0;
        wb_rhilo    <= 2'b0;
        wb_whilo    <= 2'b0;
    end
    else begin
        wb_pc       <= mem_pc;
        wb_inst     <= mem_inst;
        wb_res      <= mem_res;
        wb_hi       <= mem_hi;
        wb_lo       <= mem_lo;
        wb_rdata    <= mem_rdata;
        wb_load     <= mem_load;
        wb_al       <= mem_al;
        wb_regwen   <= mem_regwen;
        wb_wreg     <= mem_wreg;
        wb_rhilo    <= mem_rhilo;
        wb_whilo    <= mem_whilo;
    end
end

endmodule