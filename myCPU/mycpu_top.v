`timescale 1ns / 1ps
`include "./head.vh"
// 
module mycpu_top(
    input           clk,
    input           resetn,
    input   [5 :0]  ext_int,        // *硬件中断 

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
    // *Exceptions
    wire    inst_ADDRESS_ERROR;
    wire    ReservedIns;
    wire    IntegerOverflow, BreakEx, SyscallEx;
    wire    data_ADDRESS_ERROR;    
    // *ID
    wire        id_jump;
    wire        id_regwen;
    wire        id_al;
    wire        id_SPEC;
    wire        id_load;
    wire        id_loadX;
    wire        id_branch;
    wire        id_imm;
    wire        id_data_en;
    wire        id_eret;
    wire [1 :0] id_immXtype;
    wire [3 :0] id_data_ren;
    wire [3 :0] id_data_wen;
    wire [5 :0] id_func;
    wire [5 :0] id_wreg;
    wire        id_cp0ren;
    wire        id_cp0wen;
    wire [7 :0] id_cp0addr;
    wire [1 :0] id_hiloren;
    wire [1 :0] id_hilowen;
    wire [31:0] id_pc;
    wire [31:0] id_inst;
    wire [31:0] id_target;
    // *EX
    wire [31:0] ex_pc;
    wire [31:0] ex_inst;
    wire [31:0] ex_res;
    wire        ex_imm;
    wire [31:0] ex_Imm;
    wire [31:0] ex_A;
    wire [31:0] ex_B;
    wire        ex_al;
    wire        ex_SPEC;
    wire        ex_load;
    wire        ex_loadX;
    wire [5 :0] ex_ifunc;
    wire        ex_regwen;
    wire [5 :0] ex_wreg;
    wire        ex_data_en;
    wire [3 :0] ex_data_ren;
    wire [3 :0] ex_data_wen;
    wire        ex_cp0ren;
    wire        ex_cp0wen;
    wire [7 :0] ex_cp0addr;
    wire [1 :0] ex_hilowen;
    wire [1 :0] ex_hiloren;
    wire [31:0] ex_hilordata;
    // *MEM
    wire [31:0] mem_pc;
    wire [31:0] mem_inst;
    wire [31:0] mem_res;
    wire        mem_load;
    wire        mem_loadX;
    wire        mem_regwen;
    wire [5 :0] mem_wreg;
    wire [3 :0] mem_data_ren;
    wire [3 :0] mem_data_wen;
    wire        mem_cp0ren;
    wire        mem_cp0wen;
    wire [7 :0] mem_cp0addr;
    wire [31:0] mem_cp0rdata;
    wire [1 :0] mem_hilowen;
    wire [1 :0] mem_hiloren;
    wire [31:0] mem_hilordata;
    // *WB
    wire [31:0] wb_pc;
    wire [31:0] wb_inst;
    wire [31:0] wb_res;
    wire [31:0] wb_rdata;
    wire        wb_load;
    wire        wb_al;
    wire        wb_regwen;
    wire [5 :0] wb_wreg;
    wire        wb_cp0ren;
    wire [31:0] wb_cp0rdata;
    wire [1 :0] wb_hiloren;
    wire [1 :0] wb_hilowen;
    wire [31:0] wb_hilordata;

    // *IF
    assign inst_sram_en     = 1'b1;     // always enable
    assign inst_sram_wen    = 4'b0;     // not write
    assign inst_sram_wdata  = 32'b0;    // not write
    pc u_pc(
        .clk            (clk),
        .resetn         (resetn),
        .BranchTarget   (id_target),
        .BranchTake     (id_branch && id_jump),
        .exception      (), // ??? 异常 from CU

        .eret           (id_eret), // * eret
        // .epc            (), // TODO: epc ? 
        .npc            (inst_sram_addr)
    );

    assign inst_ADDRESS_ERROR = inst_sram_addr[1:0] != 2'b00;

    if_id_seg u_if_id_seg(
        .clk    (clk),
        .resetn (resetn),
        .if_pc  (inst_sram_addr),
        .if_inst(inst_sram_rdata),

        .id_pc  (id_pc),
        .id_inst(id_inst)
    );

    // *ID
    wire [31:0] inRegData;
    wire [31:0] regouta;  // TODO: 重定向 分支语句 rs rt
    wire [31:0] regoutb;
    wire [31:0] id_Imm  = id_immXtype == 2'b0  ? {16'b0, `GET_Imm(id_inst)}           : // zero extend
                        id_immXtype == 2'b01 ? {{16{id_inst[15]}}, `GET_Imm(id_inst)} : // signed extend
                        {`GET_Imm(id_inst), 16'b0};                                     // {imm, {16{0}}}

    regfile u_regfile(
        .clk    (clk),
        .resetn (resetn),
        .rs     (`GET_Rs(id_inst)),
        .rt     (`GET_Rt(id_inst)),
        .wen    (wb_regwen),
        .wreg   (wb_wreg),
        .wdata  (inRegData),

        .outA   (regouta),
        .outB   (regoutb)
    );

    id u_id(
        .id_inst    (id_inst),
        .id_pc      (id_pc),
        .rega       (regouta),
        .regb       (regoutb),

        .branch     (id_branch),
        .jump       (id_jump),
        .al         (id_al),
        .target     (id_target),
        .SPEC       (id_SPEC),
        .load       (id_load),
        .loadX      (id_loadX),
        .imm        (id_imm),
        .immXtype   (id_immXtype),
        .regwen     (id_regwen),
        .wreg       (id_wreg),
        .hiloren    (id_hiloren),
        .hilowen    (id_hilowen),
        .data_en    (id_data_en),
        .data_ren   (id_data_ren),
        .data_wen   (id_data_wen),
        .cp0ren     (id_cp0ren),
        .cp0wen     (id_cp0wen),
        .cp0addr    (id_cp0addr),
        .func       (id_func),
        .ReservedIns(ReservedIns),
        .BreakEx    (BreakEx),
        .SyscallEx  (SyscallEx)
    );

    id_ex_seg u_id_ex_seg(
        .clk        (clk),
        .resetn     (resetn),
        .id_pc      (id_pc),
        .id_inst    (id_inst),
        .id_imm     (id_imm),
        .id_Imm     (id_Imm),
        .id_A       (regouta),
        .id_B       (regoutb),
        .id_al      (id_al),
        .id_SPEC    (id_SPEC),
        .id_load    (id_load),
        .id_loadX   (id_loadX),
        .id_ifunc   (id_ifunc),
        .id_regwen  (id_regwen),
        .id_wreg    (id_wreg),
        .id_data_en (id_data_en),
        .id_data_ren(id_data_ren),
        .id_data_wen(id_data_wen),
        .id_cp0ren  (id_cp0ren),
        .id_cp0wen  (id_cp0wen),
        .id_cp0addr (id_cp0addr),
        .id_hiloren   (id_hiloren),
        .id_hilowen   (id_hilowen),

        .ex_pc      (ex_pc),
        .ex_inst    (ex_inst),
        .ex_imm     (ex_imm),
        .ex_Imm     (ex_Imm),
        .ex_A       (ex_A),
        .ex_B       (ex_B),
        .ex_al      (ex_al),
        .ex_SPEC    (ex_SPEC),
        .ex_load    (ex_load),
        .ex_loadX   (ex_loadX),
        .ex_ifunc   (ex_ifunc),
        .ex_regwen  (ex_regwen),
        .ex_wreg    (ex_wreg),
        .ex_data_en (ex_data_en),
        .ex_data_ren(ex_data_ren),
        .ex_data_wen(ex_data_wen),
        .ex_cp0ren  (ex_cp0ren),
        .ex_cp0wen  (ex_cp0wen),
        .ex_cp0addr (ex_cp0addr),
        .ex_hiloren (ex_hiloren),
        .ex_hilowen (ex_hilowen)
    );

    // *EX
    wire [31:0] inAlu1  =   (mem_regwen && mem_wreg == `GET_Rs(ex_inst)) ? mem_res :    //* mem段写ex段的rs
                            (wb_regwen && wb_wreg == `GET_Rs(ex_inst)) ? wb_res :       //* wb段写ex段的rs
                            (wb_load && wb_wreg == `GET_Rs(ex_inst)) ? wb_rdata :       //* wb段load写ex段的rs
                            (mem_cp0ren && mem_wreg == `GET_Rs(ex_inst)) ? mem_cp0rdata : //* mem段读cp0写ex段的rs
                            (wb_cp0ren && wb_wreg == `GET_Rs(ex_inst)) ? wb_cp0rdata :  //* wb段读cp0写ex段rs
                            (mem_hiloren && mem_wreg == `GET_Rs(ex_inst)) ? mem_hilordata : //* mem段读HI/LO写ex段的rs
                            (wb_hiloren && wb_wreg == `GET_Rs(ex_inst)) ? wb_hilordata ://* wb段读HI/LO写ex段的rs
                            ex_A;

    wire [31:0] inAlu2  =   ex_imm ? ex_Imm : 
                            (mem_regwen && mem_wreg == `GET_Rt(ex_inst)) ? mem_res :    //* mem段写ex段的rt
                            (wb_regwen && wb_wreg == `GET_Rt(ex_inst)) ? wb_res :       //* wb段写ex段的rt
                            (wb_load && wb_wreg == `GET_Rt(ex_inst)) ? wb_rdata :       //* wb段load写ex段的rt
                            (mem_cp0ren && mem_wreg == `GET_Rt(ex_inst)) ? mem_cp0rdata : //* mem段读cp0写ex段的rt
                            (wb_cp0ren && wb_wreg == `GET_Rt(ex_inst)) ? wb_cp0rdata :  //* wb段读cp0写ex段rt
                            (mem_hiloren && mem_wreg == `GET_Rt(ex_inst)) ? mem_hilordata : //* mem段读HI/LO写ex段的rt
                            (wb_hiloren && wb_wreg == `GET_Rt(ex_inst)) ? wb_hilordata ://* wb段读HI/LO写ex段的rt
                            ex_B;
                            
    wire [5 :0] ex_func =   ex_SPEC ? `GET_FUNC(ex_inst) : ex_ifunc;

    alu u_alu(
        .A      (inAlu1),
        .B      (inAlu2),
        .func   (ex_func),
        .sa     (`GET_SA(ex_inst)),

        .IntegerOverflow    (IntegerOverflow),
        .res                (ex_res)
    );

    // mul u_mul(

    // );

    // div u_div(

    // );

    // TODO: write HI LO
    wire [31:0] hiwdata =   ex_func == `MTHI ? ex_A : // *GPR[rs] -> HI
                            ex_mul ? :
                            ex_div ? : 32'b0;
    wire [31:0] lowdata =   ex_func == `MTLO ? ex_A : // *GPR[rs] -> LO
                            ex_mul ? :
                            ex_div ? : 32'b0;

    hilo u_hilo(
        .clk    (clk),
        .resetn (resetn),
        .wen    (ex_hilowen),
        .hiwdata(hiwdata),
        .lowdata(lowdata),
        .ren    (ex_hiloren),
        .rdata  (ex_hilordata)
    );

    ex_mem_seg u_ex_mem_seg (
        .clk        (clk),
        .resetn     (resetn),
        .ex_pc      (ex_pc),
        .ex_inst    (ex_inst),
        .ex_res     (ex_res),
        .ex_SPEC    (ex_SPEC),
        .ex_load    (ex_load),
        .ex_loadX   (ex_loadX),
        .ex_al      (ex_al),
        .ex_data_en (ex_data_en),
        .ex_data_ren(ex_data_ren),
        .ex_data_wen(ex_data_wen),
        .ex_wdata   (ex_B),
        .ex_regwen  (ex_regwen),
        .ex_wreg    (ex_wreg),
        .ex_cp0ren  (ex_cp0ren),
        .ex_cp0wen  (ex_cp0wen),
        .ex_cp0addr (ex_cp0addr),
        .ex_hiloren     (ex_hiloren),
        .ex_hilowen     (ex_hilowen),
        .ex_hilordata   (ex_hilowrdata),

        .mem_pc         (mem_pc),
        .mem_pc         (mem_inst),
        .mem_res        (mem_res),
        .mem_SPEC       (mem_SPEC),
        .mem_load       (mem_load),
        .mem_loadX      (mem_loadX),
        .mem_al         (mem_al),
        .mem_data_en    (data_sram_en),     // * data_sram_en
        .mem_data_ren   (mem_data_ren),
        .mem_data_wen   (data_sram_wen),    // * data_sram_wen
        .mem_wdata      (data_sram_wdata),  // * data_sram_wdata
        .mem_regwen     (mem_regwen),
        .mem_wreg       (mem_wreg),
        .mem_cp0ren     (mem_cp0ren),
        .mem_cp0wen     (mem_cp0wen),
        .mem_cp0addr    (mem_cp0addr),
        .mem_hiloren    (mem_hiloren),
        .mem_hilowen    (mem_hilowen),
        .mem_hilordata  (mem_hilordata)
    );

    // *MEM
    assign data_sram_addr     = mem_res;
    assign data_ADDRESS_ERROR = !data_sram_en ? 1'b0 :  // 不访存
                                mem_load ? (            // load指令
                                    (mem_data_ren == 4'b0001) ? 1'b0 :
                                    (mem_data_ren == 4'b0011) ? data_sram_addr[0] != 1'b0 :
                                    (mem_data_ren == 4'b1111) ? data_sram_addr[1:0] != 2'b00 : 1'b0
                                ) : // store
                                (mem_data_wen == 4'b0001) ? 1'b0 :
                                (mem_data_wen == 4'b0011) ? data_sram_addr[0] != 1'b0 :
                                (mem_data_wen == 4'b1111) ? data_sram_addr[1:0] != 2'b00 : 1'b0;

    // TODO: CP0 regs
    cp0 u_cp0(
        .clk    (clk),
        .resetn (resetn),
        .wen    (mem_cp0wen),
        .addr   (mem_cp0addr),
        .rdata  (mem_cp0rdata)
    );

    mem_wb_seg u_mem_wb_seg(
        .clk            (clk),
        .resetn         (resetn),
        .mem_pc         (mem_pc),
        .mem_inst       (mem_inst),
        .mem_res        (mem_res),
        .mem_rdata      (data_sram_rdata),
        .mem_load       (mem_load),
        .mem_al         (mem_al),
        .mem_regwen     (mem_regwen),
        .mem_wreg       (mem_wreg),
        .mem_cp0ren     (mem_cp0ren),
        .mem_cp0rdata   (mem_cp0rdata),
        .mem_hiloren    (mem_hiloren),
        .mem_hilowen    (mem_hilowen),
        .mem_hilordata  (mem_hilordata),

        .wb_pc      (wb_pc),
        .wb_inst    (wb_inst),
        .wb_res     (wb_res),
        .wb_rdata   (wb_rdata),
        .wb_load    (wb_load),
        .wb_al      (wb_al),
        .wb_regwen  (wb_regwen),
        .wb_wreg    (wb_wreg),
        .wb_cp0ren  (wb_cp0ren),
        .wb_cp0rdata(wb_cp0rdata),
        .wb_hiloren     (wb_hiloren),
        .wb_hilowen     (wb_hilowen),
        .wb_hilordata   (wb_hilordata)
    );

    // *WB
    assign inRegData =  wb_al ? wb_pc + 32'd8 :     // *al: pc+8 -> GPR[31]
                        wb_load ? wb_rdata :        // *load: data from mem -> GPR[rt]
                        wb_cp0ren ? wb_cp0rdata :      // *MFC0: data from CP0 -> GPR[rt]
                        wb_hiloren > 0 ? wb_hilordata : // *MFHI/LO: data from HI/LO -> GPR[rd]
                        wb_res; // *SPEC: data from ALU -> GPR[rd]

    // *debug
    assign debug_wb_pc          = wb_pc;
    assign debug_wb_rf_wen      = {3'b000, wb_regwen}; // TODO: ? {000, regwen} ? {4{regwen}}
    assign debug_wb_rf_wnum     = wb_wreg;
    assign debug_wb_rf_wdata    = inRegData;

endmodule
