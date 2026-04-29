`timescale 1ns / 1ps

module register_file (
    input  logic        clk,
    input  logic        reset,
    input  logic        we,        // Write Enable
    input  logic [4:0]  rs1_addr,  // Read Address 1 (5 bits for 32 regs)
    input  logic [4:0]  rs2_addr,  // Read Address 2
    input  logic [4:0]  rs3_addr,  // Read Address 3 (for xortea)
    input  logic [4:0]  rd_addr,   // Write Address
    input  logic [31:0] write_data,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] rs3_data
);

    logic [31:0] registers [31:0];

    // Asynchronous read
    assign rs1_data = registers[rs1_addr];
    assign rs2_data = registers[rs2_addr];
    assign rs3_data = registers[rs3_addr];

    // Synchronous write
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (we) begin
            registers[rd_addr] <= write_data;
        end
    end

endmodule
