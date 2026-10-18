# HU501 地面站 安装使用说明（发给使用者的文档）

## 一、环境要求

- Ubuntu 24.04 桌面版（amd64，普通PC/笔记本）
- 网络连接（首次安装需下载 ROS2 依赖约 300~500MB；**使用时地图也需联网**，国内直连即可无需翻墙）
- 磁盘剩余空间 ≥ 3GB

## 二、安装（二选一）

> **⚠️ 千万不要用 `sudo dpkg -i xxx.deb` 安装！** dpkg 不会安装依赖（ROS2、WebKit、flask 等），装出来必然是坏的（打开报错/功能异常）。请用下面的方式安装。

### 方式A：一键脚本（推荐）

把整个 dist 文件夹拷到对方电脑，在文件夹里打开终端：

```bash
bash install-hu501.sh
```

脚本自动配置 ROS2 国内镜像源并安装，全程无需其他操作。

### 方式B：手动

```bash
# 1. 配置ROS2源(已配过可跳过)
sudo apt install software-properties-common
sudo add-apt-repository universe
sudo apt update && sudo apt install curl gnupg
sudo curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] https://mirrors.ustc.edu.cn/ros2/ubuntu noble main" | sudo tee /etc/apt/sources.list.d/ros2.list

# 2. 安装
sudo apt update
sudo apt install ./hu501-gcs_*_amd64.deb
```

## 三、使用

1. 应用菜单搜索 **HU501 地面站** 点击启动（或终端输入 `hu501`）
2. 启动后先显示约 5 秒背景图（加载画面），随后自动进入地图主界面
3. 软件自动一键启动：地图界面 + 后端 + MPC 控制 + 串口 + 摄像头收流，**关闭窗口即全部停止**
4. 不连船也可以打开：看地图、放虚拟障碍、测避障逻辑；控制节点未连硬件时自动空转，属正常
5. **首次连串口设备需授权**（执行一次，重新登录生效）：
   ```bash
   sudo usermod -aG dialout $USER
   ```
6. 树莓派摄像头：与之前一致，船端运行 `cam_start.sh` 发流，本机自动在网页显示
7. 键盘手动操控（可选，需终端）：
   ```bash
   source /opt/hu501/setup.bash && ros2 run keyboard_controller keyboard_node
   ```

### 日志与排障

各组件日志都在 `~/.cache/hu501/` 下：
- `gaode_node.log` 网页后端 ｜ `mpc_node.log` MPC控制 ｜ `serial1_node.log` 串口 ｜ `cam_node.log` 摄像头
- 窗口空白/打不开：先看后端日志；确认 5000 端口未被占用（`ss -ltnp | grep 5000`）
- 地图瓦片加载慢：属外网问题，数据面板不受影响
- 软件窗口已强制忽略系统代理（直连）；若用浏览器访问 `http://127.0.0.1:5000` 时地图异常，请关闭浏览器/系统代理（梯子会拦截高德和本地连接）

## 四、可选：AI 视觉检测

需要 yolov 目标检测时（约1GB下载）：

```bash
sudo /opt/hu501/bin/hu501-install-ai
```

## 五、卸载

```bash
sudo apt remove hu501-gcs      # 软件整体移除, 不留系统残留
```

## 六、二次开发/命令行进阶

```bash
source /opt/hu501/setup.bash
ros2 run mpc_controller mpc_node        # 可单独运行任意节点
ros2 topic list                         # 查看话题
ros2 run keyboard_controller keyboard_node  # 键盘手动操控
```
