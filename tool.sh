#!/bin/bash

# =====================================================
# Linux 多功能工具箱（带顺序 IP 测试）
# 版本：1.3.1（系统信息静态版）
# =====================================================

SCRIPT_VERSION="1.3.1"
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
# 系统信息（静态版，不刷新）
# ================================
system_info() {
    clear
    echo -e "${blue}=============== 系统信息 ===============${plain}"

    # 系统版本
    local distro
    if command -v lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -d | awk -F':' '{print $2}' | xargs)
    else
        distro=$(awk -F= '/^PRETTY_NAME/ {gsub(/"/,"",$2); print $2}' /etc/os-release)
    fi

    echo -e "系统： ${yellow}${distro}${plain}"
    echo -e "内核： ${yellow}$(uname -r)${plain}"

    # CPU 信息
    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo | awk -F: '{print $2}' | xargs)
    echo -e "CPU 型号： ${yellow}${cpu_model}${plain}"
    echo -e "CPU 核心： ${yellow}$(nproc --all)${plain}"

    if command -v lscpu >/dev/null 2>&1; then
        echo -e "CPU 主频： ${yellow}$(lscpu | awk -F: '/CPU MHz/ {print $2}' | xargs) MHz${plain}"
    fi

    # MAC
    local mac
    mac=$(cat /sys/class/net/*/address 2>/dev/null | grep -v "00:00:00" | head -n1 || echo "未知")
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
    days=$(( uptime_sec/86400 ))
    hours=$(( (uptime_sec%86400)/3600 ))
    minutes=$(( (uptime_sec%3600)/60 ))
    echo -e "运行时间： ${yellow}${days} 天 ${hours} 小时 ${minutes} 分${plain}"

    # 内存
    local mem_total mem_used mem_free mem_pct
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_free=$((mem_total - mem_used))
    mem_pct=$(awk -v t="$mem_total" -v u="$mem_used" 'BEGIN{printf("%.0f", u*100/t)}')

    echo -e "内存占用： ${yellow}${mem_pct}%${plain} (${mem_used} MB/${mem_free} MB/${mem_total} MB)"

    # 硬盘
    read -r _ total used avail percent _ < <(df -m / | awk 'NR==2')
    echo -e "硬盘占用： ${yellow}${percent}${plain} (${used} MB/${avail} MB/${total} MB)"

    echo -e "${blue}========================================${plain}"
    read -p "按回车返回菜单..." temp
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
# 域名测试平台
# ================================
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

    # DNS
    ip=$(dig +short A "$domain" | grep -E '^[0-9.]+' | head -n1)
    if [[ -n "$ip" ]]; then
        dns_out="正常 ($ip)"
    else
        dns_out="异常 (解析失败)"
    fi

    # HTTPS
    local https_status
    https_status=$(curl -I -s --connect-timeout 8 --max-time 8 https://"$domain" | head -n1 | awk '{print $2}')
    if [[ -z "$https_status" ]]; then
        https_out="失败 (超时)"
    elif [[ "$https_status" -ge 200 && "$https_status" -lt 400 ]]; then
        https_out="正常 ($https_status)"
    else
        https_out="异常 ($https_status)"
    fi

    # HTTP
    local http_status
    http_status=$(curl -I -s --connect-timeout 8 --max-time 8 http://"$domain" | head -n1 | awk '{print $2}')
    if [[ -z "$http_status" ]]; then
        http_out="失败 (超时)"
    elif [[ "$http_status" -ge 200 && "$http_status" -lt 400 ]]; then
        http_out="正常 ($http_status)"
    else
        http_out="异常 ($http_status)"
    fi

    # RAW IP 测试
    if [[ -n "$ip" ]]; then
        raw_status=$(curl -I -s --connect-timeout 8 --max-time 8 --resolve "$domain:443:$ip" https://"$domain" | head -n1 | awk '{print $2}')
        if [[ -z "$raw_status" ]]; then
            raw_out="失败 (超时)"
        elif [[ "$raw_status" -ge 200 && "$raw_status" -lt 400 ]]; then
            raw_out="正常 ($raw_status)"
        else
            raw_out="异常 ($raw_status)"
        fi
    else
        raw_out="无法测试(无 IP)"
    fi

    # Ping
    if ping -c1 -W1 "$domain" &>/dev/null; then
        ping_out="可 ping"
    else
        ping_out="不可 ping"
    fi

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
        2) system_update ;;
        3) system_clean ;;
        4) system_tools ;;
        5) app_market ;;
        6) install_bt ;;
        7) install_1panel ;;
        8) test_ip_connect_table ;;
        9) update_script ;;
        0) exit 0 ;;
        *) echo "无效选择" ;;
    esac

    echo
    read -p "按回车返回菜单：" temp
    menu
}

menu
