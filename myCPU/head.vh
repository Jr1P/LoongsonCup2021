// * function code
`define SLL     6'b000000
`define SRL     6'b000010
`define SRA     6'b000011
`define SLLV    6'b000100
`define SRLV    6'b000110
`define SRAV    6'b000111
`define MFHI    6'b010000
`define MTHI    6'b010001
`define MFLO    6'b010010
`define MTLO    6'b010011
`define MULT    6'b011000
`define MULTU   6'b011001
`define DIV     6'b011010
`define DIVU    6'b011011
`define ADD     6'b100000
`define ADDU    6'b100001
`define SUB     6'b100010
`define SUBU    6'b100011
`define AND     6'b100100
`define OR      6'b100101
`define XOR     6'b100110
`define NOR     6'b100111
`define SLT     6'b101010
`define SLTU    6'b101011

`define SYSCALL 6'b001100
`define BREAK   6'b001101

`define JR      6'b001000
`define JALR    6'b001001

// *------------------

// * opcode
`define R_Type  6'b000000
`define JR_JALR 6'b000000
`define J       6'b000010
`define JAL     6'b000011
`define BEQ     6'b000100
`define BNE     6'b000101
`define BLEZ    6'b000110
`define BGTZ    6'b000111

`define ADDI    6'b001000
`define ADDIU   6'b001001
`define SLTI    6'b001010
`define SLTIU   6'b001011
`define ANDI    6'b001100
`define ORI     6'b001101
`define XORI    6'b001110
`define LUI     6'b001111

`define BGEZ_BLTZ_BGEZAL_BLTZAL     6'b000001

`define LB      6'b100000
`define LH      6'b100001
`define LW      6'b100011
`define LBU     6'b100100
`define LHU     6'b100101
`define SB      6'b101000
`define SH      6'b101001
`define SW      6'b101011

`define PRI     6'b010000   // * PRI means Privileged Instruction
// TODO: PRI

// *------------------

// * rt code just for BGEZ_BLTZ_BGEZAL_BLTZAL
`define BLTZ    5'b00000
`define BGEZ    5'b00001
`define BLTZAL  5'b10000
`define BGEZAL  5'b10001

// *------------------
