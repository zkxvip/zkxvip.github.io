# 文件名：net_test.sh
# 包含：所有网络测试和 IP/流量获取辅助函数及主测试函数 net_test_func。
# 依赖：tool.sh 中的颜色变量

# -------------------
# 网络流量 / IP / 格式化
# -------------------

# 格式化速度单位
format_speed_unit() {
    local bytes=$1
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
    [[ "$val" == .* ]] && val="0$val"
    echo "$val $unit"
}

# 文件大小格式化
format_bytes() {
    local bytes=$1
    local unit=("B" "KB" "MB" "GB" "TB")
    local i=0
    local val=$bytes

    if command -v awk >/dev/null 2>&1; then
        awk -v b="$bytes" 'BEGIN{
            size = b; units[0] = "B"; units[1] = "KB"; units[2] = "MB"; units[3] = "GB"; units[4] = "TB"; i = 0;
            while (size >= 1024 && i < 4) { size /= 1024; i++; }
            printf "%.2f%s", size, units[i];
        }'
    else
        while (( val >= 1024 && i < 4 )); do val=$((val / 1024)); i=$((i+1)); done
        printf "%d%s" "$val" "${unit[i]}"
    fi
}

# 获取主网络接口
get_primary_net_iface() {
    local iface
    if command -v ip >/dev/null 2>&1; then
        iface=$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -v '^lo$' | head -n1)
    fi
    if [[ -z "$iface" ]] && command -v route >/dev/null 2>&1; then
        iface=$(route | grep '^default' | awk '{print $NF}' | head -n1)
    fi
    if [[ -z "$iface" ]] && [[ -f "/proc/net/route" ]]; then
        iface=$(awk '$2 != "00000000" && $8 == "00000000" {print $1; exit}' /proc/net/route)
    fi
    if [[ -z "$iface" ]]; then
        iface=$(ls /sys/class/net | grep -v lo | head -n1 2>/dev/null || echo "")
    fi
    echo "$iface"
}

# 获取网络速度
get_net_speed() {
    local iface
    iface=$(get_primary_net_iface)
    if [[ -z "$iface" ]]; then
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
    down=$(format_speed_unit "$bytes_down")
    up=$(format_speed_unit "$bytes_up")
    printf '%s\t%s' "$down" "$up"
}

# 获取总流量
get_net_total_traffic() {
    local iface
    iface=$(get_primary_net_iface)
    if [[ -z "$iface" ]]; then
        printf '%s\t%s' "0B" "0B"
        return
    fi

    local rx tx down up
    rx=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
    tx=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)

    down=$(format_bytes "$rx")
    up=$(format_bytes "$tx")
    printf '%s\t%s' "$down" "$up"
}

# 公网 IP
get_pub_ip4() {
    if ! command -v curl >/dev/null 2>&1; then echo "获取失败 (需安装 curl)"; return; fi
    ip=$(curl -4 -s --connect-timeout 3 --max-time 5 https://api.ipify.org || echo "")
    [[ -z "$ip" ]] && ip=$(curl -4 -s --connect-timeout 3 --max-time 5 https://ifconfig.me || echo "获取失败")
    echo "${ip:-获取失败}"
}
get_pub_ip6() {
    if ! command -v curl >/dev/null 2>&1; then echo "获取失败 (需安装 curl)"; return; fi
    ip=$(curl -6 -s --connect-timeout 3 --max-time 5 https://api64.ipify.org || echo "")
    [[ -z "$ip" ]] && ip="获取失败"
    echo "$ip"
}

# 获取地理位置（基于公网 IP）
get_ip_location() {
    if ! command -v curl >/dev/null 2>&1; then echo "未知 (需安装 curl)"; return; fi

    local ip=$(get_pub_ip4)
    if [[ "$ip" == *"失败"* ]]; then echo "获取失败"; return; fi
    
    location=$(curl -s --connect-timeout 3 --max-time 5 "https://ipinfo.io/$ip/json" | \
               awk -F': ' '/"org"|country/ {
                   gsub(/"/,""); 
                   if ($1 ~ "org") { org_name = $2; }
                   if ($1 ~ "country") { country_code = $2; }
               } END {
                   if (org_name != "" && country_code != "") {
                       print org_name " (" country_code ")";
                   } else if (org_name != "") {
                       print org_name;
                   } else if (country_code != "") {
                       print country_code;
                   } else {
                       print "未知";
                   }
               }')
    
    if [[ "$location" == "未知" || -z "$location" ]]; then
        location=$(curl -s --connect-timeout 3 --max-time 5 "https://ip.gs/" | tr -d '\n')
    fi
    
    echo "${location:-未知}"
}

# -------------------
# IP 测试功能
# -------------------

# 获取 DNS 解析（优先 getent，fallback dig/host）
resolve_first_ipv4() {
    local domain="$1"
    local ip
    if command -v getent >/dev/null 2>&1; then
        ip=$(getent ahostsv4 "$domain" | awk '{print $1; exit}')
    fi
    if [[ -z "$ip" ]] && command -v dig >/dev/null 2>&1; then
        ip=$(dig +short A "$domain" | grep -E '^[0-9.]+' | head -n1)
    fi
    if [[ -z "$ip" ]] && command -v host >/dev/null 2>&1; then
        ip=$(host -4 "$domain" 2>/dev/null | awk '/has address/ {print $4; exit}')
    fi
    echo "${ip:-}"
}

# 获取 HTTP/HTTPS 状态码
get_http_status() {
    local url="$1"
    if ! command -v curl >/dev/null 2>&1; then echo ""; return; fi
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 --max-time 8 "$url" 2>/dev/null || echo "")
    echo "${status:-}"
}

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
"store.steampowered.com"
"chat.openai.com"
"bing.com"
)

print_table_header() {
    printf "%-25s %-25s %-15s %-15s %-15s %-15s\n" \
    "Domain" "DNS" "HTTPS" "HTTP" "IP直连" "PING"
    printf "%-25s %-25s %-15s %-15s %-15s %-15s\n" \
    "-------------------------" "-------------------------" "---------------" "---------------" "---------------" "---------------"
}

test_domain_table() {
    local domain="$1"
    local ip dns_out https_out http_out raw_out ping_out

    ip=$(resolve_first_ipv4 "$domain")
    if [[ -n "$ip" ]]; then dns_out="正常 ($ip)"; else dns_out="异常 (解析失败)"; fi
    
    local base_domain
    if [[ "$domain" == http* ]]; then
        base_domain=$(echo "$domain" | awk -F'/' '{print $3}')
    else
        base_domain="$domain"
    fi
    
    # HTTPS
    https_code=$(get_http_status "https://$base_domain")
    if [[ -z "$https_code" ]]; then https_out="失败 (超时)"; elif [[ "$https_code" -ge 200 && "$https_code" -lt 400 ]]; then https_out="正常 ($https_code)"; else https_out="异常 ($https_code)"; fi

    # HTTP
    http_code=$(get_http_status "http://$base_domain")
    if [[ -z "$http_code" ]]; then http_out="失败 (超时)"; elif [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then http_out="正常 ($http_code)"; else http_out="异常 ($http_code)"; fi
    
    # IP 强制连接测试
    if [[ -n "$ip" ]] && command -v curl >/dev/null 2>&1; then
        raw_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 --max-time 8 --resolve "$base_domain:443:$ip" "https://$base_domain" 2>/dev/null || echo "")
        if [[ -z "$raw_code" ]]; then raw_out="失败 (超时)"; elif [[ "$raw_code" -ge 200 && "$raw_code" -lt 400 ]]; then raw_out="正常 ($raw_code)"; else raw_out="异常 ($raw_code)"; fi
    else
        raw_out="无法测试(无 IP)"
    fi

    # PING
    if [[ -n "$ip" ]] && ping -c1 -W1 "$ip" &>/dev/null; then 
        ping_out="可 ping"
    else 
        ping_out="不可 ping"
    fi

    printf "%-25s %-25s %-15s %-15s %-15s %-15s\n" \
    "$domain" "$dns_out" "$https_out" "$http_out" "$raw_out" "$ping_out"
}

# 主函数
net_test_func() {
    clear
    echo -e "${blue}=========== 8. 网络测试（表格模式） ===========${plain}"
    echo
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${red}错误：本功能需要安装 curl${plain}"
        read -p "按回车返回菜单..." tmp
        return
    fi
    print_table_header
    for domain in "${platforms[@]}"; do
        test_domain_table "$domain"
    done
    echo
    echo -e "${green}测试完成！${plain}"
    read -p "按回车返回菜单..." tmp
}
