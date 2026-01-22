module IF_ID_Reg (
    input  wire       clk,
    input  wire       rst,
    input  wire       flush, // [NEW] To clear instruction on Jump
    input  wire [7:0] pc_in,
    input  wire [7:0] instr_in,
    output reg  [7:0] pc_out,
    output reg  [7:0] instr_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin // [MODIFIED] Flush logic
            pc_out <= 0; 
            instr_out <= 0; // NOP
        end else begin
            pc_out <= pc_in; 
            instr_out <= instr_in;
        end
    end
endmodule