`include "defines.v"

module Processor_Top (
    input  wire clk,
    input  wire rst,          
    input  wire reset_signal, 
    input  wire intr_signal,  
    input  wire [7:0] in_port,
    output reg  [7:0] out_port
);

    // =================================================================
    // 1. Internal Wires & Connections
    // =================================================================
    
    // PC & Instruction
    wire [7:0] pc; 
    wire [7:0] if_instr_wire, id_pc, id_instr;
    
    // Interrupt Signal (Direct Connection to avoid double triggering)
    wire active_intr = intr_signal; 

    // ID Stage Signals
    wire [3:0] id_opcode = id_instr[7:4];
    wire [1:0] id_ra     = id_instr[3:2];
    wire [1:0] id_rb     = id_instr[1:0];
    wire [1:0] id_dest_reg;
    wire       id_reg_write, id_update_flags, id_sp_update;
    wire       id_mem_write, id_mem_to_reg, id_io_read, id_io_write;
    wire       id_is_call, id_is_ret, id_is_loop; 
    wire [3:0] id_alu_op;
    wire [7:0] id_rdata1, id_rdata2, rf_rdata2;

    // EX Stage Signals
    wire       ex_reg_write, ex_update_flags_ctrl, ex_sp_update;
    wire       ex_mem_write, ex_mem_to_reg, ex_io_read, ex_io_write;
    wire       ex_is_call, ex_is_ret, ex_is_loop; 
    wire [7:0] ex_pc_in;              
    wire [3:0] ex_alu_op;
    wire [7:0] ex_rdata1, ex_rdata2;
    wire [1:0] ex_ra, ex_rb, ex_write_addr, ex_shift_type;
    wire [7:0] ex_result;
    wire [3:0] ex_new_flags;
    
    // Forwarding & ALU Muxes
    wire [2:0] fwd_a, fwd_b;
    reg  [7:0] alu_in_a, alu_in_b; 
    
    // MEM Stage Signals
    wire       mem_reg_write, mem_update_flags, mem_sp_update;
    wire       mem_mem_write, mem_mem_to_reg, mem_io_read, mem_io_write;
    wire       mem_is_ret;
    wire [7:0] mem_result, mem_store_data, mem_read_data;
    wire [1:0] mem_write_addr, mem_sp_addr;
    wire [3:0] mem_new_flags;
    wire [7:0] mem_extra_data;
    
    // WB Stage Signals
    wire       wb_reg_write, wb_update_flags, wb_mem_to_reg, wb_io_read, wb_sp_update;
    wire       wb_io_write;
    wire       wb_is_ret;
    wire [7:0] wb_result, wb_alu_result, wb_mem_data;
    wire [1:0] wb_write_addr, wb_sp_addr;
    wire [3:0] wb_new_flags;
    wire [3:0] ccr_reg;         
    wire [3:0] current_flags;

    // Interrupt Logic Wire
    wire intr_active_pulse;

    // =================================================================
    // 2. Instruction Fetch (IF) Stage
    // =================================================================
    
    // PC Source Mux (Reset / Interrupt / Normal)
    wire [7:0] imem_addr_in;
    wire [7:0] imem_data_out;
    
    assign imem_addr_in = (reset_signal) ? 8'd0 :
                          (active_intr)  ? 8'd1 :
                          pc;

    InstructionMemory imem (
        .addr(imem_addr_in), 
        .instr(imem_data_out)
    );
    
    assign if_instr_wire = imem_data_out; 

    // PC Unit
    reg branch_taken;
    reg [7:0] jump_target;
    
    PC_Unit pc_unit (
        .clk(clk), 
        .rst(rst), 
        .project_rst_in(reset_signal),
        .intr_in(active_intr), 
        .vector_data(imem_data_out), 
        .branch_taken(branch_taken), 
        .jump_target(jump_target), 
        .is_ret_wb(wb_is_ret), 
        .ret_addr(wb_mem_data), 
        .pc(pc),
        .intr_active_out(intr_active_pulse)
    );

    // =================================================================
    // 3. Instruction Decode (ID) Stage & Logic
    // =================================================================

    // Handle Stack Pointer (R3/SP) Addressing
    wire [1:0] rf_read_addr1 = (id_opcode == `OP_STACK_IO || id_is_call || id_is_ret) ? 2'b11 : id_ra;
    assign id_dest_reg = (id_opcode == `OP_SHIFT || id_opcode == `OP_UNARY || id_opcode == `OP_STACK_IO) ? id_rb : id_ra;
    assign id_rdata2   = (id_opcode == `OP_STACK_IO && id_ra == 2'b11) ? in_port : rf_rdata2;

    // --- Forwarding Logic Muxing (ID Stage) ---
    reg [7:0] id_fwd_r1;
    reg [7:0] id_fwd_r2;

    always @(*) begin
        // Source 1 Forwarding
        if      (ex_reg_write && (ex_write_addr == rf_read_addr1))    id_fwd_r1 = ex_result;
        else if (ex_sp_update && (rf_read_addr1 == 2'b11))            id_fwd_r1 = ex_result;
        else if (mem_reg_write && (mem_write_addr == rf_read_addr1))  id_fwd_r1 = (mem_mem_to_reg) ? mem_read_data : mem_result;
        else if (mem_sp_update && (rf_read_addr1 == 2'b11))           id_fwd_r1 = mem_result;
        else if (wb_reg_write && (wb_write_addr == rf_read_addr1))    id_fwd_r1 = wb_result;
        else if (wb_sp_update && (rf_read_addr1 == 2'b11))            id_fwd_r1 = wb_alu_result; 
        else                                                          id_fwd_r1 = id_rdata1;

        // Source 2 Forwarding
        if      (ex_reg_write && (ex_write_addr == id_rb))            id_fwd_r2 = ex_result;
        else if (ex_sp_update && (id_rb == 2'b11))                    id_fwd_r2 = ex_result;
        else if (mem_reg_write && (mem_write_addr == id_rb))          id_fwd_r2 = (mem_mem_to_reg) ? mem_read_data : mem_result;
        else if (mem_sp_update && (id_rb == 2'b11))                   id_fwd_r2 = mem_result;
        else if (wb_reg_write && (wb_write_addr == id_rb))            id_fwd_r2 = wb_result;
        else if (wb_sp_update && (id_rb == 2'b11))                    id_fwd_r2 = wb_alu_result;
        else                                                          id_fwd_r2 = id_rdata2;
    end

    // --- Branch Decision Logic (ID Stage) ---
    always @(*) begin
        branch_taken = 0;
        jump_target = id_fwd_r2;

        if (id_opcode == `OP_LOOP) begin
            if (id_fwd_r1 != 8'd1) branch_taken = 1;
        end 
        else if (id_opcode == `OP_BRANCH) begin 
             case (id_ra) 
                2'b00: branch_taken = current_flags[0]; // Z
                2'b01: branch_taken = current_flags[1]; // N
                2'b10: branch_taken = current_flags[2]; // C
                2'b11: branch_taken = current_flags[3]; // V
             endcase
        end 
        else if (id_opcode == `OP_JUMP) begin
             if (id_ra == 2'b00 || id_ra == 2'b01) branch_taken = 1;
        end
    end

    // Flush Logic (Branch, Return, Reset, or Interrupt)
    wire flush_if_id = branch_taken || wb_is_ret || reset_signal || intr_active_pulse; 

    // --- Sub-modules (ID) ---
    IF_ID_Reg if_id (
        .clk(clk), .rst(rst), 
        .flush(flush_if_id), 
        .pc_in(pc), .instr_in(if_instr_wire), 
        .pc_out(id_pc), .instr_out(id_instr)
    );

    ControlUnit cu (
        .opcode(id_opcode), .ra(id_ra),
        .is_hardware_int(active_intr), // Direct Connection
        .reg_write(id_reg_write), .update_flags(id_update_flags), .alu_op(id_alu_op),
        .mem_write(id_mem_write), .mem_to_reg(id_mem_to_reg), 
        .io_read(id_io_read), .io_write(id_io_write),
        .sp_update(id_sp_update),
        .is_call(id_is_call), .is_ret(id_is_ret), .is_loop(id_is_loop)
    );

    RegisterFile rf (
        .clk(clk), .rst(rst), 
        .we(wb_reg_write), .waddr(wb_write_addr), .wdata(wb_result), 
        .we2(wb_sp_update), .waddr2(2'b11), .wdata2(wb_alu_result), 
        .raddr1(rf_read_addr1), .raddr2(id_rb), 
        .rdata1(id_rdata1), .rdata2(rf_rdata2)
    );

    ID_EX_Reg id_ex (
        .clk(clk), .rst(rst), 
        .flush(wb_is_ret || reset_signal), 
        .wb_reg_write_in(id_reg_write), .mem_update_flags_in(id_update_flags), .ex_alu_op_in(id_alu_op), 
        .rdata1_in(id_fwd_r1), .rdata2_in(id_fwd_r2),
        .ra_in(rf_read_addr1), .rb_in(id_rb), .dest_reg_in(id_dest_reg), .shift_type_in(id_ra),
        .mem_write_in(id_mem_write), .mem_to_reg_in(id_mem_to_reg), .io_read_in(id_io_read), .io_write_in(id_io_write),
        .sp_update_in(id_sp_update),
        .is_call_in(id_is_call), .is_ret_in(id_is_ret), .is_loop_in(id_is_loop), .pc_in(id_pc),

        .wb_reg_write_out(ex_reg_write), .mem_update_flags_out(ex_update_flags_ctrl),
        .ex_alu_op_out(ex_alu_op), .rdata1_out(ex_rdata1), .rdata2_out(ex_rdata2),
        .rs_out(ex_ra), .rt_out(ex_rb), .ra_out(ex_write_addr), .shift_type_out(ex_shift_type),
        .mem_write_out(ex_mem_write), .mem_to_reg_out(ex_mem_to_reg), .io_read_out(ex_io_read), .io_write_out(ex_io_write),
        .sp_update_out(ex_sp_update),
        .is_call_out(ex_is_call), .is_ret_out(ex_is_ret), .is_loop_out(ex_is_loop), .pc_out(ex_pc_in)
    );

    // =================================================================
    // 4. Execute (EX) Stage
    // =================================================================

    ForwardingUnit fu (
        .ex_rs(ex_ra), .ex_rt(ex_rb), 
        .mem_rd(mem_write_addr), .mem_reg_write(mem_reg_write), 
        .mem_sp_addr(2'b11), .mem_sp_update(mem_sp_update), 
        .wb_rd(wb_write_addr), .wb_reg_write(wb_reg_write), 
        .wb_sp_addr(2'b11), .wb_sp_update(wb_sp_update),    
        .forward_a(fwd_a), .forward_b(fwd_b)
    );

    // ALU Input Mux Logic
    reg [7:0] fwd_b_val;
    always @(*) begin
        case (fwd_b)
            3'b000: fwd_b_val = ex_rdata2;
            3'b001: fwd_b_val = wb_result;
            3'b010: fwd_b_val = (mem_mem_to_reg) ? mem_read_data : mem_result;
            3'b011: fwd_b_val = wb_alu_result;
            3'b100: fwd_b_val = mem_result;
            default: fwd_b_val = ex_rdata2;
        endcase
    end

    always @(*) begin
        // Input A
        case (fwd_a)
            3'b000: alu_in_a = ex_rdata1;
            3'b001: alu_in_a = wb_result;
            3'b010: alu_in_a = (mem_mem_to_reg) ? mem_read_data : mem_result;
            3'b011: alu_in_a = wb_alu_result;
            3'b100: alu_in_a = mem_result;
            default: alu_in_a = ex_rdata1;
        endcase

        // Input B (Handle SP decrement or Loop)
        if (ex_sp_update || ex_is_loop) 
            alu_in_b = 8'b00000001;
        else 
            alu_in_b = fwd_b_val;
    end

    wire [7:0] data_to_store = (ex_is_call) ? (ex_pc_in + 8'd1) : fwd_b_val;

    reg [3:0] alu_safe_flags;
    always @(*) begin
        if (mem_update_flags)      alu_safe_flags = mem_new_flags;
        else if (wb_update_flags)  alu_safe_flags = wb_new_flags;  
        else                       alu_safe_flags = ccr_reg;
    end

    ALU alu (
        .A(alu_in_a), .B(alu_in_b), 
        .alu_op(ex_alu_op), .shift_type(ex_shift_type), 
        .old_flags(alu_safe_flags), 
        .result(ex_result), .new_flags(ex_new_flags)
    );

    EX_MEM_Reg ex_mem (
        .clk(clk), .rst(rst),
        .wb_reg_write_in(ex_reg_write), .alu_result_in(ex_result), .write_addr_in(ex_write_addr),
        .new_flags_in(ex_new_flags), .update_flags_in(ex_update_flags_ctrl),
        .mem_write_in(ex_mem_write), .mem_to_reg_in(ex_mem_to_reg), .io_read_in(ex_io_read), .io_write_in(ex_io_write),
        .sp_update_in(ex_sp_update), .sp_addr_in(2'b11), 
        .store_data_in(data_to_store), 
        .extra_data_in(alu_in_a), 
        .is_ret_in(ex_is_ret), 

        .wb_reg_write_out(mem_reg_write), .alu_result_out(mem_result), .write_addr_out(mem_write_addr),
        .flags_out(mem_new_flags), .update_flags_out(mem_update_flags),
        .mem_write_out(mem_mem_write), .mem_to_reg_out(mem_mem_to_reg), .io_read_out(mem_io_read), .io_write_out(mem_io_write),
        .sp_update_out(mem_sp_update), .sp_addr_out(mem_sp_addr), 
        .store_data_out(mem_store_data),
        .extra_data_out(mem_extra_data),
        .is_ret_out(mem_is_ret)
    );

    // =================================================================
    // 5. Memory (MEM) & Write Back (WB) Stages
    // =================================================================

    wire [7:0] dmem_addr = (mem_mem_write && mem_sp_update) ? mem_extra_data : mem_result;
    
    DataMemory dmem (
        .clk(clk), 
        .mem_write(mem_mem_write), 
        .addr(dmem_addr), 
        .write_data(mem_store_data), 
        .read_data(mem_read_data)
    );

    MEM_WB_Reg mem_wb (
        .clk(clk), .rst(rst),
        .wb_reg_write_in(mem_reg_write), .alu_result_in(mem_result), .write_addr_in(mem_write_addr),
        .flags_in(mem_new_flags), .update_flags_in(mem_update_flags),
        .mem_to_reg_in(mem_mem_to_reg), .io_read_in(mem_io_read), 
        .io_write_in(mem_io_write),
        .mem_data_in(mem_read_data),
        .sp_update_in(mem_sp_update), .sp_addr_in(mem_sp_addr), 
        .is_ret_in(mem_is_ret), 

        .wb_reg_write_out(wb_reg_write), .alu_result_out(wb_alu_result), .write_addr_out(wb_write_addr),
        .flags_out(wb_new_flags), .update_flags_out(wb_update_flags),
        .mem_to_reg_out(wb_mem_to_reg), .io_read_out(wb_io_read), 
        .io_write_out(wb_io_write),
        .mem_data_out(wb_mem_data),
        .sp_update_out(wb_sp_update), .sp_addr_out(wb_sp_addr),
        .is_ret_out(wb_is_ret)
    );

    // CCR & IO Output
    CCR_Unit ccr_unit (
        .clk(clk), .rst(rst),
        .ex_new_flags(ex_new_flags), .ex_update_flags(ex_update_flags_ctrl),
        .mem_new_flags(mem_new_flags), .mem_update_flags(mem_update_flags),
        .wb_new_flags(wb_new_flags), .wb_update_flags(wb_update_flags),
        .ccr_reg(ccr_reg),          
        .current_flags(current_flags) 
    );

    always @(negedge clk or posedge rst) begin
        if (rst) out_port <= 8'b0;
        else if (wb_io_write) out_port <= wb_alu_result; 
    end
    
    assign wb_result = (wb_mem_to_reg) ? wb_mem_data : wb_alu_result;

endmodule