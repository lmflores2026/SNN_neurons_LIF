`default_nettype none

module synapse (
    input wire [7:0] all_spikes, input wire [63:0] w,
    output wire signed [7:0] i0, output wire signed [7:0] i1
);
    function signed [7:0] calc;
        input [7:0] s;
        input [31:0] weights;
        integer i;
        reg signed [7:0] sum;
        begin
            sum = 8'sd0;
            for (i = 0; i < 8; i = i + 1) begin
                if (s[i]) sum = sum + $signed(weights[i*4 +: 4]);
            end
            calc = sum;
        end
    endfunction

    assign i0 = calc(all_spikes, w[31:0]);
    assign i1 = calc(all_spikes, w[63:32]);

endmodule