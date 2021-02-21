`timescale 1ns/1ps
`include "./head.vh"

// * refer to ucas
module decoder #(parameter integer bits = 4)
(
    input [bits-1:0] in,
    output [(1<<bits)-1:0] out
);

    generate
        genvar i;
        for (i=0; i<(1<<bits); i=i+1) begin
            assign out[i] = in == i;
        end
    endgenerate

endmodule

// * instruction decode
module id(

    input   [31:0]  id_inst,    // used in Branch and J ins
    input   [31:0]  id_pc,
    input   [31:0]  rega,         // val in GPR[rs]
    input   [31:0]  regb,         // val in GPR[rt]
    // * 跳转相关
    output              branch,         // ! 1: conditional branch or unconditional jump, 0: not
    output              jump,           // 1: jump to target, 0: keep going on
    output              al,             // 1: save return address, 0: not
    output      [31:0]  target,         // valid when JUMP == 1
    // *
    output              SPEC,           // 1: opcode is SPEC, 0: non-SPEC
    output              load,           // 1: load data from data mem, 0:not
    output              loadX,          // valid when load is 1, 1: signed extend data loaded from data mem, 0: zero extend
    output              imm,            // 1: with immediate, 0: not
    output      [1 :0]  immXtype,       // valid when imm is 1. 0: zero extend
                                        // 1: signed extend, 2: {imm, {16{0}}}
    output              regwen,         // write en on GPRs, 1: write GPR[wreg], 0: not write
    output      [5 :0]  wreg,           // vaild when regwen is 1
    // * HI LO
    output      [1 :0]  hiloren,        // 2'b01: read LO, 2'b10: read HI
    output      [1 :0]  hilowen,        // 0: not write, whilo[0] == 1: write lo, whilo[1] == 1: write hi
    // * Data Mem
    output              data_en,        // data active en
    output      [3 :0]  data_ren,       // 4'b0001: load byte, 4'b0011: load half word, 4'b1111: load word
    output      [3 :0]  data_wen,       // data write en
    // * cp0
    output              cp0ren,         // 1: read cp0 at cp0regs[cp0addr]
    output              cp0wen,         // 1: write cp0 at cp0regs[cp0addr]
    output      [7 :0]  cp0addr,        // read or write address of cp0regs

    output      [5 :0]  func,           // valid when SPEC is 0, use for I type
    // * 例外
    output  eret,           // eret instruction
    output  ReservedIns,    // ReservedInstruction Ex 
    output  BreakEx,        // Break point Ex
    output  SyscallEx       // System call Ex
);

wire [31:0] BranchTarget    = id_pc + {{14{id_inst[15]}}, {id_inst[15:0], 2'b00}};  // branch target
wire [31:0] JTarget         = {id_pc[31:28], id_inst[25:0], 2'b00};                 // target of J and JAL
wire [31:0] JRTarget        = rega;                                                   // target of JR and JALR
wire [5 :0] opcode          = `GET_OP(id_inst);
wire [5 :0] rscode          = `GET_Rs(id_inst);
wire [5 :0] rtcode          = `GET_Rt(id_inst);
wire [5 :0] rdcode          = `GET_Rd(id_inst);
wire [5 :0] IR_func         = `GET_FUNC(id_inst);
wire [2 :0] selcode         = `GET_SEL(id_inst);
wire MFC0 = opcode == `PRI && rscode == `MFC0;

wire [63:0] op_d, func_d;
wire [31:0] rs_d, rt_d, rd_d, sa_d;

// * inst table
decoder #(.bits(6))
    dec_op (
        .in (`GET_OP(inst)),
        .out(op_d)
    ),
    dec_func (
        .in (`GET_FUNC(inst)),
        .out(func_d)
    );

decoder #(.bits(5))
    dec_rs (
        .in (`GET_Rs(inst)),
        .out(rs_d)
    ),
    dec_rt (
        .in (`GET_Rt(inst)),
        .out(rt_d)
    ),
    dec_rd (
        .in (`GET_Rd(inst)),
        .out(rd_d)
    ),
    dec_rs (
        .in (`GET_SA(inst)),
        .out(sa_d)
    );

wire op_sll     = op_d[0] && rs_d[0] && func_d[0];
wire op_srl     = op_d[0] && rs_d[0] && func_d[2];
wire op_sra     = op_d[0] && rs_d[0] && func_d[3];
wire op_sllv    = op_d[0] && sa_d[0] && func_d[4];
wire op_srlv    = op_d[0] && sa_d[0] && func_d[6];
wire op_srav    = op_d[0] && sa_d[0] && func_d[7];
wire op_jr      = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[8];
wire op_jalr    = op_d[0] && rt_d[0] && sa_d[0] && func_d[9];
wire op_syscall = op_d[0] && func_d[12];
wire op_break   = op_d[0] && func_d[13];
wire op_mfhi    = op_d[0] && rs_d[0] && rt_d[0] && sa_d[0] && func_d[16];
wire op_mthi    = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[17];
wire op_mflo    = op_d[0] && rs_d[0] && rt_d[0] && sa_d[0] && func_d[18];
wire op_mtlo    = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[19];
wire op_mult    = op_d[0] && rd_d[0] && sa_d[0] && func_d[24];
wire op_multu   = op_d[0] && rd_d[0] && sa_d[0] && func_d[25];
wire op_div     = op_d[0] && rd_d[0] && sa_d[0] && func_d[26];
wire op_divu    = op_d[0] && rd_d[0] && sa_d[0] && func_d[27];
wire op_add     = op_d[0] && sa_d[0] && func_d[32];
wire op_addu    = op_d[0] && sa_d[0] && func_d[33];
wire op_sub     = op_d[0] && sa_d[0] && func_d[34];
wire op_subu    = op_d[0] && sa_d[0] && func_d[35];
wire op_and     = op_d[0] && sa_d[0] && func_d[36];
wire op_or      = op_d[0] && sa_d[0] && func_d[37];
wire op_xor     = op_d[0] && sa_d[0] && func_d[38];
wire op_nor     = op_d[0] && sa_d[0] && func_d[39];
wire op_slt     = op_d[0] && sa_d[0] && func_d[42];
wire op_sltu    = op_d[0] && sa_d[0] && func_d[43];
wire op_bltz    = op_d[1] && rt_d[0];
wire op_bgez    = op_d[1] && rt_d[1];
wire op_bltzal  = op_d[1] && rt_d[16];
wire op_bgezal  = op_d[1] && rt_d[17];
wire op_j       = op_d[2];
wire op_jal     = op_d[3];
wire op_beq     = op_d[4];
wire op_bne     = op_d[5];
wire op_blez    = op_d[6] && rt_d[0];
wire op_bgtz    = op_d[7] && rt_d[0];
wire op_addi    = op_d[8];
wire op_addiu   = op_d[9];
wire op_slti    = op_d[10];
wire op_sltiu   = op_d[11];
wire op_andi    = op_d[12];
wire op_ori     = op_d[13];
wire op_xori    = op_d[14];
wire op_lui     = op_d[15];
wire op_mfc0    = op_d[16] && rs_d[0] && sa_d[0] && inst[5:3] == 3'b0;
wire op_mtc0    = op_d[16] && rs_d[4] && sa_d[0] && inst[5:3] == 3'b0;
wire op_eret    = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[24];
wire op_lb      = op_d[32];
wire op_lh      = op_d[33];
wire op_lw      = op_d[35];
wire op_lbu     = op_d[36];
wire op_lhu     = op_d[37];
wire op_sb      = op_d[40];
wire op_sh      = op_d[41];
wire op_sw      = op_d[43];

assign ReservedIns  = ~|{`DECODED_OPS};

// * 跳转相关
assign branch   =   (opcode >= `J && opcode <= `BGTZ) || (opcode == `JR_JALR && (IR_func == `JALR || IR_func == `JR)); // *OK

assign target   =   (opcode == `J || opcode == `JAL) ? JTarget :
                    (opcode == `JR_JALR && (IR_func == `JR  || IR_func == `JALR)) ? JRTarget:
                    BranchTarget;   // *OK

assign al       =   (opcode == `JAL) || (opcode == `JR_JALR && IR_func == `JALR) ||
                    (opcode == `BGEZ_BLTZ_BGEZAL_BLTZAL && (rtcode == `BLTZAL || rtcode == `BGEZAL)); // *OK

assign jump     =   (opcode == `J || opcode == `JAL) ||
                    (opcode == `JR_JALR && (IR_func == `JALR || IR_func == `JR)) ||
                    (opcode == `BEQ && rega == regb) ||
                    (opcode == `BNE && rega != regb) ||
                    (opcode == `BLEZ && (rega[31] || rega == 0)) ||
                    (opcode == `BGTZ && (!rega[31] && rega != 0)) ||
                    (opcode == `BGEZ_BLTZ_BGEZAL_BLTZAL && 
                        (
                            ((rtcode == `BLTZ || rtcode == `BLTZAL) && rega[31]) ||
                            ((rtcode == `BGEZ || rtcode == `BGEZAL) && !rega[31])
                        )
                    );
// *
assign func     =   (opcode == `ADDI) ? `ADD :
                    (opcode == `SLTI) ? `SLT :
                    (opcode == `SLTIU) ? `SLTU :
                    (opcode == `ANDI) ? `AND :
                    (opcode == `ORI) ? `OR :
                    (opcode == `XORI) ? `XOR :
                    // (opcode == `PRI) ? : // *Privileged Instruction ADDU即可
                    `ADDU;


assign SPEC     =   opcode == `SPEC && IR_func != `JR && IR_func != `JALR &&
                    IR_func != `SYSCALL && IR_func != `BREAK;  // opcode = 0 and not JR,JALR,BREAK,SYSCALL

assign load     =   opcode >= `LB && opcode <= `LHU;
assign loadX    =   opcode != `LBU && opcode != `LHU;

assign imm      =   (opcode >= `ADDI && opcode <= `LUI) || (opcode >= `LB && opcode <= `SW);

assign regwen   =   !whilo && (al || load || SPEC || MFC0);

assign wreg     =   SPEC ? rdcode :
                    al ? 6'd31 :
                    (imm || MFC0) ? rtcode : 6'd0;

assign immXtype =   (opcode == `LUI) ? 2'b11:                       // {imm, 16{0}}
                    (opcode >= `ANDI && opcode <= `XORI) ? 2'b00 :  // zero extend
                    2'b01;                                          // signed ex

assign data_en  =   opcode >= `LB && opcode <= `SW;

assign data_ren =   (opcode == `LB || opcode == `LBU) ? 4'b0001 :
                    (opcode == `LH || opcode == `LHU) ? 4'b0011 :
                    (opcode == `LW) ? 4'b1111 : 4'b0;

assign data_wen =   opcode == `SB ? 4'b0001:
                    opcode == `SH ? 4'b0011:
                    opcode == `SW ? 4'b1111:
                    4'b0;

assign hiloren  =   {2{opcode == `SPEC}} & {IR_func == `MFHI, IR_func == `MFLO};

assign hilowen  =   {2{opcode == `SPEC}} & 
                    (IR_func >= `MULT && IR_func <= `DIVU) ? 2'b11 : {IR_func == `MTHI, IR_func == `MTLO};

assign cp0ren   =   opcode == `PRI && rscode == `MFC0;
assign cp0wen   =   opcode == `PRI && rscode == `MTC0;
assign cp0addr  =   {rdcode, selcode};


// * ex
assign eret         = op_eret;
assign BreakEx      = op_break;
assign SyscallEx    = op_syscall;

endmodule