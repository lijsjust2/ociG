# 多阶段构建 - 针对低配机器优化（仅 AMD64）

# Stage 1: 构建 JAR 文件
FROM maven:3.8.6-openjdk-8-slim AS builder

WORKDIR /app

# 复制根目录 pom.xml
COPY pom.xml .

# 复制 oci-common 模块
COPY oci-common/pom.xml ./oci-common/
COPY oci-common/src ./oci-common/src

# 复制 oci-server 模块
COPY oci-server/pom.xml ./oci-server/
COPY oci-server/src ./oci-server/src

# 构建 JAR 文件（跳过测试）
RUN mvn clean package -DskipTests -B

# Stage 2: 运行时镜像（针对 x86 架构优化）
FROM eclipse-temurin:8-jre-alpine

# 安装必要的工具
RUN apk add --no-cache tzdata curl

# 设置时区为上海
ENV TZ=Asia/Shanghai

# 创建应用目录
WORKDIR /app

# 从构建阶段复制 JAR 文件
    COPY --from=builder /app/oci-server/target/oci-start-release.jar ./app.jar

# 创建数据目录
RUN mkdir -p /app/data /app/logs /app/keys

# 设置 JVM 参数（针对低配机器优化）
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseCompressedClassPointers -XX:NewRatio=1 -XX:SurvivorRatio=8 -XX:+DisableExplicitGC"

# 暴露端口
EXPOSE 9856

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:9856/actuator/health || exit 1

# 启动应用
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]