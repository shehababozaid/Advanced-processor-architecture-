module HazardUnit (
    input  wire [1:0] id_ra, id_rb, // Sources in Decode
    input  wire [1:0] ex_dest_reg,  // Dest in Execute
    input  wire       ex_mem_read,  // Is instruction in EX a Load?
    
    output reg        stall_if,     // Freeze PC
    output reg        stall_id,     // Freeze IF/ID Reg
    output reg        flush_ex      // Zero out ID/EX Reg
);
    always @(*) begin
        // Default: Run normally
        stall_if = 0;
        stall_id = 0;
        flush_ex = 0;

        // Load-Use Hazard Detection
        // If EX instruction is a LOAD and its destination matches ID sources
        if (ex_mem_read && ((ex_dest_reg == id_ra) || (ex_dest_reg == id_rb))) begin
            stall_if = 1; // Stop fetching new instructions
            stall_id = 1; // Stop decoding current instruction
            flush_ex = 1; // Send a NOP to EX stage
        end
    end
endmodule