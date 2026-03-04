#!/bin/bash

# OCI-Start 优化启动脚本
# 包含性能优化参数

APP_NAME="oci-start"
JAR_NAME="oci-server.jar"
PID_FILE="$APP_NAME.pid"
LOG_DIR="logs"

# 创建日志目录
mkdir -p $LOG_DIR

# JVM 优化参数
JVM_OPTS="-Xms512m \
          -Xmx1024m \
          -XX:+UseG1GC \
          -XX:MaxGCPauseMillis=200 \
          -XX:+HeapDumpOnOutOfMemoryError \
          -XX:HeapDumpPath=$LOG_DIR/heap_dump.hprof \
          -XX:+PrintGCDetails \
          -XX:+PrintGCDateStamps \
          -Xloggc:$LOG_DIR/gc.log \
          -XX:+UseGCLogFileRotation \
          -XX:NumberOfGCLogFiles=5 \
          -XX:GCLogFileSize=10M \
          -Djava.awt.headless=true \
          -Dfile.encoding=UTF-8 \
          -Duser.timezone=Asia/Shanghai"

# Spring Boot 优化参数
SPRING_OPTS="--spring.profiles.active=optimized \
             --spring.main.lazy-initialization=true"

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
echo "Starting $APP_NAME with optimized settings..."
nohup java $JVM_OPTS -jar $JAR_NAME $SPRING_OPTS > $LOG_DIR/startup.log 2>&1 &

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
    else
        echo "Failed to start $APP_NAME"
        rm -f $PID_FILE
        exit 1
    fi
else
    echo "Failed to start $APP_NAME"
    exit 1
fi