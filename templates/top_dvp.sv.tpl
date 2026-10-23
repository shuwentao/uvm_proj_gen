// @P@ 顶层：DVP VIP(BFM) -> 占位 DUT(dvp_rx) -> 你的输出观测
//   ★ 把 u_dut 换成你自己的设计即可
`timescale 1ns/1ps
module @P@_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uvm_base_pkg::*;
  import dvp_video_pkg::*;
  import dvp_vip_pkg::*;
  import @P@_pkg::*;

  localparam int DW = 8;
  logic rst_n = 1'b0;

  dvp_bfm_if #(.DATA_WIDTH(DW)) dvp_vif (.rst_n(rst_n));
  @P@_out_if #(.DATA_WIDTH(DW)) out_vif (.clk(dvp_vif.pclk), .rst_n(rst_n));

  // 占位 DUT：DVP 接收端（替换成你自己的设计）
  dvp_rx #(
    .DATA_WIDTH(DW),
    .H_ACTIVE(640), .H_FP(16), .H_SYNC(96), .H_BP(48),
    .V_ACTIVE(480), .V_FP(10), .V_SYNC(2), .V_BP(33),
    .HSYNC_POL(1'b1), .VSYNC_POL(1'b1), .DE_POL(1'b1),
    .CHK_TIMING(1'b1), .TIMEOUT_CYCLES(0)
  ) u_dut (
    .pclk(dvp_vif.pclk), .rst_n(rst_n),
    .vsync(dvp_vif.vsync), .hsync(dvp_vif.hsync),
    .de(dvp_vif.de), .data(dvp_vif.data),
    .pixel_data(out_vif.pixel_data), .pixel_valid(out_vif.pixel_valid),
    .pixel_x(out_vif.pixel_x), .pixel_y(out_vif.pixel_y),
    .frame_start(out_vif.frame_start), .frame_end(out_vif.frame_end),
    .line_start(out_vif.line_start), .line_end(out_vif.line_end),
    .frame_active(), .frame_cnt(),
    .err_line_len(), .err_frame_lines(), .err_de_outside(), .err_timeout()
  );

  initial begin rst_n = 1'b0; #500ns; rst_n = 1'b1; end

  initial begin
    uvm_config_db #(virtual dvp_bfm_if #(DW))::set(null, "*", "dvp_vif", dvp_vif);
    uvm_config_db #(virtual @P@_out_if #(DW))::set(null, "*", "out_vif", out_vif);
    run_test("@P@_test");
  end

`ifdef UVM_BASE_DUMP_FSDB
  initial begin $fsdbDumpfile("waves/@P@_top.fsdb"); $fsdbDumpvars(0, @P@_top); end
`elsif UVM_BASE_DUMP_VCD
  initial begin $dumpfile("waves/@P@_top.vcd"); $dumpvars(0, @P@_top); end
`endif
endmodule
