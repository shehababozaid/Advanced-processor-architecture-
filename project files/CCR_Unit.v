module CCR_Unit (
    input  wire clk,
    input  wire rst,
    // Inputs from stages to determine "Current Flags" (Forwarding)
    input  wire [3:0] ex_new_flags,
    input  wire       ex_update_flags,
    input  wire [3:0] mem_new_flags,
    input  wire       mem_update_flags,
    input  wire [3:0] wb_new_flags,
    input  wire       wb_update_flags, // This is the actual Write Enable for CCR Register

    output reg  [3:0] ccr_reg,      // The stored value (Architecture State)
    output reg  [3:0] current_flags // The forwarded value (for Branch decision & Forwarding)
);

    // 1. Forwarding Logic (Combinational)
    // Determines the most up-to-date flags for Branching
    always @(*) begin
        if (ex_update_flags)      current_flags = ex_new_flags; // Priority 1: ALU result
        else if (mem_update_flags) current_flags = mem_new_flags; // Priority 2: Memory/Forwarded
        else if (wb_update_flags)  current_flags = wb_new_flags; // Priority 3: WB result
        else                       current_flags = ccr_reg;      // Default: Stored value
    end

    // 2. Register Update (Sequential)
    // Writes to the physical register at Write-Back stage
    always @(posedge clk or posedge rst) begin
        if (rst) 
            ccr_reg <= 4'b0;
        else if (wb_update_flags) 
            ccr_reg <= wb_new_flags;
    end

endmodule