`timescale 1ns / 1ps
`include "./head.vh"

// * five segment pipeline cpu
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
    wire    if_inst_ADDRESS_ERROR;
    wire    id_ReservedIns;
    wire    ex_IntegerOverflow, id_BreakEx, id_SyscallEx;
    wire    mem_data_ADDRESS_ERROR;
    // *ID
    wire [`EXBITS]  id_ex;
    wire [31:0] id_pc;
    wire [31:0] id_inst;
    wire [4 :0] id_rs = `GET_Rs(id_inst);
    wire [4 :0] id_rt = `GET_Rt(id_inst);
    wire        id_bd;
    wire        id_jump;
    wire        id_branch;
    wire [31:0] id_target;
    wire        id_al;
    wire        id_SPEC;
    wire        id_rs_ren;
    wire        id_rt_ren;
    wire [5 :0] id_ifunc;
    wire        id_load;
    wire        id_loadX;
    wire        id_imm;
    wire [1 :0] id_immXtype;
    wire        id_eret;
    wire        id_data_en;
    wire [3 :0] id_data_ren;
    wire [3 :0] id_data_wen;
    wire        id_regwen;
    wire [4 :0] id_wreg;
    wire        id_cp0ren;
    wire        id_cp0wen;
    wire [7 :0] id_cp0addr;
    wire        id_mult;
    wire        id_div;
    wire        id_mdsign;
    wire [1 :0] id_hiloren;
    wire [1 :0] id_hilowen;
    // *EX
    wire [`EXBITS]  ex_ex;
    wire [31:0] ex_pc;
    wire [31:0] ex_inst;
    wire [4 :0] ex_rs = `GET_Rs(ex_inst);
    wire [4 :0] ex_rt = `GET_Rt(ex_inst);
    wire [31:0] ex_res;
    wire        ex_imm;
    wire [31:0] ex_Imm;
    wire [31:0] ex_A;
    wire [31:0] ex_B;
    wire        ex_rs_ren;
    wire        ex_rt_ren;
    wire        ex_al;
    wire        ex_SPEC;
    wire        ex_load;
    wire        ex_loadX;
    wire        ex_bd;
    wire [5 :0] ex_ifunc;
    wire        ex_regwen;
    wire [4 :0] ex_wreg;
    wire        ex_data_en;
    wire [3 :0] ex_data_ren;
    wire [3 :0] ex_data_wen;
    wire        ex_eret;
    wire        ex_cp0ren;
    wire        ex_cp0wen;
    wire [7 :0] ex_cp0addr;
    wire        ex_mult;
    wire        ex_div;
    wire        ex_mdsign;
    wire [1 :0] ex_hilowen;
    wire [1 :0] ex_hiloren;
    wire [31:0] ex_hilordata;
    // *MEM
    wire [`EXBITS]  mem_ex;
    wire [31:0] mem_pc;
    wire [31:0] mem_inst;
    wire [31:0] mem_res;
    wire        mem_load;
    wire        mem_loadX;
    wire        mem_bd;
    wire        mem_regwen;
    wire [4 :0] mem_wreg;
    wire [3 :0] mem_data_ren;
    wire [31:0] mem_rdata;
    wire [3 :0] mem_data_wen;
    wire [31:0] mem_wdata;
    wire        mem_eret;
    wire        mem_exc_oc;
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
    wire [4 :0] wb_wreg;
    wire        wb_eret;
    wire        wb_cp0ren;
    wire [31:0] wb_cp0rdata;
    wire [1 :0] wb_hiloren;
    wire [1 :0] wb_hilowen;
    wire [31:0] wb_hilordata;

    wire [31:0] cp0_epc;

    cu u_cu(
        .id_pc      (id_pc),

        .mem_regwen (mem_regwen),
        .mem_load   (mem_load),
        .mem_wreg   (mem_wreg),
        .ex_rs_ren  (ex_rs_ren),
        .ex_rs      (ex_rs),
        .ex_rt_ren  (ex_rt_ren),
        .ex_rt      (ex_rt),

        .exc_oc     (mem_exc_oc),

        .id_branch  (id_branch),
        .id_rs_ren  (id_rs_ren),
        .id_rs      (id_rs),
        .id_rt_ren  (id_rt_ren),
        .id_rt      (id_rt),

        .ex_regwen  (ex_regwen),    
        .ex_load    (ex_load),
        .ex_cp0ren  (ex_cp0ren),
        .ex_wreg    (ex_wreg),

        .if_id_stall    (if_id_stall),
        .id_ex_stall    (id_ex_stall),
        .ex_mem_stall   (ex_mem_stall),
        .mem_wb_stall   (mem_wb_stall),

        .if_id_refresh  (if_id_refresh),
        .id_ex_refresh  (id_ex_refresh),
        .ex_mem_refresh (ex_mem_refresh),
        .mem_wb_refresh (mem_wb_refresh)
);

    // * 重定向数据
    wire [31:0] ex_reorder_data =   {32{|ex_hiloren}} & mem_hilordata   |   //* ex段读HI/LO写ex段的rs
                                    {32{ex_al}     } & (mem_pc+32'd8)   |   //* ex段al写GPR[31]
                                    {32{!ex_load && !ex_cp0ren && !(|ex_hiloren) && !ex_al}} & ex_res;

    wire [31:0] mem_reorder_data=   {32{mem_cp0ren} } & mem_cp0rdata    |   //* mem段读cp0写ex段rs
                                    {32{|mem_hiloren}} & mem_hilordata  |   //* mem段读HI/LO写ex段的rs
                                    {32{mem_al}     } & (mem_pc+32'd8)  |   //* mem段al写GPR[31]
                                    {32{!mem_load && !mem_cp0ren && !(|mem_hiloren) && !mem_al}} & mem_res;

    wire [31:0] wb_reorder_data =   {32{wb_load}    } & wb_rdata        |   //* wb段load写ex段的rs
                                    {32{wb_cp0ren}  } & wb_cp0rdata     |   //* wb段读cp0写ex段rs
                                    {32{|wb_hiloren}} & wb_hilordata    |   //* wb段读HI/LO写ex段的rs
                                    {32{wb_al}      } & (wb_pc+32'd8)   |   //* wb段al写GPR[31]
                                    {32{!wb_load && !wb_cp0ren && !(|wb_hiloren) && !wb_al}} & wb_res;

    // *IF
    assign inst_sram_en     = 1'b1;     // always enable
    assign inst_sram_wen    = 4'b0;     // not write
    assign inst_sram_wdata  = 32'b0;    // not write

    pc u_pc(
        .clk            (clk),
        .resetn         (resetn),
        .stall          (if_id_stall),
        .BranchTarget   (id_target),
        .BranchTake     (id_branch && id_jump),
        .exc_oc         (mem_exc_oc),

        .eret           (mem_eret), // * eret
        .epc            (cp0_epc),  // * epc from cp0
        .npc            (inst_sram_addr)
    );

    assign if_inst_ADDRESS_ERROR = inst_sram_addr[1:0] != 2'b00;
    wire [`EXBITS] if_ex = {if_inst_ADDRESS_ERROR, `NUM_EX_1'b0};

    if_id_seg u_if_id_seg(
        .clk    (clk),
        .resetn (resetn),

        .stall  (if_id_stall),
        .refresh(if_id_refresh),

        .id_branch  (id_branch),
        .if_ex      (if_ex),
        .if_pc      (inst_sram_addr),
        // .if_inst    (inst_sram_rdata),

        .id_bd  (id_bd),
        .id_ex  (id_ex),
        .id_pc  (id_pc)
        // .id_inst(id_inst)
    );

    // *ID
    wire [31:0] inRegData;
    wire [31:0] regouta, regoutb;

    wire [31:0] id_Imm  =   id_immXtype == 2'b0  ? {16'b0, `GET_Imm(id_inst)}           : // zero extend
                            id_immXtype == 2'b01 ? {{16{id_inst[15]}}, `GET_Imm(id_inst)} : // signed extend
                            {`GET_Imm(id_inst), 16'b0};                                     // {imm, {16{0}}}
    assign id_inst = inst_sram_rdata;

    regfile u_regfile(
        .clk    (clk),
        .resetn (resetn),
        .rs     (id_rs),
        .rt     (id_rt),
        .wen    (wb_regwen),
        .wreg   (wb_wreg),
        .wdata  (inRegData),

        .outA   (regouta),
        .outB   (regoutb)
    );

    wire [31:0] re_rs = id_branch && id_rs_ren ? 
                            ex_regwen && ex_wreg == id_rs   ? ex_reorder_data   :
                            mem_regwen && mem_wreg == id_rs ? mem_reorder_data  :
                            wb_regwen && wb_wreg == id_rs   ? wb_reorder_data   : regouta
                        : 32'b0;
    wire [31:0] re_rt = id_branch && id_rt_ren ?
                            ex_regwen && ex_wreg == id_rt   ? ex_reorder_data   :
                            mem_regwen && mem_wreg == id_rt ? mem_reorder_data  :
                            wb_regwen && wb_wreg == id_rt   ? wb_reorder_data   : regoutb
                        : 32'b0;

    id u_id(
        .id_inst    (id_inst),
        .id_pc      (id_pc),
        .rega       (re_rs),
        .regb       (re_rt),

        .branch     (id_branch),
        .jump       (id_jump),
        .al         (id_al),
        .target     (id_target),
        .SPEC       (id_SPEC),
        .rs_ren     (id_rs_ren),
        .rt_ren     (id_rt_ren),
        .load       (id_load),
        .loadX      (id_loadX),
        .imm        (id_imm),
        .immXtype   (id_immXtype),
        .regwen     (id_regwen),
        .wreg       (id_wreg),
        .mult       (id_mult),
        .div        (id_div),
        .mdsign     (id_mdsign),
        .hiloren    (id_hiloren),
        .hilowen    (id_hilowen),
        .data_en    (id_data_en),
        .data_ren   (id_data_ren),
        .data_wen   (id_data_wen),
        .cp0ren     (id_cp0ren),
        .cp0wen     (id_cp0wen),
        .cp0addr    (id_cp0addr),
        .func       (id_ifunc),

        .eret       (id_eret),
        .ReservedIns(id_ReservedIns),
        .BreakEx    (id_BreakEx),
        .SyscallEx  (id_SyscallEx)
    );

    wire [`EXBITS] ID_ex = {id_ex[`NUM_EX-1], id_ReservedIns, 1'b0, id_SyscallEx, id_BreakEx, 1'b0};

    id_ex_seg u_id_ex_seg(
        .clk    (clk),
        .resetn (resetn),

        .stall  (id_ex_stall),
        .refresh(id_ex_refresh),

        .id_ex      (ID_ex),
        .id_pc      (id_pc),
        .id_inst    (id_inst),
        .id_imm     (id_imm),
        .id_Imm     (id_Imm),
        .id_A       (regouta),
        .id_B       (regoutb),
        .id_rs_ren  (id_rs_ren),
        .id_rt_ren  (id_rt_ren),
        .id_al      (id_al),
        .id_SPEC    (id_SPEC),
        .id_load    (id_load),
        .id_loadX   (id_loadX),
        .id_bd      (id_bd),
        .id_ifunc   (id_ifunc),
        .id_regwen  (id_regwen),
        .id_wreg    (id_wreg),
        .id_data_en (id_data_en),
        .id_data_ren(id_data_ren),
        .id_data_wen(id_data_wen),
        .id_eret    (id_eret),
        .id_cp0ren  (id_cp0ren),
        .id_cp0wen  (id_cp0wen),
        .id_cp0addr (id_cp0addr),
        .id_mult    (id_mult),
        .id_div     (id_div),
        .id_mdsign  (id_mdsign),
        .id_hiloren (id_hiloren),
        .id_hilowen (id_hilowen),

        .ex_ex      (ex_ex),
        .ex_pc      (ex_pc),
        .ex_inst    (ex_inst),
        .ex_imm     (ex_imm),
        .ex_Imm     (ex_Imm),
        .ex_A       (ex_A),
        .ex_B       (ex_B),
        .ex_rs_ren  (ex_rs_ren),
        .ex_rt_ren  (ex_rt_ren),
        .ex_al      (ex_al),
        .ex_SPEC    (ex_SPEC),
        .ex_load    (ex_load),
        .ex_loadX   (ex_loadX),
        .ex_bd      (ex_bd),
        .ex_ifunc   (ex_ifunc),
        .ex_regwen  (ex_regwen),
        .ex_wreg    (ex_wreg),
        .ex_data_en (ex_data_en),
        .ex_data_ren(ex_data_ren),
        .ex_data_wen(ex_data_wen),
        .ex_eret    (ex_eret),
        .ex_cp0ren  (ex_cp0ren),
        .ex_cp0wen  (ex_cp0wen),
        .ex_cp0addr (ex_cp0addr),
        .ex_mult    (ex_mult),
        .ex_div     (ex_div),
        .ex_mdsign  (ex_mdsign),
        .ex_hiloren (ex_hiloren),
        .ex_hilowen (ex_hilowen)
    );

    // *EX
    wire [31:0] inAlu1  =   mem_wreg == ex_rs && mem_regwen ? mem_reorder_data  :
                            wb_wreg == ex_rs && wb_regwen   ? wb_reorder_data   : ex_A;

    wire [31:0] inAlu2  =   ex_imm ? ex_Imm : 
                            mem_wreg == ex_rt && mem_regwen ? mem_reorder_data  :
                            wb_wreg == ex_rt && wb_regwen   ? wb_reorder_data   : ex_B;
                            
    wire [5 :0] ex_func =   ex_SPEC ? `GET_FUNC(ex_inst) : ex_ifunc;

    alu u_alu(
        .A      (inAlu1),
        .B      (inAlu2),
        .func   (ex_func),
        .sa     (`GET_SA(ex_inst)),

        .IntegerOverflow    (ex_IntegerOverflow),
        .res                (ex_res)
    );

    wire [63:0] mul_res, mul_signed_res;
    mul u_mul(
        .A      (inAlu1),
        .B      (inAlu2),

        .res        (mul_res),
        .signedres  (mul_signed_res)
    );
    wire [63:0] div_res, div_signed_res;
    div u_div(
        .A  (inAlu1),
        .B  (inAlu2),

        .res        (div_res),
        .signedres  (div_signed_res)
    );

    // * write HI LO
    wire [31:0] hiwdata =   ex_func == `MTHI ? inAlu1 : // *GPR[rs] -> HI
                            ex_mult ?
                                {32{ex_mdsign}  } & mul_res[63:32] |
                                {32{!ex_mdsign} } & mul_signed_res[63:32] :
                            ex_div  ? 
                                {32{ex_mdsign}  } & div_res[63:32] |
                                {32{!ex_mdsign} } & div_signed_res[63:32] :
                            32'b0;
    wire [31:0] lowdata =   ex_func == `MTLO ? inAlu1 : // *GPR[rs] -> LO
                            ex_mult ?
                                {32{ex_mdsign}  } & mul_res[31:0] |
                                {32{!ex_mdsign} } & mul_signed_res[31:0] :
                            ex_div  ? 
                                {32{ex_mdsign}  } & div_res[31:0] |
                                {32{!ex_mdsign} } & div_signed_res[31:0] :
                            32'b0;

    hilo u_hilo(
        .clk    (clk),
        .resetn (resetn),
        .wen    (ex_hilowen),
        .hiwdata(hiwdata),
        .lowdata(lowdata),
        .ren    (ex_hiloren),
        .rdata  (ex_hilordata)
    );

    wire [`EXBITS] EX_ex = ex_ex | {2'b0, ex_IntegerOverflow, 3'b0};

    ex_mem_seg u_ex_mem_seg (
        .clk    (clk),
        .resetn (resetn),

        .stall  (ex_mem_stall),
        .refresh(ex_mem_refresh),

        .ex_ex      (EX_ex),
        .ex_pc      (ex_pc),
        .ex_inst    (ex_inst),
        .ex_res     (ex_res),
        .ex_SPEC    (ex_SPEC),
        .ex_load    (ex_load),
        .ex_loadX   (ex_loadX),
        .ex_bd      (ex_bd),
        .ex_al      (ex_al),
        .ex_data_en (ex_data_en),
        .ex_data_ren(ex_data_ren),
        .ex_data_wen(ex_data_wen),
        .ex_wdata   (ex_B),     // *store命令写入的数据, mtc0命令的写入数据
        .ex_regwen  (ex_regwen),
        .ex_wreg    (ex_wreg),
        .ex_eret    (ex_eret),
        .ex_cp0ren  (ex_cp0ren),
        .ex_cp0wen  (ex_cp0wen),
        .ex_cp0addr (ex_cp0addr),
        .ex_hiloren     (ex_hiloren),
        .ex_hilowen     (ex_hilowen),
        .ex_hilordata   (ex_hilordata),

        .mem_ex         (mem_ex),
        .mem_pc         (mem_pc),
        .mem_inst       (mem_inst),
        .mem_res        (mem_res),
        .mem_SPEC       (mem_SPEC),
        .mem_load       (mem_load),
        .mem_loadX      (mem_loadX),
        .mem_bd         (mem_bd),
        .mem_al         (mem_al),
        .mem_data_en    (data_sram_en),     // * data_sram_en
        .mem_data_ren   (mem_data_ren),
        .mem_data_wen   (data_sram_wen),    // * data_sram_wen
        .mem_wdata      (mem_wdata),        // * mem_wdata: store命令写入数据, mtc0命令的写入数据
        .mem_regwen     (mem_regwen),
        .mem_wreg       (mem_wreg),
        .mem_eret       (mem_eret),
        .mem_cp0ren     (mem_cp0ren),
        .mem_cp0wen     (mem_cp0wen),
        .mem_cp0addr    (mem_cp0addr),
        .mem_hiloren    (mem_hiloren),
        .mem_hilowen    (mem_hilowen),
        .mem_hilordata  (mem_hilordata)
    );

    // *MEM
    wire [4:0] mem_rt = `GET_Rt(mem_inst);
    assign data_sram_addr = mem_res;
 
    assign mem_data_ADDRESS_ERROR = data_sram_en && (mem_load && (mem_data_ren == 4'b0011 && data_sram_addr[0] || mem_data_ren == 4'b1111 && data_sram_addr[1:0] != 2'b00)
                                    || !mem_load && (mem_data_wen == 4'b0011 && data_sram_addr[0] || mem_data_wen == 4'b1111 && data_sram_addr[1:0] != 2'b00));
                                // !data_sram_en ? 1'b0 :  // 不访存
                                // mem_load ? (            // load指令
                                //     (mem_data_ren == 4'b0001) ? 1'b0 :
                                //     (mem_data_ren == 4'b0011) ? data_sram_addr[0] != 1'b0 :
                                //     (mem_data_ren == 4'b1111) ? data_sram_addr[1:0] != 2'b00 : 1'b0
                                // ) : // store
                                // (mem_data_wen == 4'b0001) ? 1'b0 :
                                // (mem_data_wen == 4'b0011) ? data_sram_addr[0] != 1'b0 :
                                // (mem_data_wen == 4'b1111) ? data_sram_addr[1:0] != 2'b00 : 1'b0;

    wire [`EXBITS] MEM_ex = mem_ex | {5'b0, mem_data_ADDRESS_ERROR};
    wire [4:0] ex_excode =  ext_int ? `EXC_INT :
                            MEM_ex[5] ? `EXC_AdEL : // *取指地址错
                            MEM_ex[4] ? `EXC_RI :   // *RI
                            MEM_ex[3] ? `EXC_Ov :   // *Overflow
                            MEM_ex[2] ? `EXC_Bp :   // *Break point
                            MEM_ex[1] ? `EXC_Sys :  // *syscall
                            MEM_ex[0] ? 
                                mem_load ? `EXC_AdEL : `EXC_AdES
                            : 5'b0;

    wire ext_int_response;
    wire [31:0] ex_epc = mem_bd ? mem_pc-32'd4 : mem_pc;
    wire [31:0] cp0_status, cp0_cause;
    wire ex_valid = cp0_cause[`Status_EXL] ? !wb_eret : // * valid 1 : 表示有例外在处理, 刚传到mem段的例外也算属于在处理
                    ext_int_response ? 1'b1 : |MEM_ex;
    wire [31:0] cp0_wdata = wb_regwen && mem_rt == wb_wreg ? wb_reorder_data : mem_wdata;
    assign data_sram_wdata = cp0_wdata; // * 重定向一致 cp0_wdata, data_sram_wdata
  
    assign mem_exc_oc = !cp0_cause[`Status_EXL] && ex_valid;
    // * CP0 regs
    cp0 u_cp0(
        .clk    (clk),
        .resetn (resetn),

        .ext_int            (ext_int),
        .ext_int_response   (ext_int_response),

        .wen    (mem_cp0wen),
        .addr   (mem_cp0addr),
        .wdata  (cp0_wdata),
        .rdata  (mem_cp0rdata),

        .ex_valid   (ex_valid),
        .ex_excode  (ex_excode),
        .ex_bd      (mem_bd),
        .ex_epc     (ex_epc),   // * 中断的时候epc 也给mem段的pc
        .ex_badvaddr(data_sram_addr),
        .ex_eret    (mem_eret),

        .cause      (cp0_cause),
        .status     (cp0_status),
        .epc        (cp0_epc)
    );

    mem_wb_seg u_mem_wb_seg(
        .clk    (clk),
        .resetn (resetn),

        .stall  (mem_wb_stall),
        .refresh(mem_wb_refresh),

        .mem_pc         (mem_pc),
        .mem_inst       (mem_inst),
        .mem_res        (mem_res),
        .mem_load       (mem_load),
        .mem_al         (mem_al),
        .mem_regwen     (mem_regwen),
        .mem_wreg       (mem_wreg),
        .mem_eret       (mem_eret),
        .mem_cp0ren     (mem_cp0ren),
        .mem_cp0rdata   (mem_cp0rdata),
        .mem_hiloren    (mem_hiloren),
        .mem_hilowen    (mem_hilowen),
        .mem_hilordata  (mem_hilordata),

        .wb_pc      (wb_pc),
        .wb_inst    (wb_inst),
        .wb_res     (wb_res),
        .wb_load    (wb_load),
        .wb_al      (wb_al),
        .wb_regwen  (wb_regwen),
        .wb_wreg    (wb_wreg),
        .wb_eret    (wb_eret),
        .wb_cp0ren  (wb_cp0ren),
        .wb_cp0rdata(wb_cp0rdata),
        .wb_hiloren     (wb_hiloren),
        .wb_hilowen     (wb_hilowen),
        .wb_hilordata   (wb_hilordata)
    );

    assign wb_rdata = data_sram_rdata;

    // *WB
    assign inRegData =  wb_al ? wb_pc + 32'd8 :     // *al: pc+8 -> GPR[31]
                        wb_load ? wb_rdata :        // *load: data from mem -> GPR[rt]
                        wb_cp0ren ? wb_cp0rdata :      // *MFC0: data from CP0 -> GPR[rt]
                        |wb_hiloren ? wb_hilordata : // *MFHI/LO: data from HI/LO -> GPR[rd]
                        wb_res; // *SPEC: data from ALU -> GPR[rd]

    // *debug
    assign debug_wb_pc          = wb_pc;
    assign debug_wb_rf_wen      = {4{wb_regwen}};
    assign debug_wb_rf_wnum     = wb_wreg;
    assign debug_wb_rf_wdata    = inRegData;

endmodule
