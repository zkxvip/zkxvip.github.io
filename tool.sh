#!/bin/bash
# =====================================================
# Linux 多功能工具箱（带顺序 IP 测试）tool.sh
# 版本：1.3.0
# =====================================================

SCRIPT_VERSION="1.3.0"
SCRIPT_URL="http://your-ip-or-domain/tool.sh"   # 更新脚本使用，请改成你的地址

# ================================
# 基础颜色
# ================================
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[36m"
plain="\033[0m"

# ================================
# 系统信息（增强版：IPv4/IPv6/MAC/CPU/内存/硬盘）
# ================================
system_info() {
    echo -e "${blue}========== 系统信息 ==========${plain}"

    # 发行版描述（若无 lsb_release 则读取 /etc/os-release）
    local distro
    if command -v lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -d 2>/dev/null | awk -F':' '{print $2}' | xargs)
    else
        distro=$(awk -F= '/^PRETTY_NAME/{gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null || cat /etc/os-release 2>/dev/null | head -n1)
    fi
    echo -e "系统： ${yellow}${distro}${plain}"

    # 内核
    echo -e "内核： ${yellow}$(uname -r)${plain}"

    # CPU 型号、核心、线程、频率（尽量兼容）
    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | awk -F: '{print $2}' | xargs)
    if [[ -z "$cpu_model" ]]; then
        cpu_model=$(awk -F: '/^Model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null | xargs)
    fi
    local cpu_cores
    cpu_cores=$(nproc --all 2>/dev/null || echo "-")
    # cpu freq
    local cpu_freq
    if command -v lscpu >/dev/null 2>&1; then
        cpu_freq=$(lscpu 2>/dev/null | awk -F: '/CPU MHz/{print $2}' | xargs)
    else
        cpu_freq=$(awk -F: '/cpu MHz/{print $2; exit}' /proc/cpuinfo 2>/dev/null | xargs)
    fi
    echo -e "CPU 型号： ${yellow}${cpu_model}${plain}"
    echo -e "CPU 核心： ${yellow}${cpu_cores}${plain}"
    if [[ -n "$cpu_freq" ]]; then
        echo -e "CPU 主频： ${yellow}${cpu_freq} MHz${plain}"
    fi

    # MAC 地址：取第一个非 lo 的 link/ether
    local mac
    mac=$(ip -o link 2>/dev/null | awk '/link\/ether/ {print $2; exit}')
    if [[ -z "$mac" ]]; then
        mac=$(cat /sys/class/net/*/address 2>/dev/null | grep -v '^00:00:00' | head -n1 || echo "未知")
    fi
    echo -e "MAC 地址： ${yellow}${mac}${plain}"

    # 公网 IPv4 / IPv6（使用 ifconfig.me，超时短）
    local ipv4 ipv6
    ipv4=$(curl -4 -s --connect-timeout 3 --max-time 5 ifconfig.me || echo "获取失败")
    ipv6=$(curl -6 -s --connect-timeout 3 --max-time 5 ifconfig.me || echo "获取失败")
    echo -e "公网 IPv4： ${yellow}${ipv4}${plain}"
    echo -e "公网 IPv6： ${yellow}${ipv6}${plain}"

    # --- 内存信息（MB） ---
    local mem_total mem_used mem_free mem_available mem_used_pct
    # use available for "可用"
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_available=$(free -m | awk '/Mem:/ {print $7}')
    if [[ -z "$mem_total" || "$mem_total" == "0" ]]; then
        echo -e "内存信息： ${yellow}无法获取${plain}"
    else
        # percent used by (total - available)/total*100
        mem_used_pct=$(awk -v t="$mem_total" -v a="$mem_available" 'BEGIN{used=(t-a); if(t>0) printf("%.1f", used*100/t); else print "0"}')
        echo -e "内存总量： ${yellow}${mem_total} MB${plain}"
        echo -e "内存已用： ${yellow}$((mem_total - mem_available)) MB${plain}"
        echo -e "内存可用： ${yellow}${mem_available} MB${plain}"
        echo -e "内存占用： ${yellow}${mem_used_pct}%${plain}"
    fi

    # --- 硬盘（根分区 / ）显示总/已用/可用/占用%
    local disk_total disk_used disk_avail disk_pct
    disk_total=$(df -h / | awk 'NR==2{print $2}')
    disk_used=$(df -h / | awk 'NR==2{print $3}')
    disk_avail=$(df -h / | awk 'NR==2{print $4}')
    disk_pct=$(df -h / | awk 'NR==2{print $5}')
    echo -e "硬盘总量： ${yellow}${disk_total}${plain}"
    echo -e "硬盘已用： ${yellow}${disk_used}${plain}"
    echo -e "硬盘可用： ${yellow}${disk_avail}${plain}"
    echo -e "硬盘占用： ${yellow}${disk_pct}${plain}"

    echo -e "${blue}====================================${plain}"
}

# ================================
# 系统更新
# ================================
system_update() {
    echo -e "${green}正在更新系统...${plain}"
    apt update && apt upgrade -y
    echo -e "${green}系统更新完成！${plain}"
}

# ================================
# 系统清理
# ================================
system_clean() {
    echo -e "${green}正在清理系统...${plain}"
    apt autoremove -y
    apt autoclean -y
    apt clean -y
    echo -e "${green}系统清理完成！${plain}"
}

# ================================
# 系统工具
# ================================
system_tools() {
    echo -e "${blue}===== 系统工具 =====${plain}"
    echo "1) htop"
    echo "2) iftop"
    echo "3) vnstat"
    echo "4) 返回菜单"
    read -p "请选择：" t

    case $t in
        1) apt install -y htop && htop ;;
        2) apt install -y iftop && iftop ;;
        3) apt install -y vnstat && vnstat ;;
        4) ;;
        *) echo "无效选择" ;;
    esac
}

# ================================
# 应用市场
# ================================
app_market() {
    echo -e "${blue}===== 应用市场 =====${plain}"
    echo "1) Docker"
    echo "2) Nginx"
    echo "3) Node.js"
    echo "4) 返回菜单"
    read -p "请选择：" a

    case $a in
        1) apt install -y docker.io ;;
        2) apt install -y nginx ;;
        3) curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt install -y nodejs ;;
        4) ;;
        *) echo "无效选择" ;;
    esac
}

# ================================
# 安装宝塔
# ================================
install_bt() {
    echo -e "${yellow}正在安装宝塔...${plain}"
    curl -sSO https://download.bt.cn/install/install_panel.sh && bash install_panel.sh
}

# ================================
# 安装 1Panel
# ================================
install_1panel() {
    echo -e "${yellow}正在安装 1Panel...${plain}"
    curl -sSL https://resource.fit2cloud.com/1panel/install.sh | bash
}

# ================================
# 高级（顺序）IP 测试模块 — 顺序逐个检测（详细模式）
# ================================
print_delimiter() {
    echo -e "${blue}----------------------------------------${plain}"
}

# 获取第一个 IPv4（A 记录）
get_first_ip() {
    local domain=$1
    # prefer A record
    dig +short A "$domain" 2>/dev/null | grep -E '^[0-9.]+' | head -n1 || true
}

# HTTPS 测试（域名）
test_https() {
    local domain=$1
    local status
    status=$(curl -I -s --connect-timeout 10 --max-time 10 "https://$domain" 2>/dev/null | head -n1 | awk '{print $2}')
    if [[ -z "$status" ]]; then
        echo -e "${red}失败（超时）${plain}"
    elif [[ "$status" -ge 200 && "$status" -lt 400 ]]; then
        echo -e "${green}正常 (${status})${plain}"
    else
        echo -e "${yellow}异常 (${status})${plain}"
    fi
}

# HTTP 测试（域名）
test_http() {
    local domain=$1
    local status
    status=$(curl -I -s --connect-timeout 10 --max-time 10 "http://$domain" 2>/dev/null | head -n1 | awk '{print $2}')
    if [[ -z "$status" ]]; then
        echo -e "${red}失败（超时）${plain}"
    elif [[ "$status" -ge 200 && "$status" -lt 400 ]]; then
        echo -e "${green}正常 (${status})${plain}"
    else
        echo -e "${yellow}异常 (${status})${plain}"
    fi
}

# IP 直连测试（使用 --resolve 强制 SNI，针对 IPv4）
test_raw_ip() {
    local domain=$1
    local ip=$2
    if [[ -z "$ip" ]]; then
        echo -e "${red}无法测试（无 IP）${plain}"
        return
    fi
    local status
    status=$(curl -I -s --connect-timeout 10 --max-time 10 --resolve "$domain:443:$ip" "https://$domain" 2>/dev/null | head -n1 | awk '{print $2}')
    if [[ -z "$status" ]]; then
        echo -e "${red}失败（超时）${plain}"
    elif [[ "$status" -ge 200 && "$status" -lt 400 ]]; then
        echo -e "${green}正常 (${status})${plain}"
    else
        echo -e "${yellow}异常 (${status})${plain}"
    fi
}

# Ping 测试（域名，单包，超时 1 秒）
test_ping() {
    local domain=$1
    local host
    host=$(echo "$domain" | awk -F/ '{print $3}')
    if [[ -z "$host" ]]; then
        echo -e "${red}不可 ping（域名解析失败）${plain}"
        return
    fi
    if ping -c1 -W1 "$host" &>/dev/null; then
        echo -e "${green}可 ping${plain}"
    else
        echo -e "${red}不可 ping${plain}"
    fi
}

# 单域名顺序检测函数（输出详细结果）
test_domain_full_sequential() {
    local domain=$1
    local label=$2

    print_delimiter
    echo -e "测试平台：${yellow}${label}${plain}"
    echo -e "域名：${yellow}${domain}${plain}"

    # DNS
    local ip
    ip=$(get_first_ip "$domain")
    if [[ -n "$ip" ]]; then
        echo -e "DNS 测试：      ${green}正常 (${ip})${plain}"
    else
        echo -e "DNS 测试：      ${red}失败${plain}"
    fi

    # HTTPS
    echo -n "HTTPS 测试：    "; test_https "$domain"

    # HTTP
    echo -n "HTTP 测试：     "; test_http "$domain"

    # IP 直连（使用第一个解析到的 IP）
    echo -n "IP 直连测试：   "; test_raw_ip "$domain" "$ip"

    # PING
    echo -n "PING 测试：     "; test_ping "https://$domain"

    print_delimiter
    echo
}

# 平台列表（label:domain）
platforms=(
    "Dazn:dazn.com"
    "HotStar:hotstar.com"
    "Disney+:disneyplus.com"
    "Netflix:netflix.com"
    "YouTube Premium:youtube.com"
    "Amazon Prime Video:primevideo.com"
    "TVBAnywhere+:tvbanywhere.com"
    "iQiyi Oversea Region:iq.com"
    "Viu:viu.com"
    "YouTube CDN:googlevideo.com"
    "Netflix Preferred CDN:nflxvideo.net"
    "Spotify Registration:spotify.com"
    "Steam Currency:store.steampowered.com"
    "ChatGPT:chat.openai.com"
    "Bing Region:bing.com"
)

# 入口函数（顺序检测所有平台）
test_ip_connect() {
    clear
    echo -e "${blue}=========== 高级 IP 测试（顺序逐个） ===========${plain}"
    echo

    for item in "${platforms[@]}"; do
        label=${item%%:*}
        domain=${item##*:}
        test_domain_full_sequential "$domain" "$label"
    done

    echo -e "${green}测试完成！${plain}"
}

# ================================
# 脚本更新
# ================================
update_script() {
    echo -e "${yellow}正在更新脚本...${plain}"

    if curl -sSL "$SCRIPT_URL" -o tool.sh; then
        chmod +x tool.sh
        echo -e "${green}脚本更新成功！使用 ./tool.sh 重新运行${plain}"
        exit 0
    else
        echo -e "${red}更新失败！${plain}"
    fi
}

# ================================
# 主菜单
# ================================
menu() {
    clear
    echo -e "${green}=============== Linux 多功能工具箱 ===============${plain}"
    echo -e "脚本版本：${yellow}$SCRIPT_VERSION${plain}"
    echo
    echo "1) 查看系统信息"
    echo "2) 系统更新"
    echo "3) 系统清理"
    echo "4) 系统工具"
    echo "5) 应用市场"
    echo "6) 安装宝塔"
    echo "7) 安装 1Panel"
    echo "8) IP 测试（顺序版 - 详细模式）"
    echo "9) 脚本更新"
    echo "0) 退出"
    echo

    read -p "请输入选择：" choice

    case $choice in
        1) system_info ;;
        2) system_update ;;
        3) system_clean ;;
        4) system_tools ;;
        5) app_market ;;
        6) install_bt ;;
        7) install_1panel ;;
        8) test_ip_connect ;;
        9) update_script ;;
        0) exit ;;
        *) echo "无效选择" ;;
    esac

    echo
    read -p "按回车返回菜单..." temp
    menu
}

menu
