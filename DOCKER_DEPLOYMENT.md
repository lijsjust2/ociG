# OCI-Start Docker 部署指南 (AMD64)

## 📋 目录

- [使用 GitHub Actions 构建 Docker 镜像](#使用-github-actions-构建-docker-镜像)
- [在 NAS 上部署](#在-nas-上部署)
- [配置说明](#配置说明)
- [常用命令](#常用命令)
- [故障排查](#故障排查)

---

## 🚀 使用 GitHub Actions 构建 Docker 镜像

### 方式一：手动触发构建（推荐）

1. **进入 GitHub Actions 页面**
   - 打开你的 GitHub 仓库
   - 点击 "Actions" 标签
   - 选择 "Build Docker Image (AMD64)" 工作流

2. **点击 "Run workflow"**
   - 输入构建版本（默认：latest）
   - 选择是否创建 GitHub Release（默认：false）
   - 点击 "Run workflow" 按钮

3. **等待构建完成**
   - 构建过程大约需要 3-5 分钟（仅 AMD64）
   - 构建完成后，可以在 "Artifacts" 部分下载镜像

4. **下载 Docker 镜像**
   - 点击构建任务中的 "Artifacts"
   - 下载 `docker-image-amd64-latest`（或指定版本）
   - 解压后得到：`oci-start-amd64-latest.tar`

### 方式二：自动触发构建

当以下事件发生时，会自动触发构建：
- 推送到 `main` 或 `master` 分支
- 创建 Pull Request 到 `main` 或 `master` 分支

### 方式三：创建 Release

1. **触发构建并创建 Release**
   - 在 "Run workflow" 时，勾选 "create_release"
   - 输入版本号（如：1.0.0）
   - 点击 "Run workflow"

2. **下载 Release**
   - 构建完成后，会自动创建 GitHub Release
   - 在 "Releases" 页面可以下载对应版本的镜像

---

## 📦 在 NAS 上部署

### 前提条件

- NAS 支持 Docker（Synology DSM、QTS、TrueNAS 等）
- NAS 架构为 x86_64（AMD64）
- 至少 1GB 可用内存（推荐 2GB+）
- 至少 2GB 可用磁盘空间

### 部署步骤

#### 第一步：准备文件

1. **创建工作目录**
   ```bash
   # SSH 登录到 NAS
   ssh user@nas-ip
   
   # 创建工作目录
   mkdir -p /volume1/docker/oci-start
   cd /volume1/docker/oci-start
   
   # 创建子目录
   mkdir -p data logs keys
   ```

2. **传输 Docker 镜像**
   ```bash
   # 在本地机器上，将镜像传输到 NAS
   scp oci-start-amd64-latest.tar user@nas-ip:/volume1/docker/oci-start/
   
   # 或使用 NAS 的文件管理器上传
   ```

3. **传输配置文件**
   ```bash
   # 复制配置文件模板
   cp oci-server/src/main/resources/oci-start.properties /volume1/docker/oci-start/data/
   
   # 或传输到 NAS
   scp oci-server/src/main/resources/oci-start.properties user@nas-ip:/volume1/docker/oci-start/data/
   ```

4. **传输密钥文件**
   ```bash
   # 传输 OCI 密钥文件
   scp /path/to/your/key.pem user@nas-ip:/volume1/docker/oci-start/keys/
   
   # 设置密钥文件权限
   ssh user@nas-ip "chmod 600 /volume1/docker/oci-start/keys/*.pem"
   ```

#### 第二步：加载 Docker 镜像

```bash
# SSH 登录到 NAS
ssh user@nas-ip

# 进入工作目录
cd /volume1/docker/oci-start

# 加载 Docker 镜像
docker load -i oci-start-amd64-latest.tar

# 验证镜像已加载
docker images | grep oci-start
```

#### 第三步：配置应用

```bash
# 编辑配置文件
vim /volume1/docker/oci-start/data/oci-start.properties
```

**配置示例**:
```properties
# 用户 1
oracle.users.user1.userId=ocid1.user.oc1...
oracle.users.user1.userName=user1
oracle.users.user1.fingerprint=xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx
oracle.users.user1.tenancy=ocid1.tenancy.oc1...
oracle.users.user1.region=ap-tokyo-1
oracle.users.user1.keyFile=/app/keys/user1.pem
oracle.users.user1.ocpus=1
oracle.users.user1.memory=1
oracle.users.user1.disk=50
oracle.users.user1.architecture=AMD
oracle.users.user1.operationSystem=Ubuntu
oracle.users.user1.interval=60
oracle.users.user1.rootPassword=yourpassword
```

**注意**: `keyFile` 路径必须使用容器内路径 `/app/keys/xxx.pem`

#### 第四步：启动容器

**方式 A：使用 docker-compose（推荐）**

1. **复制 docker-compose.yml**
   ```bash
   # 复制 docker-compose.yml 到 NAS
   scp docker-compose.yml user@nas-ip:/volume1/docker/oci-start/
   ```

2. **启动容器**
   ```bash
   # SSH 登录到 NAS
   ssh user@nas-ip
   cd /volume1/docker/oci-start
   
   # 启动容器
   docker-compose up -d
   
   # 查看日志
   docker-compose logs -f
   ```

**方式 B：使用 docker run**

```bash
# SSH 登录到 NAS
ssh user@nas-ip

# 启动容器
docker run -d \
  --name oci-start \
  --restart unless-stopped \
  -p 9856:9856 \
  -v /volume1/docker/oci-start/data:/app/data \
  -v /volume1/docker/oci-start/logs:/app/logs \
  -v /volume1/docker/oci-start/keys:/app/keys \
  -e JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseCompressedClassPointers -XX:NewRatio=1 -XX:SurvivorRatio=8 -XX:+DisableExplicitGC" \
  -e TZ=Asia/Shanghai \
  oci-start:amd64

# 查看日志
docker logs -f oci-start
```

#### 第五步：验证部署

```bash
# 检查容器状态
docker ps | grep oci-start

# 检查端口监听
netstat -tlnp | grep 9856

# 查看日志
docker logs -f oci-start

# 测试 Web 访问
curl http://localhost:9856
# 或在浏览器中访问 http://nas-ip:9856
```

---

## ⚙️ 配置说明

### 目录结构

```
/volume1/docker/oci-start/
├── data/                    # 配置和数据目录
│   └── oci-start.properties  # OCI 配置文件
├── logs/                    # 日志目录
│   ├── application.log       # 应用日志
│   └── startup.log         # 启动日志
├── keys/                    # OCI 密钥文件目录
│   ├── user1.pem           # 用户 1 密钥
│   └── user2.pem           # 用户 2 密钥
├── docker-compose.yml        # Docker Compose 配置
└── oci-start-amd64-latest.tar  # Docker 镜像文件
```

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|---------|------|
| `JAVA_OPTS` | 见下方 | JVM 参数 |
| `TZ` | Asia/Shanghai | 时区设置 |

**默认 JVM 参数**（针对低配机器优化）:
```
-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseCompressedClassPointers -XX:NewRatio=1 -XX:SurvivorRatio=8 -XX:+DisableExplicitGC
```

### 端口映射

| 容器端口 | 宿主机端口 | 说明 |
|----------|-----------|------|
| 9856 | 9856 | Web 界面 |

### 资源限制

默认配置（可在 docker-compose.yml 中调整）:
- **内存限制**: 1GB
- **内存预留**: 512MB

---

## 🔧 常用命令

### 容器管理

```bash
# 启动容器
docker-compose up -d
# 或
docker start oci-start

# 停止容器
docker-compose down
# 或
docker stop oci-start

# 重启容器
docker-compose restart
# 或
docker restart oci-start

# 查看容器状态
docker ps | grep oci-start

# 查看容器日志
docker-compose logs -f
# 或
docker logs -f oci-start

# 进入容器
docker exec -it oci-start sh

# 删除容器
docker-compose down
# 或
docker rm -f oci-start
```

### 镜像管理

```bash
# 查看镜像
docker images | grep oci-start

# 删除镜像
docker rmi oci-start:amd64

# 重新加载镜像
docker load -i oci-start-amd64-latest.tar
```

### 配置管理

```bash
# 编辑配置文件
vim /volume1/docker/oci-start/data/oci-start.properties

# 重启容器使配置生效
docker-compose restart

# 查看日志
docker logs -f oci-start
```

---

## 🐛 故障排查

### 问题 1: 容器无法启动

**检查步骤**:
```bash
# 查看容器日志
docker logs oci-start

# 检查容器状态
docker ps -a | grep oci-start

# 检查镜像是否加载
docker images | grep oci-start
```

**常见原因**:
- 镜像未正确加载
- 端口被占用
- 配置文件错误
- 密钥文件权限不正确

### 问题 2: 无法访问 Web 界面

**检查步骤**:
```bash
# 检查容器是否运行
docker ps | grep oci-start

# 检查端口映射
docker port oci-start

# 检查防火墙
# 在 NAS 上检查防火墙设置

# 测试本地访问
docker exec -it oci-start curl http://localhost:9856
```

**常见原因**:
- 容器未启动
- 端口映射错误
- 防火墙阻止
- NAS 网络配置问题

### 问题 3: 内存不足

**解决方法**:
```bash
# 查看容器资源使用
docker stats oci-start

# 降低 JVM 堆内存
# 修改 docker-compose.yml 中的 JAVA_OPTS
# 将 -Xmx512m 改为 -Xmx384m

# 重启容器
docker-compose restart
```

### 问题 4: 配置文件错误

**检查步骤**:
```bash
# 查看容器日志
docker logs oci-start

# 检查配置文件
cat /volume1/docker/oci-start/data/oci-start.properties

# 检查密钥文件
ls -la /volume1/docker/oci-start/keys/

# 验证密钥文件权限
stat /volume1/docker/oci-start/keys/*.pem
```

**常见原因**:
- 配置文件格式错误
- 密钥文件路径错误
- 密钥文件权限不正确（应为 600）

### 问题 5: 实例创建失败

**检查步骤**:
```bash
# 查看应用日志
docker logs -f oci-start | grep -i error

# 检查配置文件
cat /volume1/docker/oci-start/data/oci-start.properties

# 验证 OCI 账户信息
# 登录 OCI 控制台检查配额和权限
```

**常见原因**:
- OCI 账户信息错误
- 密钥文件不匹配
- OCI 配额不足
- 区域选择错误

---

## 📊 性能优化

### 针对 NAS 的优化建议

1. **使用 SSD 存储**
   - 将 Docker 数据目录放在 SSD 上
   - 提高容器启动和运行速度

2. **调整资源限制**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 2G
       reservations:
         memory: 512M
   ```

3. **启用 Docker 日志轮转**
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

4. **使用 NAS 的 Docker 优化功能**
   - Synology: 启用 Docker 性能模式
   - QNAP: 启用容器优化
   - TrueNAS: 调整 ZFS 设置

---

## 🔄 更新镜像

### 更新步骤

1. **下载新版本镜像**
   - 从 GitHub Actions 下载新版本
   - 或从 GitHub Release 下载

2. **停止并删除旧容器**
   ```bash
   docker-compose down
   # 或
   docker stop oci-start && docker rm oci-start
   ```

3. **删除旧镜像**
   ```bash
   docker rmi oci-start:amd64
   ```

4. **加载新镜像**
   ```bash
   docker load -i oci-start-amd64-new-version.tar
   ```

5. **启动新容器**
   ```bash
   docker-compose up -d
   ```

---

## 📋 部署检查清单

- [ ] 下载 Docker 镜像（AMD64）
- [ ] 创建工作目录（data, logs, keys）
- [ ] 传输 Docker 镜像到 NAS
- [ ] 传输配置文件到 NAS
- [ ] 传输密钥文件到 NAS
- [ ] 设置密钥文件权限（chmod 600）
- [ ] 加载 Docker 镜像
- [ ] 编辑配置文件（oci-start.properties）
- [ ] 启动容器
- [ ] 验证容器运行状态
- [ ] 验证端口监听
- [ ] 测试 Web 访问
- [ ] 配置 NAS 防火墙（如需要）
- [ ] 设置开机自启（如需要）

---

## 🎯 总结

通过 Docker 部署 OCI-Start 到 NAS，可以：

- ✅ 简化部署流程
- ✅ 方便管理和维护
- ✅ 资源隔离和安全
- ✅ 易于备份和迁移
- ✅ 针对低配机器优化
- ✅ 仅支持 AMD64 架构，构建更快

如有问题，请查看容器日志或参考故障排查部分。