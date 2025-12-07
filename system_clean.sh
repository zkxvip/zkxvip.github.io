# 文件名：system_clean.sh
# 包含：系统清理功能。
# 依赖：tool.sh 中的颜色变量和 PKG 变量

system_clean_func() {
    clear
    echo -e "${blue}===== 3. 系统清理 =====${plain}"
    if [[ "$PKG" == "apt" ]]; then
        echo -e "正在清理 APT 缓存和无用依赖..."
        sudo apt autoremove -y 2>/dev/null
        sudo apt clean 2>/dev/null
        echo -e "${green}APT 清理完成！${plain}"
    elif [[ "$PKG" == "dnf" || "$PKG" == "yum" ]]; then
        echo -e "正在清理 DNF/YUM 缓存和无用依赖..."
        sudo $PKG autoremove -y 2>/dev/null
        sudo $PKG clean all 2>/dev/null
        echo -e "${green}DNF/YUM 清理完成！${plain}"
    else
        echo -e "${red}未识别包管理器，请手动清理缓存${plain}"
    fi
    read -p "按回车返回菜单..." tmp
}
