<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>@P@</title>
<style>
  body { font-family: -apple-system, "Segoe UI", "PingFang SC", "Microsoft YaHei", sans-serif;
         line-height: 1.7; color: #24292f; max-width: 1000px; margin: 0 auto; padding: 24px 28px 64px; }
  h1 { font-size: 26px; border-bottom: 3px solid #0969da; padding-bottom: 10px; }
  h2 { font-size: 20px; margin-top: 32px; border-bottom: 1px solid #d0d7de; padding-bottom: 6px; }
  code { background: #f6f8fa; padding: 2px 5px; border-radius: 4px; font-size: 13px;
         font-family: "SFMono-Regular", Consolas, monospace; }
  pre { background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 6px; padding: 14px 16px;
        overflow-x: auto; font-size: 13px; line-height: 1.55; font-family: "SFMono-Regular", Consolas, monospace; }
  table { border-collapse: collapse; width: 100%; margin: 14px 0; font-size: 14px; }
  th, td { border: 1px solid #d0d7de; padding: 8px 12px; text-align: left; vertical-align: top; }
  th { background: #f6f8fa; }
  blockquote { margin: 12px 0; padding: 10px 16px; border-left: 4px #0969da; background: #f6f8fa; color: #57606a; }
  blockquote.warn { border-left-color: #bc4c00; background: #fff8e5; }
</style>
</head>
<body>

<h1>@P@</h1>
<blockquote>由 <b>uvm_proj_gen</b> 生成的 UVM 验证工程骨架。</blockquote>

<h2>1. 目录结构</h2>
<pre><code>@P@/
├── lib/       依赖（submodule）
├── src/       你的被测设计
├── tb/        你的验证代码（接口 / env / test）
├── sim/       编译相关：Makefile、filelist.f、mk_config.mk
├── script/    你自己的工具脚本（空目录）
└── README.html</code></pre>

<h2>2. 怎么跑</h2>
<pre><code>cd @P@/sim &amp;&amp; make check</code></pre>
<blockquote>编译产物 <code>simv / csrc / logs / waves</code> 都在 <code>sim/</code> 下。</blockquote>

<h2>3. 接下来要做的事</h2>
<ol>
<li>把<b>你的设计</b>放进 <code>src/</code>，并在 <code>sim/filelist.f</code> 里登记（路径写 <code>../src/xxx.sv</code>）</li>
<li><code>tb/@P@_top.sv</code> 里的 <code>u_dut</code> 换成你的模块（当前是占位 DUT）</li>
<li><code>tb/@P@_out_if.sv</code> 的输出信号按你的 DUT 修改</li>
<li>在 <code>tb/@P@_pkg.sv</code> 里写<b>你自己的 checker</b>（当前只统计、不做比对）</li>
<li><code>cd sim &amp;&amp; make check</code></li>
</ol>

<h2>4. 常用命令</h2>
<table>
<tr><th>命令</th><th>说明</th></tr>
<tr><td><code>make comp</code></td><td>只编译</td></tr>
<tr><td><code>make run</code></td><td>只仿真</td></tr>
<tr><td><code>make check</code></td><td>编译 + 仿真</td></tr>
<tr><td><code>make verdi</code></td><td>打开 Verdi 看波形</td></tr>
<tr><td><code>make clean</code></td><td>清理编译产物</td></tr>
</table>

<h2>5. 注意</h2>
<blockquote class="warn">
<b>路径基准</b>：<code>sim/filelist.f</code> 里的路径以 <code>sim/</code> 为基准
（<code>../src</code>、<code>../tb</code>、<code>../lib</code>），因为 make 在 <code>sim/</code> 下运行。<br>
<b>构造函数</b>：继承 <code>uvm_base_*</code> 的组件必须显式声明
<code>function new(string name, uvm_component parent)</code>。
</blockquote>

</body>
</html>
