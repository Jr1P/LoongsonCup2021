`timescale 1ns/1ps

module ex_mem_seg (
    input           clk,
    input           resetn,
    input [31:0]    ex_pc,
    input [31:0]    ex_res,
    input [31:0]    ex_hi,
    input [31:0]    ex_lo,
    input           ex_R,
    input           ex_load,
    input           ex_al,
    // input           ex_imm,

    input           ex_data_en,
    input [3 :0]    ex_data_wen,
    input [31:0]    ex_wdata,

    input           ex_regwen,
    input [5 :0]    ex_wreg,
    input [1 :0]    ex_rhilo,
    input [1 :0]    ex_whilo,

    output reg [31:0]   mem_pc,
    output reg [31:0]   mem_res,
    output reg [31:0]   mem_hi,
    output reg [31:0]   mem_lo,
    output reg          mem_R,
    output reg          mem_load,
    output reg          mem_al,
    // output reg          mem_imm,

    output reg          mem_data_en,
    output reg [3 :0]   mem_data_wen,
    output reg [31:0]   mem_wdata,

    output reg          mem_regwen,
    output reg [5 :0]   mem_wreg,
    output reg [1 :0]   mem_rhilo,
    output reg [1 :0]   mem_whilo
);

always @(posedge clk) begin
    if(!resetn) begin
        mem_pc      <= 32'b0;
        mem_res     <= 32'b0;
        mem_hi      <= 32'b0;
        mem_lo      <= 32'b0;
        mem_R       <= 1'b0;
        mem_load    <= 1'b0;
        mem_al      <= 1'b0;
        // mem_imm     <= 1'b0;
        mem_data_en <= 1'b0;
        mem_data_wen<= 4'b0;
        mem_wdata   <= 32'b0;
        mem_regwen  <= 1'b0;
        mem_wreg    <= 6'b0;
        mem_rhilo   <= 2'b0;
        mem_whilo   <= 2'b0;
    end
    else begin
        mem_pc      <= ex_pc;
        mem_res     <= ex_res;
        mem_hi      <= ex_hi;
        mem_lo      <= ex_lo;
        mem_R       <= ex_R;
        mem_load    <= ex_load;
        mem_al      <= ex_al;
        // mem_imm     <= ex_imm;
        mem_data_wen<= ex_data_wen;
        mem_data_en <= ex_data_en;
        mem_wdata   <= ex_wdata;
        mem_regwen  <= ex_regwen;
        mem_wreg    <= ex_wreg;
        mem_rhilo   <= ex_rhilo;
        mem_whilo   <= ex_whilo;
    end
end

endmodule