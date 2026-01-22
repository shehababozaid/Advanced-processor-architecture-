module EX_MEM_Reg (
    input  wire       clk, rst,
    
    input  wire       wb_reg_write_in, 
    input  wire [7:0] alu_result_in,
    input  wire [1:0] write_addr_in,
    input  wire [3:0] new_flags_in,
    input  wire       update_flags_in,
    
    input  wire       mem_write_in,
    input  wire       mem_to_reg_in,
    input  wire       io_read_in,
    input  wire       io_write_in,
    input  wire       sp_update_in,
    input  wire [1:0] sp_addr_in,

    input  wire [7:0] store_data_in,
    input  wire [7:0] extra_data_in,
    
    // [NEW] RET Signal
    input  wire       is_ret_in,

    output reg        wb_reg_write_out, 
    output reg  [7:0] alu_result_out,
    output reg  [1:0] write_addr_out,
    output reg  [3:0] flags_out,
    output reg        update_flags_out,
    
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        io_read_out,
    output reg        io_write_out,
    output reg        sp_update_out,
    output reg  [1:0] sp_addr_out,
    
    output reg  [7:0] store_data_out,
    output reg  [7:0] extra_data_out,
    
    // [NEW] Output
    output reg        is_ret_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_reg_write_out <= 0;
            alu_result_out   <= 0;
            write_addr_out   <= 0;
            flags_out        <= 0;
            update_flags_out <= 0;
            mem_write_out    <= 0;
            mem_to_reg_out   <= 0;
            io_read_out      <= 0;
            io_write_out     <= 0;
            sp_update_out    <= 0;
            sp_addr_out      <= 0;
            store_data_out   <= 0;
            extra_data_out   <= 0;
            is_ret_out       <= 0;
        end else begin
            wb_reg_write_out <= wb_reg_write_in;
            alu_result_out   <= alu_result_in;
            write_addr_out   <= write_addr_in;
            flags_out        <= new_flags_in;
            update_flags_out <= update_flags_in;
            mem_write_out    <= mem_write_in;
            mem_to_reg_out   <= mem_to_reg_in;
            io_read_out      <= io_read_in;
            io_write_out     <= io_write_in;
            sp_update_out    <= sp_update_in;
            sp_addr_out      <= sp_addr_in;
            store_data_out   <= store_data_in;
            extra_data_out   <= extra_data_in;
            is_ret_out       <= is_ret_in;
        end
    end
endmodule