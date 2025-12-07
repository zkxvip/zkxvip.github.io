# 文件名：script_update.sh
# 包含：脚本自我更新功能。
# 依赖：tool.sh 中的颜色变量和 SCRIPT_URL 变量

script_update_func() {
    clear
    echo -e "${blue}===== 9. 脚本更新 =====${plain}"
    echo -e "${yellow}正在更新脚本...${plain}"
    
    # SCRIPT_URL 必须在 tool.sh 中定义
    if command -v curl >/dev/null 2>&1 && curl -sSL "$SCRIPT_URL" -o tool.sh; then
        chmod +x tool.sh
        echo -e "${green}脚本更新成功！请使用 ./tool.sh 重新运行${plain}"
        exit 0
    else
        echo -e "${red}更新失败，确认 SCRIPT_URL 与网络可达，且系统安装 curl${plain}"
    fi
    read -p "按回车返回菜单..." tmp
}
