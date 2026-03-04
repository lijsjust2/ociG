# OCI-Start 部署到 N2830 机器人完整指南

## 📋 部署前准备

### 1. 确认 N2830 机器人环境

**硬件配置**:
- 处理器: Intel Celeron N2830 (双核四线程)
- 内存: 4GB RAM
- 操作系统: Linux (建议 Ubuntu 20.04+ 或 Debian 11+)

**检查系统信息**:
```bash
# 查看处理器信息
cat /proc/cpuinfo | grep "model name"

# 查看内存信息
free -h

# 查看磁盘空间
df -h

# 查看 Java 版本
java -version
```

### 2. 安装必要软件

**安装 Java 8+**:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y openjdk-8-jdk

# CentOS/RHEL
sudo yum install -y java-1.8.0-openjdk

# 验证安装
java -version
```

**安装 Maven** (如果需要在机器人上编译):
```bash
# Ubuntu/Debian
sudo apt install -y maven

# CentOS/RHEL
sudo yum install -y maven
```

**安装其他工具**:
```bash
# 安装必要工具
sudo apt install -y wget curl vim git

# 安装 screen (用于后台运行)
sudo apt install -y screen
```

## 📦 第一步：打包项目

### 方式一：在当前机器打包（推荐）

**1. 在 Windows/Mac 机器上打包**:
```bash
# 进入项目根目录
cd d:\oci-start-master

# 清理并打包
mvn clean package -DskipTests

# 打包完成后，JAR 文件位置
# oci-server/target/oci-server.jar
```

**2. 验证打包结果**:
```bash
# 检查 JAR 文件是否存在
ls -lh oci-server/target/oci-server.jar

# 应该看到类似输出：
# -rwxr-xr-x 1 user user 50M Jan 15 10:30 oci-server/target/oci-server.jar
```

### 方式二：在 N2830 机器人上直接编译

**1. 复制整个项目到机器人**:
```bash
# 使用 scp 复制项目
scp -r d:\oci-start-master user@n2830-ip:/home/user/

# 或使用 rsync
rsync -avz d:\oci-start-master/ user@n2830-ip:/home/user/oci-start-master/
```

**2. 在机器人上编译**:
```bash
# SSH 登录到机器人
ssh user@n2830-ip

# 进入项目目录
cd /home/user/oci-start-master

# 编译项目
mvn clean package -DskipTests

# 编译完成后，JAR 文件位置
# oci-server/target/oci-server.jar
```

## 📤 第二步：传输文件到 N2830 机器人

### 准备传输的文件

**必需文件**:
```
oci-start-master/
├── oci-server/target/oci-server.jar          # 主程序 JAR 文件
├── oci-server/src/main/resources/oci-start.properties  # 配置文件
├── oci-start-low-spec.sh                     # 优化启动脚本
├── oci-start-low-spec.bat                   # Windows 启动脚本（可选）
└── LOW_SPEC_OPTIMIZATION.md                 # 优化指南（可选）
```

### 使用 SCP 传输

**从 Windows 传输**:
```cmd
REM 使用 PowerShell 或 Git Bash
scp oci-server/target/oci-server.jar user@n2830-ip:/home/user/oci-start/
scp oci-server/src/main/resources/oci-start.properties user@n2830-ip:/home/user/oci-start/
scp oci-start-low-spec.sh user@n2830-ip:/home/user/oci-start/
```

**从 Linux/Mac 传输**:
```bash
scp oci-server/target/oci-server.jar user@n2830-ip:/home/user/oci-start/
scp oci-server/src/main/resources/oci-start.properties user@n2830-ip:/home/user/oci-start/
scp oci-start-low-spec.sh user@n2830-ip:/home/user/oci-start/
```

### 使用 SFTP 传输

```bash
# 连接到机器人
sftp user@n2830-ip

# 创建目录
mkdir /home/user/oci-start

# 上传文件
put oci-server/target/oci-server.jar /home/user/oci-start/
put oci-server/src/main/resources/oci-start.properties /home/user/oci-start/
put oci-start-low-spec.sh /home/user/oci-start/

# 退出
exit
```

### 使用 Git 传输（推荐）

```bash
# 在机器人上克隆项目
ssh user@n2830-ip
cd /home/user
git clone <你的仓库地址> oci-start-master

# 或者使用你修改后的项目
# 先将修改后的项目推送到 GitHub/Gitee
# 然后在机器人上拉取
```

## ⚙️ 第三步：在 N2830 上配置

### 1. 创建工作目录

```bash
# SSH 登录到机器人
ssh user@n2830-ip

# 创建工作目录
mkdir -p /home/user/oci-start
mkdir -p /home/user/oci-start/logs
mkdir -p /home/user/oci-start/data

# 进入工作目录
cd /home/user/oci-start
```

### 2. 配置 OCI 账户信息

**编辑配置文件**:
```bash
vim oci-start.properties
```

**配置示例**:
```properties
# 第一个用户
oracle.users.user1.userId=ocid1.user.oc1...
oracle.users.user1.userName=user1
oracle.users.user1.fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
oracle.users.user1.tenancy=ocid1.tenancy.oc1...
oracle.users.user1.region=ap-tokyo-1
oracle.users.user1.keyFile=/home/user/oci-start/keys/user1.pem
oracle.users.user1.ocpus=1
oracle.users.user1.memory=1
oracle.users.user1.disk=50
oracle.users.user1.architecture=AMD
oracle.users.user1.operationSystem=Ubuntu
oracle.users.user1.interval=60
oracle.users.user1.rootPassword=yourpassword

# 第二个用户（可选）
oracle.users.user2.userId=ocid1.user.oc1...
oracle.users.user2.userName=user2
oracle.users.user2.fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
oracle.users.user2.tenancy=ocid1.tenancy.oc1...
oracle.users.user2.region=ap-osaka-1
oracle.users.user2.keyFile=/home/user/oci-start/keys/user2.pem
oracle.users.user2.ocpus=1
oracle.users.user2.memory=1
oracle.users.user2.disk=50
oracle.users.user2.architecture=AMD
oracle.users.user2.operationSystem=Ubuntu
oracle.users.user2.interval=60
oracle.users.user2.rootPassword=yourpassword
```

### 3. 上传 OCI 密钥文件

```bash
# 创建密钥目录
mkdir -p /home/user/oci-start/keys

# 上传密钥文件
scp /path/to/your/key.pem user@n2830-ip:/home/user/oci-start/keys/

# 设置密钥文件权限
chmod 600 /home/user/oci-start/keys/*.pem
```

### 4. 配置 Telegram 通知（可选）

如果需要 Telegram 通知，需要配置 Telegram Bot Token 和 Chat ID：

**查找配置文件中的 Telegram 配置**:
```bash
# 搜索相关配置
grep -r "telegram" /home/user/oci-start/
```

**配置 Telegram**（根据项目实际情况）:
```properties
# Telegram Bot 配置
telegram.bot.token=your_bot_token
telegram.chat.id=your_chat_id
```

## 🚀 第四步：启动应用

### 方式一：使用优化启动脚本（推荐）

```bash
# 进入工作目录
cd /home/user/oci-start

# 赋予执行权限
chmod +x oci-start-low-spec.sh

# 启动应用
./oci-start-low-spec.sh
```

### 方式二：使用 screen 后台运行

```bash
# 创建 screen 会话
screen -S oci-start

# 启动应用
java -Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -jar oci-server.jar

# 按 Ctrl+A 然后按 D 分离会话

# 重新连接到会话
screen -r oci-start
```

### 方式三：使用 nohup 后台运行

```bash
# 启动应用
nohup java -Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -jar oci-server.jar > logs/startup.log 2>&1 &

# 保存进程 ID
echo $! > oci-start.pid

# 查看日志
tail -f logs/application.log
```

### 方式四：使用 systemd 服务（推荐长期运行）

**创建服务文件**:
```bash
sudo vim /etc/systemd/system/oci-start.service
```

**服务配置**:
```ini
[Unit]
Description=OCI-Start Service
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/home/user/oci-start
ExecStart=/usr/bin/java -Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -jar /home/user/oci-start/oci-server.jar
Restart=always
RestartSec=10
StandardOutput=append:/home/user/oci-start/logs/application.log
StandardError=append:/home/user/oci-start/logs/error.log

[Install]
WantedBy=multi-user.target
```

**启动服务**:
```bash
# 重载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start oci-start

# 设置开机自启
sudo systemctl enable oci-start

# 查看服务状态
sudo systemctl status oci-start

# 查看日志
sudo journalctl -u oci-start -f
```

## ✅ 第五步：验证部署

### 1. 检查进程状态

```bash
# 查看进程
ps aux | grep oci-server

# 应该看到类似输出：
# user  12345  2.0  5.0  500000 200000 ?  Sl   10:30   0:05 java -Xms256m -Xmx512m -XX:+UseG1GC -jar oci-server.jar
```

### 2. 检查端口监听

```bash
# 检查端口 9856 是否监听
netstat -tlnp | grep 9856

# 或使用 ss 命令
ss -tlnp | grep 9856

# 应该看到类似输出：
# tcp  0  0  0.0.0.0:9856  0.0.0.0:*  LISTEN  12345/java
```

### 3. 检查日志

```bash
# 查看应用日志
tail -f /home/user/oci-start/logs/application.log

# 查看启动日志
cat /home/user/oci-start/logs/startup.log

# 应该看到类似输出：
# INFO  - OCI-Start application started successfully
# INFO  - Initialized 2 user tasks
```

### 4. 检查内存使用

```bash
# 查看系统内存
free -h

# 查看进程内存
ps aux | grep oci-server | awk '{print $6}' | awk '{sum+=$1} END {print "Total Memory: " sum/1024 " MB"}'

# 应该看到内存使用在 300-500MB 之间
```

### 5. 测试 Web 访问

```bash
# 在浏览器中访问
http://n2830-ip:9856

# 或使用 curl 测试
curl http://localhost:9856

# 应该看到 HTML 响应
```

## 📊 第六步：监控运行状态

### 实时监控脚本

创建监控脚本 `monitor.sh`:
```bash
#!/bin/bash

echo "=== OCI-Start 监控 ==="
echo ""

# 检查进程
if pgrep -f "oci-server.jar" > /dev/null; then
    echo "✓ 进程运行中"
    ps aux | grep "oci-server.jar" | grep -v grep
else
    echo "✗ 进程未运行"
fi

echo ""

# 检查内存
echo "=== 内存使用 ==="
free -h

echo ""

# 检查端口
echo "=== 端口监听 ==="
netstat -tlnp | grep 9856 || echo "✗ 端口 9856 未监听"

echo ""

# 检查最近日志
echo "=== 最近日志 ==="
tail -n 10 /home/user/oci-start/logs/application.log
```

**使用监控脚本**:
```bash
chmod +x monitor.sh
./monitor.sh
```

## 🔧 常用管理命令

### 启动/停止/重启

```bash
# 启动
./oci-start-low-spec.sh

# 停止
pkill -f "oci-server.jar"

# 重启
pkill -f "oci-server.jar"
sleep 5
./oci-start-low-spec.sh
```

### 查看日志

```bash
# 实时查看日志
tail -f logs/application.log

# 查看最近 100 行
tail -n 100 logs/application.log

# 搜索错误日志
grep -i "error" logs/application.log

# 搜索警告日志
grep -i "warn" logs/application.log
```

### 检查状态

```bash
# 检查进程
ps aux | grep oci-server

# 检查端口
netstat -tlnp | grep 9856

# 检查内存
free -h
```

## 🐛 故障排查

### 问题 1: 启动失败

**检查步骤**:
```bash
# 1. 检查 Java 版本
java -version

# 2. 检查端口占用
netstat -tlnp | grep 9856

# 3. 查看启动日志
cat logs/startup.log

# 4. 检查配置文件
cat oci-start.properties
```

### 问题 2: 内存不足

**解决方法**:
```bash
# 1. 检查系统内存
free -h

# 2. 降低 JVM 堆内存
# 修改启动脚本中的 -Xmx512m 为 -Xmx384m

# 3. 关闭其他应用
# 释放更多内存给 OCI-Start
```

### 问题 3: 无法访问 Web 界面

**检查步骤**:
```bash
# 1. 检查端口监听
netstat -tlnp | grep 9856

# 2. 检查防火墙
sudo ufw status
sudo firewall-cmd --list-all

# 3. 检查应用日志
tail -f logs/application.log

# 4. 测试本地访问
curl http://localhost:9856
```

### 问题 4: 实例创建失败

**检查步骤**:
```bash
# 1. 检查配置文件
cat oci-start.properties

# 2. 检查密钥文件权限
ls -la keys/

# 3. 查看应用日志
tail -f logs/application.log

# 4. 检查 OCI 配额
# 登录 OCI 控制台查看配额
```

## 📋 部署检查清单

- [ ] 确认 N2830 机器人环境（Java 8+, 4GB RAM）
- [ ] 打包项目生成 oci-server.jar
- [ ] 传输 JAR 文件到机器人
- [ ] 传输配置文件到机器人
- [ ] 上传 OCI 密钥文件
- [ ] 配置 oci-start.properties
- [ ] 配置 Telegram 通知（可选）
- [ ] 赋予启动脚本执行权限
- [ ] 启动应用
- [ ] 验证进程运行状态
- [ ] 验证端口监听
- [ ] 验证 Web 访问
- [ ] 设置开机自启（可选）
- [ ] 配置监控脚本（可选）

## 🎯 总结

按照以上步骤，你应该能够成功将优化后的 OCI-Start 部署到 N2830 机器人上。关键点：

1. **使用优化配置** - 确保使用针对低配机器优化的配置
2. **监控资源使用** - 定期检查内存和 CPU 使用情况
3. **查看日志** - 及时发现和解决问题
4. **设置开机自启** - 使用 systemd 确保服务稳定运行

如有问题，请查看日志文件或参考故障排查部分。