`timescale 1ns / 1ps
// =============================================================================
// snn_top_v3.v - FINAL YOSYS-CLEAN VERSION (synchronous reset)
// Fixes:
//   - Removed unused integer i
//   - Synchronous reset everywhere → no more "Multiple edge sensitive events"
//   - All warnings cleaned or made harmless
// =============================================================================

module spike_encoder #(parameter WIDTH = 8)(
    input clk, input rst,
    input [WIDTH-1:0] rate,
    output reg spike_out
);
    reg [7:0] lfsr;
    always @(posedge clk) begin
        if (rst) begin
            lfsr <= 8'hAC;
            spike_out <= 1'b0;
        end else begin
            lfsr <= {lfsr[6:0], 1'b0} ^ (lfsr[7] ? 8'hB8 : 8'h00);
            spike_out <= (lfsr < rate) ? 1'b1 : 1'b0;
        end
    end
endmodule

module mac_unit #(parameter WIDTH = 8)(
    input [1:0] mode,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [15:0] product
);
    wire [15:0] prod_exact = a * b;

    reg [3:0] exp_a, exp_b;
    reg [4:0] exp_sum;
    reg [7:0] man;
    reg [15:0] prod_m;

    always @* begin
        prod_m = 16'd0; exp_a = 4'd0; exp_b = 4'd0; exp_sum = 5'd0; man = 8'd0;
        if (a != 0 && b != 0) begin
            exp_a = a[7] ? 4'd7 : a[6]?4'd6:a[5]?4'd5:a[4]?4'd4:
                    a[3]?4'd3:a[2]?4'd2:a[1]?4'd1:4'd0;
            exp_b = b[7] ? 4'd7 : b[6]?4'd6:b[5]?4'd5:b[4]?4'd4:
                    b[3]?4'd3:b[2]?4'd2:b[1]?4'd1:4'd0;
            exp_sum = exp_a + exp_b;
            man = ((a >> (exp_a > 0 ? exp_a-1 : 0)) & 4'hF) *
                  ((b >> (exp_b > 0 ? exp_b-1 : 0)) & 4'hF);
            prod_m = (exp_sum >= 15) ? 16'hFFFF : ({8'h00, man} << exp_sum);
        end
    end

    wire [15:0] prod_trunc = {a[7:4] * b[7:4], 8'b0};

    always @* begin
        case (mode)
            2'b00: product = prod_exact;
            2'b01: product = prod_m;
            2'b10: product = prod_trunc;
            default: product = prod_exact;
        endcase
    end
endmodule

module mode_controller #(
    parameter WINDOW = 8, parameter HI_THRESH = 6, parameter LO_THRESH = 2
)(
    input clk, input rst, input [7:0] hidden_spikes, output reg [1:0] mac_mode
);
    reg [3:0] spike_cnt;
    reg [3:0] win [0:7];
    reg [6:0] win_sum;
    integer j, k;

    always @* begin
        spike_cnt = 4'd0;
        for (j = 0; j < 8; j = j + 1)
            spike_cnt = spike_cnt + {3'b0, hidden_spikes[j]};
    end

    always @(posedge clk) begin
        if (rst) begin
            win_sum <= 7'd0; mac_mode <= 2'b01;
            for (k = 0; k < 8; k = k + 1) win[k] <= 4'd0;
        end else begin
            win_sum <= win_sum - win[7] + spike_cnt;
            for (k = 7; k > 0; k = k - 1) win[k] <= win[k-1];
            win[0] <= spike_cnt;
            if (win_sum >= HI_THRESH * WINDOW) mac_mode <= 2'b00;
            else if (win_sum <= LO_THRESH * WINDOW) mac_mode <= 2'b10;
            else mac_mode <= 2'b01;
        end
    end
endmodule

module weight_mem #(
    parameter DEPTH = 16, parameter WIDTH = 8
)(
    input clk, input rst, input wr_en, input [3:0] wr_addr,
    input [WIDTH-1:0] wr_data, input [3:0] rd_addr,
    output [WIDTH-1:0] rd_data
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (rst) begin
            mem[0]<=8'h90; mem[1]<=8'h80; mem[2]<=8'hA0; mem[3]<=8'h70;
            mem[4]<=8'h88; mem[5]<=8'h98; mem[6]<=8'hB0; mem[7]<=8'h78;
            mem[8]<=8'h80; mem[9]<=8'h90; mem[10]<=8'hA8; mem[11]<=8'h68;
            mem[12]<=8'h78; mem[13]<=8'hA0; mem[14]<=8'h88; mem[15]<=8'h80;
        end else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end
    assign rd_data = mem[rd_addr];
endmodule

module spike_activity_monitor #(parameter IDLE_CYCLES = 8)(
    input clk, input rst, input input_valid,
    input [7:0] hidden_spikes, input [1:0] output_spikes,
    output reg clk_enable
);
    reg [3:0] idle_ctr;
    wire any_act = input_valid | (|hidden_spikes) | (|output_spikes);
    always @(posedge clk) begin
        if (rst) begin
            idle_ctr <= 4'd0; clk_enable <= 1'b1;
        end else if (any_act) begin
            idle_ctr <= 4'd0; clk_enable <= 1'b1;
        end else if (idle_ctr < IDLE_CYCLES) begin
            idle_ctr <= idle_ctr + 1; clk_enable <= 1'b1;
        end else begin
            clk_enable <= 1'b0;
        end
    end
endmodule

module lif_neuron_v3 #(
    parameter WIDTH = 8, parameter LEAK = 8'h04, parameter THRESH = 8'h60
)(
    input clk, input rst, input update_en,
    input [WIDTH-1:0] synaptic_current,
    output reg spike, output [WIDTH-1:0] Vmem_out
);
    reg [WIDTH-1:0] Vmem;
    wire [WIDTH:0] after_leak = (Vmem > LEAK) ?
        {1'b0, Vmem} - {1'b0, LEAK[WIDTH-1:0]} : {(WIDTH+1){1'b0}};
    wire [WIDTH:0] after_input = after_leak + {1'b0, synaptic_current};
    wire [WIDTH-1:0] Vmem_next = after_input[WIDTH] ? {WIDTH{1'b1}} : after_input[WIDTH-1:0];
    wire fire = update_en & (Vmem_next >= THRESH);

    always @(posedge clk) begin
        if (rst) begin Vmem <= 0; spike <= 0; end
        else if (fire) begin Vmem <= 0; spike <= 1; end
        else if (update_en) begin Vmem <= Vmem_next; spike <= 0; end
        else begin Vmem <= after_leak[WIDTH-1:0]; spike <= 0; end
    end
    assign Vmem_out = Vmem;
endmodule

// =============================================================================
// TOP MODULE
// =============================================================================
module snn_top_v3 #(parameter WIDTH = 8)(
    input clk, input rst, input input_valid,
    input wr_en, input [3:0] wr_addr, input [WIDTH-1:0] wr_data,
    input [WIDTH-1:0] input_act_0, input [WIDTH-1:0] input_act_1,
    output [1:0] output_spikes, output [1:0] mac_mode_out,
    output clk_enable_out
);

    wire enc_spike_0, enc_spike_1;
    spike_encoder #(.WIDTH(WIDTH)) enc0 (.clk(clk), .rst(rst), .rate(input_act_0), .spike_out(enc_spike_0));
    spike_encoder #(.WIDTH(WIDTH)) enc1 (.clk(clk), .rst(rst), .rate(input_act_1), .spike_out(enc_spike_1));

    wire [WIDTH-1:0] act_0 = enc_spike_0 ? 8'hFF : 8'h00;
    wire [WIDTH-1:0] act_1 = enc_spike_1 ? 8'hFF : 8'h00;

    wire [7:0] hidden_spikes;
    wire [1:0] mac_mode;
    assign mac_mode_out = mac_mode;

    mode_controller #(.WINDOW(8), .HI_THRESH(6), .LO_THRESH(2)) mc (
        .clk(clk), .rst(rst), .hidden_spikes(hidden_spikes), .mac_mode(mac_mode));

    wire [WIDTH-1:0] w [0:15];
    genvar wi;
    generate
        for (wi = 0; wi < 16; wi = wi + 1) begin : wm_inst
            weight_mem #(.DEPTH(16), .WIDTH(WIDTH)) wmem (
                .clk(clk), .rst(rst),
                .wr_en(wr_en & (wr_addr == wi[3:0])),
                .wr_addr(wr_addr), .wr_data(wr_data),
                .rd_addr(wi[3:0]), .rd_data(w[wi]));
        end
    endgenerate

    wire [WIDTH-1:0] current_h [0:7];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : hl
            wire [15:0] prod0, prod1;
            mac_unit #(.WIDTH(WIDTH)) m0 (.mode(mac_mode), .a(w[2*i]),   .b(act_0), .product(prod0));
            mac_unit #(.WIDTH(WIDTH)) m1 (.mode(mac_mode), .a(w[2*i+1]), .b(act_1), .product(prod1));

            wire [8:0] s = {1'b0, prod0[12:5]} + {1'b0, prod1[12:5]};
            assign current_h[i] = s[8] ? 8'hFF : s[7:0];

            lif_neuron_v3 #(.WIDTH(WIDTH), .LEAK(8'h04), .THRESH(8'h60)) lh (
                .clk(clk), .rst(rst), .update_en(input_valid),
                .synaptic_current(current_h[i]),
                .spike(hidden_spikes[i]), .Vmem_out()
            );
        end
    endgenerate

    wire [9:0] raw0 = ({6'b0, hidden_spikes[3:0]} * 10'd8) + ({6'b0, hidden_spikes[7:4]} * 10'd4);
    wire [9:0] raw1 = ({6'b0, hidden_spikes[7:4]} * 10'd8) + ({6'b0, hidden_spikes[3:0]} * 10'd4);
    wire [WIDTH-1:0] co0 = raw0[9:2];
    wire [WIDTH-1:0] co1 = raw1[9:2];

    wire os0, os1;
    lif_neuron_v3 #(.WIDTH(WIDTH), .LEAK(8'h04), .THRESH(8'h40)) lo0 (
        .clk(clk), .rst(rst), .update_en(input_valid),
        .synaptic_current(co0), .spike(os0), .Vmem_out()
    );
    lif_neuron_v3 #(.WIDTH(WIDTH), .LEAK(8'h04), .THRESH(8'h40)) lo1 (
        .clk(clk), .rst(rst), .update_en(input_valid),
        .synaptic_current(co1), .spike(os1), .Vmem_out()
    );

    reg [1:0] out_reg;
    always @(posedge clk) out_reg <= rst ? 2'b00 : {os1, os0};
    assign output_spikes = out_reg;

    spike_activity_monitor #(.IDLE_CYCLES(8)) sam (
        .clk(clk), .rst(rst),
        .input_valid(input_valid),
        .hidden_spikes(hidden_spikes),
        .output_spikes(out_reg),
        .clk_enable(clk_enable_out));

endmodule
