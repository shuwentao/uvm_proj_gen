// 被测 DUT 输出侧接口（按你的实际输出信号修改）
`ifndef @P@_OUT_IF_SV
`define @P@_OUT_IF_SV
`timescale 1ns/1ps

interface @P@_out_if #(parameter int DATA_WIDTH = 8) (input logic clk, input logic rst_n);
  logic [DATA_WIDTH-1:0] pixel_data;
  logic                  pixel_valid;
  logic [15:0]           pixel_x;
  logic [15:0]           pixel_y;
  logic                  frame_start, frame_end, line_start, line_end;

  clocking mon_cb @(posedge clk);
    default input #1step;
    input pixel_data, pixel_valid, pixel_x, pixel_y;
    input frame_start, frame_end, line_start, line_end;
  endclocking
endinterface

`endif
