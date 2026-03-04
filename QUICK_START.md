# 快速部署到 N2830 机器人

## 🚀 快速开始（3 步完成）

### 第一步：打包项目

```bash
# 在当前机器上打包
cd d:\oci-start-master
mvn clean package -DskipTests

# 确认 JAR 文件已生成
ls -lh oci-server/target/oci-server.jar
```

### 第二步：传输文件

**方式 A：使用自动化部署脚本（推荐）**

```bash
# 赋予执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh <机器人IP> [用户名]

# 示例
./deploy.sh 192.168.1.100 root
```

**方式 B：手动传输**

```bash
# 创建远程目录
ssh root@机器人IP "mkdir -p /root/oci-start/logs /root/oci-start/data /root/oci-start/keys"

# 传输文件
scp oci-server/target/oci-server.jar root@机器人IP:/root/oci-start/
scp oci-server/src/main/resources/oci-start.properties root@机器人IP:/root/oci-start/
scp oci-start-low-spec.sh root@机器人IP:/root/oci-start/oci-start.sh

# 传输密钥文件
scp /path/to/your/key.pem root@机器人IP:/root/oci-start/keys/
```

### 第三步：配置并启动

```bash
# SSH 登录到机器人
ssh root@机器人IP

# 进入目录
cd /root/oci-start

# 编辑配置文件
vim oci-start.properties

# 配置 OCI 账户信息
# 配置密钥文件路径
# 配置 Telegram 通知（可选）

# 设置密钥文件权限
chmod 600 keys/*.pem

# 赋予启动脚本执行权限
chmod +x oci-start.sh

# 启动应用
./oci-start.sh
```

## ✅ 验证部署

```bash
# 检查进程
ps aux | grep oci-server

# 检查端口
netstat -tlnp | grep 9856

# 查看日志
tail -f logs/application.log

# 测试 Web 访问
curl http://localhost:9856
# 或在浏览器中访问 http://机器人IP:9856
```

## 📋 配置文件示例

**oci-start.properties**:
```properties
# 用户 1
oracle.users.user1.userId=ocid1.user.oc1...
oracle.users.user1.userName=user1
oracle.users.user1.fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
oracle.users.user1.tenancy=ocid1.tenancy.oc1...
oracle.users.user1.region=ap-tokyo-1
oracle.users.user1.keyFile=/root/oci-start/keys/user1.pem
oracle.users.user1.ocpus=1
oracle.users.user1.memory=1
oracle.users.user1.disk=50
oracle.users.user1.architecture=AMD
oracle.users.user1.operationSystem=Ubuntu
oracle.users.user1.interval=60
oracle.users.user1.rootPassword=yourpassword
```

## 🔧 常用命令

```bash
# 启动
./oci-start.sh

# 停止
pkill -f "oci-server.jar"

# 重启
pkill -f "oci-server.jar" && sleep 5 && ./oci-start.sh

# 查看日志
tail -f logs/application.log

# 查看进程状态
ps aux | grep oci-server

# 查看内存使用
free -h
```

## 📊 预期性能

在 N2830 + 4GB RAM 机器上：

- **内存占用**: 300-500MB
- **CPU 使用率**: 30-50%
- **线程数**: 4-6 个
- **响应时间**: 3-8 秒

## 🐛 常见问题

### 问题 1: 内存不足

```bash
# 降低 JVM 堆内存
# 编辑启动脚本，将 -Xmx512m 改为 -Xmx384m
```

### 问题 2: 端口被占用

```bash
# 检查端口占用
netstat -tlnp | grep 9856

# 杀死占用进程
kill -9 <PID>
```

### 问题 3: 启动失败

```bash
# 查看启动日志
cat logs/startup.log

# 检查 Java 版本
java -version

# 检查配置文件
cat oci-start.properties
```

## 📞 获取帮助

- **详细部署指南**: [DEPLOYMENT_GUIDE.md](file:///d:/oci-start-master/DEPLOYMENT_GUIDE.md)
- **优化指南**: [LOW_SPEC_OPTIMIZATION.md](file:///d:/oci-start-master/LOW_SPEC_OPTIMIZATION.md)
- **应用日志**: `logs/application.log`
- **启动日志**: `logs/startup.log`

## 🎯 下一步

部署完成后：

1. ✅ 访问 Web 界面：http://机器人IP:9856
2. ✅ 配置 OCI 账户信息
3. ✅ 开始创建实例
4. ✅ 接收 Telegram 通知（如果配置了）

---

**提示**: 如果遇到问题，请查看日志文件或参考详细部署指南。