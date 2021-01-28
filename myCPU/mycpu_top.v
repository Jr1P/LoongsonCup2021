`timescale 1ns / 1ps

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

    reg [31:0]  PC;       // * PC[1:0] is always 2'b0

    // *regs
    // * IF/ID 
    reg [31:0]  IF_ID_PC;
    reg [31:0]  IF_ID_NPC;
    reg [31:0]  IF_ID_IR;
    // * ID/EX
    reg         ID_EX_imm;
    reg         ID_EX_regwen;
    reg         ID_EX_R;
    reg         ID_EX_AL;
    reg [3 :0]  ID_EX_data_wen;
    reg [5 :0]  ID_EX_func;
    reg [31:0]  ID_EX_A;
    reg [31:0]  ID_EX_B;
    reg [31:0]  ID_EX_PC;
    reg [31:0]  ID_EX_IR;
    reg [31:0]  ID_EX_Imm;
    // * EX/MEM
    reg         EX_MEM_R;
    reg         EX_MEM_regwen;
    reg [31:0]  EX_MEM_PC;
    reg [31:0]  EX_MEM_IR;
    reg [31:0]  EX_MEM_AluOut;
    reg [31:0]  EX_MEM_B;
    // * MEM/WB
    reg         MEM_WB_R;
    reg         MEM_WB_regwen;
    reg [31:0]  MEM_WB_PC;
    reg [31:0]  MEM_WB_AluOut;
    reg [31:0]  MEM_WB_DataOut;

    // *wires
    // *IF
    wire [31:0] NPC;
    // *ID
    wire        JUMP;
    wire        regwen;
    wire        AL;
    wire        R;
    wire        branch;
    wire        imm;
    wire [1 :0] immXtype;
    wire [3 :0] data_wen;
    wire [5 :0] func;
    wire [31:0] Imm;
    wire [31:0] inRegData;
    wire [31:0] regouta;
    wire [31:0] regoutb;
    wire [31:0] target;
    // *EX
    wire [31:0] inAlu1;
    wire [31:0] inAlu2;
    // *MEM

    // *WB

    always @(posedge clk) begin
        // MEM/WB
        MEM_WB_DataOut <= data_sram_rdata;

        ID_EX_imm   <= imm;

        ID_EX_Imm   <= Imm;

        IF_ID_PC    <= PC;
        IF_ID_IR    <= inst_sram_rdata;
        IF_ID_NPC   <= NPC;

        PC <= !resetn ? 32'b0 : NPC;
       

    end
    
    // *IF
    assign inst_sram_en     = 1'b1;     // always
    assign inst_sram_wen    = 4'b0;     // not write
    assign inst_sram_addr   = PC;
    assign inst_sram_wdata  = 32'b0;    // not write

    assign NPC = branch && JUMP ? target : PC+4;
    // *ID
    assign inRegData= ;   // TODO:
    assign Imm      =   immXtype == 2'b0  ? {16'b0, IF_ID_IR[15:0]}             :   // zero extend
                        immXtype == 2'b01 ? {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]}:   // signed extend
                        {IF_ID_IR[15:0], 16'b0};                                    // {imm, {16{0}}}
    regfile regfile(
        .clk    (clk            ),
        .resetn (resetn         ),
        .rs     (IF_ID_IR[25:21]),
        .rt     (IF_ID_IR[20:16]),
        .wen    (MEM_WB_regwen  ),
        .wreg   (MEM_WB_wreg    ),
        .inData (inRegData      ),

        .outA   (regouta        ),
        .outB   (regoutb        )
    );

    cu cu(
        .IR         (IF_ID_IR   ),
        .PC         (IF_ID_PC   ),
        .rs         (regouta    ),
        .rt         (regoutb    ),

        .regwen     (regwen     ),
        .branch     (branch     ),
        .JUMP       (JUMP       ),
        .AL         (AL         ),
        .R          (R          ),
        .imm        (imm        ),
        .immXtype   (immXtype   ),
        .data_wen   (data_wen   ),
        .func       (func       ),
        .target     (target     )
    );

    // *EX
    assign inAlu1   = ;
    assign inAlu2   = ;
    alu alu(
        .clk            (clk),
        .resetn         (resetn),
        .A              (inAlu1),
        .B              (inAlu2),
        .func           (ID_EX_IR[5:0]),
        .sa             (ID_EX_IR[]),

        .IntegerOverflow(),
        .res()
    );

    // *MEM
    assign data_sram_en     = ;         // Load Store: 1
    assign data_sram_wen    = ;         //
    assign data_sram_addr   = ;         //
    assign data_sram_wdata  = ;         //

    // *WB


    // *debug
    assign debug_wb_pc          = MEM_WB_PC;
    assign debug_wb_rf_wen      = {3'b000, MEM_WB_regwen};
    assign debug_wb_rf_wnum     = MEM_WB_wreg;
    assign debug_wb_rf_wdata    = inRegData;


endmodule
