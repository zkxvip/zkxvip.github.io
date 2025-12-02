#!/bin/bash

# =====================================================
# Linux 多功能工具箱（带顺序 IP 测试）tool.sh
# 版本：1.3.0（表格对齐增强版）
# =====================================================

SCRIPT_VERSION="1.3.0"
SCRIPT_URL="http://your-ip-or-domain/tool.sh"   # 更新脚本使用，请改成你的地址

# ================================
# 基础颜色（不要在表格单元格内使用颜色，否则会破坏对齐）
# ================================
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[36m"
plain="\033[0m"

# ================================
# 系统信息（增强版）
# ================================
system_info() {
    echo -e "${blue}========== 系统信息 ==========${plain}"

    local distro
    if command -v lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -d 2>/dev/null | awk -F':' '{print $2}' | xargs)
    else
        distro=$(awk -F= '/^PRETTY_NAME/{gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null)
    fi
    echo -e "系统： ${yellow}${distro}${plain}"
    echo -e "内核： ${yellow}$(uname -r)${plain}"

    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | awk -F: '{print $2}' | xargs)
    local cpu_cores=$(nproc --all 2>/dev/null || echo "-")
    local cpu_freq=""
    if command -v lscpu >/dev/null 2>&1; then
        cpu_freq=$(lscpu 2>/dev/null | awk -F: '/CPU MHz/{print $2}' | xargs)
    fi
    echo -e "CPU 型号： ${yellow}${cpu_model}${plain}"
    echo -e "CPU 核心： ${yellow}${cpu_cores}${plain}"
    [[ -n "$cpu_freq" ]] && echo -e "CPU 主频： ${yellow}${cpu_freq} MHz${plain}"

    local mac=$(cat /sys/class/net/*/address 2>/dev/null | grep -v '^00:00:00' | head -n1 || echo "未知")
    echo -e "MAC 地址： ${yellow}${mac}${plain}"

    local ipv4=$(curl -4 -s --connect-timeout 3 --max-time 5 ifconfig.me || echo "获取失败")
    local ipv6=$(curl -6 -s --connect-timeout 3 --max-time 5 ifconfig.me || echo "获取失败")
    echo -e "公网 IPv4： ${yellow}${ipv4}${plain}"
    echo -e "公网 IPv6： ${yellow}${ipv6}${plain}"

    local mem_total=$(free -m | awk '/Mem:/ {print $2}')
    local mem_available=$(free -m | awk '/Mem:/ {print $7}')
    if [[ -n "$mem_total" && "$mem_total" -ne 0 ]]; then
        local mem_used=$((mem_total - mem_available))
        local mem_used_pct
        mem_used_pct=$(awk -v t="$mem_total" -v u="$mem_used" 'BEGIN{printf("%.1f", u*100/t)}')
        echo -e "内存总量： ${yellow}${mem_total} MB${plain}"
        echo -e "内存已用： ${yellow}${mem_used} MB${plain}"
        echo -e "内存可用： ${yellow}${mem_available} MB${plain}"
        echo -e "内存占用： ${yellow}${mem_used_pct}%${plain}"
    else
        echo -e "内存信息： ${yellow}无法获取${plain}"
    fi

    local disk_total=$(df -h / | awk 'NR==2{print $2}')
    local disk_used=$(df -h / | awk 'NR==2{print $3}')
    local disk_avail=$(df -h / | awk 'NR==2{print $4}')
    local disk_pct=$(df -h / | awk 'NR==2{print $5}')
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
# 安装宝塔（修复版）
# ================================
install_bt() {
    echo -e "${yellow}正在安装宝塔...${plain}"
    curl -sSO https://download.bt.cn/install/install_panel.sh && bash install_panel.sh
}

# ================================
# 安装 1Panel（修复版）
# ================================
install_1panel() {
    echo -e "${yellow}正在安装 1Panel...${plain}"
    curl -sSL https://resource.fit2cloud.com/1panel/install.sh | bash
}

# ================================
# IP 测试（顺序输出表格） 强制宽度对齐
# ================================
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

# 说明：下面的列宽是固定的（以字符宽度为准）
# %-24s 域名列（24 字符宽）
# %-28s DNS 测试列（28 字符宽）
# %-16s HTTPS 列（16 字符宽）
# %-14s HTTP 列（14 字符宽）
# %-20s IP 直连列（20 字符宽）
# %-10s PING 列（10 字符宽）
print_table_header() {
    # 使用纯 ASCII 标题（中文会占两个单元格宽，可能影响视觉对齐，但列格式固定）
    printf "%-24s %-28s %-16s %-14s %-20s %-10s\n" \
    "域名" "DNS 测试" "HTTPS 测试" "HTTP 测试" "IP 直连测试" "PING 测试"
    printf "%-24s %-28s %-16s %-14s %-20s %-10s\n" \
    "------------------------" "----------------------------" "----------------" "--------------" "--------------------" "----------"
}

# 测试单个域名并按固定宽度打印一行
test_domain_table() {
    local domain="$1"

    # 解析 A 记录以获取第一个 IPv4
    local ip
    ip=$(dig +short A "$domain" 2>/dev/null | grep -E '^[0-9.]+' | head -n1)

    local dns_out
    if [[ -n "$ip" ]]; then
        dns_out="正常 ($ip)"
    else
        dns_out="异常 (解析失败)"
    fi

    # HTTPS 测试（短响应头）
    local https_status
    https_status=$(curl -I -s --connect-timeout 8 --max-time 8 "https://$domain" 2>/dev/null | head -n1 | awk '{print $2}')
    local https_out
    if [[ -z "$https_status" ]]; then
        https_out="失败(超时)"
    elif [[ "$https_status" -ge 200 && "$https_status" -lt 400 ]]; then
        https_out="正常 ($https_status)"
    else
        https_out="异常 ($https_status)"
    fi

    # HTTP 测试
    local http_status
    http_status=$(curl -I -s --connect-timeout 8 --max-time 8 "http://$domain" 2>/dev/null | head -n1 | awk '{print $2}')
    local http_out
    if [[ -z "$http_status" ]]; then
        http_out="失败(超时)"
    elif [[ "$http_status" -ge 200 && "$http_status" -lt 400 ]]; then
        http_out="正常 ($http_status)"
    else
        http_out="异常 ($http_status)"
    fi

    # IP 直连（使用 --resolve 强制 host -> ip）测试 HTTPS
    local raw_out
    if [[ -n "$ip" ]]; then
        local raw_status
        raw_status=$(curl -I -s --connect-timeout 8 --max-time 8 --resolve "$domain:443:$ip" "https://$domain" 2>/dev/null | head -n1 | awk '{print $2}')
        if [[ -z "$raw_status" ]]; then
            raw_out="失败(超时)"
        elif [[ "$raw_status" -ge 200 && "$raw_status" -lt 400 ]]; then
            raw_out="正常 ($raw_status)"
        else
            raw_out="异常 ($raw_status)"
        fi
    else
        raw_out="无法测试(无 IP)"
    fi

    # PING 测试（对域名 ping）
    local ping_out
    if ping -c1 -W1 "$domain" &>/dev/null; then
        ping_out="可 ping"
    else
        ping_out="不可 ping"
    fi

    # 打印到表格：注意所有字段都是纯文本（不带颜色转义）
    printf "%-24s %-28s %-16s %-14s %-20s %-10s\n" \
    "$domain" "$dns_out" "$https_out" "$http_out" "$raw_out" "$ping_out"
}

test_ip_connect_table() {
    clear
    # 表头前使用颜色高亮提示，但不在单元格内部使用颜色
    echo -e "${blue}=========== 高级 IP 测试（表格模式） ===========${plain}"
    echo

    print_table_header

    for item in "${platforms[@]}"; do
        domain=${item##*:}
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
    echo "1) 查看系统信息"
    echo "2) 系统更新"
    echo "3) 系统清理"
    echo "4) 系统工具"
    echo "5) 应用市场"
    echo "6) 安装宝塔"
    echo "7) 安装 1Panel"
    echo "8) IP 测试（表格模式）"
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
        8) test_ip_connect_table ;;
        9) update_script ;;
        0) exit 0 ;;
        *) echo "无效选择" ;;
    esac

    echo
    read -p "按回车返回菜单..." temp
    menu
}

menu
