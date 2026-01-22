module DataMemory (
    input  wire       clk,
    input  wire       mem_write,   // Write Enable
    input  wire [7:0] addr,        // Address Input
    input  wire [7:0] write_data,  // Data to write
    output wire [7:0] read_data    // Data Output
);

    // Define Memory: 256 bytes, 8-bit width
    reg [7:0] mem [0:255];

    integer i;

    initial begin
        // 1. Initialize memory to zero to avoid 'X' states
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 8'b0;

        // "program.mem" must contain the hex code, starting at address 0.
        $readmemh("program.mem", mem); 
    end

    // Synchronous Write: Happens on the clock edge
    always @(posedge clk) begin
        if (mem_write) begin
            mem[addr] <= write_data;
        end
    end

    // Asynchronous Read:
    // We use continuous assignment so data is available immediately
    assign read_data = mem[addr];

endmodule