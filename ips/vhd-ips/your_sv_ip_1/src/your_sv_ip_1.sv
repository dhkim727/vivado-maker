// ==============================================================
// Example SystemVerilog IP for vivado-maker
// ==============================================================

module your_sv_ip_1 #(
    parameter int DATA_WIDTH = 8
) (
    input  logic                  clk_i,
    input  logic                  rstn_i,
    input  logic                  d_i,
    output logic [DATA_WIDTH-1:0] d_o
);

    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            d_o <= '0;
        end else if (d_i) begin
            d_o <= DATA_WIDTH'(8'h5A);
        end
    end

endmodule