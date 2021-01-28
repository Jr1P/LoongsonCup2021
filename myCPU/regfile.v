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
    input [31:0]    wdata,  // the data to be written to wreg

    output[31:0]    outA,
    output[31:0]    outB
);

reg [31:0] GPR[31:0];
integer i;
always @(posedge clk) begin
    if(!resetn) begin
        for(i = 0; i < 32; i = i+1)
            GPR[i] <= 32'h0;
    end
    else if(wen) begin
        GPR[wreg] <= inData;
    end
end

assign outA = (wen && wreg == rs) ? wdata : GPR[rs];
assign outB = (wen && wreg == rt) ? wdata : GPR[rt];

endmodule