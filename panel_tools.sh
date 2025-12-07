# 文件名：panel_tools.sh
# 包含：宝塔/1Panel 安装脚本。
# 依赖：tool.sh 中的颜色变量

install_bt() {
    echo -e "${yellow}正在安装宝塔面板...${plain}"
    if command -v curl >/dev/null 2>&1; then
        curl -sSO https://download.bt.cn/install/install_panel.sh 2>/dev/null && bash install_panel.sh
    else
        echo -e "${red}错误：请先安装 curl。${plain}"
    fi
}

install_1panel() {
    echo -e "${yellow}正在安装 1Panel...${plain}"
    if command -v curl >/dev/null 2>&1; then
        curl -sSL https://resource.fit2cloud.com/1panel/install.sh 2>/dev/null | bash
    else
        echo -e "${red}错误：请先安装 curl。${plain}"
    fi
}

panel_tools_func() {
    clear
    echo -e "${blue}===== 6. 面板工具 =====${plain}"
    echo "1) 安装 宝塔面板 (BT)"
    echo "2) 安装 1Panel (下一代 Linux 面板)"
    echo "3) 返回菜单"
    echo
    read -p "请选择：" p
    case $p in
        1) install_bt ;;
        2) install_1panel ;;
        *) ;;
    esac
    read -p "按回车返回菜单..." tmp
}
