#!/usr/bin/env bash

# ===========================
#  颜色设置
# ===========================
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
nc="\033[0m"

# ===========================
#  上一次网络字节数，用来计算上下行
# ===========================
get_net_bytes() {
    RX=$(cat /sys/class/net/$NET/dev | awk '/:/ {print $2}')
    TX=$(cat /sys/class/net/$NET/dev | awk '/:/ {print $10}')
}

calc_speed() {
    NOW_RX=$(cat /sys/class/net/$NET/dev | awk '/:/ {print $2}')
    NOW_TX=$(cat /sys/class/net/$NET/dev | awk '/:/ {print $10}')

    DOWN_RAW=$((NOW_RX - RX))
    UP_RAW=$((NOW_TX - TX))

    # KB/s
    DOWN_SPEED=$(echo "scale=1; $DOWN_RAW/1024" | bc)
    UP_SPEED=$(echo "scale=1; $UP_RAW/1024" | bc)

    RX=$NOW_RX
    TX=$NOW_TX
}

# 选择第一块有效网卡
NET=$(ls /sys/class/net | grep -v lo | head -n 1)
get_net_bytes

clear

# ===========================
#   固定的界面框架（不再刷新）
# ===========================
echo -e "${blue}============== 系统实时状态监控 ==============${nc}"
echo ""
echo -e " CPU 占用率（总）    : "
echo -e " CPU 各核心占用率    : "
echo -e " 内存使用情况        : "
echo -e " 硬盘使用情况        : "
echo -e " 服务器负载状态      : "
echo -e " 网络速度            : "
echo ""
echo -e "按 ${yellow}Q${nc} 退出"
echo ""

# ===========================
#   主循环 - 每秒刷新数据
# ===========================
while true; do
    # 检测按键 Q 退出
    read -rsn1 -t 0.1 key
    if [[ "$key" == "q" || "$key" == "Q" ]]; then
        echo -e "${yellow}已退出系统实时监控${nc}"
        exit 0
    fi

    # -------------------------
    # CPU 总占用
    # -------------------------
    CPU_TOTAL=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    CPU_TOTAL_INT=${CPU_TOTAL%.*}

    # -------------------------
    # CPU 各核心
    # -------------------------
    CPU_CORES=$(mpstat -P ALL 1 1 | awk '/Average/ && $2 ~ /[0-9]+/ {print 100 - $12"%"}' | xargs)

    # -------------------------
    # 内存
    # -------------------------
    mem_total=$(free -m | awk '/Mem/ {print $2}')
    mem_used=$(free -m | awk '/Mem/ {print $3}')
    mem_percent=$((100 * mem_used / mem_total))

    # -------------------------
    # 硬盘
    # -------------------------
    disk_total=$(df -m / | awk 'NR==2{print $2}')
    disk_used=$(df -m / | awk 'NR==2{print $3}')
    disk_percent=$((100 * disk_used / disk_total))

    # -------------------------
    # 负载（load average）
    # -------------------------
    load1=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | sed 's/ //g')
    cores=$(nproc)
    load_usage=$(echo "scale=0; ($load1 / $cores) * 100" | bc)

    # 设置颜色和提示
    if (( load_usage < 50 )); then
        load_color=$green
        load_msg="服务器负载较低，运行流畅"
    elif (( load_usage < 90 )); then
        load_color=$yellow
        load_msg="运行正常"
    else
        load_color=$red
        load_msg="警告：运行堵塞"
    fi

    # -------------------------
    # 网络上下行速度
    # -------------------------
    calc_speed

    # ===========================
    #    更新界面（只更新数据）
    # ===========================
    tput cup 2 28;   echo -e "${yellow}${CPU_TOTAL_INT}%${nc}"
    tput cup 3 28;   echo -e "${blue}${CPU_CORES}${nc}"
    tput cup 4 28;   echo -e "$mem_used MB / $mem_total MB (${mem_percent}%)"
    tput cup 5 28;   echo -e "$disk_used MB / $disk_total MB (${disk_percent}%)"
    tput cup 6 28;   echo -e "${load_color}${load_msg}${nc}"
    tput cup 7 28;   echo -e "↓ ${DOWN_SPEED} KB/s   ↑ ${UP_SPEED} KB/s"

    sleep 1
done
