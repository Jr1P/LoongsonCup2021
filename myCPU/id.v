`timescale 1ns/1ps
`include "./head.vh"

// * instruction decode
module id(

    input   [31:0]  IR,         // used in Branch and J ins
    input   [31:0]  PC,         // ! PC of next ins, delay slot
    input   [31:0]  rs,         // val in GPR[rs]
    input   [31:0]  rt,         // val in GPR[rt]

    output              regwen,         // write en on reg file, 1: write reg file, 0: not write
    output              branch,         // ! 1: conditional branch or unconditional jump, 0: not
    output reg          JUMP,           // 1: jump to target, 0: keep going on
    output              AL,             // 1: save return address, 0: not
    output              R,              // 1: R type, 0: non-R
    output              imm,            // 1: with immediate, 0: not
    output      [1 :0]  immXtype,       // valid when imm is 1. 0: zero extend
                                        // 1: signed extend, 2: {imm, {16{0}}}
    output      [3 :0]  data_wen,       // data_wen
    output reg  [5 :0]  func,           // valid when R is 0, use for I type
    output      [31:0]  target          // valid when JUMP == 1
    // ? output reg         ReservedIns,    // ReservedInstruction Ex
    // ? output reg         AddressError    // 
);

wire [31:0] BranchTarget    = PC + {{14{IR[15]}}, {IR[15:0], 2'b00}}; // branch target
wire [31:0] JTarget         = {PC[31:28], IR[25:0], 2'b00};          // target of J and JAL
wire [31:0] JRTarget        = rs;                                    // target of JR and JALR
wire [5 :0] opcode          = IR[31:26];
wire [5 :0] rtnumber        = IR[20:16];
wire [5 :0] IR_func         = IR[5:0];
always @(*) begin
    case(opcode)
        `R_Type : begin
            if(IR_func == `J || IR_func == `JAL) begin
                JUMP <= 1'b1;
            end
            else begin
            end
        end                     // 
        `ADDI   : func <= `ADD;
        `ADDIU  : func <= `ADDU;
        `SLTI   : func <= `SLT;
        `SLTIU  : func <= `SLTU;
        `ANDI   : func <= `AND;
        `ORI    : func <= `OR;
        `XORI   : func <= `XOR;
        `LUI    : ; // TODO: LUI ins

        `J      : JUMP <= 1'b1;
        `JAL    : JUMP <= 1'b1;
        `BEQ    : JUMP <= rs == rt;
        `BNE    : JUMP <= rs != rt;
        `BGTZ   : JUMP <= (rs[31] != 1'b1 && rs != 0);
        `BLEZ   : JUMP <= (rs[31] == 1'b1 || rs == 0);
        `BGEZ_BLTZ_BGEZAL_BLTZAL: begin
            case(rtnumber)
                `BLTZ   : JUMP <= rs[31] == 1'b1;
                `BGEZ   : JUMP <= rs[31] == 1'b0;
                `BLTZAL : JUMP <= rs[31] == 1'b1;
                `BGEZAL : JUMP <= rs[31] == 1'b0;
                default : ; // TODO: EX
            endcase
        end

        `LB     : func <= `ADD;
        `LH     : func <= `ADD;
        `LW     : func <= `ADD;
        `LBU    : func <= `ADD;
        `LHU    : func <= `ADD;
        `SB     : func <= `ADD;
        `SH     : func <= `ADD;
        `SW     : func <= `ADD;
        `PRI    : ; // TODO: Privileged Instruction
        default : ; // TODO: ReservedIns Exception
    endcase

end

assign R        = opcode == `R_Type && IR_func != `JR && IR_func != `JALR &&
                IR_func != `SYSCALL && IR_func != `BREAK;  // opcode = 0 and not JR,JALR,BREAK,SYSCALL

assign AL       = opcode == `JAL || (opcode == `JR_JALR && IR_func == `JALR) ||
                (opcode == `BGEZ_BLTZ_BGEZAL_BLTZAL && (rtnumber == `BLTZAL || rtnumber == `BGEZAL));

assign imm      = (opcode >= `ADDI && opcode <= `LUI) || (opcode >= `LB && opcode <= `SW);

assign regwen   = AL || (imm && opcode <= `LHU) || R; // TODO: reg write signal, PRI

assign immXtype =   (opcode == `LUI) ? 2'b11:                       // {imm, 16{0}}
                    (opcode >= `ANDI && opcode <= `XORI) ? 2'b00 :  // zero extend
                    2'b01;                                          // signed ex

assign branch   =   (opcode >= `J && opcode <= `BGTZ) || (opcode == `JR_JALR && (IR_func == `JALR || IR_func == `JR));
// assign JUMP     =   (opcode == `J || opcode == `JAL || (opcode == `JR_JALR && (IR_func == `JALR || IR_func == `J))) ? 1'b1 :

assign target   =   (opcode == `J || opcode == `JAL) ? JTarget :
                    (opcode == `JR_JALR && (IR_func == `JR  || IR_func == `JALR)) ? JRTarget:
                    BranchTarget;

assign data_wen =   opcode == `SB ? 4'b0001: // TODO: ???? wen ? 0~15 : ? 0 means not write ?
                    opcode == `SH ? 4'b0010:
                    opcode == `SW ? 4'b0100:
                    4'b0;
endmodule
