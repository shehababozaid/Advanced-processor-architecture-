module ForwardingUnit (
    input      [1:0] ex_rs,      
    input      [1:0] ex_rt,      
    
    // MEM Stage Checks
    input      [1:0] mem_rd,     
    input            mem_reg_write,
    input      [1:0] mem_sp_addr,   // [NEW] Check SP update
    input            mem_sp_update, // [NEW] 
    
    // WB Stage Checks
    input      [1:0] wb_rd,      
    input            wb_reg_write,
    input      [1:0] wb_sp_addr,    // [NEW]
    input            wb_sp_update,  // [NEW]
    
    output reg [2:0] forward_a,  // [CHANGED] 3 bits now
    output reg [2:0] forward_b
);
    // Codes:
    // 000: No Forward (RegFile)
    // 001: Forward Data from WB (wb_result)
    // 010: Forward Data from MEM (mem_result/read_data)
    // 011: Forward SP from WB (wb_alu_result)
    // 100: Forward SP from MEM (mem_result)

    always @(*) begin
        forward_a = 3'b000;
        forward_b = 3'b000;

        // --- SOURCE A (RS) ---
        // 1. Priority to MEM Stage (SP Update)
        if (mem_sp_update && (mem_sp_addr == ex_rs)) forward_a = 3'b100;
        // 2. Priority to MEM Stage (Data Update)
        else if (mem_reg_write && (mem_rd == ex_rs)) forward_a = 3'b010;
        // 3. WB Stage (SP Update)
        else if (wb_sp_update && (wb_sp_addr == ex_rs)) forward_a = 3'b011;
        // 4. WB Stage (Data Update)
        else if (wb_reg_write && (wb_rd == ex_rs)) forward_a = 3'b001;

        // --- SOURCE B (RT) ---
        // 1. Priority to MEM Stage (SP Update)
        if (mem_sp_update && (mem_sp_addr == ex_rt)) forward_b = 3'b100;
        // 2. Priority to MEM Stage (Data Update)
        else if (mem_reg_write && (mem_rd == ex_rt)) forward_b = 3'b010;
        // 3. WB Stage (SP Update)
        else if (wb_sp_update && (wb_sp_addr == ex_rt)) forward_b = 3'b011;
        // 4. WB Stage (Data Update)
        else if (wb_reg_write && (wb_rd == ex_rt)) forward_b = 3'b001;
    end
endmodule