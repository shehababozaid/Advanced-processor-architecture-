// Instruction Opcodes (Matches PDF)
`define OP_NOP      4'b0000 // 0
`define OP_MOV      4'b0001 // 1
`define OP_ADD      4'b0010 // 2
`define OP_SUB      4'b0011 // 3
`define OP_AND      4'b0100 // 4
`define OP_OR       4'b0101 // 5
`define OP_SHIFT    4'b0110 // 6
`define OP_STACK_IO 4'b0111 // 7 (PUSH, POP, OUT, IN) - Distinguished by RA
`define OP_UNARY    4'b1000 // 8
`define OP_BRANCH   4'b1001 // 9 (JZ, JN, JC, JV)
`define OP_LOOP     4'b1010 // 10
`define OP_JUMP     4'b1011 // 11
`define OP_STI      4'b1100 // 12 (Store Indirect)
`define OP_LDI      4'b1101 // 13 (Load Indirect) (JMP, CALL, RET, RTI)

// ALU Operation Codes (Internal use between CU and ALU)
`define ALU_OP_MOV   4'b0001
`define ALU_OP_ADD   4'b0010
`define ALU_OP_SUB   4'b0011
`define ALU_OP_AND   4'b0100
`define ALU_OP_OR    4'b0101
`define ALU_OP_SHIFT 4'b0110
`define ALU_OP_UNARY 4'b1000
`define ALU_OP_MOVA  4'b1001 // New code to pass A
`define ALU_OP_PUSH  4'b1101 // Custom
`define ALU_OP_POP   4'b1110 // Custom