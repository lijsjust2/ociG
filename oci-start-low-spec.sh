#!/bin/bash

# OCI-Start 低配机器优化启动脚本
# 适用于 N2830 + 4GB RAM 配置

APP_NAME="oci-start"
JAR_NAME="oci-server.jar"
PID_FILE="$APP_NAME.pid"
LOG_DIR="logs"

# 创建日志目录
mkdir -p $LOG_DIR

# JVM 优化参数（针对低配机器）
JVM_OPTS="-Xms256m \
          -Xmx512m \
          -XX:+UseG1GC \
          -XX:MaxGCPauseMillis=200 \
          -XX:+UseStringDeduplication \
          -XX:+OptimizeStringConcat \
          -XX:+UseCompressedOops \
          -XX:+UseCompressedClassPointers \
          -XX:NewRatio=1 \
          -XX:SurvivorRatio=8 \
          -XX:+DisableExplicitGC \
          -Djava.awt.headless=true \
          -Dfile.encoding=UTF-8 \
          -Duser.timezone=Asia/Shanghai \
          -Dsun.net.client.defaultConnectTimeout=30000 \
          -Dsun.net.client.defaultReadTimeout=30000"

# 检查是否已经运行
if [ -f "$PID_FILE" ]; then
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "$APP_NAME is already running with PID $PID"
        exit 1
    else
        rm -f $PID_FILE
    fi
fi

# 启动应用
echo "Starting $APP_NAME with optimized settings for low-spec machine..."
echo "JVM Options: $JVM_OPTS"
nohup java $JVM_OPTS -jar $JAR_NAME > $LOG_DIR/startup.log 2>&1 &

# 保存 PID
echo $! > $PID_FILE

# 等待启动
sleep 5

# 检查是否启动成功
if [ -f "$PID_FILE" ]; then
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "$APP_NAME started successfully with PID $PID"
        echo "Logs are available in $LOG_DIR/"
        echo "You can view logs with: tail -f $LOG_DIR/application.log"
        echo ""
        echo "Memory usage (check with): free -h"
        echo "Process memory (check with): ps aux | grep $PID"
    else
        echo "Failed to start $APP_NAME"
        rm -f $PID_FILE
        exit 1
    fi
else
    echo "Failed to start $APP_NAME"
    exit 1
fi