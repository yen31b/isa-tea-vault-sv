module memory #(
    parameter MEM_SIZE   = 65536,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  mem_read,
    input  logic                  mem_write,
    input  logic [ADDR_WIDTH-1:0] address,
    input  logic [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] read_data
);

    logic [7:0] ram [0:MEM_SIZE-1]; // byte-addressable internamente

    initial begin
        $readmemh("mem/program.mem", ram);
    end

    
    assign read_data = mem_read ? {
        ram[{address[ADDR_WIDTH-1:2], 2'b11}],  // bits [31:24]
        ram[{address[ADDR_WIDTH-1:2], 2'b10}],  // bits [23:16]
        ram[{address[ADDR_WIDTH-1:2], 2'b01}],  // bits [15:8]
        ram[{address[ADDR_WIDTH-1:2], 2'b00}]   // bits [7:0]
    } : 32'b0;

    
    always_ff @(posedge clk) begin
        if (mem_write) begin
            ram[{address[ADDR_WIDTH-1:2], 2'b00}] <= write_data[7:0];   // LSB
            ram[{address[ADDR_WIDTH-1:2], 2'b01}] <= write_data[15:8];
            ram[{address[ADDR_WIDTH-1:2], 2'b10}] <= write_data[23:16];
            ram[{address[ADDR_WIDTH-1:2], 2'b11}] <= write_data[31:24]; // MSB
        end
    end

endmodule