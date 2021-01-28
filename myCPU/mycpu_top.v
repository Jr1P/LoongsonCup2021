`timescale 1ns / 1ps
`include "./head.vh"
// 
module mycpu_top(
    input           clk,
    input           resetn,
    input   [5 :0]  ext_int,

    output          inst_sram_en,
    output  [3 :0]  inst_sram_wen,
    output  [31:0]  inst_sram_addr,
    output  [31:0]  inst_sram_wdata,
    input   [31:0]  inst_sram_rdata,
    
    output          data_sram_en,
    output  [3 :0]  data_sram_wen,
    output  [31:0]  data_sram_addr,
    output  [31:0]  data_sram_wdata,
    input   [31:0]  data_sram_rdata,
    
    output  [31:0]  debug_wb_pc,
    output  [3 :0]  debug_wb_rf_wen,
    output  [4 :0]  debug_wb_rf_wnum,
    output  [31:0]  debug_wb_rf_wdata
);
    // *wire
    // *ID
    wire        id_jump;
    wire        id_regwen;
    wire        id_al;
    wire        id_R;
    wire        id_branch;
    wire        id_imm;
    wire        id_data_en;
    wire [1 :0] id_immXtype;
    wire [3 :0] id_data_wen;
    wire [5 :0] id_func;
    wire [31:0] id_pc;
    wire [31:0] id_inst;
    wire [31:0] id_target;
    // *EX
    wire [31:0]   ex_pc;
    wire [31:0]   ex_inst;
    wire          ex_imm;
    wire [31:0]   ex_Imm;
    wire [31:0]   ex_A;
    wire [31:0]   ex_B;
    wire          ex_al;
    wire          ex_R;
    wire [5 :0]   ex_ifunc;
    wire          ex_regwen;
    wire [5 :0]   ex_wreg;
    wire [3 :0]   ex_data_wen;
    wire [1 :0]   ex_whilo;
    // *MEM
    wire [31:0] mem_pc;
    wire [31:0] mem_res;
    // wire [31:0] mem_wdata;
    wire        mem_regwen;
    wire [1 :0] mem_whilo;
    wire [5 :0] mem_wreg;
    // *WB
    wire        wb_regwen;
    wire [5 :0] wb_wreg;
    wire [1 :0] wb_whilo;

    // *IF
    assign inst_sram_en     = 1'b1;     // always
    assign inst_sram_wen    = 4'b0;     // not write
    assign inst_sram_wdata  = 32'b0;    // not write
    pc pc(
        .clk            (clk),
        .resetn         (resetn),
        .BranchTarget   (id_target),
        .BranchTake     (id_branch && id_jump),
        .exeception     (),

        .npc            (inst_sram_addr)
    );

    if_id_seg if_id_seg(
        .clk    (clk),
        .resetn (resetn),
        .if_pc  (inst_sram_addr),
        .if_inst(inst_sram_rdata),

        .id_pc  (id_pc),
        .id_inst(id_inst)
    );

    // *ID
    wire [31:0] inRegData;
    wire [31:0] regouta;
    wire [31:0] regoutb;
    wire [31:0] id_Imm  = id_immXtype == 2'b0  ? {16'b0, `GET_Imm(id_inst)}           :   // zero extend
                        id_immXtype == 2'b01 ? {{16{id_inst[15]}}, `GET_Imm(id_inst)} :   // signed extend
                        {`GET_Imm(id_inst), 16'b0};                                    // {imm, {16{0}}}

    regfile regfile(
        .clk    (clk),
        .resetn (resetn),
        .rs     (`GET_Rs(id_inst)),
        .rt     (`GET_Rt(id_inst)),
        .wen    (), // *wb
        .wreg   (), //
        .wdata  (), // *wb

        .outA   (regouta),
        .outB   (regoutb)
    );

    id id(
        .id_inst    (id_inst),
        .id_pc      (id_pc),
        .rega       (regouta),
        .regb       (regoutb),

        .branch     (id_branch),
        .jump       (id_jump),
        .al         (id_al),
        .target     (id_target),
        .R          (id_R),
        .imm        (id_imm),
        .immXtype   (id_immXtype),
        .regwen     (id_regwen),
        .wreg       (id_wreg),
        .whilo      (id_whilo),
        .data_en    (id_data_en),
        .data_wen   (id_data_wen),
        .func       (id_func),
        .ReservedIns() // TODO:
    );

    id_ex_seg id_ex_seg(
        .clk        (clk),
        .resetn     (resetn),
        .id_pc      (id_pc),
        .id_inst    (id_inst),
        .id_imm     (id_imm),
        .id_Imm     (id_Imm),
        .id_A       (regouta),
        .id_B       (regoutb),
        .id_al      (id_al),
        .id_R       (id_R),
        .id_ifunc   (id_ifunc),
        .id_regwen  (id_regwen),
        .id_wreg    (id_wreg),
        .id_data_en (id_data_en),
        .id_data_wen(id_data_wen),
        .id_whilo   (id_whilo),

        .ex_pc      (ex_pc),
        .ex_inst    (ex_inst),
        .ex_imm     (ex_imm),
        .ex_Imm     (ex_Imm),
        .ex_A       (ex_A),
        .ex_B       (ex_B),
        .ex_al      (ex_al),
        .ex_R       (ex_R),
        .ex_ifunc   (ex_ifunc),
        .ex_regwen  (ex_regwen),
        .ex_wreg    (ex_wreg),
        .ex_data_en (ex_data_en),
        .ex_data_wen(ex_data_wen),
        .ex_whilo   (ex_whilo)
    );

    // *EX
    wire [31:0] inAlu1  = ; // TODO: 重定向
    wire [31:0] inAlu2  = ;
    wire [5 :0] ex_func = ;
    wire [31:0] ex_hi;
    wire [31:0] ex_res;

    alu alu(
        .clk    (clk),
        .resetn (resetn),
        .A      (inAlu1),
        .B      (inAlu2),
        .func   (ex_func),
        .sa     (`GET_SA(ex_inst)),

        .IntegerOverflow    (), // TODO:
        .res                (ex_res),
        .hi                 (ex_hi)
    );

    ex_mem_seg ex_mem_seg (
        .clk        (clk),
        .resetn     (resetn),
        .ex_pc      (ex_pc),
        .ex_res     (ex_res),
        .ex_data_en (ex_data_en),
        .ex_data_wen(ex_data_wen),
        .ex_wdata   (ex_B),
        .ex_regwen  (ex_regwen),
        .ex_wreg    (ex_wreg),
        .ex_whilo   (ex_whilo),

        .mem_pc         (mem_pc),
        .mem_res        (mem_res),
        .mem_data_en    (data_sram_en),
        .mem_data_wen   (data_sram_wen)
        .mem_wdata      (data_sram_wdata),
        .mem_regwen     (mem_regwen),
        .mem_wreg       (mem_wreg),
        .mem_whilo      (mem_whilo)
    );
    // *MEM
    // assign data_sram_en     = ;         // * 这三个信号直接在 ex_mem段连
    // assign data_sram_wen    = ;
    // assign data_sram_wdata  = ;
    assign data_sram_addr   = mem_res;

    mem_wb_seg mem_wb_seg(
        .clk(clk),
        .resetn(resetn),
        .
    );

    // *WB
    assign inRegData = ;

    // *debug
    assign debug_wb_pc          = mem_pc;
    assign debug_wb_rf_wen      = {3'b000, mem_regwen};
    assign debug_wb_rf_wnum     = mem_wreg;
    assign debug_wb_rf_wdata    = inRegData;


endmodule
