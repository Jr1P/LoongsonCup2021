`timescale 1ns/1ps
`include "./head.vh"

// * ALU
// * at posedge write HI, LO
// * ERET, MFC0, MTC0, SYSCALL, BREAK do not need ALU
// ! pay attentin on func
module alu(
    input               clk,
    input               resetn,
    input       [31:0]  A,
    input       [31:0]  B,
    input       [5 :0]  func,               // function code
    input       [5 :0]  sa,                 // shift amount

    output              IntegerOverflow,    // IntegerOverflow Exception
    // output              ReservedIns,        // ReservedInstruction Ex
    output reg  [31:0]  res                 // result
);

reg             Cin;

wire    [31:0]  signA   = $signed(A);   // signed A
wire    [31:0]  signB   = $signed(B);   // signed B  
wire    [4 :0]  sav     = A[4:0];       // shift amount variable

always @(*) begin
    case(func)
        `ADD    : {Cin, res}   <= {A[31], A} + {B[31], B};      // ADD
        `ADDU   : res          <= A + B;                        // ADDU
        `SUB    : {Cin, res}   <= {A[31], A} - {B[31], B};      // SUB
        `SUBU   : res          <= A - B;                        // SUBU
        `AND    : res          <= A & B;                        // AND
        `OR     : res          <= A | B;                        // OR
        `XOR    : res          <= A ^ B;                        // XOR
        `NOR    : res          <= ~(A | B);                     // NOR

        `SLT    : res          <= (signA < signB) ? 1 : 0;      // SLT
        `SLTU   : res          <= (A < B) ? 1 : 0;              // SLTU
        
        `SLL    : res          <= {B[31-sa:0], {sa{1'b0}}};     // SLL
        `SRL    : res          <= {{sa{1'b0}}, B[31:sa]};       // SRL
        `SRA    : res          <= {{sa{B[31]}}, B[31:sa]};      // SRA
        `SLLV   : res          <= {B[31-sav:0], {sav{1'b0}}};   // SLLV
        `SRLV   : res          <= {{sav{1'b0}}, B[31:sav]};     // SRLV
        `SRAV   : res          <= {{sav{B[31]}}, B[31:sav]};    // SRAV

        `MFHI   : res          <= HI;                           // MFHI
        `MFLO   : res          <= LO;                           // MFLO

        // ?`LUI_FUN: res          <= B;                            // LUI

        default: ; // TODO: ReservedInstruction Exception
    endcase
end

// * write HI and LO at posedge
always @(posedge clk) begin
    if(!resetn) begin
        HI <= 0;
        LO <= 0;
        Cin <= 0;
    end
    else begin
        case(func)
            `MULT   : {HI, LO} <= signA * signB;                     // MULT
            `MULTU  : {HI, LO} <= A * B;                             // MULTU
            `DIV    : {HI, LO} <= {signA % signB, signA / signB};    // DIV
            `DIVU   : {HI, LO} <= {A % B, A / B};                    // DIVU
            `MTHI   : HI       <= A;                                 // MTHI
            `MTLO   : LO       <= A;                                 // MTLO
            default : ;
        endcase
    end
end
// *                         ADD,ADDI          SUB,SUBI
assign IntegerOverflow = (func == `ADD || func == `SUB) && Cin != res[31]; // IntegerOverflow Exception

endmodule