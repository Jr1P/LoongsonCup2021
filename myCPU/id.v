`timescale 1ns/1ps
`include "./head.vh"

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
    output      [31:0]  target          // valid when JUMP == 1
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
    output      [1 :0]  rhilo,          // 2'b01: read LO, 2'b10: read HI
    output      [1 :0]  whilo,          // 0: not write, whilo[0] == 1: write lo, whilo[1] == 1: write hi
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

assign rhilo    =   {2{opcode == `SPEC}} & {IR_func == `MFHI, IR_func == `MFLO};

assign whilo    =   {2{opcode == `SPEC}} & 
                    (IR_func >= `MULT && IR_func <= `DIVU) ? 2'b11 : {IR_func == `MTHI, IR_func == `MTLO};

assign cp0ren   =   opcode == `PRI && rscode == `MFC0;
assign cp0wen   =   opcode == `PRI && rscode == `MTC0;
assign cp0addr  =   {rdcode, selcode};

// * ex
assign eret         = id_inst == `ERET;
assign ReservedIns  = ; // TODO: inst table
assign BreakEx      = opcode == `SPEC && IR_func == `BREAK;
assign SyscallEx    = opcode == `SPEC && IR_func == `SYSCALL;

endmodule