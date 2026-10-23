#!/usr/bin/env bash
# =============================================================================
# File    : uvm_proj_gen/create_project.sh
# Purpose : 生成一个新的 UVM 验证工程，并按需要挂载 submodule
#
# 用法:
#   ./create_project.sh my_proj                 # 交互式选择要挂的仓库
#   ./create_project.sh my_proj -y              # 非交互，用 repo.list 默认勾选
#   ./create_project.sh my_proj -r uvm_base,dvp_vip
#   ./create_project.sh my_proj -r uvm_base,dvp_vip --dir ~/work
#   ./create_project.sh my_proj --local         # 本地开发：软链接代替 submodule
#   ./create_project.sh --list                  # 只打印可用仓库清单
#
# 选项:
#   -r, --repos <a,b,c>   指定要挂的仓库名
#   -y, --yes             非交互（采用 repo.list 里的默认勾选）
#   --dir <path>          工程创建位置（默认当前目录）
#   --local               不 git submodule add，改为软链到 ../../<仓库名>
#   --list                打印 repo.list 并退出
#   --config <file>       使用其它仓库清单（默认 ./repo.list）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL_DIR="${SCRIPT_DIR}/templates"
FRAG_DIR="${TPL_DIR}/repo_fragments"
CONFIG="${SCRIPT_DIR}/repo.list"

PROJ=""
DIR="$(pwd)"
REPOS_OPT=""
NONINT=0
MODE="submodule"

#---------------------------------------------------------------- 参数解析 ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)   CONFIG="${CONFIG}"; PRINT_LIST=1; shift ;;
    --config) CONFIG="$2"; shift 2 ;;
    -r|--repos) REPOS_OPT="$2"; shift 2 ;;
    -y|--yes) NONINT=1; shift ;;
    --dir)    DIR="$2"; shift 2 ;;
    --local)  MODE="local"; shift ;;
    -h|--help) sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) if [ -z "${PROJ}" ]; then PROJ="$1"; shift; else
         echo "[ERROR] 未知参数: $1"; exit 1; fi ;;
  esac
done

#---------------------------------------------------------------- 读仓库清单 --
R_NAME=(); R_PATH=(); R_URL=(); R_DESC=(); R_DEF=()

while IFS= read -r line; do
  line="$(echo "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "${line}" ] && continue
  case "${line}" in \#*) continue ;; esac
  n="$(echo "${line}" | awk -F'|' '{print $1}' | tr -d ' ')"
  p="$(echo "${line}" | awk -F'|' '{print $2}' | tr -d ' ')"
  u="$(echo "${line}" | awk -F'|' '{print $3}' | tr -d ' ')"
  d="$(echo "${line}" | awk -F'|' '{print $4}' | sed -e 's/^ *//' -e 's/ *$//')"
  f="$(echo "${line}" | awk -F'|' '{print $5}' | tr -d ' ')"
  R_NAME+=("${n}"); R_PATH+=("${p}"); R_URL+=("${u}"); R_DESC+=("${d}"); R_DEF+=("${f:-0}")
done < "${CONFIG}"

if [ "${PRINT_LIST:-0}" = "1" ] || [ -z "${PROJ}" ]; then
  echo "可用仓库（${CONFIG}）:"
  for i in "${!R_NAME[@]}"; do
    printf "  %-10s %-14s %-45s %s  [默认:%s]\n" \
      "${R_NAME[$i]}" "${R_PATH[$i]}" "${R_URL[$i]}" "${R_DESC[$i]}" "${R_DEF[$i]}"
  done
  [ -z "${PROJ}" ] && { echo; echo "用法: $0 <工程名> [-r a,b] [--dir DIR] [--local]"; }
  exit 0
fi

#---------------------------------------------------------------- 选择仓库 ----
SELECTED=()
in_arr() { local needle="$1"; shift; local x; for x in "$@"; do [ "${x}" = "${needle}" ] && return 0; done; return 1; }
has_repo()   { in_arr "$1" "${SELECTED[@]:-}"; }        # 是否已被选中
valid_repo() { in_arr "$1" "${R_NAME[@]}"; }            # 是否在仓库清单中

if [ -n "${REPOS_OPT}" ]; then
  IFS=',' read -ra SELECTED <<< "${REPOS_OPT}"
else
  if [ "${NONINT}" = "1" ]; then
    for i in "${!R_NAME[@]}"; do [ "${R_DEF[$i]}" = "1" ] && SELECTED+=("${R_NAME[$i]}") || true; done
  else
    echo "可挂载的仓库："
    for i in "${!R_NAME[@]}"; do
      mark=" "; [ "${R_DEF[$i]}" = "1" ] && mark="*"
      printf "  [%d] %s %-10s %-45s %s\n" "$((i+1))" "${mark}" "${R_NAME[$i]}" "${URL_NULL:-${R_URL[$i]}}" "${R_DESC[$i]}"
    done
    echo
    read -r -p "请选择序号（空格分隔，直接回车=默认带 * 的）: " ans
    if [ -z "${ans}" ]; then
      for i in "${!R_NAME[@]}"; do [ "${R_DEF[$i]}" = "1" ] && SELECTED+=("${R_NAME[$i]}") || true; done
    else
      for k in ${ans}; do
        idx=$((k-1))
        if [ "${idx}" -ge 0 ] && [ "${idx}" -lt "${#R_NAME[@]}" ]; then
          SELECTED+=("${R_NAME[$idx]}")
        else
          echo "[WARN] 忽略无效序号: ${k}"
        fi
      done
    fi
  fi
fi

# 去重 + 校验
UNIQ=()
for r in "${SELECTED[@]:-}"; do
  [ -z "${r}" ] && continue
  valid_repo "${r}" || { echo "[ERROR] 仓库清单里没有: ${r}"; exit 1; }
  in_arr "${r}" "${UNIQ[@]:-}" || UNIQ+=("${r}")        # 去重：与已收集结果比较
done
SELECTED=()
for r in "${UNIQ[@]:-}"; do [ -n "${r}" ] && SELECTED+=("${r}"); done

if [ "${#SELECTED[@]}" -eq 0 ]; then
  echo "[ERROR] 至少要选一个仓库（通常选 uvm_base）"; exit 1
fi
if ! has_repo uvm_base; then
  echo "[WARN] 没有选 uvm_base —— 它是底座，确定要跳过吗？"
  read -r -p "继续? [y/N] " yn
  [ "${yn}" = "y" ] || exit 1
fi

#---------------------------------------------------------------- 建工程 ------
ROOT="${DIR}/${PROJ}"
[ -e "${ROOT}" ] && { echo "[ERROR] ${ROOT} 已存在"; exit 1; }

echo "[INFO] 工程     : ${ROOT}"
echo "[INFO] 挂载仓库 : ${SELECTED[*]}"
echo "[INFO] 模式     : ${MODE}"

mkdir -p "${ROOT}/src" "${ROOT}/tb" "${ROOT}/lib" "${ROOT}/sim" "${ROOT}/script"

render() {  # render <模板> <目标>
  mkdir -p "$(dirname "$2")"
  sed "s/@P@/${PROJ}/g" "$1" > "$2"
}

# 通用文件
render "${TPL_DIR}/gitignore.tpl"       "${ROOT}/.gitignore"
# 工程根目录 README
render "${TPL_DIR}/README.html.tpl"     "${ROOT}/README.html"

# src/ 为空目录：放 .gitkeep 便于 git 跟踪
cat > "${ROOT}/src/.gitkeep" <<'EOF'
# src/ 放你的被测设计(.sv / .v)，并在 ../sim/filelist.f 里登记（写 ../src/xxx.sv）
EOF
render "${TPL_DIR}/out_if.sv.tpl"       "${ROOT}/tb/${PROJ}_out_if.sv"

# 按是否挂了 dvp_vip 选择 pkg / top 模板
if has_repo dvp_vip; then
  render "${TPL_DIR}/pkg_dvp.sv.tpl"    "${ROOT}/tb/${PROJ}_pkg.sv"
  render "${TPL_DIR}/top_dvp.sv.tpl"    "${ROOT}/tb/${PROJ}_top.sv"
else
  render "${TPL_DIR}/pkg_base.sv.tpl"   "${ROOT}/tb/${PROJ}_pkg.sv"
  render "${TPL_DIR}/top_base.sv.tpl"   "${ROOT}/tb/${PROJ}_top.sv"
fi

# filelist.f = 头 + 各仓库 fragment + 工程文件
# 注意：filelist 放在 sim/ 下，make 也从 sim/ 目录运行，
#       因此这里的相对路径全部以 sim/ 为基准（../tb、../src、../lib ...）
{
  echo "# ${PROJ} 编译文件列表（位于 sim/ 下，路径以 sim/ 为基准）"
  echo "+incdir+../tb"
  echo "+incdir+../src"
  for r in "${SELECTED[@]}"; do
    if [ -f "${FRAG_DIR}/${r}.frag" ]; then
      echo ""
      echo "# ---- ${r} ----"
      cat "${FRAG_DIR}/${r}.frag"
    else
      echo "[WARN] 缺少 ${r} 的 filelist 片段: ${FRAG_DIR}/${r}.frag" >&2
    fi
  done
  echo ""
  echo "# ---- ${PROJ} ----"
  echo "../tb/${PROJ}_out_if.sv"
  echo "../tb/${PROJ}_pkg.sv"
  echo "../tb/${PROJ}_top.sv"
} > "${ROOT}/sim/filelist.f"

# Makefile：拼 MK 变量片段 / DEFS / PLUS
# mk_config.mk：各仓库的 Makefile 变量片段（多行，单独成文件由 Makefile include）
{
  echo "# 自动生成 by create_project.sh —— 挂载仓库: ${SELECTED[*]}"
  for r in "${SELECTED[@]}"; do
    [ -f "${FRAG_DIR}/${r}.mk" ] && { echo ""; echo "# ---- ${r} ----"; cat "${FRAG_DIR}/${r}.mk"; }
  done
} > "${ROOT}/sim/mk_config.mk"

DEFS=""; PLUS=""
for r in "${SELECTED[@]}"; do
  if [ -f "${FRAG_DIR}/${r}.flags" ]; then
    while IFS= read -r fl; do
      [ -z "${fl}" ] && continue
      case "${fl}" in
        DEFS+=*) DEFS="${DEFS} $(echo "${fl}" | sed 's/^DEFS+=\s*//')" ;;
        PLUS+=*) PLUS="${PLUS} $(echo "${fl}" | sed 's/^PLUS+=\s*//')" ;;
      esac
    done < "${FRAG_DIR}/${r}.flags"
  fi
done

sed -e "s/@P@/${PROJ}/g" \
    -e "s|@DEFS@|${DEFS}|" \
    -e "s|@PLUS@|${PLUS}|" \
    "${TPL_DIR}/Makefile.tpl" > "${ROOT}/sim/Makefile"

# script/：只建空目录（.gitkeep 便于 git 跟踪），内容全部由使用者自己写
cat > "${ROOT}/script/.gitkeep" <<'EOF'
# script/ 用于放本工程自己的脚本/工具（由使用者编写）
# 例如：regress.sh、cov.sh、wave.sh、gen_*.py ...
# 生成器不会往这里放任何东西。
EOF

#---------------------------------------------------------------- lib 依赖 ----
if [ "${MODE}" = "submodule" ]; then
  ( cd "${ROOT}" && git init -q -b main
    for i in "${!R_NAME[@]}"; do
      r="${R_NAME[$i]}"
      has_repo "${r}" || continue
      git -c protocol.file.allow=always submodule add "${R_URL[$i]}" "${R_PATH[$i]}"
    done )
  echo "[INFO] 已添加 submodule"
else
  for i in "${!R_NAME[@]}"; do
    r="${R_NAME[$i]}"
    has_repo "${r}" || continue
    ln -s "../../${r}" "${ROOT}/lib/${r}"
  done
  echo "[INFO] --local 模式：lib/ 下为软链（指向 ../../<仓库名>）"
fi

echo ""
echo "[DONE] ${ROOT}"
echo "       下一步: cd ${ROOT}/sim && make check"
echo "               script/ 为空目录，放你自己写的工具脚本"
