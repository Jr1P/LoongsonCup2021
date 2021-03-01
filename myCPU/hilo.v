`timescale 1ns/1ps

module hilo (
    input           clk,
    input           resetn,
    input [1 :0]    wen,
    input [31:0]    hiwdata,
    input [31:0]    lowdata,
    input [1 :0]    ren,
    output [31:0]   rdata
);

reg [31:0] hi, lo;

always @(posedge clk) begin
    if(!resetn) begin
        hi <= 32'b0;
        lo <= 32'b0;
    end
    else begin
        if(wen[1] == 1'b1) hi <= hiwdata;
        if(wen[0] == 1'b1) lo <= lowdata;
    end
end

assign rdata =  {32{ren[0]}} & lo |
                {32{ren[1]}} & hi ;

endmodule