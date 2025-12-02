#!/usr/bin/env bash
# =====================================================
# Linux 多功能工具箱 — 完整优化版 1.5
# 包含：系统信息（强化）、顺序 IP 测试、脚本更新等
# =====================================================

SCRIPT_VERSION="1.5.0"
SCRIPT_URL="http://your-ip-or-domain/tool.sh"   # 更新脚本使用，请改成你的地址

# -------------------
# 颜色
# -------------------
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[36m"
plain="\033[0m"

# -------------------
# 检测包管理器（apt / dnf / yum）
# -------------------
detect_pkg_mgr() {
    if command -v apt >/dev/null 2>&1; then
        PKG="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG="yum"
    else
        PKG=""
    fi
}
detect_pkg_mgr

# -------------------
# 工具可用性 helpers
# -------------------
ensure_cmd() {
    # 不自动安装，返回 0 表示存在
    command -v "$1" >/dev/null 2>&1
}

# -------------------
# CPU 使用率（总 & 各核） — 标准算法
# 读取 /proc/stat 两次计算 diff
# -------------------
read_cpu_stat_line() {
    # 参数: line (e.g. "cpu" or "cpu0")
    awk -v line="$1" '$1==line {print $2,$3,$4,$5,$6,$7,$8,$9}' /proc/stat
}

get_cpu_total_usage() {
    # 返回整数百分比（0-100）
    read -r u1 n1 s1 i1 w1 irq1 soft1 steal1 <<< "$(read_cpu_stat_line cpu)"
    total1=$((u1 + n1 + s1 + i1 + w1 + irq1 + soft1 + steal1))
    idle1=$((i1 + w1))
    # 短暂停
    sleep 0.5
    read -r u2 n2 s2 i2 w2 irq2 soft2 steal2 <<< "$(read_cpu_stat_line cpu)"
    total2=$((u2 + n2 + s2 + i2 + w2 + irq2 + soft2 + steal2))
    idle2=$((i2 + w2))

    diff_total=$((total2 - total1))
    diff_idle=$((idle2 - idle1))
    if (( diff_total > 0 )); then
        # 乘以 1000 再四舍五入到整数
        usage=$(( ( (diff_total - diff_idle) * 1000 / diff_total + 5 ) / 10 ))
    else
        usage=0
    fi
    echo "$usage"
}

get_cpu_cores_usage() {
    # 返回所有核占用数组，以空格分隔（整数百分比）
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

    # 输出空格分隔的占用
    echo "${res[@]}"
}

# -------------------
# 网络速度 — 采样 1 秒，自动单位换算（B/KB/MB/GB）
# 使用明确分隔符（tab）返回，避免 read 按空格拆分单位
# -------------------
format_speed_unit() {
    # 输入 bytes_per_sec，输出 "X.Y UNIT"
    local bytes=$1
    # handle negative (shouldn't happen)
    if (( bytes < 0 )); then bytes=0; fi

    if (( bytes < 1024 )); then
        val=$(awk -v b="$bytes" 'BEGIN{printf("%.1f", b)}')
        unit="B/s"
    elif (( bytes < 1024*1024 )); then
        val=$(awk -v b="$bytes" 'BEGIN{printf("%.1f", b/1024)}')
        unit="KB/s"
    elif (( bytes < 1024*1024*1024 )); then
        val=$(awk -v b="$bytes" 'BEGIN{printf("%.1f", b/1024/1024)}')
        unit="MB/s"
    else
        val=$(awk -v b="$bytes" 'BEGIN{printf("%.1f", b/1024/1024/1024)}')
        unit="GB/s"
    fi
    # 补 .7 -> 0.7
    [[ "$val" == .* ]] && val="0$val"
    echo "$val $unit"
}

get_primary_net_iface() {
    # 选第一个 UP 且不是 lo 的接口
    iface=$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -v '^lo$' | head -n1)
    # fallback to first non-lo
    if [[ -z "$iface" ]]; then
        iface=$(ls /sys/class/net | grep -v lo | head -n1 2>/dev/null || echo "")
    fi
    echo "$iface"
}

get_net_speed() {
    local iface
    iface=$(get_primary_net_iface)
    if [[ -z "$iface" ]]; then
        # 使用 tab 分隔下/上行，保证读取时不会被空格拆开
        printf '%s\t%s' "0.0 KB/s" "0.0 KB/s"
        return
    fi

    local rx1 tx1 rx2 tx2 bytes_down bytes_up down up
    rx1=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
    tx1=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)
    sleep 1
    rx2=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
    tx2=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)

    bytes_down=$((rx2 - rx1))
    bytes_up=$((tx2 - tx1))
    # bytes per second -> 格式化为带单位字符串
    down=$(format_speed_unit "$bytes_down")
    up=$(format_speed_unit "$bytes_up")
    # 用 tab 分隔，外部读取时用 IFS=$'\t' 保证完整性
    printf '%s\t%s' "$down" "$up"
}

# -------------------
# 公网 IP（优先 ipify，带超时回退）
# -------------------
get_pub_ip4() {
    ip=$(curl -4 -s --connect-timeout 3 --max-time 5 https://api.ipify.org || echo "")
    [[ -z "$ip" ]] && ip=$(curl -4 -s --connect-timeout 3 --max-time 5 https://ifconfig.me || echo "获取失败")
    echo "${ip:-获取失败}"
}
get_pub_ip6() {
    ip=$(curl -6 -s --connect-timeout 3 --max-time 5 https://api64.ipify.org || echo "")
    [[ -z "$ip" ]] && ip="获取失败"
    echo "$ip"
}

# -------------------
# MAC 地址：取第一个 UP 的接口
# -------------------
get_primary_mac() {
    iface=$(get_primary_net_iface)
    if [[ -n "$iface" ]]; then
        cat /sys/class/net/"$iface"/address 2>/dev/null || echo "未知"
    else
        echo "未知"
    fi
}

# -------------------
# 负载状态（基于 1-min load / cores）
# -------------------
get_load_percentage_and_msg() {
    local load1 cores pct msg color
    load1=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | sed 's/ //g')
    cores=$(nproc)
    # using awk for float math and rounding
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
    echo "$pct" "$color" "$msg"
}

# -------------------
# 获取 DNS 解析（优先 getent，fallback dig/host）
# -------------------
resolve_first_ipv4() {
    local domain="$1"
    local ip
    if command -v getent >/dev/null 2>&1; then
        ip=$(getent ahostsv4 "$domain" | awk '{print $1; exit}')
    fi
    if [[ -z "$ip" && -n "$(command -v dig 2>/dev/null)" ]]; then
        ip=$(dig +short A "$domain" | grep -E '^[0-9.]+' | head -n1)
    fi
    if [[ -z "$ip" && -n "$(command -v host 2>/dev/null)" ]]; then
        ip=$(host -4 "$domain" 2>/dev/null | awk '/has address/ {print $4; exit}')
    fi
    echo "${ip:-}"
}

# -------------------
# 获取 HTTP/HTTPS 状态码（更稳健）
# -------------------
get_http_status() {
    local url="$1"
    # 使用 curl -s -o /dev/null -w "%{http_code}"
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 --max-time 8 "$url" 2>/dev/null || echo "")
    echo "${status:-}"
}

# -------------------
# 系统信息（增强版 v1.5）
# -------------------
system_info() {
    clear
    # 标题使用 -e 以便颜色生效
    echo -e "${blue}=============== 系统信息（增强版 v1.5） ===============${plain}"

    # OS
    local distro
    if command -v lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -d 2>/dev/null | awk -F':' '{print $2}' | xargs)
    else
        distro=$(awk -F= '/^PRETTY_NAME/ {gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null || cat /etc/os-release | head -n1)
    fi
    echo -e "操作系统： ${yellow}${distro}${plain}"
    echo -e "内核信息： ${yellow}$(uname -r)${plain}"

    # CPU
    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | awk -F: '{print $2}' | xargs)
    echo -e "CPU 型号： ${yellow}${cpu_model}${plain}"
    echo -e "CPU 核心： ${yellow}$(nproc --all)${plain}"

    # CPU 使用
    cpu_total=$(get_cpu_total_usage)
    echo -e "CPU 总占： ${yellow}${cpu_total}%${plain}"
    # 各核
    cpu_cores_usage=($(get_cpu_cores_usage))
    # 使用 printf 输出，确保颜色转义被正确解释且不被 shell 当作字面文本
    printf "CPU 各核： "
    for i in "${!cpu_cores_usage[@]}"; do
        # printf 不会自动添加换行；每项后加两个空格便于阅读
        printf "核:%s %b%s%%%b  " "$i" "$yellow" "${cpu_cores_usage[$i]}" "$plain"
    done
    printf "\n"

    # 负载状态
    # get_load_percentage_and_msg 返回三项，第二项包含颜色转义
    read -r load_pct load_color load_msg <<< "$(get_load_percentage_and_msg)"
    # 使用 echo -e 确保颜色生效
    echo -e "负载状态： ${load_pct}% （${load_color}${load_msg}${plain}）"

    # MAC & 公网 IP
    echo -e "MAC 地址： ${yellow}$(get_primary_mac)${plain}"
    echo -e "公网IPv4： ${yellow}$(get_pub_ip4)${plain}"
    echo -e "公网IPv6： ${yellow}$(get_pub_ip6)${plain}"

    # Uptime
    uptime_sec=$(awk '{print int($1)}' /proc/uptime)
    days=$(( uptime_sec/86400 ))
    hours=$(( (uptime_sec%86400)/3600 ))
    minutes=$(( (uptime_sec%3600)/60 ))
    echo -e "运行时间： ${yellow}${days} 天 ${hours} 小时 ${minutes} 分${plain}"

    # 内存（使用 available 更准确）
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_avail=$(free -m | awk '/Mem:/ {print $7}')
    mem_pct=$(awk -v t="$mem_total" -v u="$mem_used" 'BEGIN{printf("%.0f", u*100/t)}')
    echo -e "内存占用： ${yellow}${mem_pct}%${plain} (${mem_used} MB/${mem_avail} MB/${mem_total} MB)"

    # 磁盘（根分区）
    read -r _ d_total d_used d_avail d_percent _ < <(df -m / | awk 'NR==2')
    echo -e "硬盘占用： ${yellow}${d_percent}${plain} (${d_used} MB/${d_avail} MB/${d_total} MB)"

    # 网络速度
    # get_net_speed 使用 tab 作为分隔符，读取时设置 IFS=$'\t' 保证带单位字符串完整
    IFS=$'\t' read -r down_speed up_speed <<< "$(get_net_speed)"
    # 使用 echo -e 打印
    echo -e "网络速度： ↓ ${yellow}${down_speed}${plain}   ↑ ${yellow}${up_speed}${plain}"

    echo -e "${blue}========================================${plain}"
    read -p "按回车返回菜单..." temp
}

# -------------------
# IP/HTTP 测试（表格）
# -------------------
platforms=(
"dazn.com"
"hotstar.com"
"disneyplus.com"
"netflix.com"
"youtube.com"
"primevideo.com"
"tvbanywhere.com"
"iq.com"
"viu.com"
"googlevideo.com"
"nflxvideo.net"
"spotify.com"
"store.steampowered.com"
"chat.openai.com"
"bing.com"
)

print_table_header() {
    printf "%-25s %-25s %-15s %-15s %-15s %-15s\n" \
    "Domain" "DNS" "HTTPS" "HTTP" "IP" "PING"
    printf "%-25s %-25s %-15s %-15s %-15s %-15s\n" \
    "-------------------------" "-------------------------" "---------------" "---------------" "---------------" "---------------"
}

test_domain_table() {
    local domain="$1"
    local ip dns_out https_out http_out raw_out ping_out

    ip=$(resolve_first_ipv4 "$domain")
    if [[ -n "$ip" ]]; then dns_out="正常 ($ip)"; else dns_out="异常 (解析失败)"; fi

    https_code=$(get_http_status "https://$domain")
    if [[ -z "$https_code" ]]; then https_out="失败 (超时)"; elif [[ "$https_code" -ge 200 && "$https_code" -lt 400 ]]; then https_out="正常 ($https_code)"; else https_out="异常 ($https_code)"; fi

    http_code=$(get_http_status "http://$domain")
    if [[ -z "$http_code" ]]; then http_out="失败 (超时)"; elif [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then http_out="正常 ($http_code)"; else http_out="异常 ($http_code)"; fi

    if [[ -n "$ip" ]]; then
        raw_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 --max-time 8 --resolve "$domain:443:$ip" "https://$domain" 2>/dev/null || echo "")
        if [[ -z "$raw_code" ]]; then raw_out="失败 (超时)"; elif [[ "$raw_code" -ge 200 && "$raw_code" -lt 400 ]]; then raw_out="正常 ($raw_code)"; else raw_out="异常 ($raw_code)"; fi
    else
        raw_out="无法测试(无 IP)"
    fi

    if ping -c1 -W1 "$domain" &>/dev/null; then ping_out="可 ping"; else ping_out="不可 ping"; fi

    printf "%-25s %-25s %-15s %-15s %-15s %-15s\n" \
    "$domain" "$dns_out" "$https_out" "$http_out" "$raw_out" "$ping_out"
}

test_ip_connect_table() {
    clear
    echo -e "${blue}=========== 高级 IP 测试（表格模式） ===========${plain}"
    echo
    print_table_header
    for domain in "${platforms[@]}"; do
        test_domain_table "$domain"
    done
    echo
    echo -e "${green}测试完成！${plain}"
    read -p "按回车返回菜单..." tmp
}

# -------------------
# 脚本更新
# -------------------
update_script() {
    echo -e "${yellow}正在更新脚本...${plain}"
    if command -v curl >/dev/null 2>&1 && curl -sSL "$SCRIPT_URL" -o tool.sh; then
        chmod +x tool.sh
        echo -e "${green}脚本更新成功！使用 ./tool.sh 重新运行${plain}"
        exit 0
    else
        echo -e "${red}更新失败，确认 SCRIPT_URL 与网络可达，且系统安装 curl${plain}"
    fi
    read -p "按回车返回菜单..." tmp
}

# -------------------
# 菜单
# -------------------
menu() {
    while true; do
        clear
        echo -e "${green}=============== Linux 多功能工具箱 ===============${plain}"
        echo -e "脚本版本：${yellow}$SCRIPT_VERSION${plain}"
        echo
        echo "1) 系统信息"
        echo "2) 系统更新"
        echo "3) 系统清理"
        echo "4) 系统工具"
        echo "5) 应用市场"
        echo "6) 安装宝塔"
        echo "7) 安装1Panel"
        echo "8) IP 测试"
        echo "9) 脚本更新"
        echo "0) 脚本退出"
        echo
        read -p "请输入数字回车：" choice

        case $choice in
            1) system_info ;;
            2)
                if [[ "$PKG" == "apt" ]]; then sudo apt update && sudo apt upgrade -y; 
                elif [[ "$PKG" == "dnf" || "$PKG" == "yum" ]]; then sudo $PKG upgrade -y; 
                else echo "未识别包管理器，请手动更新"; fi
                read -p "按回车返回菜单..." tmp ;;
            3) system_clean ;;
            4)
                echo -e "${blue}===== 系统工具 =====${plain}"
                echo "1) htop"
                echo "2) iftop"
                echo "3) vnstat"
                echo "4) 返回菜单"
                read -p "请选择：" t
                case $t in
                    1) $PKG && sudo $PKG install -y htop >/dev/null 2>&1; command -v htop >/dev/null 2>&1 && htop || echo "请安装 htop";;
                    2) sudo $PKG install -y iftop >/dev/null 2>&1; command -v iftop >/dev/null 2>&1 && iftop || echo "请安装 iftop";;
                    3) sudo $PKG install -y vnstat >/dev/null 2>&1; command -v vnstat >/dev/null 2>&1 && vnstat || echo "请安装 vnstat";;
                    *) ;;
                esac
                read -p "按回车返回菜单..." tmp ;;
            5) app_market ;;
            6) install_bt; read -p "按回车返回菜单..." tmp ;;
            7) install_1panel; read -p "按回车返回菜单..." tmp ;;
            8) test_ip_connect_table ;;
            9) update_script ;;
            0) echo "退出."; exit 0 ;;
            *) echo "无效选择"; read -p "按回车..." tmp ;;
        esac
    done
}

# 小工具：应用市场/安装脚本（保留原样）
app_market() {
    echo -e "${blue}===== 应用市场 =====${plain}"
    echo "1) Docker"
    echo "2) Nginx"
    echo "3) Node.js"
    echo "4) 返回菜单"
    read -p "请选择：" a
    case $a in
        1) 
            if [[ "$PKG" == "apt" ]]; then sudo apt install -y docker.io; 
            else sudo $PKG install -y docker; fi ;;
        2) sudo $PKG install -y nginx ;;
        3) curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash - && sudo apt install -y nodejs ;;
        *) ;;
    esac
    read -p "按回车返回菜单..." tmp
}

install_bt() {
    echo -e "${yellow}正在安装宝塔...${plain}"
    curl -sSO https://download.bt.cn/install/install_panel.sh && bash install_panel.sh
}

install_1panel() {
    echo -e "${yellow}正在安装 1Panel...${plain}"
    curl -sSL https://resource.fit2cloud.com/1panel/install.sh | bash
}

# 启动菜单
menu
