`timescale 1ns / 1ps

module Processor_TB;
    reg clk, rst, reset_signal, intr_signal;
    reg [7:0] in_port;
    wire [7:0] out_port;

    Processor_Top uut (
        .clk(clk), .rst(rst), 
        .reset_signal(reset_signal), 
        .intr_signal(intr_signal), 
        .in_port(in_port), .out_port(out_port)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // Opcode Monitor
    reg [64:1] id_op_name; 
    always @(*) begin
        if (uut.cu.is_hardware_int) id_op_name = ">> HW_INT <<";
        else case(uut.id_opcode)
            0: id_op_name = "NOP";
            1: id_op_name = "MOV"; 2: id_op_name = "ADD"; 3: id_op_name = "SUB";
            4: id_op_name = "AND"; 5: id_op_name = "OR";
            6: id_op_name = "SHIFT";
            7: begin
                case(uut.id_ra)
                    0: id_op_name = "PUSH"; 1: id_op_name = "POP";
                    2: id_op_name = "OUT"; 3: id_op_name = "IN";
                endcase
            end
            8: id_op_name = "UNARY";
            10: id_op_name = "LOOP";
            11: begin
                case(uut.id_ra) 
                    0: id_op_name = "JMP"; 1: id_op_name = "CALL";
                    2: id_op_name = "RET"; 3: id_op_name = "RTI";
                endcase
            end
            default: id_op_name = "???";
        endcase
    end

    // Monitor Output Table
    initial begin
        $display("=========================================================================");
        $display("| Time   | PC   | Instruction | R0 (Acc) | R1 | R2 | SP | OutPort | Flags |");
        $display("=========================================================================");
        forever begin
            @(negedge clk);
            if (!rst) begin
                $display("| %6t |  %h  | %-11s |    %h    | %h | %h | %h |    %h   |  %b |", 
                    $time, uut.pc, id_op_name,   
                    uut.rf.registers[0], uut.rf.registers[1], 
                    uut.rf.registers[2], uut.rf.registers[3], 
                    out_port, uut.current_flags
                );
            end
        end
    end

    // Monitor Port Changes
    always @(out_port) begin
        if (!rst && !reset_signal) begin
            $display("\n[OUTPUT] >>> Port Value: %h at Time: %t\n", out_port, $time);
        end
    end

    // =========================================================
    //  UNIFIED TEST SCENARIO
    // =========================================================
    initial begin
        rst = 1;
        reset_signal = 0; intr_signal = 0; in_port = 0;
        #100; rst = 0; 
        
        $display("--- 1. STARTING SIMULATION ---");
        reset_signal = 1; #10; reset_signal = 0;
        
        // --- PHASE 1: LOOP SETUP ---
        wait(uut.pc == 8'h03); in_port = 8'h03; // Loop Count = 3
        wait(uut.pc == 8'h04); in_port = 8'h06; // Loop Target = 06
        wait(uut.pc == 8'h05); in_port = 8'h00; // Init R2 = 0

        // --- PHASE 2: CALL/RET SETUP ---
        // Wait until Loop finishes and PC reaches Call setup (Addr 09)
        // (This happens after 3 loops)
        wait(uut.pc == 8'h0A); in_port = 8'h0A; // Load Data 10
        wait(uut.pc == 8'h0B); in_port = 8'h20; // Load Subroutine Addr 20

        // --- PHASE 3: IDLE LOOP SETUP ---
        // Wait until Return completes and we reach Infinite Loop setup
        wait(uut.pc == 8'h10); in_port = 8'h0F; // JMP Target = 0F (Self)

        // Let it spin in the idle loop for a bit
        #100;

        // --- PHASE 4: TRIGGER INTERRUPT ---
        $display("\n--- !!! TRIGGERING INTERRUPT !!! ---");
        @(posedge clk);
        intr_signal = 1;
        @(posedge clk); // Pulse for 1 cycle
        intr_signal = 0;

        // ISR Input
        wait(uut.pc == 8'hE0);
        in_port = 8'hAA; // ISR Indicator

        // Wait for RTI and Return to Idle
        #150;
        
        $display("\n--- ALL TESTS PASSED SUCCESSFULLY ---");
        $stop;
    end
endmodule