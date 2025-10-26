#!/usr/bin/env bash
set -euo pipefail

# -------- 基本配置 --------
BUILD_TYPE="debug"  # 或 release
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
UNITTEST_BIN="$ROOT_DIR/build/${BUILD_TYPE}/test/unittest"

# 测试目录（静态定义，可按需增删）
TEST_DIRS=(
  "test/sql/index"
  "test/sql/scans"
  "test/sql/where"
  "test/sql/bitmap"
)

# 日志目录与文件
LOG_ROOT="$ROOT_DIR/smoke_logs"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_ROOT"
LOG_FILE="$LOG_ROOT/smoke_${RUN_ID}.log"
SUMMARY_FILE="$LOG_ROOT/summary_${RUN_ID}.txt"

# -------- 打印环境信息 --------
echo "=============================================" | tee "$LOG_FILE"
echo "  DuckDB MVP Sequential Smoke Test Runner"    | tee -a "$LOG_FILE"
echo "---------------------------------------------" | tee -a "$LOG_FILE"
echo " Build Type : $BUILD_TYPE"                    | tee -a "$LOG_FILE"
echo " Run ID     : $RUN_ID"                        | tee -a "$LOG_FILE"
echo " Log File   : $LOG_FILE"                      | tee -a "$LOG_FILE"
echo "---------------------------------------------" | tee -a "$LOG_FILE"
date "+ Start Time : %Y-%m-%d %H:%M:%S"            | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"

# -------- 校验测试可执行文件 --------
if [[ ! -x "$UNITTEST_BIN" ]]; then
  echo "[ERR] unittest binary not found: $UNITTEST_BIN" | tee -a "$LOG_FILE"
  echo "      Please build DuckDB first." | tee -a "$LOG_FILE"
  exit 1
fi

# -------- 顺序运行每个目录 --------
total=0
passed=0
failed=0

for dir in "${TEST_DIRS[@]}"; do
  if [[ -d "$ROOT_DIR/$dir" ]]; then
    echo "" | tee -a "$LOG_FILE"
    echo ">>> Running tests in [$dir]" | tee -a "$LOG_FILE"
    echo "---------------------------------------------" | tee -a "$LOG_FILE"

    # 执行并捕获退出码
    if "$UNITTEST_BIN" "[${dir##*/}]" >>"$LOG_FILE" 2>&1; then
      echo "[PASS] $dir" | tee -a "$LOG_FILE"
      ((passed++))
    else
      echo "[FAIL] $dir" | tee -a "$LOG_FILE"
      ((failed++))
    fi
    ((total++))
  else
    echo "[SKIP] $dir (not found)" | tee -a "$LOG_FILE"
  fi
done

# -------- 汇总 --------
echo "" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"
echo "             SMOKE TEST SUMMARY              " | tee -a "$LOG_FILE"
echo "---------------------------------------------" | tee -a "$LOG_FILE"
echo " Total  : $total" | tee -a "$LOG_FILE"
echo " Passed : $passed" | tee -a "$LOG_FILE"
echo " Failed : $failed" | tee -a "$LOG_FILE"
date "+ End Time : %Y-%m-%d %H:%M:%S" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"

# 输出简版汇总（供CI用）
{
  echo "Run ID: $RUN_ID"
  echo "Total: $total"
  echo "Passed: $passed"
  echo "Failed: $failed"
  echo "Log File: $LOG_FILE"
} > "$SUMMARY_FILE"

# -------- 退出码 --------
if [[ "$failed" -gt 0 ]]; then
  echo "[SUMMARY] Some tests failed. See $LOG_FILE"
  exit 1
else
  echo "[SUMMARY] All smoke tests passed!"
  exit 0
fi
