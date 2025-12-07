#!/usr/bin/env bash
# =====================================================
# Linux 多功能工具箱 — 主体文件 1.5.3
# 负责：菜单、核心逻辑、自动检测、下载、验证并引入所有模块
# =====================================================

SCRIPT_VERSION="1.5.3"
SCRIPT_URL="https://zkxvip.github.io/tool.sh"
# 🚨 替换为您存放所有 .sh 文件的根目录
GITHUB_BASE_URL="https://zkxvip.github.io" 

# -------------------
# 颜色定义（保持不变）
# -------------------
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
blue="\033[36m"
plain="\033[0m"

# -------------------
# 检测包管理器（保持不变）
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
# 依赖文件列表（保持不变）
# -------------------
MODULE_FILES=(
    "system_info.sh"
    "system_update.sh"
    "system_clean.sh"
    "system_tools.sh"
    "app_market.sh"
    "panel_tools.sh"
    "security.sh"
    "net_test.sh"
    "script_update.sh"
)

# -------------------
# 依赖文件检查与下载/验证/引入 (核心逻辑修改)
# -------------------
check_and_download() {
    local filename="$1"
    local file_url="$GITHUB_BASE_URL/$filename"

    if [ ! -f "./$filename" ]; then
        echo -e "${yellow}检测到缺少依赖文件：$filename，正在尝试下载...${plain}"
        
        # 尝试下载文件到当前目录
        if ! curl -sL "$file_url" -o "./$filename"; then
            echo -e "${red}❌ $filename 下载失败，请检查 URL 或网络连接。${plain}"
            exit 1
        fi
        echo -e "${green}✅ $filename 下载成功!${plain}"
    fi

    # 验证文件内容是否为脚本（避免加载 HTML）
    if grep -qE '^(<!DOCTYPE html>|<html)' "./$filename"; then
        echo -e "${red}❌ ${filename} 文件验证失败！内容包含 HTML 标记。${plain}"
        echo -e "${red}这通常意味着 ${file_url} 地址返回了 404 错误页面。${plain}"
        rm -f "./$filename" # 删除无效文件
        exit 1
    fi
    
    # 引入文件
    echo -e "   正在引入 ${blue}$filename${plain}..."
    source "./$filename"
}

# 检查 curl 是否存在
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${red}错误: 脚本需要 'curl' 命令。请先安装 curl。${plain}"
    exit 1
fi

# 循环检查和引入所有模块
echo -e "${blue}===== 正在加载功能模块... =====${plain}"
for file in "${MODULE_FILES[@]}"; do
    check_and_download "$file"
done
echo -e "${green}所有模块加载完成。${plain}"

# -------------------
# 菜单（保持不变）
# -------------------
menu() {
    while true; do
        clear
        echo -e "${green}=============== Linux 多功能工具箱 ===============${plain}"
        echo -e "脚本版本：${yellow}$SCRIPT_VERSION${plain}"
        echo
        echo "1) 系统信息"
        echo "2) 系统更新"
        echo "3) 系统清理"
        echo "4) 系统工具"
        echo "5) 应用市场"
        echo "6) 面板工具"
        echo "7) 安全防御"
        echo "8) 网络测试"
        echo "9) 脚本更新"
        echo "0) 脚本退出"
        echo
        read -p "请输入数字回车：" choice

        case $choice in
            1) system_info_func ;;
            2) system_update_func ;;
            3) system_clean_func ;;
            4) system_tools_func ;;
            5) app_market_func ;;
            6) panel_tools_func ;;
            7) security_defense_func ;;
            8) net_test_func ;;
            9) script_update_func ;;
            0) echo -e "${green}退出。${plain}"; exit 0 ;;
            *) echo -e "${red}无效选择${plain}"; read -p "按回车..." tmp ;;
        esac
    done
}

# 启动菜单
menu
