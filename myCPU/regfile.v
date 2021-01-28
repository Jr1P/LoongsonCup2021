`timescale 1ns/1ps

// * register file
// * posedge write GPRs
// ? how to initialize GPRs
module regfile(
    input           clk,
    input           resetn,

    input [4 :0]    rs,
    input [4 :0]    rt,

    input           wen,    // write engine
    input [4 :0]    wreg,   // the register to be written
    input [31:0]    inData, // the data to be written to wreg

    output[31:0]    outA,
    output[31:0]    outB
);

reg [31:0] GPR[31:0];

always @(posedge clk) begin
    if(!resetn) begin
        // TODO: initialize GPRs
    end
    else if(wen) begin
        GPR[wreg] = inData;
    end
end

assign outA = GPR[rs];
assign outB = GPR[rt];

endmodule