module InstructionMemory (
    input  wire [7:0] addr,
    output wire [7:0] instr
);

    reg [7:0] imem [0:255];

    initial begin
        // Load the machine code from a file
        // Format of program.mem: Hexadecimal values separated by newlines
        // Address 00: Value to be loaded into PC on Reset
        // Address 01: Value to be loaded into PC on Interrupt
        // Address 02+: Your actual code
        $readmemh("program.mem", imem);
    end

    assign instr = imem[addr];

endmodule