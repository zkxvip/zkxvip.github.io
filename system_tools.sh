# 文件名：system_tools.sh
# 包含：系统工具安装和运行菜单。
# 依赖：tool.sh 中的颜色变量和 PKG 变量

system_tools_func() {
    clear
    echo -e "${blue}===== 4. 系统工具 (需提前安装) =====${plain}"
    echo "1) htop (高级任务管理器)"
    echo "2) iftop (实时带宽监控)"
    echo "3) vnstat (网络流量统计)"
    echo "4) 返回菜单"
    echo
    read -p "请选择：" t
    case $t in
        1) $PKG && sudo $PKG install -y htop >/dev/null 2>&1; command -v htop >/dev/null 2>&1 && htop || echo -e "${red}请先安装 htop。${plain}";;
        2) $PKG && sudo $PKG install -y iftop >/dev/null 2>&1; command -v iftop >/dev/null 2>&1 && iftop || echo -e "${red}请先安装 iftop。${plain}";;
        3) $PKG && sudo $PKG install -y vnstat >/dev/null 2>&1; command -v vnstat >/dev/null 2>&1 && vnstat || echo -e "${red}请先安装 vnstat。${plain}";;
        *) ;;
    esac
    read -p "按回车返回菜单..." tmp
}
