#!/bin/bash

# 设置 trap 处理 Ctrl+C，恢复光标和屏幕
trap "tput cnorm; tput rmcup; clear; exit" INT

# 隐藏光标，并切换到替换缓冲区
tput civis
tput smcup

# 获取 CPU 核心数
cpu_cores=$(nproc)

# 初始读取 CPU 统计数据
readarray -t prev_stats < <(awk '/^cpu /{flag=1}/^intr/{flag=0}flag' /proc/stat)
sleep 1

while true; do
    # 读取新的 CPU 统计数据
    readarray -t cur_stats < <(awk '/^cpu /{flag=1}/^intr/{flag=0}flag' /proc/stat)

    # 计算 CPU 总占用率和各核占用率
    cpu_usage_total=0
    declare -a cpu_usage_core
    for i in "${!cur_stats[@]}"; do
        prev=(${prev_stats[i]})
        cur=(${cur_stats[i]})
        prev_idle=$((prev[4] + prev[5]))
        cur_idle=$((cur[4] + cur[5]))
        prev_total=0; cur_total=0
        for j in {1..7}; do
            prev_total=$((prev_total + prev[j]))
            cur_total=$((cur_total + cur[j]))
        done
        total_diff=$((cur_total - prev_total))
        idle_diff=$((cur_idle - prev_idle))
        if [ $total_diff -eq 0 ]; then
            usage=0
        else
            usage=$(( (100 * (total_diff - idle_diff) / total_diff) ))
        fi
        if [ $i -eq 0 ]; then
            cpu_usage_total=$usage
        else
            cpu_usage_core[$((i-1))]=$usage
        fi
    done

    # 计算系统运行时间（天）和当前时间
    uptime_sec=$(awk '{print int($1)}' /proc/uptime)
    days=$((uptime_sec/86400))
    current_time=$(date "+%H:%M:%S")
    printf "运行时间: %d 天  当前时间: %s\n" "$days" "$current_time"

    # 输出负载百分比并设定颜色 (<50% 绿, 50-90% 黄, >90% 红)
    if (( cpu_usage_total < 50 )); then
        color=$(tput setaf 2)  # 绿色
        status="低"
    elif (( cpu_usage_total < 90 )); then
        color=$(tput setaf 3)  # 黄色
        status="正常"
    else
        color=$(tput setaf 1)  # 红色
        status="过高"
    fi
    reset=$(tput sgr0)
    printf "负载百分比: %s%3d%%%s (负载%s)\n" "$color" "$cpu_usage_total" "$reset" "$status"

    # 输出 CPU 总占用率的柱状图
    bar_width=30
    used_chars=$(( cpu_usage_total * bar_width / 100 ))
    printf "CPU 总: ["
    for ((i=0; i<used_chars; i++)); do printf "#"; done
    for ((i=used_chars; i<bar_width; i++)); do printf " "; done
    printf "] %3d%%\n" "$cpu_usage_total"

    # 输出每个核心的占用率柱状图
    for ((i=0; i<cpu_cores; i++)); do
        usage=${cpu_usage_core[i]}
        used_chars=$(( usage * bar_width / 100 ))
        printf "  核心%2d: [" "$i"
        for ((j=0; j<used_chars; j++)); do printf "#"; done
        for ((j=used_chars; j<bar_width; j++)); do printf " "; done
        printf "] %3d%%\n" "$usage"
    done

    # 计算内存使用情况 (使用 MemAvailable 计算真实已用)
    mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    mem_avail=$(awk '/^MemAvailable/ {print $2}' /proc/meminfo)
    mem_used=$((mem_total - mem_avail))
    mem_percent=$((100 * mem_used / mem_total))
    mem_total_mb=$((mem_total/1024))
    mem_used_mb=$((mem_used/1024))
    used_chars=$(( mem_percent * bar_width / 100 ))
    printf "内存:   ["
    for ((i=0; i<used_chars; i++)); do printf "#"; done
    for ((i=used_chars; i<bar_width; i++)); do printf " "; done
    printf "] %3d%%  (%dMB/%dMB)\n" "$mem_percent" "$mem_used_mb" "$mem_total_mb"

    # 计算根分区硬盘使用情况
    disk=$(df -h / | sed -n '2p')
    disk_total=$(echo "$disk" | awk '{print $2}')
    disk_used=$(echo "$disk" | awk '{print $3}')
    disk_avail=$(echo "$disk" | awk '{print $4}')
    disk_percent=$(echo "$disk" | awk '{print $5}')
    printf "硬盘:   总计 %s  已用 %s  可用 %s  (%s)\n" "$disk_total" "$disk_used" "$disk_avail" "$disk_percent"

    # 读取网络接口收发字节总数 (跳过 lo)，计算上下行速率
    rx=0; tx=0
    while read -r line; do
        IFS=':' read -r iface data <<< "$line"
        if [[ -n "$data" ]]; then
            read -r bytes_rx _ _ _ _ _ _ _ bytes_tx <<< "$data"
            rx=$((rx + bytes_rx))
            tx=$((tx + bytes_tx))
        fi
    done <<< "$(grep -vE '^ *lo:' /proc/net/dev)"
    if [[ -z "$last_rx" ]]; then
        last_rx=$rx; last_tx=$tx
    fi
    rx_rate=$((rx - last_rx))
    tx_rate=$((tx - last_tx))
    last_rx=$rx; last_tx=$tx
    format_rate() {
        local rate=$1
        if (( rate >= 1048576 )); then
            echo "$(awk "BEGIN {printf \"%.1f\", $rate/1048576}") MB/s"
        elif (( rate >= 1024 )); then
            echo "$(awk "BEGIN {printf \"%.1f\", $rate/1024}") KB/s"
        else
            echo "${rate} B/s"
        fi
    }
    down_str=$(format_rate "$rx_rate")
    up_str=$(format_rate "$tx_rate")
    printf "网络:   下行 %s  上行 %s\n" "$down_str" "$up_str"

    # 更新之前的 CPU 统计数据，用于下一轮计算
    prev_stats=("${cur_stats[@]}")

    sleep 1
done
