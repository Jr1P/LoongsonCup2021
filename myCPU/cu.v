`timescale 1ns/1ps

// * Pipeline stall and refresh
module cu(
    input clk,
    input resetn,

    input [31:0]id_pc,

    input       mem_regwen,
    input       mem_load,
    input [4:0] mem_wreg,

    input       ex_rs_ren,
    input [4:0] ex_rs,
    input       ex_rt_ren,
    input [4:0] ex_rt,

    input exc_oc,

    input id_branch,
    input id_rs_ren,
    input [4:0] id_rs,
    input id_rt_ren,
    input [4:0] id_rt,

    input ex_regwen,
    input ex_load,
    input ex_cp0ren,
    input [4:0] ex_wreg,

    output  id_recode,

    output  if_id_stall,
    output  id_ex_stall,
    output  ex_mem_stall,
    output  mem_wb_stall,

    output  if_id_refresh,
    output  id_ex_refresh,
    output  ex_mem_refresh,
    output  mem_wb_refresh
);

wire ex_rel_rs  = id_branch && id_rs_ren && ex_regwen && ex_wreg == id_rs;
wire ex_rel_rt  = id_branch && id_rt_ren && ex_regwen && ex_wreg == id_rt;
wire ex_stall   = (ex_rel_rs || ex_rel_rt) && (ex_load || ex_cp0ren);

wire mem_rel_rs = id_branch && id_rs_ren && mem_regwen && mem_wreg == id_rs;
wire mem_rel_rt = id_branch && id_rt_ren && mem_regwen && mem_wreg == id_rt;
wire mem_stall  = !ex_rel_rs && !ex_rel_rt && (mem_rel_rs || mem_rel_rt) && mem_load;

wire load_stall = mem_load && (ex_rs_ren && mem_wreg == ex_rs || ex_rt_ren && mem_wreg == ex_rt);

// *id recode load load 时重新译码
assign id_recode = load_stall || mem_stall;
// always @(posedge clk) begin
//     if(!resetn) id_recode <= 1'b0;
//     else id_recode <= load_stall || mem_stall;
// end

assign mem_wb_stall = 1'b0;
assign ex_mem_stall = 1'b0;
// assign id_ex_stall = load_stall;
assign id_ex_stall = 1'b0;  // *id recode
assign if_id_stall = load_stall || ex_stall || mem_stall;

assign if_id_refresh = exc_oc;
assign id_ex_refresh = exc_oc || ex_stall || !id_pc;
assign ex_mem_refresh = exc_oc || load_stall || mem_stall;
assign mem_wb_refresh = 1'b0;

endmodule


// // *EX
// wire [31:0] inAlu1  =   (wb_load        && wb_wreg  == ex_rs) ? wb_rdata     :   //* wb段load写ex段的rs
//                         (mem_cp0ren     && mem_wreg == ex_rs) ? mem_cp0rdata :   //* mem段读cp0写ex段的rs
//                         (wb_cp0ren      && wb_wreg  == ex_rs) ? wb_cp0rdata  :   //* wb段读cp0写ex段rs
//                         (mem_hiloren    && mem_wreg == ex_rs) ? mem_hilordata:   //* mem段读HI/LO写ex段的rs
//                         (wb_hiloren     && wb_wreg  == ex_rs) ? wb_hilordata :   //* wb段读HI/LO写ex段的rs
//                         (mem_regwen     && mem_wreg == ex_rs) ? mem_res      :   //* mem段写ex段的rs
//                         (wb_regwen      && wb_wreg  == ex_rs) ? wb_res       :   //* wb段写ex段的rs
//                         ex_A;

// // *EX
// wire [31:0] inAlu1  =   mem_wreg == ex_rs   ? 
//                             mem_cp0ren  ? mem_cp0rdata  :   //* mem段读cp0写ex段的rs
//                             mem_hiloren ? mem_hilordata :   //* mem段读HI/LO写ex段的rs
//                             mem_regwen  ? mem_res : ex_A    //* mem段写ex段的rs
//                         : wb_wreg == ex_rs  ?
//                             wb_load     ? wb_rdata      :   //* wb段load写ex段的rs
//                             wb_cp0ren   ? wb_cp0rdata   :   //* wb段读cp0写ex段rs
//                             wb_hiloren  ? wb_hilordata  :   //* wb段读HI/LO写ex段的rs
//                             wb_regwen   ? wb_res : ex_A     //* wb段写ex段的rs
//                         : ex_A;