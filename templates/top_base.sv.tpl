// @P@ 顶层骨架（未挂载协议 VIP）
`timescale 1ns/1ps
module @P@_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uvm_base_pkg::*;
  import @P@_pkg::*;

  logic clk = 1'b0, rst_n = 1'b0;
  initial forever #5ns clk = ~clk;
  initial begin rst_n = 0; #200ns; rst_n = 1; end

  // TODO: 例化你的 interface 与 DUT，并用 config_db 下发虚接口
  initial run_test("@P@_test");
endmodule
