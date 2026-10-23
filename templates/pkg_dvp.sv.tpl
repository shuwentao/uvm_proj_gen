// @P@ 工程：配置 / 环境 / 用例
//   ★ 集成点：dvp_agent 来自 dvp_vip；你的 checker 在这里写
`ifndef @P@_PKG_SV
`define @P@_PKG_SV

package @P@_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uvm_base_pkg::*;
  import dvp_video_pkg::*;
  import dvp_vip_pkg::*;

  //---------------- 配置 ----------------
  class @P@_cfg extends uvm_base_cfg;
    `uvm_object_utils(@P@_cfg)
    dvp_agent_cfg                     dvp_cfg;
    virtual @P@_out_if #(8)           out_vif;
    int  num_frames     = 1;
    int  pclk_period_ps = 10000;
    function new(string n = "@P@_cfg");
      super.new(n); dvp_cfg = new("dvp_cfg");
    endfunction
    // 激励时序与你的 DUT 参数对齐（按实际修改）
    function dvp_timing_cfg dut_timing();
      dvp_timing_cfg t = new("t");
      t.set_preset(DVP_PRESET_VGA);
      t.set_pclk_ps(pclk_period_ps);
      return t;
    endfunction
  endclass

  //---------------- 输出侧观测（示例：只统计，不做比对）----------------
  class @P@_out_item extends uvm_base_item;
    `uvm_object_utils(@P@_out_item)
    int pixels = 0, lines = 0;
    function new(string n = "@P@_out_item"); super.new(n); endfunction
  endclass

  class @P@_out_monitor extends uvm_base_monitor #(@P@_out_item);
    `uvm_component_utils(@P@_out_monitor)
    virtual @P@_out_if #(8) vif;
    protected int p_cnt = 0, l_cnt = 0;
    function new(string n = "@P@_out_monitor", uvm_component p = null); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db #(virtual @P@_out_if #(8))::get(this, "", "out_vif", vif))
        `uvm_fatal("NOVIF", "out_vif 未设置")
    endfunction
    virtual task pre_run(); @(posedge vif.rst_n); endtask
    virtual task do_monitor();
      @(vif.mon_cb);
      if (vif.mon_cb.pixel_valid) p_cnt++;
      if (vif.mon_cb.line_end)    l_cnt++;
      if (vif.mon_cb.frame_end) begin
        @P@_out_item it;
        void'($cast(it, @P@_out_item::type_id::create("it")));
        it.pixels = p_cnt; it.lines = l_cnt;
        p_cnt = 0; l_cnt = 0;
        `uvm_info("OUTMON", $sformatf("frame done: pixels=%0d lines=%0d", it.pixels, it.lines), UVM_MEDIUM)
        emit(it);
      end
    endtask
  endclass

  //---------------- env ----------------
  class @P@_env extends uvm_base_env #(@P@_cfg);
    `uvm_component_utils(@P@_env)
    dvp_agent       dvp_ag;      // ★ 来自 DVP VIP
    @P@_out_monitor out_mon;
    // ★ 必须显式声明 new：factory 用 new(name,parent) 创建组件
    function new(string n = "@P@_env", uvm_component p = null); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_config_db #(dvp_agent_cfg)::set(this, "dvp_ag", "cfg", cfg.dvp_cfg);
      dvp_ag  = dvp_agent::type_id::create("dvp_ag", this);
      out_mon = @P@_out_monitor::type_id::create("out_mon", this);
      out_mon.vif = cfg.out_vif;
    endfunction
  endclass

  //---------------- test ----------------
  class @P@_test extends uvm_base_test;
    `uvm_component_utils(@P@_test)
    @P@_env env; @P@_cfg cfg;
    function new(string n = "@P@_test", uvm_component p = null); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
      virtual dvp_bfm_if #(8)     v_dvp;
      virtual @P@_out_if #(8)     v_out;
      super.build_phase(phase);
      cfg = new("cfg");
      if (!uvm_config_db #(virtual dvp_bfm_if #(8))::get(this, "", "dvp_vif", v_dvp))
        `uvm_fatal("NOVIF", "dvp_vif 未设置")
      if (!uvm_config_db #(virtual @P@_out_if #(8))::get(this, "", "out_vif", v_out))
        `uvm_fatal("NOVIF", "out_vif 未设置")
      cfg.dvp_cfg.vif = v_dvp;
      cfg.out_vif     = v_out;
      cfg.num_frames      = ub_get_int("NUM_FRAMES", cfg.num_frames);
      cfg.pclk_period_ps  = ub_get_int("PCLK_PS",    cfg.pclk_period_ps);
      uvm_config_db #(@P@_cfg)::set(this, "env", "cfg", cfg);
      env = @P@_env::type_id::create("env", this);
    endfunction
    virtual function uvm_sequence_base create_main_sequence();
      dvp_smoke_seq s;
      void'($cast(s, dvp_smoke_seq::type_id::create("seq")));
      s.base_tcfg = cfg.dut_timing();      // ★ 激励时序对齐你的 DUT
      return s;
    endfunction
    virtual function uvm_sequencer_base main_sequencer();
      return env.dvp_ag.sqr;               // ★ 跑在 VIP 的 sequencer 上
    endfunction
  endclass

endpackage

`endif
