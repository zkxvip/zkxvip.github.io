# 文件名：system_update.sh
# 包含：系统更新功能。
# 依赖：tool.sh 中的颜色变量和 PKG 变量

system_update_func() {
    clear
    echo -e "${blue}===== 2. 系统更新 =====${plain}"
    echo -e "${yellow}正在执行系统更新...${plain}"
    if [[ "$PKG" == "apt" ]]; then 
        sudo apt update 2>/dev/null && sudo apt upgrade -y 2>/dev/null
    elif [[ "$PKG" == "dnf" || "$PKG" == "yum" ]]; then 
        sudo $PKG upgrade -y 2>/dev/null
    else 
        echo -e "${red}未识别包管理器，请手动更新${plain}"
    fi
    echo -e "${green}系统更新尝试完成。${plain}"
    read -p "按回车返回菜单..." tmp
}
