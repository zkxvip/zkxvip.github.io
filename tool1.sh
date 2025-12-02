#!/bin/bash

# 隐藏光标并设置退出时恢复
tput civis
cleanup() {
    tput cnorm
    clear
}
trap cleanup EXIT

# 检测默认网络接口
NET_IFACE=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')
if [ -z "$NET_IFACE" ]; then
    NET_IFACE=$(ip addr show | awk '/state UP/ && !/lo/ {print $2; exit}' | sed 's/://')
fi

# 读取初始网络字节数
LINE=$(grep "$NET_IFACE:" /proc/net/dev | sed "s/.*://")
RX_PREV=$(echo "$LINE" | awk '{print $1}')
TX_PREV=$(echo "$LINE" | awk '{print $9}')

# ANSI颜色定义
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; RESET='\e[0m'

while true; do
    # 系统运行时间（天、小时、分钟）
    UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime)
    DAYS=$((UPTIME_SEC/86400))
    HOURS=$(( (UPTIME_SEC%86400)/3600 ))
    MINS=$(( (UPTIME_SEC%3600)/60 ))
    CUR_TIME=$(date "+%F %T")

    # 获取负载（1分钟平均），计算百分比
    LOAD1=$(cut -d ' ' -f1 /proc/loadavg)
    CPU_CORES=$(nproc)
    LOADPERCENT=$(printf "%.0f" "$(echo "$LOAD1 / $CPU_CORES * 100" | bc -l)")
    if [ "$LOADPERCENT" -lt 50 ]; then
        LOAD_COLOR=$GREEN
    elif [ "$LOADPERCENT" -lt 90 ]; then
        LOAD_COLOR=$YELLOW
    else
        LOAD_COLOR=$RED
    fi

    # 计算CPU总体和各核占用
    # 读取 /proc/stat (第一行cpu，总计各核)
    IFS=' ' read -r cpu user nice system idle iowait irq softirq steal < /proc/stat
    CPU_IDLE1=$((idle + iowait))
    CPU_TOTAL1=$((user + nice + system + idle + iowait + irq + softirq + steal))
    declare -a CPUS1 CPUS2
    n=0
    for line in $(grep '^cpu[0-9]' /proc/stat); do
        read -r label u n s id i iw ir si st < <(echo $line)
        CPUS1[$n]=$((u + n + s + iw + ir + si))
        CPUS1_TOTAL[$n]=$((u + n + s + id + iw + ir + si + st))
        ((n++))
    done

    sleep 1

    # 再次读取用于差值计算
    IFS=' ' read -r cpu user nice system idle iowait irq softirq steal < /proc/stat
    CPU_IDLE2=$((idle + iowait))
    CPU_TOTAL2=$((user + nice + system + idle + iowait + irq + softirq + steal))
    # 重新读取各核
    n=0
    for line in $(grep '^cpu[0-9]' /proc/stat); do
        read -r label u n s id i iw ir si st < <(echo $line)
        CPU_USED_CUR=$((u + n + s + ir + si))
        CPU_TOTAL_CUR=$((u + n + s + id + iw + ir + si + st))
        CPU_USED_PREV=${CPUS1[$n]}
        CPU_TOTAL_PREV=${CPUS1_TOTAL[$n]}
        # 计算核心利用率
        if [ $((CPU_TOTAL_CUR - CPU_TOTAL_PREV)) -ne 0 ]; then
            CPU_USAGE_N=$(printf "%.0f" "$(echo "($CPU_USED_CUR - $CPU_USED_PREV) * 100 / ($CPU_TOTAL_CUR - $CPU_TOTAL_PREV)" | bc -l)")
        else
            CPU_USAGE_N=0
        fi
        CPU_USAGE_CORES[$n]=$CPU_USAGE_N
        ((n++))
    done
    # 总体CPU使用率
    if [ $((CPU_TOTAL2 - CPU_TOTAL1)) -ne 0 ]; then
        CPU_USAGE_TOTAL=$(printf "%.0f" "$(echo "($CPU_TOTAL2 - CPU_TOTAL1 - ($CPU_IDLE2 - $CPU_IDLE1)) * 100 / ($CPU_TOTAL2 - $CPU_TOTAL1)" | bc -l)")
    else
        CPU_USAGE_TOTAL=0
    fi

    # 内存使用
    MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    MEM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
    MEM_PERCENT=$(printf "%.0f" "$(echo "$MEM_USED * 100 / $MEM_TOTAL" | bc -l)")

    # 磁盘使用 (根分区)
    DISK_INFO=$(df -h / | awk 'NR==2{print $2" "$3" "$4" "$5}')
    DISK_TOTAL=$(echo $DISK_INFO | awk '{print $1}')
    DISK_USED=$(echo $DISK_INFO | awk '{print $2}')
    DISK_AVAIL=$(echo $DISK_INFO | awk '{print $3}')
    DISK_PERCENT=$(echo $DISK_INFO | awk '{print $4}')

    # 网络速率计算
    LINE=$(grep "$NET_IFACE:" /proc/net/dev | sed "s/.*://")
    RX_CUR=$(echo "$LINE" | awk '{print $1}')
    TX_CUR=$(echo "$LINE" | awk '{print $9}')
    RX_RATE=$((RX_CUR - RX_PREV))
    TX_RATE=$((TX_CUR - TX_PREV))
    RX_PREV=$RX_CUR; TX_PREV=$TX_CUR
    # 自动转换单位
    function fmt_speed() {
        local bytes=$1; local speed unit
        if [ $bytes -lt 1024 ]; then
            speed=$bytes; unit="B/s"
        elif [ $bytes -lt $((1024*1024)) ]; then
            speed=$(printf "%.1f" "$(echo "$bytes/1024" | bc -l)"); unit="KB/s"
        else
            speed=$(printf "%.1f" "$(echo "$bytes/1048576" | bc -l)"); unit="MB/s"
        fi
        echo "$speed $unit"
    }
    RX_FMT=$(fmt_speed $RX_RATE)
    TX_FMT=$(fmt_speed $TX_RATE)

    # 绘制条形图函数（宽度20）
    draw_bar() {
        local percent=$1 width=20 filled=$((percent * width / 100))
        local empty=$((width - filled))
        printf "["
        printf "%0.s#" $(seq 1 $filled)
        printf "%0.s " $(seq 1 $empty)
        printf "]"
    }

    # 缓冲输出并清屏
    output=""
    output+="系统运行时间：${DAYS}天 ${HOURS}小时 ${MINS}分钟    当前时间：$CUR_TIME\n"
    output+="系统负载 (1m 平均)：${LOAD_COLOR}${LOADPERCENT}%${RESET}\n"
    output+="CPU 总占用： ${CPU_USAGE_TOTAL}% $(draw_bar $CPU_USAGE_TOTAL)\n"
    for i in "${!CPU_USAGE_CORES[@]}"; do
        output+=" CPU$i 占用： ${CPU_USAGE_CORES[$i]}% $(draw_bar ${CPU_USAGE_CORES[$i]})\n"
    done
    # 将 kB 转换为 GB/MB/KB
    MEM_TOT_H=$(printf "%.0f" "$(echo "$MEM_TOTAL/1024" | bc -l)")
    MEM_USED_H=$(printf "%.0f" "$(echo "$MEM_USED/1024" | bc -l)")
    MEM_AVAIL_H=$(printf "%.0f" "$(echo "$MEM_AVAIL/1024" | bc -l)")
    output+="内存使用： 总${MEM_TOT_H}MB 已用${MEM_USED_H}MB 可用${MEM_AVAIL_H}MB  占用${MEM_PERCENT}% $(draw_bar $MEM_PERCENT)\n"
    output+="磁盘(/)使用： 总${DISK_TOTAL} 已用${DISK_USED} 可用${DISK_AVAIL}  占用${DISK_PERCENT}\n"
    output+="网络($NET_IFACE)速率： 上行 ${TX_FMT}  下行 ${RX_FMT}\n"
    # 清屏并输出
    printf "\033[H\033[2J$output"
done
