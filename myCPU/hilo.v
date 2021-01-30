`timescale 1ns/1ps

module hilo (
    input           clk,
    input           resetn,
    input [31:0]    whi,
    input [31:0]    wlo,
    input [1 :0]    whilo,

    output reg [31:0]   hi,
    output reg [31:0]   lo
);

always @(posedge clk) begin
    if(!resetn) begin
        hi <= 32'b0;
        lo <= 32'b0;
    end
    else begin
        if(whilo == 2'b01) begin
            lo <= wlo;
        end
        else if(whilo == 2'b10) begin
            hi <= whi;
        end
    end
end

endmodule