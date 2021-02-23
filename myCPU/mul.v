`timescale 1ns/1ps

// * normal mul
module mul(
    input [31:0] A,
    input [31:0] B,

    output [31:0] hi,
    output [31:0] lo
);

assign {hi, lo} = A * B; // TODO:有符号和无符号

endmodule