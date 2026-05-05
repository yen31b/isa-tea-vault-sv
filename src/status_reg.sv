`timescale 1ns / 1ps

module status_reg (
    input  logic       clk,
    input  logic       reset,
    input  logic       we,          // Write enable for flags (usually after ALU op)
    input  logic [5:0] alu_flags,   // Flags from ALU (Z, N, C, V)
    input  logic       auth_in,     // Authentication status from Security Unit
    input  logic       exc_in,      // Exception signal from Security Unit
    input  logic       set_auth,    // Control signal to update AUTH flag
    input  logic       set_exc,     // Control signal to update EXC flag
    output logic [5:0] current_flags
);

    // [5]: EXC, [4]: AUTH, [3]: V, [2]: C, [1]: N, [0]: Z
    logic [5:0] flags;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            flags <= 6'b0;
        end else begin
            if (we) begin
                flags[3:0] <= alu_flags[3:0]; // Update ALU flags
            end
            if (set_auth) begin
                flags[4] <= auth_in;
            end
            if (set_exc) begin
                flags[5] <= exc_in;
            end
        end
    end

    assign current_flags = flags;

endmodule
