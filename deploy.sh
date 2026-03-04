#!/bin/bash

# OCI-Start 部署脚本 - 自动化部署到 N2830 机器人

set -e

# 配置变量
REMOTE_HOST=""
REMOTE_USER="root"
REMOTE_DIR="/root/oci-start"
LOCAL_JAR="oci-server/target/oci-server.jar"
LOCAL_CONFIG="oci-server/src/main/resources/oci-start.properties"
LOCAL_START_SCRIPT="oci-start-low-spec.sh"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."
    
    if ! command -v ssh &> /dev/null; then
        print_error "ssh 未安装"
        exit 1
    fi
    
    if ! command -v scp &> /dev/null; then
        print_error "scp 未安装"
        exit 1
    fi
    
    print_info "依赖检查通过"
}

# 检查本地文件
check_local_files() {
    print_info "检查本地文件..."
    
    if [ ! -f "$LOCAL_JAR" ]; then
        print_error "JAR 文件不存在: $LOCAL_JAR"
        print_info "请先运行: mvn clean package -DskipTests"
        exit 1
    fi
    
    if [ ! -f "$LOCAL_CONFIG" ]; then
        print_error "配置文件不存在: $LOCAL_CONFIG"
        exit 1
    fi
    
    if [ ! -f "$LOCAL_START_SCRIPT" ]; then
        print_warn "启动脚本不存在: $LOCAL_START_SCRIPT"
    fi
    
    print_info "本地文件检查通过"
}

# 连接测试
test_connection() {
    print_info "测试连接到 $REMOTE_USER@$REMOTE_HOST..."
    
    if ssh -o ConnectTimeout=5 "$REMOTE_USER@$REMOTE_HOST" "echo 'Connection successful'" &> /dev/null; then
        print_info "连接测试通过"
    else
        print_error "无法连接到 $REMOTE_USER@$REMOTE_HOST"
        exit 1
    fi
}

# 在远程机器上创建目录
create_remote_directories() {
    print_info "在远程机器上创建目录..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR/logs $REMOTE_DIR/data $REMOTE_DIR/keys"
    
    print_info "目录创建完成"
}

# 上传文件
upload_files() {
    print_info "上传文件到远程机器..."
    
    # 上传 JAR 文件
    print_info "上传 JAR 文件..."
    scp "$LOCAL_JAR" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/oci-server.jar"
    
    # 上传配置文件
    print_info "上传配置文件..."
    scp "$LOCAL_CONFIG" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/oci-start.properties"
    
    # 上传启动脚本
    if [ -f "$LOCAL_START_SCRIPT" ]; then
        print_info "上传启动脚本..."
        scp "$LOCAL_START_SCRIPT" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/oci-start.sh"
    fi
    
    print_info "文件上传完成"
}

# 设置远程权限
set_remote_permissions() {
    print_info "设置远程文件权限..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "chmod +x $REMOTE_DIR/oci-start.sh"
    
    print_info "权限设置完成"
}

# 检查远程环境
check_remote_environment() {
    print_info "检查远程环境..."
    
    # 检查 Java
    if ssh "$REMOTE_USER@$REMOTE_HOST" "java -version" &> /dev/null; then
        JAVA_VERSION=$(ssh "$REMOTE_USER@$REMOTE_HOST" "java -version 2>&1 | head -n 1")
        print_info "Java 版本: $JAVA_VERSION"
    else
        print_error "远程机器未安装 Java"
        print_info "请先在远程机器上安装 Java 8+"
        exit 1
    fi
    
    # 检查内存
    MEMORY=$(ssh "$REMOTE_USER@$REMOTE_HOST" "free -m | grep Mem | awk '{print \$2}'")
    print_info "可用内存: ${MEMORY}MB"
    
    if [ "$MEMORY" -lt 2048 ]; then
        print_warn "内存不足 2GB，可能会影响性能"
    fi
    
    # 检查磁盘空间
    DISK=$(ssh "$REMOTE_USER@$REMOTE_HOST" "df -m $REMOTE_DIR | tail -1 | awk '{print \$4}'")
    print_info "可用磁盘空间: ${DISK}MB"
    
    if [ "$DISK" -lt 1024 ]; then
        print_warn "磁盘空间不足 1GB"
    fi
}

# 显示部署信息
show_deployment_info() {
    print_info "部署信息:"
    echo "  远程主机: $REMOTE_USER@$REMOTE_HOST"
    echo "  远程目录: $REMOTE_DIR"
    echo "  JAR 文件: $LOCAL_JAR"
    echo "  配置文件: $LOCAL_CONFIG"
}

# 主函数
main() {
    echo "========================================="
    echo "  OCI-Start 自动部署脚本"
    echo "========================================="
    echo ""
    
    # 检查参数
    if [ -z "$1" ]; then
        print_error "请提供远程主机 IP 地址"
        echo "用法: $0 <远程主机IP> [远程用户名]"
        echo "示例: $0 192.168.1.100 root"
        exit 1
    fi
    
    REMOTE_HOST="$1"
    
    if [ -n "$2" ]; then
        REMOTE_USER="$2"
    fi
    
    show_deployment_info
    echo ""
    
    # 执行部署步骤
    check_dependencies
    check_local_files
    test_connection
    check_remote_environment
    create_remote_directories
    upload_files
    set_remote_permissions
    
    echo ""
    print_info "部署完成！"
    echo ""
    print_info "下一步操作:"
    echo "  1. SSH 登录到远程机器: ssh $REMOTE_USER@$REMOTE_HOST"
    echo "  2. 进入目录: cd $REMOTE_DIR"
    echo "  3. 配置 OCI 账户: vim oci-start.properties"
    echo "  4. 上传密钥文件: scp keys/*.pem $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/keys/"
    echo "  5. 启动应用: ./oci-start.sh"
    echo ""
}

# 运行主函数
main "$@"