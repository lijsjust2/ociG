@echo off
REM OCI-Start 低配机器优化启动脚本 (Windows 版本)
REM 适用于 N2830 + 4GB RAM 配置

set APP_NAME=oci-start
set JAR_NAME=oci-server.jar
set PID_FILE=%APP_NAME%.pid
set LOG_DIR=logs

REM 创建日志目录
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM JVM 优化参数（针对低配机器）
set JVM_OPTS=-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseCompressedClassPointers -XX:NewRatio=1 -XX:SurvivorRatio=8 -XX:+DisableExplicitGC -Djava.awt.headless=true -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai

REM 检查是否已经运行
if exist "%PID_FILE%" (
    set /p PID=<%PID_FILE%
    tasklist /FI "PID eq %PID%" 2>NUL | find /I /N "java.exe">NUL
    if "%ERRORLEVEL%"=="0" (
        echo %APP_NAME% is already running with PID %PID%
        exit /b 1
    ) else (
        del "%PID_FILE%"
    )
)

REM 启动应用
echo Starting %APP_NAME% with optimized settings for low-spec machine...
echo JVM Options: %JVM_OPTS%
start /B java %JVM_OPTS% -jar %JAR_NAME% > "%LOG_DIR%\startup.log" 2>&1

REM 获取进程 ID
for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq java.exe" /FO CSV ^| find "java.exe"') do (
    set PID=%%i
    set PID=!PID:"=!
    echo !PID! > "%PID_FILE%"
    goto :found
)

:found
timeout /t 5 /nobreak >nul

REM 检查是否启动成功
if exist "%PID_FILE%" (
    set /p PID=<%PID_FILE%
    tasklist /FI "PID eq %PID%" 2>NUL | find /I /N "java.exe">NUL
    if "%ERRORLEVEL%"=="0" (
        echo %APP_NAME% started successfully with PID %PID%
        echo Logs are available in %LOG_DIR%\
        echo You can view logs with: type %LOG_DIR%\application.log
    ) else (
        echo Failed to start %APP_NAME%
        del "%PID_FILE%"
        exit /b 1
    )
) else (
    echo Failed to start %APP_NAME%
    exit /b 1
)