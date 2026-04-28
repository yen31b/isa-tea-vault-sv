// Memoria de datos (RAM) para LD/ST

module data_mem #(
    parameter MEM_SIZE   = 65536,   // 64 KB en bytes
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  mem_read,    // señal LD desde control_unit
    input  logic                  mem_write,   // señal ST desde control_unit
    input  logic [ADDR_WIDTH-1:0] address,     // rs1 + offset (datapath)
    input  logic [DATA_WIDTH-1:0] write_data,  // dato a guardar (ST) — viene de rs2
    output logic [DATA_WIDTH-1:0] read_data    // dato leído (LD) — va a rd
);

    // Memoria interna byte-addressable
    // 65536 bytes = 64 KB = 16384 palabras de 32 bits
    logic [7:0] ram [0:MEM_SIZE-1];

    // Cargar datos iniciales desde archivo .mem
    // Generado por el programa de cargar archivos
    initial begin
        $readmemh("mem/program.mem", ram);
    end

    assign read_data = mem_read ? {
        ram[{address[ADDR_WIDTH-1:2], 2'b11}],  // bits [31:24] MSB
        ram[{address[ADDR_WIDTH-1:2], 2'b10}],  // bits [23:16]
        ram[{address[ADDR_WIDTH-1:2], 2'b01}],  // bits [15:8]
        ram[{address[ADDR_WIDTH-1:2], 2'b00}]   // bits [7:0]  LSB
    } : 32'b0;

    always_ff @(posedge clk) begin
        if (mem_write) begin
            ram[{address[ADDR_WIDTH-1:2], 2'b00}] <= write_data[7:0];    // LSB
            ram[{address[ADDR_WIDTH-1:2], 2'b01}] <= write_data[15:8];
            ram[{address[ADDR_WIDTH-1:2], 2'b10}] <= write_data[23:16];
            ram[{address[ADDR_WIDTH-1:2], 2'b11}] <= write_data[31:24];  // MSB
        end
    end

endmodule