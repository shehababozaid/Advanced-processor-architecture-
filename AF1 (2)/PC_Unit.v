`include "defines.v"

module PC_Unit (
    input  wire       clk,
    input  wire       rst,           // Hardware Reset (Global)
    
    // Control Signals
    input  wire       project_rst_in, // Input Signal: Reset (Loads M[0])
    input  wire       intr_in,        // Input Signal: Interrupt (Loads M[1])
    
    // Branching & Vectors
    input  wire [7:0] vector_data,    // The value read from Memory (M[0] or M[1])
    input  wire       branch_taken,
    input  wire [7:0] jump_target,
    input  wire       is_ret_wb,
    input  wire [7:0] ret_addr,

    output reg  [7:0] pc,
    output reg        intr_active_out // To signal the system to save PC (Push)
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 8'd0; // Hardware initial state (Safety)
            intr_active_out <= 0;
        end 
        else begin
            intr_active_out <= 0; // Default

            // --- Priority 1: Project Reset (PC <- M[0]) ---
            // We assume Processor_Top forces Memory Addr = 0 when this is high
            if (project_rst_in) begin
                pc <= vector_data; 
            end
            
            // --- Priority 2: Interrupt (PC <- M[1]) ---
            // We assume Processor_Top forces Memory Addr = 1 when this is high
            else if (intr_in) begin
                pc <= vector_data;
                intr_active_out <= 1; // Signal to push old PC (handled in Top/Control)
            end
            
            // --- Priority 3: Normal Execution & Branching ---
            else begin
                if (is_ret_wb)      
                    pc <= ret_addr;
                else if (branch_taken) 
                    pc <= jump_target;
                else               
                    pc <= pc + 1;
            end
        end
    end
endmodule