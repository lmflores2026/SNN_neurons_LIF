/*
 * Copyright (c) 2026 Martin Flores
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_SNN_neurons_LIF(
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire ena,
    input wire clk,
    input wire rst_n
);

    wire [1:0] spikes;
    wire prog_done;
    wire [63:0] weights;

    weight wg (
        .clk(clk),
        .rst_n(rst_n),
        .s_data(ui_in[0]),
        .s_clk_en(ui_in[1]),
        .mode_prog(ui_in[2]),
        .weights(weights),
        .prog_done(prog_done)
    );

    // Sincronizador de 2 etapas para obs_step y las 4 entradas externas
    reg [4:0] sync_a, sync_b;
    reg obs_step_d;
    reg obs_sel;                       // 0 = neurona 0, 1 = neurona 1
    wire [3:0] stim = sync_b[4:1];
    wire obs_step = sync_b[0];

    always @(posedge clk) begin
        if (!rst_n) begin
            sync_a <= 5'b0;
            sync_b <= 5'b0;
            obs_step_d <= 1'b0;
            obs_sel <= 1'b0;
        end else begin
            sync_a <= ui_in[7:3];
            sync_b <= sync_a;
            obs_step_d <= obs_step;
            if (obs_step && !obs_step_d) obs_sel <= ~obs_sel;
        end
    end

    // 8 sinapsis por neurona:
    //   [1:0] spikes de las 2 neuronas (recurrentes, incluye auto-sinapsis)
    //   [5:2] estimulos externos ui[7:4]
    //   [7:6] sin conexion (0) -> pesos almacenados pero sin efecto
    wire [7:0] all_spikes = {2'b00, stim, spikes};
    wire signed [7:0] i0, i1;

    synapse sp (
        .all_spikes(all_spikes),
        .w(weights),
        .i0(i0),
        .i1(i1)
    );

    wire signed [7:0] v0, v1;

    LIF_neuron neuron0 (.clk(clk), .rst_n(rst_n), .ena(ena),
        .current_in(i0), .spike(spikes[0]), .v_mem(v0));
    LIF_neuron neuron1 (.clk(clk), .rst_n(rst_n), .ena(ena),
        .current_in(i1), .spike(spikes[1]), .v_mem(v1));

    wire [7:0] v_obs = obs_sel ? v1 : v0;

    assign uio_out = v_obs;
    assign uio_oe = 8'hFF;
    // uo[1:0]=spikes, uo[2]=prog_done, uo[3]=obs_sel, uo[7:4]=0
    assign uo_out = {4'b0000, obs_sel, prog_done, spikes};
    wire _unused = &{uio_in, 1'b0};

endmodule
