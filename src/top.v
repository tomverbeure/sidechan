

// Divide input clock by 32 with cascaded FFs
module clk_div32(input clk_in, output clk_out);

    reg [4:0] cntr;

    always @(posedge clk_in)
        cntr[0] <= !cntr[0];

    always @(posedge cntr[0])
        cntr[1] <= !cntr[1];

    always @(posedge cntr[1])
        cntr[2] <= !cntr[2];

    always @(posedge cntr[2])
        cntr[3] <= !cntr[3];

    always @(posedge cntr[3])
        cntr[4] <= !cntr[4];

    assign clk_out = cntr[4];

endmodule

module top(
    input   clk50,
    input   button,
    output  primary_out,
    output  ring_osc_out,
    output  led0,
    output  led1,
    output  led2
);

    // ============================================================
    // Design one: shift register that toggles all the time (or not)
    // ============================================================

    localparam  nr_ffs = 3000;

    reg [nr_ffs-1:0] shift_reg;

    wire main_clk;

    pll	pll_inst (
	    .areset (1'b0),
	    .inclk0 (clk50),
	    .c0 (main_clk),
	    .locked ()
	);

    // Shift toggle pattern when button = 1, otherwise shift static value.
    always @(posedge main_clk) begin
        shift_reg[nr_ffs-1:1] <= shift_reg[nr_ffs-2:0];
        shift_reg[0] <= shift_reg[0] ^ button;
    end

    wire primary_clk;
    clk_div32 primary_div(.clk_in(shift_reg[nr_ffs-1]), .clk_out(primary_clk));

    reg [21:0] cntr;

    always @(posedge primary_clk)
        cntr <= cntr + 1'b1;

    assign led0 = cntr[21];
    assign primary_out = primary_clk;

    // ============================================================
    // Design two: free-running ring oscillator
    // ============================================================

    wire [6:0] ring;

    lcell cell0 (.in(!ring[6]), .out(ring[0]));
    lcell cell1 (.in(!ring[0]), .out(ring[1]));
    lcell cell2 (.in(!ring[1]), .out(ring[2]));
    lcell cell3 (.in(!ring[2]), .out(ring[3]));
    lcell cell4 (.in(!ring[3]), .out(ring[4]));
    lcell cell5 (.in(!ring[4]), .out(ring[5]));
    lcell cell6 (.in(!ring[5]), .out(ring[6]));

    wire secondary_clk;
    clk_div32 secondary_div(.clk_in(ring[6]), .clk_out(secondary_clk));

    reg [21:0] ring_cntr;

    always @(posedge secondary_clk) begin
        ring_cntr <= ring_cntr + 1'b1;
    end

    assign ring_osc_out = secondary_clk;

    assign led1 = ring_cntr[21];
    assign led2 = 1'b1;

endmodule
