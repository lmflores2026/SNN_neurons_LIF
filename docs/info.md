<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements the Leaky Integrate-and-Fire model in a simple 2-neuron spiking neural network chip designed for TinyTapeout GF180nm

Every neuron has a membrane potential and an incoming current. Each clock cycle, the neuron receives input current from neurons that fired in the previous cycle and leaks a fraction of its current voltage (1/8 of the current voltage) according to the following equation:

V[t+1] = V[t] - V[t]/8 + I[t]

Once the voltage inside a neuron reaches 64, it fires a spike and resets its membrane potential to 0.

Each neuron has eight synapses: two from the neurons' spikes (both neurons, including its own),
four from external stimulus inputs on ui[7:4], and two unconnected synapses (reserved, no effect). Positive weights push the membrane potential towards threshold,
negative weights pull it away. The potential saturates at -128 and 127 instead of wrapping.

<img width="675" height="495" alt="image" src="https://github.com/user-attachments/assets/b7bc04e0-5808-418b-8898-c4481d6c32ad" />

Here is what each block does:

weight.v: A 64-bit shift register. It is programmed serially using ui_in[0] (data), ui_in[1] (clock enable), and ui_in[2] (programming mode). It outputs weights[63:0] and asserts the `prog_done` signal once all 64 bits have been loaded.
Synchronizer (within project.v): Passes ui_in[7:3] through two flip-flops. This includes 4 external stimuli (`stim`) and an `obs_step` signal. Each rising edge of `obs_step` toggles `obs_sel`.
synapse.v: Receives 8 input spikes (2 recurrent, 4 external, and 2 unconnected). Each neuron uses 32 bits for weights—specifically, eight 4-bit signed weights. The output (i0/i1) is the sum of the weights corresponding to the active inputs.
LIF_neuron.v (x2): Integrates the current with a leakage term defined as `v_mem >>> 3`. When the membrane potential (`v_mem`) reaches 64, it generates a spike and resets to 0.
Feedback: Spikes from both neurons are fed back to the synapse (indicated by the amber line). This includes the self-synapse for each neuron.
Outputs: `uio_out` carries the `v_mem` value of the neuron selected by `obs_sel`. `uo_out` consists of `{obs_sel, prog_done, spikes}`.


## How to test

1) Hold rst_n low for at least 3 clock cycles, then release. All membrane potentials and spike outputs clear to zero.

2) Assert ui[2] high (mode_prog = 1). Shift in 64 bits MSB-first by toggling ui[1] (s_clk_en) while driving ui[0] (s_data) with each bit. After 64 bits, uo[2] (prog_done) goes high confirming the weight matrix is fully loaded. De-assert ui[2].

3) Assert ena = 1 and drive one or more stimulus inputs high on ui[7:4]. Spike outputs appear
on uo[1:0], one bit per neuron. With all stimulus inputs low the network stays at rest.

4) Pulse ui[3] to toggle between the two neurons; uo[3] shows which neuron is selected and
uio[7:0] shows its membrane potential as a signed 8-bit value.

## External hardware

No external hardware is required.
