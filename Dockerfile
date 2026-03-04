# 多阶段构建 - 针对低配机器优化（仅 AMD64）

# Stage 1: 构建 JAR 文件
FROM maven:3.8.6-openjdk-8-slim AS builder

WORKDIR /app

# 复制 pom.xml 并下载依赖（利用 Docker 缓存）
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 复制源代码
COPY src ./src

# 构建 JAR 文件（跳过测试）
RUN mvn clean package -DskipTests -B

# Stage 2: 运行时镜像（针对 x86 架构优化）
FROM openjdk:8-jre-alpine

# 安装必要的工具
RUN apk add --no-cache tzdata curl

# 设置时区为上海
ENV TZ=Asia/Shanghai

# 创建应用目录
WORKDIR /app

# 从构建阶段复制 JAR 文件
COPY --from=builder /app/oci-server/target/oci-server.jar ./app.jar

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