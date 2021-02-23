`timescale 1ns/1ps

module cu(
    input   [5:0]   ex_int,
    input           inst_ADDRESS_ERROR, // *if seg
    input           ReservedIns,        // *id seg
    input           IntegerOverflow,    // *ex seg
    input           BreakEx,            // *id seg
    input           SyscallEx,          // *id seg
    input           data_ADDRESS_ERROR, // *mem seg

    input   if_bd,
    input   id_bd,
    input   ex_bd,
    input   mem_bd,

    output  stall,
    output  flash,
    output  EX
);

assign EX = (|ex_inst) || inst_ADDRESS_ERROR || ReservedIns || IntegerOverflow || BreakEx || SyscallEx || data_ADDRESS_ERROR;


endmodule