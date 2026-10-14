#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

source "$input/process.env"

if [ "$action" = "repair" ]; then
    
    ps_line=$(ps -o pid=,user=,stat=,command= -p "$TARGET_PID")
    ps_pid=$(echo "$ps_line" | awk '{print $1}')
    ps_user=$(echo "$ps_line" | awk '{print $2}')
    ps_state=$(echo "$ps_line" | awk '{print $3}')
    ps_command=$(echo "$ps_line" | cut -d' ' -f4-)
    cat > "$output/process.txt" <<EOF
pid=$ps_pid
user=$ps_user
state=$ps_state
command=$ps_command
EOF

    
    grep '^TICK' "$WORKER_LOG" 2>/dev/null | head -5 > "$output/collector-sample.log" || true

                   
    kill "$TARGET_PID" 2>/dev/null || true
    for _ in $(seq 1 20); do
        if ! kill -0 "$TARGET_PID" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done

   
    kill "$SERVICE_PID" 2>/dev/null || true
    for _ in $(seq 1 20); do
        if ! kill -0 "$SERVICE_PID" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done

   
    cat > "$output/server.conf" <<EOF
bind=127.0.0.1
port=$TARGET_PORT
route=/status
EOF

   
    bash "$START_TOOL" "$output/server.conf" "$output/service"

    
    http_status=""
    http_body=""
    for _ in $(seq 1 20); do
        http_status=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$TARGET_PORT/status" 2>/dev/null || true)
        if [ "$http_status" = "200" ]; then
            http_body=$(curl -s "http://127.0.0.1:$TARGET_PORT/status" 2>/dev/null || true)
            break
        fi
        sleep 0.1
    done

    printf '%s\n' "$http_status" > "$output/http-status.txt"
    printf '%s\n' "${http_body%$'\n'}" > "$output/http-body.txt"


elif [ "$action" = "cleanup" ]; then
    
    svc_pid_file="$output/service/pid"
    if [ -f "$svc_pid_file" ]; then
        svc_pid=$(cat "$svc_pid_file")
        if [ -n "$svc_pid" ] && kill -0 "$svc_pid" 2>/dev/null; then
            kill "$svc_pid" 2>/dev/null || true
            for _ in $(seq 1 20); do
                if ! kill -0 "$svc_pid" 2>/dev/null; then
                    break
                fi
                sleep 0.1
            done
        fi
    fi
fi
