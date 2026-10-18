#!/bin/bash
# HU501 地面站 目标机一键安装脚本
# 用法: 将 dist/ 目录整体拷到对方电脑后执行:
#   bash install-hu501.sh
# 功能: 配置 ROS2 apt 源(已配则跳过) -> apt 安装 hu501-gcs_*_amd64.deb
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROS_MIRROR="${ROS_MIRROR:-https://mirrors.ustc.edu.cn/ros2/ubuntu}"
ROS_LIST=/etc/apt/sources.list.d/ros2-latest.list
KEYRING_SRC="$HERE/ros-archive-keyring.gpg"
KEYRING_DST=/usr/share/keyrings/ros-archive-keyring.gpg

log()  { echo -e "\e[32m[install]\e[0m $*"; }
warn() { echo -e "\e[33m[install]\e[0m $*" >&2; }
die()  { echo -e "\e[31m[install] 错误:\e[0m $*" >&2; exit 1; }

[ "$(uname -m)" = "x86_64" ] || die "本包仅支持 amd64 (x86_64) 电脑"
grep -q "Ubuntu 24.04" /etc/os-release || warn "检测到非 Ubuntu 24.04 系统, 安装可能失败(仅支持 24.04 + ROS2 Jazzy)"

DEB="$(ls "$HERE"/hu501-gcs_*_amd64.deb 2>/dev/null | sort -V | tail -1 || true)"
[ -n "$DEB" ] || die "未在 $HERE 找到 hu501-gcs_*_amd64.deb, 请将 deb 与本脚本放在同一目录"

if [ "$(id -u)" -ne 0 ]; then
    log "需要 root 权限, 切换 sudo..."
    exec sudo bash "$0" "$@"
fi

# ---------- 1. universe 仓库(webkit等依赖在universe) ----------
if command -v add-apt-repository >/dev/null; then
    add-apt-repository -y universe >/dev/null 2>&1 || true
fi

# ---------- 2. ROS2 apt 源 ----------
if [ -f "$KEYRING_SRC" ]; then
    install -m 644 "$KEYRING_SRC" "$KEYRING_DST"
elif [ -f "$KEYRING_DST" ]; then
    log "系统已有 ROS 密钥, 沿用"
else
    log "本地无 ros-archive-keyring.gpg, 在线获取官方密钥..."
    needs=""
    command -v curl >/dev/null || needs="$needs curl"
    command -v gpg  >/dev/null || needs="$needs gnupg"
    [ -z "$needs" ] || apt-get install -y $needs
    curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
        | gpg --dearmor -o "$KEYRING_DST" \
        || die "密钥获取失败(网络受限?), 请手动配置 ROS2 源后重试"
fi

if ! grep -rq "ros2/ubuntu" /etc/apt/sources.list.d/ 2>/dev/null; then
    log "配置 ROS2 apt 源 ($ROS_MIRROR)..."
    cat > "$ROS_LIST" <<EOF
deb [arch=amd64 signed-by=$KEYRING_DST] $ROS_MIRROR noble main
EOF
    # 国内官方源备用(注释形式写入供切换)
    echo "#deb [arch=amd64 signed-by=$KEYRING_DST] http://packages.ros.org/ros2/ubuntu noble main" >> "$ROS_LIST"
else
    log "ROS2 apt 源已配置, 跳过"
fi

# ---------- 3. 安装 ----------
log "apt update (首次需下载 ROS 依赖, 视网速可能 10 分钟以上)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
log "安装 $DEB ..."
apt-get install -y "$DEB"

log "安装完成。在应用菜单搜索 'HU501 地面站' 启动, 或终端运行 hu501"
log "串口权限(连船必做): sudo usermod -aG dialout \$USER 然后注销重登"
