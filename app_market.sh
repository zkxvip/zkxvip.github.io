# 文件名：app_market.sh
# 包含：一键安装 Docker/Nginx/Node.js 等应用。
# 依赖：tool.sh 中的颜色变量和 PKG 变量

app_market_func() {
    clear
    echo -e "${blue}===== 5. 应用市场（一键安装） =====${plain}"
    echo "1) Docker (容器化)"
    echo "2) Nginx (Web服务器)"
    echo "3) Node.js (v18 LTS)"
    echo "4) 返回菜单"
    echo
    read -p "请选择：" a
    case $a in
        1) 
            echo -e "${yellow}正在安装 Docker...${plain}"
            if [[ "$PKG" == "apt" ]]; then sudo apt update && sudo apt install -y docker.io 2>/dev/null; 
            else sudo $PKG install -y docker 2>/dev/null; fi
            echo -e "${green}Docker 安装尝试完成。${plain}" ;;
        2) 
            echo -e "${yellow}正在安装 Nginx...${plain}"
            sudo $PKG install -y nginx 2>/dev/null
            echo -e "${green}Nginx 安装尝试完成。${plain}" ;;
        3) 
            echo -e "${yellow}正在安装 Node.js (v18 LTS)...${plain}"
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash - 2>/dev/null && sudo apt install -y nodejs 2>/dev/null
            else
                echo -e "${red}错误：请先安装 curl。${plain}"
            fi
            echo -e "${green}Node.js 安装尝试完成。${plain}" ;;
        *) ;;
    esac
    read -p "按回车返回菜单..." tmp
}
