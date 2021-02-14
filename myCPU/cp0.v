`timescale 1ns/1ps

module cp0 (
    input           clk,
    input           resetn,

    input           wen,
    input [7 :0]    addr,

    output [31:0]   rdata
);

reg [31:0] CP0Regs [255:0];

always(@posedge clk) begin
    if(!resetn) begin
        // TODO: initialize CP0Regs
    end
    else if(wen) begin
        CP0Regs[addr] <= wdata;
    end

end

assign rdata = CP0Regs[addr];

endmodule