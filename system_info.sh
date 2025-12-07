# 文件名：system_info.sh
# 包含：所有用于获取 CPU、内存、磁盘、负载等系统硬件和操作系统信息的辅助函数及主显示函数 system_info_func。
# 依赖：tool.sh 中的颜色变量

# -------------------
# CPU 辅助函数
# -------------------
read_cpu_stat_line() {
    awk -v line="$1" '$1==line {print $2,$3,$4,$5,$6,$7,$8,$9}' /proc/stat
}

get_cpu_total_usage() {
    read -r u1 n1 s1 i1 w1 irq1 soft1 steal1 <<< "$(read_cpu_stat_line cpu)"
    total1=$((u1 + n1 + s1 + i1 + w1 + irq1 + soft1 + steal1))
    idle1=$((i1 + w1))
    sleep 0.5
    read -r u2 n2 s2 i2 w2 irq2 soft2 steal2 <<< "$(read_cpu_stat_line cpu)"
    total2=$((u2 + n2 + s2 + i2 + w2 + irq2 + soft2 + steal2))
    idle2=$((i2 + w2))

    diff_total=$((total2 - total1))
    diff_idle=$((idle2 - idle1))
    if (( diff_total > 0 )); then
        usage=$(( ( (diff_total - diff_idle) * 1000 / diff_total + 5 ) / 10 ))
    else
        usage=0
    fi
    echo "$usage"
}

get_cpu_cores_usage() {
    local cores
    cores=$(grep -c '^cpu[0-9]' /proc/stat)
    local -a t1 idle1_arr
    for ((i=0;i<cores;i++)); do
        read -r u n s id w irq soft steal <<< "$(read_cpu_stat_line cpu$i)"
        t1[$i]=$((u + n + s + id + w + irq + soft + steal))
        idle1_arr[$i]=$((id + w))
    done

    sleep 0.5

    local -a t2 idle2_arr res
    for ((i=0;i<cores;i++)); do
        read -r u n s id w irq soft steal <<< "$(read_cpu_stat_line cpu$i)"
        t2[$i]=$((u + n + s + id + w + irq + soft + steal))
        idle2_arr[$i]=$((id + w))

        dt=$((t2[i] - t1[i]))
        di=$((idle2_arr[i] - idle1_arr[i]))
        if (( dt > 0 )); then
            res[$i]=$(( ( (dt - di) * 1000 / dt + 5)/10 ))
        else
            res[$i]=0
        fi
    done
    echo "${res[@]}"
}

# -------------------
# 辅助函数（通用性）
# -------------------
get_load_percentage_and_msg() {
    local load1 load5 load15 cores pct msg color
    
    if command -v uptime >/dev/null 2>&1; then
        load_raw=$(uptime | awk -F'load average:' '{print $2}' | sed 's/ //g')
    else
        load_raw=$(cat /proc/loadavg | awk '{print $1",", $2",", $3}')
    fi
    
    load1=$(echo "$load_raw" | cut -d',' -f1 | xargs)
    load5=$(echo "$load_raw" | cut -d',' -f2 | xargs)
    load15=$(echo "$load_raw" | cut -d',' -f3 | xargs)

    cores=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)
    
    pct=$(awk -v l="$load1" -v c="$cores" 'BEGIN{ if(c>0) printf("%.0f", (l/c)*100); else print 0 }')
    
    if (( pct < 50 )); then
        color="$green"
        msg="运行流畅"
    elif (( pct < 90 )); then
        color="$yellow"
        msg="运行正常"
    else
        color="$red"
        msg="警告：运行堵塞"
    fi
    echo "$pct" "$color" "$msg" "$load1" "$load5" "$load15"
}

get_net_connections() {
    local tcp_count=0
    local udp_count=0
    
    if [[ -f "/proc/net/tcp" ]]; then
        tcp_count=$(($(wc -l < /proc/net/tcp) - 1))
    fi
    
    if [[ -f "/proc/net/udp" ]]; then
        udp_count=$(($(wc -l < /proc/net/udp) - 1))
    fi
    
    if (( tcp_count <= 0 && udp_count <= 0 )); then
        if command -v ss >/dev/null 2>&1; then
            tcp_count=$(ss -t | wc -l)
            udp_count=$(ss -u | wc -l)
            tcp_count=$((tcp_count > 0 ? tcp_count - 1 : 0))
            udp_count=$((udp_count > 0 ? udp_count - 1 : 0))
        elif command -v netstat >/dev/null 2>&1; then
            tcp_count=$(netstat -atn 2>/dev/null | grep -c 'ESTABLISHED\|LISTEN')
            udp_count=$(netstat -aun 2>/dev/null | grep -c 'udp')
        else
            echo "未知 (需 /proc/net/ 或 ss/netstat)"
            return
        fi
    fi

    echo "$tcp_count TCP, $udp_count UDP"
}

get_cpu_freq() {
    local freq
    freq_mhz=$(grep -m1 'cpu MHz' /proc/cpuinfo 2>/dev/null | awk '{print $4}')
    if [[ -n "$freq_mhz" ]]; then
        freq=$(awk -v f="$freq_mhz" 'BEGIN{printf "%.2fGHz", f/1000}')
    fi
    if [[ -z "$freq" ]] && [[ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq" ]]; then
        freq_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
        freq=$(awk -v f="$freq_khz" 'BEGIN{printf "%.2fGHz", f/1000/1000}')
    fi
    echo "${freq:-未知}"
}

get_dns_servers() {
    dns=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null | grep -v '^#' | paste -sd, -)
    echo "${dns:-未知}"
}

get_net_algo() {
    if [[ -f "/proc/sys/net/ipv4/tcp_congestion_control" ]]; then
        algo=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
    elif command -v sysctl >/dev/null 2>&1; then
        algo=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
    fi
    echo "${algo:-未知}"
}

get_primary_mac() {
    iface=$(get_primary_net_iface) # 依赖于 net_test.sh 中的 get_primary_net_iface
    if [[ -n "$iface" ]]; then
        cat /sys/class/net/"$iface"/address 2>/dev/null || echo "未知"
    else
        echo "未知"
    fi
}

# -------------------
# 主函数
# -------------------
system_info_func() {
    clear
    echo -e "${blue}=============== 1. 系统信息（增强版） ===============${plain}"

    # OS
    local distro
    if command -v lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -d 2>/dev/null | awk -F':' '{print $2}' | xargs)
    else
        distro=$(awk -F= '/^PRETTY_NAME/ {gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null || cat /etc/os-release 2>/dev/null | head -n1)
    fi
    echo -e "主机名称： ${yellow}$(hostname)${plain}"
    echo -e "系统版本： ${yellow}${distro:-未知}${plain}"
    echo -e "内核信息： ${yellow}$(uname -r)${plain}"

    # CPU
    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | awk -F: '{print $2}' | xargs)
    echo -e "CPU 型号： ${yellow}${cpu_model:-未知}${plain}"
    cpu_cores=$(nproc --all 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null)
    echo -e "CPU 核心： ${yellow}${cpu_cores:-未知}${plain}"
    echo -e "CPU 频率： ${yellow}$(get_cpu_freq)${plain}"

    # CPU 使用
    cpu_total=$(get_cpu_total_usage)
    echo -e "CPU 总占： ${yellow}${cpu_total}%${plain}"
    cpu_cores_usage=($(get_cpu_cores_usage))
    printf "CPU 各核： "
    for i in "${!cpu_cores_usage[@]}"; do
        printf "[核%s: %b%s%%%b]  " "$i" "$yellow" "${cpu_cores_usage[$i]}" "$plain"
    done
    printf "\n"

    # MAC
    echo -e "MAC 地址： ${yellow}$(get_primary_mac)${plain}"

    # 负载状态
    read -r load_pct load_color load_msg load1 load5 load15 <<< "$(get_load_percentage_and_msg)"
    echo -e "负载状态： ${load_pct}% [${load1}, ${load5}, ${load15}] （${load_color}${load_msg}${plain}）"

    # TCP/UDP 连接数
    echo -e "TCP|UDP连接数： ${yellow}$(get_net_connections)${plain}"

    # 内存
    mem_total=0; mem_used=0; mem_avail=0
    if command -v free >/dev/null 2>&1; then
        read -r _ m_total m_used m_free m_shared m_cache m_avail <<< "$(free -m | awk 'NR==2')"
        mem_total=${m_total:-0}
        mem_avail=${m_avail:-0}
        if [[ "$mem_avail" -le 0 ]] && [[ -n "$m_free" ]] && [[ -n "$m_cache" ]]; then
            mem_avail=$((m_free + m_cache))
        fi
        mem_used=$((mem_total - mem_avail))
        swap_total=$(free -m 2>/dev/null | awk '/Swap:/ {print $2}')
        swap_used=$(free -m 2>/dev/null | awk '/Swap:/ {print $3}')
        swap_avail=$((swap_total - swap_used))
    elif [[ -f "/proc/meminfo" ]]; then
        mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_free_kb=$(grep MemFree /proc/meminfo | awk '{print $2}')
        mem_buffer_kb=$(grep Buffers /proc/meminfo | awk '{print $2}')
        mem_cached_kb=$(grep Cached /proc/meminfo | awk '{print $2}')
        mem_avail_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        mem_total=$((mem_total_kb / 1024))
        if [[ -n "$mem_avail_kb" ]]; then
            mem_avail=$((mem_avail_kb / 1024))
        else
            mem_avail=$(((mem_free_kb + mem_buffer_kb + mem_cached_kb) / 1024))
        fi
        mem_used=$((mem_total - mem_avail))
        swap_total=0; swap_used=0; swap_avail=0
    fi

    mem_pct=0
    if (( mem_total > 0 )); then
        mem_pct=$(awk -v t="$mem_total" -v u="$mem_used" 'BEGIN{printf("%.0f", u*100/t)}')
    fi
    echo -e "物理内存： ${yellow}${mem_pct}%${plain} (使用:${mem_used} MB/空闲:${mem_avail} MB/总量:${mem_total} MB)"
    
    swap_pct=0
    if (( swap_total > 0 )); then
        swap_pct=$(awk -v t="$swap_total" -v u="$swap_used" 'BEGIN{printf("%.0f", u*100/t)}')
    fi
    echo -e "虚拟内存： ${yellow}${swap_pct}%${plain} (使用:${swap_used} MB/空闲:${swap_avail} MB/总量:${swap_total} MB)"

    # 磁盘（根分区）
    root_dev=$(awk '$2=="/" {print $1; exit}' /proc/mounts 2>/dev/null)
    if [[ -n "$root_dev" ]]; then
        read -r _ d_total d_used d_avail d_percent _ < <(df -m "$root_dev" 2>/dev/null | awk 'NR==2')
    else
        read -r _ d_total d_used d_avail d_percent _ < <(df -m / 2>/dev/null | awk 'NR==2')
    fi
    d_total=${d_total:-0}; d_used=${d_used:-0}; d_avail=${d_avail:-0}; d_percent=${d_percent:-0%}
    echo -e "硬盘占用： ${yellow}${d_percent}${plain} (使用:${d_used} MB/空闲:${d_avail} MB/总量:${d_total} MB)"

    # 网络信息 (依赖 net_test.sh 函数)
    IFS=$'\t' read -r total_down total_up <<< "$(get_net_total_traffic)"
    echo -e "总 接 收： ${yellow}${total_down}${plain}  总发送： ${yellow}${total_up}${plain}"

    IFS=$'\t' read -r down_speed up_speed <<< "$(get_net_speed)"
    echo -e "网络速度： 下行：↓ ${yellow}${down_speed}${plain}    上行：↑ ${yellow}${up_speed}${plain}"
    
    echo -e "网络算法： ${yellow}$(get_net_algo)${plain}"
    echo -e "DNS 地址： ${yellow}$(get_dns_servers)${plain}"

    location_isp=$(get_ip_location)
    if [[ "$location_isp" == *"("* ]]; then
        isp=$(echo "$location_isp" | cut -d '(' -f1 | xargs)
        geo=$(echo "$location_isp" | cut -d '(' -f2 | cut -d ')' -f1 | xargs)
    else
        isp="未知"
        geo="$location_isp"
    fi
    echo -e "运 营 商： ${yellow}${isp}${plain}"
    echo -e "地理位置： ${yellow}${geo}${plain}"

    # 系统时间 & Uptime & IP
    echo -e "系统时间： ${yellow}$(date "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "未知")${plain}"
    echo -e "公网IPv4： ${yellow}$(get_pub_ip4)${plain}"
    echo -e "公网IPv6： ${yellow}$(get_pub_ip6)${plain}"

    uptime_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
    if [[ -n "$uptime_sec" ]]; then
        days=$(( uptime_sec/86400 ))
        hours=$(( (uptime_sec%86400)/3600 ))
        minutes=$(( (uptime_sec%3600)/60 ))
        uptime_str="${days} 天 ${hours} 小时 ${minutes} 分"
    else
        uptime_str="未知"
    fi
    echo -e "运行时间： ${yellow}${uptime_str}${plain}"

    echo -e "${blue}========================================${plain}"
    IFS=' '
    read -p "按回车返回菜单..." temp
}
