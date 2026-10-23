// @P@ 工程：配置 / 环境 / 用例（未挂载任何协议 VIP 的基础骨架）
`ifndef @P@_PKG_SV
`define @P@_PKG_SV

package @P@_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uvm_base_pkg::*;

  class @P@_cfg extends uvm_base_cfg;
    `uvm_object_utils(@P@_cfg)
    int num_items = 1;
    function new(string n = "@P@_cfg"); super.new(n); endfunction
  endclass

  // TODO: 在这里加你自己的 agent / scoreboard / 序列
  class @P@_env extends uvm_base_env #(@P@_cfg);
    `uvm_component_utils(@P@_env)
    // ★ 必须显式声明 new
    function new(string n = "@P@_env", uvm_component p = null); super.new(n, p); endfunction
  endclass

  class @P@_test extends uvm_base_test;
    `uvm_component_utils(@P@_test)
    @P@_env env; @P@_cfg cfg;
    function new(string n = "@P@_test", uvm_component p = null); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg = new("cfg");
      uvm_config_db #(@P@_cfg)::set(this, "env", "cfg", cfg);
      env = @P@_env::type_id::create("env", this);
    endfunction
    // 没有主序列时返回 null（基类会自动跳过）
    virtual function uvm_sequence_base  create_main_sequence(); return null; endfunction
    virtual function uvm_sequencer_base main_sequencer();      return null; endfunction
  endclass

endpackage

`endif
