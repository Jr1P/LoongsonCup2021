`timescale 1ns/1ps

module id_ex_seg (
    input           clk,
    input           resetn,
    input [31:0]    id_pc,
    input [31:0]    id_inst,
    input           id_imm,
    input [31:0]    id_Imm,
    input [31:0]    id_A,           // GPR[rs]
    input [31:0]    id_B,           // GPR[rt]
    input           id_al,
    input           id_SPEC,
    input           id_load,
    input           id_loadX,
    input [5 :0]    id_ifunc,      // use for I type
    input           id_regwen,
    input [5 :0]    id_wreg,
    input           id_data_en,
    input [3 :0]    id_data_ren,
    input [3 :0]    id_data_wen,
    input           id_cp0ren,
    input           id_cp0wen,
    input [7 :0]    id_cp0addr,
    input [1 :0]    id_rhilo,
    input [1 :0]    id_whilo,

    output reg [31:0]   ex_pc,
    output reg [31:0]   ex_inst,
    output reg          ex_imm,
    output reg [31:0]   ex_Imm,
    output reg [31:0]   ex_A,
    output reg [31:0]   ex_B,
    output reg          ex_al,
    output reg          ex_SPEC,
    output reg          ex_load,
    output reg [3 :0]   ex_loadX,
    output reg [5 :0]   ex_ifunc,
    output reg          ex_regwen,
    output reg [5 :0]   ex_wreg,
    output reg          ex_data_en,
    output reg [3 :0]   ex_data_ren,
    output reg [3 :0]   ex_data_wen,
    output reg          ex_cp0ren,
    output reg          ex_cp0wen,
    output reg [7 :0]   ex_cp0addr,
    output reg [1 :0]   ex_rhilo,
    output reg [1 :0]   ex_whilo
);

always @(posedge clk) begin
    if(!resetn) begin
        ex_pc       <= 32'h0;
        ex_inst     <= 32'h0;
        ex_imm      <= 1'b0;
        ex_Imm      <= 32'h0;
        ex_A        <= 32'h0;
        ex_B        <= 32'h0;
        ex_al       <= 1'b0;
        ex_SPEC     <= 1'b0;
        ex_load     <= 1'b0;
        ex_loadX    <= 1'b0;
        ex_ifunc    <= 6'h0;
        ex_regwen   <= 1'b0;
        ex_wreg     <= 6'h0;
        ex_data_en  <= 1'b0;
        ex_data_ren <= 4'b0;
        ex_data_wen <= 4'h0;
        ex_cp0ren   <= 1'b0;
        ex_cp0wen   <= 1'b0;
        ex_cp0addr  <= 8'b0;
        ex_whilo    <= 2'b0;
        ex_rhilo    <= 2'b0;
    end
    else begin
        ex_pc       <= id_pc;
        ex_inst     <= id_inst;
        ex_imm      <= id_imm;
        ex_Imm      <= id_Imm;
        ex_A        <= id_A;
        ex_B        <= id_B;
        ex_al       <= id_al;
        ex_SPEC     <= id_SPEC;
        ex_load     <= id_load;
        ex_loadX    <= id_loadX;
        ex_ifunc    <= id_ifunc;
        ex_regwen   <= id_regwen;
        ex_wreg     <= id_wreg;
        ex_data_en  <= id_data_en;
        ex_data_ren <= id_data_ren;
        ex_data_wen <= id_data_wen;
        ex_cp0ren   <= id_cp0ren;
        ex_cp0wen   <= id_cp0wen;
        ex_cp0addr  <= id_cp0addr;
        ex_whilo    <= id_whilo;
        ex_rhilo    <= id_rhilo;
    end
end

endmodule