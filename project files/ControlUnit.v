`include "defines.v"

module ControlUnit (
    input  wire [3:0] opcode,
    input  wire [1:0] ra, 
    input  wire       is_hardware_int, 

    output reg        reg_write,
    output reg        update_flags,
    output reg  [3:0] alu_op,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        io_read,
    output reg        io_write,
    output reg        sp_update,
    output reg        is_call, 
    output reg        is_ret,
    output reg        is_loop
);
    always @(*) begin
        // Defaults
        reg_write    = 0;
        update_flags = 0;
        alu_op       = 4'b0000;
        mem_write    = 0;
        mem_to_reg   = 0;
        io_read      = 0;
        io_write     = 0;
        sp_update    = 0;
        is_call      = 0;
        is_ret       = 0;
        is_loop      = 0;

        // [CRITICAL] Priority for Hardware Interrupt
        if (is_hardware_int) begin
            mem_write = 1;
            sp_update = 1; 
            is_call   = 1; // Reuse CALL logic to save PC
            alu_op    = 4'b0011; // SUB for SP decrement
        end
        else begin
            case (opcode)
                `OP_NOP:   ;
                `OP_MOV:   begin reg_write = 1; alu_op = 4'b0000; end 
                `OP_ADD:   begin reg_write = 1; update_flags = 1; alu_op = 4'b0010; end
                `OP_SUB:   begin reg_write = 1; update_flags = 1; alu_op = 4'b0011; end
                `OP_AND:   begin reg_write = 1; update_flags = 1; alu_op = 4'b0100; end
                `OP_OR:    begin reg_write = 1; update_flags = 1; alu_op = 4'b0101; end
                `OP_SHIFT: begin reg_write = 1; update_flags = 1; alu_op = 4'b0110; end 
                
                `OP_STACK_IO: begin
                    if (ra == 0) begin      // PUSH
                        mem_write = 1; sp_update = 1; alu_op = 4'b0011; 
                    end else if (ra == 1) begin // POP
                        reg_write = 1; mem_to_reg = 1; sp_update = 1; alu_op = 4'b0010; 
                    end else if (ra == 2) begin io_write = 1; end
                    else if (ra == 3) begin reg_write = 1; io_read = 1; end
                end

                `OP_UNARY: begin reg_write = 1; update_flags = 1; alu_op = 4'b1000; end
                `OP_BRANCH: begin end

                `OP_JUMP: begin 
                    if (ra == 2'b00) begin end // JMP
                    else if (ra == 2'b01) begin // CALL
                        is_call = 1; mem_write = 1; sp_update = 1; alu_op = 4'b0011;
                    end
                    else if (ra == 2'b10) begin // RET
                        is_ret = 1; sp_update = 1; alu_op = 4'b0010; mem_to_reg = 1;
                    end
                    else if (ra == 2'b11) begin // RTI
                        is_ret = 1; sp_update = 1; alu_op = 4'b0010; mem_to_reg = 1; 
                    end
                end
                
                4'b1010: begin // LOOP
                    is_loop = 1; reg_write = 1; alu_op = 4'b0011; update_flags = 1;
                end

                `OP_STI: begin 
                    mem_write = 1; 
                    alu_op = 4'b1001; // Use ALU_OP_MOVA
                end
                `OP_LDI: begin 
                    reg_write = 1; 
                    mem_to_reg = 1;
                    alu_op = 4'b1001; // Use ALU_OP_MOVA
                end
                
                default: ;
            endcase
        end
    end
endmodule