# ================================
# 系统信息（静态版）
# ================================
system_info() {
    clear
    echo -e "${blue}=============== 系统信息 ===============${plain}"

    # 系统发行版
    local distro
    if command -v lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -d 2>/dev/null | awk -F':' '{print $2}' | xargs)
    else
        distro=$(awk -F= '/^PRETTY_NAME/{gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null)
    fi
    echo -e "系统： ${yellow}${distro}${plain}"
    echo -e "内核： ${yellow}$(uname -r)${plain}"

    # CPU 信息
    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | awk -F: '{print $2}' | xargs)
    echo -e "CPU 型号： ${yellow}${cpu_model}${plain}"
    echo -e "CPU 核心： ${yellow}$(nproc --all)${plain}"

    # CPU 主频（可选）
    if command -v lscpu >/dev/null 2>&1; then
        echo -e "CPU 主频： ${yellow}$(lscpu 2>/dev/null | awk -F: '/CPU MHz/{print $2}' | xargs) MHz${plain}"
    fi

    # MAC 地址
    local mac
    mac=$(cat /sys/class/net/*/address 2>/dev/null | grep -v '^00:00:00' | head -n1 || echo "未知")
    echo -e "MAC 地址： ${yellow}${mac}${plain}"

    # 公网 IP
    local ipv4 ipv6
    ipv4=$(curl -4 -s --connect-timeout 3 --max-time 5 ifconfig.me || echo "获取失败")
    ipv6=$(curl -6 -s --connect-timeout 3 --max-time 5 ifconfig.me || echo "获取失败")
    echo -e "公网 IPv4： ${yellow}${ipv4}${plain}"
    echo -e "公网 IPv6： ${yellow}${ipv6}${plain}"

    # 运行时间
    local uptime_sec days hours minutes
    uptime_sec=$(awk '{print int($1)}' /proc/uptime)
    days=$((uptime_sec/86400))
    hours=$(( (uptime_sec%86400)/3600 ))
    minutes=$(( (uptime_sec%3600)/60 ))
    echo -e "运行时间： ${yellow}${days} 天 ${hours} 小时 ${minutes} 分${plain}"

    # 内存占用
    local mem_total mem_used mem_free mem_used_pct
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_free=$((mem_total - mem_used))
    mem_used_pct=$(awk -v t="$mem_total" -v u="$mem_used" 'BEGIN{printf("%.0f", u*100/t)}')
    echo -e "内存占用： ${yellow}${mem_used_pct}%${plain} (${mem_used} MB/${mem_free} MB/${mem_total} MB)"

    # 硬盘占用（根分区）
    local total used avail percent
    read -r _ total used avail percent _ < <(df -m / | awk 'NR==2')
    echo -e "硬盘占用： ${yellow}${percent}${plain} (${used} MB/${avail} MB/${total} MB)"

    echo -e "${blue}========================================${plain}"
    read -p "按回车返回菜单..." temp
}
