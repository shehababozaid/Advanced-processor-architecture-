module RegisterFile (
    input  wire       clk,
    input  wire       rst,
    
    // Write Port 1 (General Purpose - WB Stage)
    input  wire       we,
    input  wire [1:0] waddr,
    input  wire [7:0] wdata,
    
    // Write Port 2 (Stack Pointer Update - SP Specific)
    // This is used because SP update happens alongside other operations
    input  wire       we2,
    input  wire [1:0] waddr2,
    input  wire [7:0] wdata2,
    
    // Read Ports (ID Stage)
    input  wire [1:0] raddr1,
    input  wire [1:0] raddr2,
    output wire [7:0] rdata1,
    output wire [7:0] rdata2
);

    reg [7:0] registers [0:3];
    integer i;

    // Initialization
    initial begin
        for (i = 0; i < 4; i = i + 1)
            registers[i] = 8'b0;
        
        registers[3] = 8'd255; // SP Initial Value according to spec
    end

    // Write Logic (Synchronous)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            registers[0] <= 8'b0;
            registers[1] <= 8'b0;
            registers[2] <= 8'b0;
            registers[3] <= 8'd255; // Reset SP to 255
        end
        else begin
            // Port 1 Write
            if (we) begin
                registers[waddr] <= wdata;
            end
            
            // Port 2 Write (Priority to Port 2 if addresses conflict? 
            // Usually SP update is distinct, but let's assume Port 2 overwrites if same)
            if (we2) begin
                registers[waddr2] <= wdata2;
            end
        end
    end

    // Read Logic (Asynchronous)
    assign rdata1 = registers[raddr1];
    assign rdata2 = registers[raddr2];

endmodule