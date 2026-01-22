module ID_EX_Reg (
    input  wire       clk, rst, flush,
    
    input  wire       wb_reg_write_in, 
    input  wire       mem_update_flags_in,
    input  wire [3:0] ex_alu_op_in,
    
    input  wire       mem_write_in,
    input  wire       mem_to_reg_in,
    input  wire       io_read_in,
    input  wire       io_write_in,
    input  wire       sp_update_in,
    
    // Call/Ret/Loop Signals & PC
    input  wire       is_call_in,
    input  wire       is_ret_in,
    input  wire       is_loop_in,
    input  wire [7:0] pc_in,

    input  wire [7:0] rdata1_in, rdata2_in,
    input  wire [1:0] ra_in,        
    input  wire [1:0] rb_in,        
    input  wire [1:0] dest_reg_in,  
    input  wire [1:0] shift_type_in,

    output reg        wb_reg_write_out, 
    output reg        mem_update_flags_out,
    output reg  [3:0] ex_alu_op_out,
    
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        io_read_out,
    output reg        io_write_out,
    output reg        sp_update_out,
    
    output reg        is_call_out,
    output reg        is_ret_out,
    output reg        is_loop_out,
    output reg  [7:0] pc_out,

    output reg  [7:0] rdata1_out, rdata2_out,
    output reg  [1:0] rs_out,     
    output reg  [1:0] rt_out,      
    output reg  [1:0] ra_out,       
    output reg  [1:0] shift_type_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            wb_reg_write_out     <= 0;
            mem_update_flags_out <= 0;
            ex_alu_op_out        <= 0;
            mem_write_out        <= 0;
            mem_to_reg_out       <= 0;
            io_read_out          <= 0;
            io_write_out         <= 0;
            sp_update_out        <= 0;
            is_call_out          <= 0;
            is_ret_out           <= 0;
            is_loop_out          <= 0;
            pc_out               <= 0;
            rdata1_out           <= 0;
            rdata2_out           <= 0;
            rs_out               <= 0;
            rt_out               <= 0;
            ra_out               <= 0;
            shift_type_out       <= 0;
        end else begin
            wb_reg_write_out     <= wb_reg_write_in;
            mem_update_flags_out <= mem_update_flags_in;
            ex_alu_op_out        <= ex_alu_op_in;
            mem_write_out        <= mem_write_in;
            mem_to_reg_out       <= mem_to_reg_in;
            io_read_out          <= io_read_in;
            io_write_out         <= io_write_in;
            sp_update_out        <= sp_update_in;
            is_call_out          <= is_call_in;
            is_ret_out           <= is_ret_in;
            is_loop_out          <= is_loop_in;
            pc_out               <= pc_in;
            rdata1_out           <= rdata1_in;
            rdata2_out           <= rdata2_in;
            rs_out               <= ra_in;
            rt_out               <= rb_in;
            ra_out               <= dest_reg_in;
            shift_type_out       <= shift_type_in;
        end
    end
endmodule