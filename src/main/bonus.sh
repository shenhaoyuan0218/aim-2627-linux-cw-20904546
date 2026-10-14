#!/bin/bash
# Bonus：start 时创建分离的 tmux 会话和采集器；stop 时正常停止采集器并结束会话。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-start}

source "$input/bonus.env"

if [ "$action" = "start" ]; then
   
    tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" \
        "python3 \"$WORKER_TOOL\" --token \"$TOKEN\" --log \"$output/bonus.log\""

elif [ "$action" = "stop" ]; then
    
    pid=""
    if [ -f "$output/bonus.log" ]; then
        pid=$(grep "^START $TOKEN pid=" "$output/bonus.log" | tail -1 | sed 's/.*pid=//')
    fi

    if [ -n "$pid" ]; then
        kill "$pid" 2>/dev/null || true
        for _ in $(seq 1 20); do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done
    fi

    tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION" 2>/dev/null || true
fi
