`include "defines.v"

module ALU (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [3:0] alu_op,
    input  wire [1:0] shift_type,
    input  wire [3:0] old_flags, // V, C, N, Z
    output reg  [7:0] result,
    output reg  [3:0] new_flags  // V, C, N, Z
);

    wire C_in = old_flags[2]; 

    always @(*) begin
        // Default values
        result = 8'b0;
        new_flags = old_flags; 

        case (alu_op)
            // MOV Operation (Pass B)
            4'b0000: begin
                result = B;
                // MOV usually does NOT update flags, but if you want it to:
                // new_flags[0] = (result == 0); new_flags[1] = result[7];
            end

            // ADD (Opcode 0010)
            4'b0010: begin
                {new_flags[2], result} = A + B; 
                new_flags[3] = (A[7] == B[7]) && (result[7] != A[7]); // Overflow
                new_flags[0] = (result == 8'b0); // Z
                new_flags[1] = result[7];        // N
            end

            // SUB
            4'b0011: begin
                {new_flags[2], result} = A - B;
                new_flags[3] = (A[7] != B[7]) && (result[7] != A[7]); // Overflow
                new_flags[0] = (result == 8'b0); // Z
                new_flags[1] = result[7];        // N
            end

            // AND
            4'b0100: begin
                result = A & B;
                new_flags[0] = (result == 0);
                new_flags[1] = result[7];
                new_flags[2] = 0; // Carry cleared? (Usually preserved or cleared)
                new_flags[3] = 0; // Overflow cleared
            end

            // OR
            4'b0101: begin
                result = A | B;
                new_flags[0] = (result == 0);
                new_flags[1] = result[7];
                new_flags[2] = 0;
                new_flags[3] = 0;
            end

            // SHIFT / ROTATE / FLAGS
            4'b0110: begin
                case (shift_type)
                    2'b00: begin // RLC
                        result = {B[6:0], C_in};
                        new_flags[2] = B[7]; // New Carry
                    end
                    2'b01: begin // RRC
                        result = {C_in, B[7:1]};
                        new_flags[2] = B[0]; // New Carry
                    end
                    2'b10: begin // SETC
                        new_flags[2] = 1;
                        result = B; 
                    end
                    2'b11: begin // CLRC
                        new_flags[2] = 0;
                        result = B; 
                    end
                endcase
                // Update Z and N for shifts too
                if (shift_type == 2'b00 || shift_type == 2'b01) begin
                    new_flags[0] = (result == 0);
                    new_flags[1] = result[7];
                end
            end
            
            // UNARY Operations (NOT, NEG, INC, DEC)
            4'b1000: begin
               case (shift_type) 
                   2'b00: result = ~B;          // NOT
                   2'b01: result = -B;          // NEG
                   2'b10: begin                 // INC
                        {new_flags[2], result} = B + 1;
                        new_flags[3] = (B == 8'h7F);
                   end
                   2'b11: begin                 // DEC
                        {new_flags[2], result} = B - 1;
                        new_flags[3] = (B == 8'h80);
                   end
               endcase
               
               new_flags[0] = (result == 8'b0); // Z
               new_flags[1] = result[7];        // N
            end
            4'b1001: result = A; // Pass Address (ra) through
            default: result = 8'b0;
        endcase
    end
endmodule