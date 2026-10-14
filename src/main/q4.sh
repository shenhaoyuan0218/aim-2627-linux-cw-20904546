#!/bin/bash
# Q4：合并日志，按级别提取，保存首尾片段并统计错误行数。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

cat "$input/boot.log" "$input/run.log" > "$output/all.log"

grep '^ERROR ' "$output/all.log" > "$output/errors.log" 2>/dev/null || true

grep -E '^(WARN |ERROR )' "$output/all.log" > "$output/attention.log" 2>/dev/null || true

tail -n 5 "$output/all.log" > "$output/recent.log"

grep '^ERROR ' "$output/all.log" 2>/dev/null | head -n 3 > "$output/first-errors.log" || true

error_count=$(grep -c '^ERROR ' "$output/all.log" 2>/dev/null || true)
if [ -z "$error_count" ]; then
  error_count=0
fi
printf '%s\n' "$error_count" > "$output/error-count.txt"
