`timescale 1ns/1ps
`include "./head.vh"

// * ALU
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
    output      [31:0]  res,                // result
    output      [31:0]  hi,                 // hi
    output      [31:0]  lo                  // lo
);

wire            Cin;
wire    [31:0]  signA   = $signed(A);   // signed A
wire    [31:0]  signB   = $signed(B);   // signed B  
wire    [4 :0]  sav     = `GET_SA(A);   // shift amount variable

assign {Cin, res} = func == `ADD    ? {A[31], A} + {B[31], B} :
                    func == `ADDU   ? A + B :
                    func == `SUB    ? {A[31], A} - {B[31], B} :
                    func == `SUBU   ? A - B :
                    func == `AND    ? {1'b0, A & B} :
                    func == `OR     ? {1'b0, A | B} :
                    func == `XOR    ? {1'b0, A ^ B} :
                    func == `NOR    ? {1'b0, ~(A | B)} :
                    func == `SLT    ? {1'b0, (signA < signB) ? 32'b1 : 32'b0} :
                    func == `SLTU   ? {1'b0, (A < B) ? 32'b1 : 32'b0} :
                    func == `SLL    ? {1'b0, B << sa} :
                    func == `SRL    ? {1'b0, B >> sa} :
                    func == `SRA    ? {1'b0, B >>> sa} :
                    func == `SLLV   ? {1'b0, B << sav} :
                    func == `SRLV   ? {1'b0, B >> sav} :
                    func == `SRAV   ? {1'b0, B >>> sav} :
                    func == `MTHI || 
                    func == `MTLO   ? {1'b0, A} : 33'b0;  // TODO: modify if other instruction needs


// *                         ADD,ADDI          SUB,SUBI
assign IntegerOverflow = (func == `ADD || func == `SUB) && Cin != res[31]; // IntegerOverflow Exception

endmodule