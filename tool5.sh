#!/usr/bin/env bash
# =====================================================
# Linux 多功能工具箱 — 主体文件 1.5.2
# 负责：菜单、核心逻辑、文件引用 (新增自动下载依赖)
# =====================================================

SCRIPT_VERSION="1.5.2"
SCRIPT_URL="https://zkxvip.github.io/tool.sh"
# 🚨 请将此 URL 替换为您存放 system_info.sh 和 net_test.sh 文件的根目录
GITHUB_BASE_URL="https://zkxvip.github.io" 

# -------------------
# 颜色
# -------------------
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[36m"
plain="\033[0m"

# -------------------
# 检测包管理器（apt / dnf / yum）
# -------------------
detect_pkg_mgr() {
    if command -v apt >/dev/null 2>&1; then
        PKG="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG="yum"
    else
        PKG=""
    fi
}
detect_pkg_mgr

# -------------------
# 依赖文件检查与下载
# -------------------
# 检查 curl 是否存在
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${red}错误: 脚本需要 'curl' 命令。请先安装 curl。${plain}"
    exit 1
fi

check_and_download() {
    local filename="$1"
    local file_url="$GITHUB_BASE_URL/$filename"

    # 检查当前目录是否存在该文件
    if [ ! -f "./$filename" ]; then
        echo -e "${yellow}检测到缺少依赖文件：$filename，正在尝试下载...${plain}"
        
        # 尝试下载文件到当前目录
        if curl -sL "$file_url" -o "./$filename"; then
            echo -e "${green}✅ $filename 下载成功!${plain}"
        else
            echo -e "${red}❌ $filename 下载失败，请检查 GITHUB_BASE_URL 或网络连接。${plain}"
            exit 1
        fi
    fi
}

# -------------------
# 引入功能模块
# -------------------

# 步骤 1: 检查并下载 system_info.sh
check_and_download "system_info.sh"

# 步骤 2: 检查并下载 net_test.sh
check_and_download "net_test.sh"

# 步骤 3: 引入文件，加载函数
source ./system_info.sh
source ./net_test.sh


# -------------------
# 核心功能函数
# -------------------

# 脚本更新
update_script() {
    echo -e "${yellow}正在更新脚本...${plain}"
    if command -v curl >/dev/null 2>&1 && curl -sSL "$SCRIPT_URL" -o tool.sh; then
        chmod +x tool.sh
        echo -e "${green}脚本更新成功！使用 ./tool.sh 重新运行${plain}"
        exit 0
    else
        echo -e "${red}更新失败，确认 SCRIPT_URL 与网络可达，且系统安装 curl${plain}"
    fi
    read -p "按回车返回菜单..." tmp
}

# 系统清理
system_clean() {
    clear
    echo -e "${blue}===== 系统清理 =====${plain}"
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

# 系统工具
system_tools() {
    clear
    echo -e "${blue}===== 系统工具 (需提前安装) =====${plain}"
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

# 应用市场 (安装 Docker/Nginx/Node.js)
app_market() {
    clear
    echo -e "${blue}===== 应用市场（一键安装） =====${plain}"
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

# 面板工具
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

panel_tools() {
    clear
    echo -e "${blue}===== 面板工具 =====${plain}"
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

# 安全防御
security_defense() {
    clear
    echo -e "${blue}===== 安全防御与检测（占位符） =====${plain}"
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

# -------------------
# 菜单
# -------------------
menu() {
    while true; do
        clear
        echo -e "${green}=============== Linux 多功能工具箱 ===============${plain}"
        echo -e "脚本版本：${yellow}$SCRIPT_VERSION${plain}"
        echo
        echo "1) 系统信息 (增强版)"
        echo "2) 系统更新 (包管理器)"
        echo "3) 系统清理 (包管理器缓存)"
        echo "4) 系统工具 (htop/iftop 等)"
        echo "5) 应用市场 (Docker/Nginx/Node.js)"
        echo "6) 面板工具 (宝塔/1Panel)"
        echo "7) 安全防御 (登录/进程/Web攻击检查)"
        echo "8) 网络测试 (IP/域名/HTTP表格测试)"
        echo "9) 脚本更新"
        echo "0) 脚本退出"
        echo
        read -p "请输入数字回车：" choice

        case $choice in
            1) system_info ;;
            2)
                echo -e "${yellow}正在执行系统更新...${plain}"
                if [[ "$PKG" == "apt" ]]; then sudo apt update 2>/dev/null && sudo apt upgrade -y 2>/dev/null; 
                elif [[ "$PKG" == "dnf" || "$PKG" == "yum" ]]; then sudo $PKG upgrade -y 2>/dev/null; 
                else echo -e "${red}未识别包管理器，请手动更新${plain}"; fi
                echo -e "${green}系统更新尝试完成。${plain}"
                read -p "按回车返回菜单..." tmp ;;
            3) system_clean ;;
            4) system_tools ;;
            5) app_market ;;
            6) panel_tools ;;
            7) security_defense ;;
            8) test_ip_connect_table ;;
            9) update_script ;;
            0) echo -e "${green}退出。${plain}"; exit 0 ;;
            *) echo -e "${red}无效选择${plain}"; read -p "按回车..." tmp ;;
        esac
    done
}

# 启动菜单
menu
