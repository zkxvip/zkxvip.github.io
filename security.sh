# 文件名：security.sh
# 包含：安全防御和检测功能。
# 依赖：tool.sh 中的颜色变量

security_defense_func() {
    clear
    echo -e "${blue}===== 7. 安全防御与检测 =====${plain}"
    echo "1) 查看 SSH 登录失败日志 (Lastb)"
    echo "2) 检查高 CPU/内存占用恶意进程"
    echo "3) 网站 Web 攻击日志分析 (Nginx/Apache)"
    echo "4) 返回菜单"
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
            echo -e "${yellow}Web 攻击日志分析需要指定日志路径，此功能为占位符。${plain}"
            echo "请根据您的 Web 服务器配置手动查看日志文件，例如 /var/log/nginx/access.log" ;;
        *) ;;
    esac
    read -p "按回车返回菜单..." tmp
}
