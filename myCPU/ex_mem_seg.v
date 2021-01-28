`timescale 1ns/1ps

module ex_mem_seg (
    input           clk,
    input           resetn,
    input [31:0]    ex_pc,
    input [31:0]    ex_res,

    input           ex_data_en,
    input [3 :0]    ex_data_wen,
    input [31:0]    ex_wdata,

    input           ex_regwen,
    input [5 :0]    ex_wreg,
    input [1 :0]    ex_whilo,

    output reg [31:0]   mem_pc,
    output reg [31:0]   mem_res,

    output reg          mem_data_en,
    output reg [3 :0]   mem_data_wen,
    output reg [31:0]   mem_wdata,

    output reg          mem_regwen,
    output reg [5 :0]   mem_wreg,
    output reg [1 :0]   mem_whilo
);

always @(posedge clk) begin
    if(!resetn) begin
        mem_pc      <= 32'b0;
        mem_res     <= 32'b0;
        mem_data_en <= 1'b0;
        mem_data_wen<= 4'b0;
        mem_wdata   <= 32'b0;
        mem_regwen  <= 1'b0;
        mem_wreg    <= 6'b0;
        mem_whilo   <= 2'b0;
    end
    else begin
        mem_pc      <= ex_pc;
        mem_res     <= ex_res;
        mem_data_wen<= ex_data_wen;
        mem_data_en <= ex_data_en;
        mem_wdata   <= ex_wdata;
        mem_regwen  <= ex_regwen;
        mem_wreg    <= ex_wreg;
        mem_whilo   <= ex_whilo;
    end
end

endmodule