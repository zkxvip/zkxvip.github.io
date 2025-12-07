# 文件名：script_update.sh
# 包含：脚本自我更新/修复功能。
# 依赖：tool.sh 中的颜色变量和 SCRIPT_URL 变量

script_update_func() {
    clear
    echo -e "${blue}===== 9. 修复更新（清理模块并更新主脚本） =====${plain}"
    
    # ----------------------------------------------------
    # 新增：删除所有已下载的模块文件，以便下次运行重新下载
    # ----------------------------------------------------
    echo -e "${yellow}正在清理旧的模块文件...${plain}"
    rm -f system_info.sh system_update.sh system_clean.sh system_tools.sh app_market.sh panel_tools.sh security.sh net_test.sh script_update.sh 2>/dev/null
    echo -e "${green}✅ 旧模块清理完成。${plain}"
    
    # ----------------------------------------------------
    # 更新主脚本
    # ----------------------------------------------------
    echo -e "${yellow}正在从 $SCRIPT_URL 更新 tool.sh 主脚本...${plain}"
    
    # SCRIPT_URL 必须在 tool.sh 中定义
    if command -v curl >/dev/null 2>&1 && curl -sSL "$SCRIPT_URL" -o tool.sh; then
        chmod +x tool.sh
        echo -e "${green}脚本更新成功！${plain}"
        echo -e "请使用 ${yellow}./tool.sh${plain} 重新运行，它将自动下载所有最新的依赖模块。"
        exit 0
    else
        echo -e "${red}❌ 更新失败，确认 SCRIPT_URL 与网络可达，且系统安装 curl${plain}"
    fi
    read -p "按回车返回菜单..." tmp
}
