# 文件名：security.sh
# 包含：安全防御和检测功能。
# 依赖：tool.sh 中的颜色变量

web_log_query() {
    local log_path
    read -p "请输入要分析的 Web 日志文件路径 (例如: /var/log/nginx/access.log)：" log_path

    if [[ ! -f "$log_path" ]]; then
        echo -e "${red}错误：文件 $log_path 不存在，请检查路径。${plain}"
        return 1
    fi

    clear
    echo -e "${yellow}===== Web 攻击日志快速查询 =====${plain}"
    echo "当前日志路径: $log_path"
    echo
    echo "1) 查找 SQL 注入尝试 (常见关键字: UNION, SELECT, OR 1=1)"
    echo "2) 查找 XSS/HTML 注入尝试 (常见关键字: <script>, onerror, onload)"
    echo "3) 查找 LFI/路径遍历尝试 (常见关键字: ../, /etc/passwd)"
    echo "4) 查找高频 4xx 错误状态码 (异常爬虫或扫描)"
    echo "5) 返回上一级菜单"
    echo
    read -p "请选择查询类型：" q_choice

    local keyword=""
    local title=""
    
    case $q_choice in
        1) keyword='UNION.*SELECT|OR.*1=1|exec|xp_cmdshell'; title="SQL 注入尝试";;
        2) keyword='<script|onerror|onload|document.cookie'; title="XSS/HTML 注入尝试";;
        3) keyword='../|%2e%2e%2f|/etc/passwd|/proc/self/fd'; title="LFI/路径遍历尝试";;
        4) keyword=' 4\d{2} '; title="高频 4xx 错误";;
        *) echo -e "${green}取消查询。${plain}"; return 0;;
    esac

    echo -e "\n${yellow}===== 正在搜索日志中的 [$title]... =====${plain}"

    # 使用 cat 和 grep -E (扩展正则) 进行搜索，并限制显示条数
    # -i 忽略大小写
    if [[ "$q_choice" == "4" ]]; then
        # 统计高频 4xx 状态码（通常是 404/403）
        grep -E ' 4\d{2} ' "$log_path" | awk '{print $9}' | sort | uniq -c | sort -nr | head -n 10
        echo -e "\n${yellow}以上为状态码统计。请查看整个日志文件 $log_path 获取详情。${plain}"
    else
        # 搜索攻击关键字，并显示匹配的日志行
        grep -E -i "$keyword" "$log_path" | head -n 20
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            echo -e "${green}未发现匹配项。${plain}"
        else
            echo -e "\n${yellow}以上为前 20 条可疑日志。${plain}"
        fi
    fi
}

security_defense_func() {
    clear
    echo -e "${blue}===== 7. 安全防御与检测 =====${plain}"
    echo "1) 查看 SSH 登录失败日志 (Lastb)"
    echo "2) 检查高 CPU/内存占用恶意进程"
    echo "3) Web 攻击日志查询 (基于关键字)"
    echo "4) 查看当前已建立的网络连接 (ESTABLISHED)"
    echo "5) 统计连接数最多的远程 IP (Top 20)"
    echo "6) 返回菜单"
    echo
    read -p "请选择：" s
    case $s in
        1) 
            echo -e "${yellow}最近的登录失败记录 (lastb):${plain}"
            if command -v lastb >/dev/null 2>&1; then
                lastb | head -n 10
            else
                echo -e "${red}未找到 lastb 命令，可能需要安装。${plain}"
            fi ;;
        2) 
            echo -e "${yellow}当前按 CPU 排序的前 10 个进程 (ps aux --sort=-%cpu | head):${plain}"
            if command -v ps >/dev/null 2>&1; then
                ps aux --sort=-%cpu | head -n 11
            else
                echo -e "${red}未找到 ps 命令。${plain}"
            fi ;;
        3) 
            web_log_query 
            ;;
        4) 
            echo -e "${yellow}当前已建立 (ESTABLISHED) 的 TCP/UDP 网络连接:${plain}"
            if command -v netstat >/dev/null 2>&1; then
                netstat -tunp | grep ESTABLISHED
            else
                echo -e "${red}未找到 netstat 命令，请安装 net-tools 包。${plain}"
            fi ;;
        5)
            echo -e "${yellow}正在统计连接数最多的前 20 个远程 IP 地址 (可能需要几秒)...${plain}"
            if command -v netstat >/dev/null 2>&1; then
                # 优先使用 ss (iproute2) 进行统计，速度更快
                if command -v ss >/dev/null 2>&1; then
                    ss -anp | grep 'tcp' | awk '{print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -n20
                else
                    # Fallback 到 netstat
                    netstat -anlp | grep 'tcp' | awk '{print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -n20
                fi
            else
                echo -e "${red}未找到 netstat 或 ss 命令，无法执行统计。${plain}"
            fi ;;
        *) ;;
    esac
    read -p "按回车返回菜单..." tmp
}
