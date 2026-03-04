#!/bin/bash

# OCI-Start 监控脚本 - 用于 N2830 机器人

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
APP_NAME="oci-server"
APP_DIR="/root/oci-start"
LOG_DIR="$APP_DIR/logs"
PID_FILE="$APP_DIR/oci-start.pid"

# 打印函数
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  OCI-Start 监控面板${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 检查进程
check_process() {
    print_section "进程状态"
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null 2>&1; then
            print_ok "进程运行中 (PID: $PID)"
            
            # 显示进程详细信息
            echo ""
            echo "进程信息:"
            ps aux | grep $PID | grep -v grep | awk '{printf "  CPU: %s%%, MEM: %s%%, TIME: %s\n", $3, $4, $10}'
            
            # 显示线程数
            THREAD_COUNT=$(ps -eLf | grep $PID | wc -l)
            echo "  线程数: $THREAD_COUNT"
        else
            print_error "PID 文件存在但进程未运行"
            print_warn "请删除 PID 文件: rm $PID_FILE"
        fi
    else
        if pgrep -f "$APP_NAME.jar" > /dev/null; then
            PID=$(pgrep -f "$APP_NAME.jar")
            print_ok "进程运行中 (PID: $PID)"
            print_warn "PID 文件不存在，建议创建: echo $PID > $PID_FILE"
        else
            print_error "进程未运行"
        fi
    fi
    echo ""
}

# 检查端口
check_port() {
    print_section "端口监听"
    
    PORT=9856
    if netstat -tlnp 2>/dev/null | grep -q ":$PORT "; then
        print_ok "端口 $PORT 正在监听"
        netstat -tlnp 2>/dev/null | grep ":$PORT " | awk '{printf "  地址: %s\n  PID: %s\n", $4, $7}'
    else
        print_error "端口 $PORT 未监听"
    fi
    echo ""
}

# 检查内存
check_memory() {
    print_section "内存使用"
    
    # 系统内存
    TOTAL_MEM=$(free -m | grep Mem | awk '{print $2}')
    USED_MEM=$(free -m | grep Mem | awk '{print $3}')
    FREE_MEM=$(free -m | grep Mem | awk '{print $7}')
    MEM_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))
    
    echo "系统内存:"
    echo "  总计: ${TOTAL_MEM}MB"
    echo "  已用: ${USED_MEM}MB (${MEM_PERCENT}%)"
    echo "  可用: ${FREE_MEM}MB"
    
    # 应用内存
    if pgrep -f "$APP_NAME.jar" > /dev/null; then
        PID=$(pgrep -f "$APP_NAME.jar")
        APP_MEM=$(ps -p $PID -o rss= | awk '{print $1/1024}')
        echo ""
        echo "应用内存:"
        echo "  使用: ${APP_MEM}MB"
        
        if (( $(echo "$APP_MEM > 512" | bc -l) )); then
            print_warn "应用内存使用超过 512MB"
        else
            print_ok "应用内存使用正常"
        fi
    fi
    echo ""
}

# 检查磁盘
check_disk() {
    print_section "磁盘使用"
    
    df -h | grep -E "Filesystem|/$APP_DIR"
    echo ""
}

# 检查日志
check_logs() {
    print_section "最近日志"
    
    if [ -f "$LOG_DIR/application.log" ]; then
        echo "最近的 10 条日志:"
        tail -n 10 "$LOG_DIR/application.log" | while read line; do
            echo "  $line"
        done
        
        # 统计错误和警告
        ERROR_COUNT=$(grep -c "ERROR" "$LOG_DIR/application.log" 2>/dev/null || echo 0)
        WARN_COUNT=$(grep -c "WARN" "$LOG_DIR/application.log" 2>/dev/null || echo 0)
        
        echo ""
        echo "日志统计:"
        echo "  错误: $ERROR_COUNT"
        echo "  警告: $WARN_COUNT"
        
        if [ "$ERROR_COUNT" -gt 0 ]; then
            print_warn "发现 $ERROR_COUNT 个错误"
        fi
    else
        print_error "日志文件不存在: $LOG_DIR/application.log"
    fi
    echo ""
}

# 检查配置
check_config() {
    print_section "配置检查"
    
    CONFIG_FILE="$APP_DIR/oci-start.properties"
    
    if [ -f "$CONFIG_FILE" ]; then
        print_ok "配置文件存在"
        
        # 检查用户数量
        USER_COUNT=$(grep -c "^oracle\.users\." "$CONFIG_FILE" | head -1)
        echo "  配置用户数: $USER_COUNT"
        
        # 检查密钥文件
        KEY_COUNT=$(grep "keyFile=" "$CONFIG_FILE" | wc -l)
        echo "  密钥文件数: $KEY_COUNT"
        
        # 检查密钥文件是否存在
        MISSING_KEYS=0
        grep "keyFile=" "$CONFIG_FILE" | cut -d'=' -f2 | while read keyfile; do
            if [ ! -f "$keyfile" ]; then
                print_warn "密钥文件不存在: $keyfile"
                MISSING_KEYS=$((MISSING_KEYS + 1))
            fi
        done
    else
        print_error "配置文件不存在: $CONFIG_FILE"
    fi
    echo ""
}

# 检查网络
check_network() {
    print_section "网络连接"
    
    # 检查网络接口
    echo "网络接口:"
    ip addr show | grep "inet " | awk '{printf "  %s: %s\n", $2, $NF}'
    
    # 检查外网连接
    echo ""
    if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        print_ok "外网连接正常"
    else
        print_error "外网连接失败"
    fi
    echo ""
}

# 检查 Java
check_java() {
    print_section "Java 环境"
    
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1)
        print_ok "Java 已安装"
        echo "  版本: $JAVA_VERSION"
        
        # 检查 JVM 参数
        if pgrep -f "$APP_NAME.jar" > /dev/null; then
            PID=$(pgrep -f "$APP_NAME.jar")
            JVM_ARGS=$(ps -p $PID -o args= | grep -oP '(?<=-Xmx)\d+')
            if [ -n "$JVM_ARGS" ]; then
                echo "  最大堆内存: ${JVM_ARGS}MB"
            fi
        fi
    else
        print_error "Java 未安装"
    fi
    echo ""
}

# 生成建议
generate_suggestions() {
    print_section "优化建议"
    
    SUGGESTIONS=0
    
    # 检查内存
    TOTAL_MEM=$(free -m | grep Mem | awk '{print $2}')
    if [ "$TOTAL_MEM" -lt 4096 ]; then
        print_warn "内存不足 4GB，建议升级或关闭其他应用"
        SUGGESTIONS=$((SUGGESTIONS + 1))
    fi
    
    # 检查应用内存
    if pgrep -f "$APP_NAME.jar" > /dev/null; then
        PID=$(pgrep -f "$APP_NAME.jar")
        APP_MEM=$(ps -p $PID -o rss= | awk '{print $1/1024}')
        if (( $(echo "$APP_MEM > 512" | bc -l) )); then
            print_warn "应用内存使用较高，考虑降低 JVM 堆内存"
            SUGGESTIONS=$((SUGGESTIONS + 1))
        fi
    fi
    
    # 检查日志错误
    if [ -f "$LOG_DIR/application.log" ]; then
        ERROR_COUNT=$(grep -c "ERROR" "$LOG_DIR/application.log" 2>/dev/null || echo 0)
        if [ "$ERROR_COUNT" -gt 10 ]; then
            print_warn "日志中有较多错误，建议检查配置"
            SUGGESTIONS=$((SUGGESTIONS + 1))
        fi
    fi
    
    if [ "$SUGGESTIONS" -eq 0 ]; then
        print_ok "系统运行状态良好，无需优化"
    fi
    echo ""
}

# 主函数
main() {
    print_header
    
    check_process
    check_port
    check_memory
    check_disk
    check_java
    check_config
    check_network
    check_logs
    generate_suggestions
    
    print_section "监控完成"
    echo "下次运行: $0"
    echo "持续监控: watch -n 5 $0"
}

# 运行主函数
main