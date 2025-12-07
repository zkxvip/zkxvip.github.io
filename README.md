# 🛠️ Linux 多功能工具箱 (tool.sh)

[![GitHub license](https://img.shields.io/github/license/zkxvip/tool.sh?style=flat-square)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zkxvip/tool.sh?style=flat-square)](https://github.com/zkxvip/tool.sh/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/zkxvip/tool.sh?style=flat-square)](https://github.com/zkxvip/tool.sh/network)

一个专为 Linux 服务器设计的**多功能集成工具箱**，集成了系统信息查看、资源清理、常用工具安装、面板管理、安全检测等功能。旨在提供一站式的服务器日常维护和管理解决方案，支持主流 Linux 发行版（如 Debian, Ubuntu, CentOS, RHEL 等）。

---

## 🚀 一键运行 (推荐)

此脚本支持**非交互式**的一键运行，脚本会先下载核心文件并自动加载所有模块。

> **注意：** 首次运行时，脚本会自动下载所有依赖模块 (`*.sh` 文件) 到当前目录。

```bash
[root@YourServer ~]# bash <(curl -sL [https://zkxvip.github.io/tool.sh](https://zkxvip.github.io/tool.sh))

离线运行 / 已下载用户
如果您已经将 tool.sh 文件下载到本地，可以直接运行：

[root@YourServer ~]# chmod +x tool.sh
[root@YourServer ~]# ./tool.sh

✨ 功能列表
当前工具箱版本：1.5.3。功能模块化设计，易于扩展和维护。

💻 系统管理 (System)
1) 系统信息 (System Info)：查看主机名称、内核、CPU、内存、硬盘、负载状态、网络信息等。

2) 系统更新 (System Update)：一键更新系统软件包。

3) 系统清理 (System Clean)：清理软件包缓存、日志文件等，释放磁盘空间。

4) 系统工具 (System Tools)：快速安装和配置常用的系统诊断工具（例如 htop, iperf, net-tools 等）。

🔒 安全与网络 (Security & Net)
7) 安全防御 (Security Defense)：

查看 SSH 登录失败日志。

检查高 CPU/内存占用恶意进程。

Web 攻击日志查询 (基于常见 SQLi/XSS/LFI 关键字，需手动输入日志路径)。

查看当前已建立的网络连接。

统计连接数最多的远程 IP (Top 20)。

8) 网络测试 (Net Test)：集成常用网络连通性测试和测速工具。

⚙️ 应用与维护 (App & Maintenance)
5) 应用市场 (App Market)：常用服务的快速安装脚本（例如 Docker, Git, Nginx 等）。

6) 面板工具 (Panel Tools)：集成主流面板（如宝塔、1Panel）的快捷操作或安装。

9) 修复更新 (Fix Update)：彻底清理本地所有旧的模块文件，并重新下载主脚本，用于修复因下载错误导致的模块加载失败问题。

文件名,对应功能,描述
tool.sh,主体,菜单展示、依赖检测、模块加载核心逻辑。
system_info.sh,1) 系统信息,负责所有硬件和系统状态信息采集。
security.sh,7) 安全防御,负责安全日志分析和网络连接统计。
script_update.sh,9) 修复更新,负责脚本的自我清理和更新。
(其他模块),"2, 3, 4, 5, 6, 8",对应其他功能菜单项。

🤝 贡献与反馈
欢迎所有形式的贡献，无论是功能建议、Bug 报告还是代码改进！

Fork 本仓库。

创建您的功能分支 (git checkout -b feature/AmazingFeature)。

提交您的更改 (git commit -m 'Add some AmazingFeature')。

推送到分支 (git push origin feature/AmazingFeature)。

创建一个 Pull Request。

许可证
本项目使用 MIT 许可证。详见 LICENSE 文件。
