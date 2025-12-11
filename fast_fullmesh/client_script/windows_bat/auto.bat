@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: Fast Fullmesh Client - Windows
:: WireGuard Full Mesh 自动同步客户端

:: 配置文件路径
set "CONFIG_FILE=%APPDATA%\wg-auto-sync\config.ini"
set "WG_CONFIG_DIR=%APPDATA%\wg-auto-sync"
set "LOG_FILE=%WG_CONFIG_DIR%\sync.log"

:: WireGuard 安装路径
set "WG_PATH=C:\Program Files\WireGuard"
set "WIREGUARD_EXE=%WG_PATH%\wireguard.exe"
set "WG_EXE=%WG_PATH%\wg.exe"

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 请以管理员身份运行此脚本
    echo 右键点击脚本 -^> 以管理员身份运行
    pause
    exit /b 1
)

:: 创建配置目录
if not exist "%WG_CONFIG_DIR%" mkdir "%WG_CONFIG_DIR%"

:: 检查命令行参数（用于定时任务静默执行）
if "%~1"=="sync" goto silent_sync

:: 主菜单
:main_menu
cls
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                                                               ║
echo ║   ██╗    ██╗ ██████╗       █████╗ ██╗   ██╗████████╗ ██████╗  ║
echo ║   ██║    ██║██╔════╝      ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗ ║
echo ║   ██║ █╗ ██║██║  ███╗     ███████║██║   ██║   ██║   ██║   ██║ ║
echo ║   ██║███╗██║██║   ██║     ██╔══██║██║   ██║   ██║   ██║   ██║ ║
echo ║   ╚███╔███╔╝╚██████╔╝     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝ ║
echo ║    ╚══╝╚══╝  ╚═════╝      ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ║
echo ║                                                               ║
echo ║              Fast Fullmesh Client (Windows)                  ║
echo ║                                                               ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
call :show_status
echo.
echo ═══════════════════════════ 主菜单 ═══════════════════════════
echo.
echo   1) 配置参数
echo   2) 立即同步
echo   3) 安装为系统服务 (开机自启)
echo   4) 卸载系统服务
echo   5) 查看 WireGuard 状态
echo   6) Tunnel Control (Start/Stop)
echo   7) 添加定时任务
echo   8) 删除定时任务
echo   9) 查看日志
echo.
echo   ─────────── 高级功能 ───────────
echo   A) 网络共享设置 (NAT转发)
echo.
echo   0) 退出
echo.
set /p choice="请选择: "

if "%choice%"=="1" goto do_configure
if "%choice%"=="2" goto do_sync
if "%choice%"=="3" goto do_install_service
if "%choice%"=="4" goto do_uninstall_service
if "%choice%"=="5" goto do_wg_status
if "%choice%"=="6" goto do_tunnel_control
if "%choice%"=="7" goto do_register_task
if "%choice%"=="8" goto do_unregister_task
if "%choice%"=="9" goto do_view_log
if /i "%choice%"=="A" goto do_network_share
if "%choice%"=="0" goto end
goto main_menu

:: 显示当前状态
:show_status
echo ═══════════════════════════ 当前状态 ═══════════════════════════
echo.
:: 检查配置
if exist "%CONFIG_FILE%" (
    echo [√] 配置已设置
    setlocal DisableDelayedExpansion
    for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
    setlocal EnableDelayedExpansion
    echo     接口名称: !WG_INTERFACE!
    echo     服务器: !SERVER_ADDRESS!
    echo     节点名称: !PEER_NAME!
    echo     配置名称: !CONFIG_NAME!
) else (
    echo [×] 尚未配置
)
:: 检查服务状态
if exist "%CONFIG_FILE%" (
    setlocal DisableDelayedExpansion
    for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
    setlocal EnableDelayedExpansion
)
sc query "WireGuardTunnel$!WG_INTERFACE!" >nul 2>&1
if !errorlevel!==0 (
    echo [√] WireGuard 服务已安装
) else (
    echo [×] WireGuard 服务未安装
)
:: 检查定时任务
schtasks /query /tn "WG-AutoSync" >nul 2>&1
if %errorlevel%==0 (
    echo [√] 定时同步已启用
) else (
    echo [×] 定时同步未启用
)
goto :eof

:: 配置参数
:do_configure
cls
echo ═══════════════════════════ 配置向导 ═══════════════════════════
echo.

:: 读取现有配置
if exist "%CONFIG_FILE%" (
    setlocal DisableDelayedExpansion
    for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
    setlocal EnableDelayedExpansion
)

echo [1/5] WireGuard 接口名称
echo       用于标识本地 WireGuard 接口
echo       示例: wg0, WGL
set /p "WG_INTERFACE=      请输入 [%WG_INTERFACE%]: " || set "WG_INTERFACE=%WG_INTERFACE%"
if "%WG_INTERFACE%"=="" set "WG_INTERFACE=WGL"
echo.

echo [2/5] 服务器地址
echo       Fast Fullmesh API 的完整地址
echo       示例: https://wg-api.example.com
echo             http://192.168.1.1:18889
set /p "SERVER_ADDRESS=      请输入: "
if "%SERVER_ADDRESS%"=="" (
    echo [错误] 服务器地址不能为空
    pause
    goto main_menu
)
echo.

echo [3/5] API 密钥 (SECRET)
echo       用于 API 认证，留空表示不启用
set /p "SECRET=      请输入: "
echo.

echo [4/5] 本机节点名称
echo       在 WGDashboard 中配置的 Peer 名称
echo       示例: WGL-home, WGL-office
set /p "PEER_NAME=      请输入: "
if "%PEER_NAME%"=="" (
    echo [错误] 节点名称不能为空
    pause
    goto main_menu
)
echo.

echo [5/5] WireGuard 配置名称
echo       WGDashboard 中的配置名称
set /p "CONFIG_NAME=      请输入 [WGL]: " || set "CONFIG_NAME=WGL"
if "%CONFIG_NAME%"=="" set "CONFIG_NAME=WGL"
echo.

:: 保存配置
echo WG_INTERFACE=%WG_INTERFACE%>"%CONFIG_FILE%"
echo SERVER_ADDRESS=%SERVER_ADDRESS%>>"%CONFIG_FILE%"
echo SECRET=%SECRET%>>"%CONFIG_FILE%"
echo PEER_NAME=%PEER_NAME%>>"%CONFIG_FILE%"
echo CONFIG_NAME=%CONFIG_NAME%>>"%CONFIG_FILE%"

echo [√] 配置已保存到 %CONFIG_FILE%
pause
goto main_menu

:: 执行同步
:do_sync
cls
echo [INFO] 开始同步 WireGuard 配置...
echo.

:: 读取配置
if not exist "%CONFIG_FILE%" (
    echo [错误] 配置文件不存在，请先进行配置
    pause
    goto main_menu
)
:: 临时禁用延迟扩展来读取配置，避免 ! 被吞掉
setlocal DisableDelayedExpansion
for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
setlocal EnableDelayedExpansion

:: 构建 URL - 使用延迟扩展
set "URL=!SERVER_ADDRESS!?peername=!PEER_NAME!"
set "URL=!URL!&config=!CONFIG_NAME!"
if not "!SECRET!"=="" set "URL=!URL!&secret=!SECRET!"

set "CONF_PATH=!WG_CONFIG_DIR!\!WG_INTERFACE!.conf"
set "TEMP_CONF=!WG_CONFIG_DIR!\!WG_INTERFACE!.conf.tmp"

echo [INFO] 正在从服务器获取配置...
echo [INFO] URL: !URL!

:: 下载配置
curl.exe -s -m 15 "!URL!" -o "%TEMP_CONF%"
if not exist "%TEMP_CONF%" (
    echo [错误] 无法连接服务器或下载配置
    pause
    goto main_menu
)

:: 检查文件是否为空
for %%A in ("%TEMP_CONF%") do if %%~zA==0 (
    echo [错误] 下载的配置文件为空
    del "%TEMP_CONF%" 2>nul
    pause
    goto main_menu
)

:: 检查是否为 HTML
findstr /i "<html>" "%TEMP_CONF%" >nul 2>&1
if %errorlevel%==0 (
    echo [错误] 服务器返回了 HTML 页面而非配置文件
    del "%TEMP_CONF%" 2>nul
    pause
    goto main_menu
)

:: 检查是否包含 [Interface]
findstr /i "\[Interface\]" "%TEMP_CONF%" >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 响应不是有效的 WireGuard 配置
    type "%TEMP_CONF%"
    del "%TEMP_CONF%" 2>nul
    pause
    goto main_menu
)

:: 检查配置是否有变化
if exist "%CONF_PATH%" (
    fc /b "%TEMP_CONF%" "%CONF_PATH%" >nul 2>&1
    if %errorlevel%==0 (
        echo [INFO] 配置无变化，无需更新
        del "%TEMP_CONF%" 2>nul
        pause
        goto main_menu
    )
)

:: 保存配置
move /y "%TEMP_CONF%" "%CONF_PATH%" >nul
echo [√] 配置已保存到 %CONF_PATH%

:: 检查隧道是否运行中，尝试热更新
"%WG_EXE%" show "%WG_INTERFACE%" >nul 2>&1
if %errorlevel%==0 (
    echo [INFO] 隧道运行中，尝试热更新...
    :: 提取纯 wg 配置并热更新
    call :extract_wg_config "%CONF_PATH%" "%TEMP_CONF%.wg"
    "%WG_EXE%" syncconf "%WG_INTERFACE%" "%TEMP_CONF%.wg" 2>nul
    if %errorlevel%==0 (
        echo [√] 配置热更新成功（连接未中断）
        del "%TEMP_CONF%.wg" 2>nul
    ) else (
        echo [×] 热更新失败，需要重启隧道
        del "%TEMP_CONF%.wg" 2>nul
        echo [INFO] 请手动重启隧道或重新安装服务
    )
) else (
    echo [INFO] 隧道未运行
    echo [INFO] 请选择 "3) 安装为系统服务" 或 "6) 启动隧道" 来启动
)

echo.
echo [√] 同步完成！
echo.
:: 记录日志
echo [%date% %time%] 同步完成: %PEER_NAME% >> "%LOG_FILE%"
pause
goto main_menu

:: 提取纯 wg 配置（去除 Address, DNS 等字段）
:extract_wg_config
set "INPUT=%~1"
set "OUTPUT=%~2"
(
    for /f "usebackq delims=" %%L in ("%INPUT%") do (
        set "line=%%L"
        echo !line! | findstr /i "^Address ^DNS ^MTU ^Table ^PreUp ^PostUp ^PreDown ^PostDown ^SaveConfig" >nul
        if errorlevel 1 echo %%L
    )
) > "%OUTPUT%"
goto :eof

:: 安装为系统服务
:do_install_service
cls
echo [INFO] 安装 WireGuard 服务...

if not exist "%CONFIG_FILE%" (
    echo [错误] 请先配置参数
    pause
    goto main_menu
)
setlocal DisableDelayedExpansion
for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
setlocal EnableDelayedExpansion

set "CONF_PATH=!WG_CONFIG_DIR!\!WG_INTERFACE!.conf"
if not exist "%CONF_PATH%" (
    echo [错误] 配置文件不存在: %CONF_PATH%
    echo [INFO] 请先执行同步获取配置
    pause
    goto main_menu
)

:: 先卸载旧服务
"%WIREGUARD_EXE%" /uninstalltunnelservice "%WG_INTERFACE%" >nul 2>&1
timeout /t 2 /nobreak >nul

:: 安装新服务
echo [INFO] 正在安装服务: WireGuardTunnel$%WG_INTERFACE%
"%WIREGUARD_EXE%" /installtunnelservice "%CONF_PATH%"
if %errorlevel%==0 (
    echo [√] 服务安装成功！
    echo [√] 隧道将在系统启动时自动连接
) else (
    echo [错误] 服务安装失败
)
pause
goto main_menu

:: 卸载系统服务
:do_uninstall_service
cls
echo [INFO] 卸载 WireGuard 服务...

if not exist "%CONFIG_FILE%" (
    echo [错误] 请先配置参数
    pause
    goto main_menu
)
setlocal DisableDelayedExpansion
for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
setlocal EnableDelayedExpansion

"%WIREGUARD_EXE%" /uninstalltunnelservice "!WG_INTERFACE!"
if %errorlevel%==0 (
    echo [√] 服务已卸载
) else (
    echo [×] 卸载失败或服务不存在
)
pause
goto main_menu

:: 查看 WireGuard 状态
:do_wg_status
cls
echo ═══════════════════════════ WireGuard 状态 ═══════════════════════════
echo.

if not exist "%CONFIG_FILE%" (
    echo [!] 请先配置参数
    pause
    goto main_menu
)
setlocal DisableDelayedExpansion
for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
setlocal EnableDelayedExpansion

"%WG_EXE%" show "!WG_INTERFACE!"
if !errorlevel! neq 0 (
    echo [×] 隧道 !WG_INTERFACE! 未运行
)
echo.
pause
goto main_menu

:: 隧道控制
:do_tunnel_control
cls
echo ═══════════════════════════ 隧道控制 ═══════════════════════════
echo.

if not exist "%CONFIG_FILE%" (
    echo [×] 请先配置参数
    pause
    goto main_menu
)
setlocal DisableDelayedExpansion
for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
setlocal EnableDelayedExpansion

sc query "WireGuardTunnel$!WG_INTERFACE!" >nul 2>&1
if !errorlevel!==0 (
    echo [√] 服务状态: 已安装
) else (
    echo [×] 服务状态: 未安装
)

echo.
echo   1) 启动隧道服务
echo   2) 停止隧道服务
echo   3) 重启隧道服务
echo   0) 返回
echo.
set /p choice="请选择: "

if "%choice%"=="1" (
    net start "WireGuardTunnel$!WG_INTERFACE!"
    echo [√] 隧道已启动
)
if "%choice%"=="2" (
    net stop "WireGuardTunnel$!WG_INTERFACE!"
    echo [√] 隧道已停止
)
if "%choice%"=="3" (
    net stop "WireGuardTunnel$!WG_INTERFACE!" 2>nul
    timeout /t 2 /nobreak >nul
    net start "WireGuardTunnel$!WG_INTERFACE!"
    echo [√] 隧道已重启
)
if "%choice%"=="0" goto main_menu
pause
goto main_menu

:: 注册定时任务
:do_register_task
cls
echo ═══════════════════════════ 定时同步设置 ═══════════════════════════
echo.
echo   1) 每 2 分钟同步
echo   2) 每 5 分钟同步
echo   3) 每 10 分钟同步
echo   0) 返回
echo.
set /p choice="请选择: "

set "INTERVAL=2"
if "%choice%"=="1" set "INTERVAL=2"
if "%choice%"=="2" set "INTERVAL=5"
if "%choice%"=="3" set "INTERVAL=10"
if "%choice%"=="0" goto main_menu

:: 删除旧任务
schtasks /delete /tn "WG-AutoSync" /f >nul 2>&1

:: 创建新任务
schtasks /create /tn "WG-AutoSync" /tr "\"%~f0\" sync" /sc minute /mo %INTERVAL% /ru SYSTEM /rl HIGHEST /f
if %errorlevel%==0 (
    echo [√] 定时任务已创建：每 %INTERVAL% 分钟同步一次
) else (
    echo [错误] 创建定时任务失败
)
pause
goto main_menu

:: 删除定时任务
:do_unregister_task
schtasks /delete /tn "WG-AutoSync" /f >nul 2>&1
echo [√] 定时任务已删除
pause
goto main_menu

:: 查看日志
:do_view_log
cls
echo ═══════════════════════════ 同步日志 ═══════════════════════════
echo.
if exist "%LOG_FILE%" (
    type "%LOG_FILE%"
) else (
    echo [×] 日志文件不存在
)
echo.
pause
goto main_menu

:: 网络共享设置（NAT转发）
:do_network_share
cls
echo ═══════════════════════════════════════════════════════════════════════
echo                        网络共享设置 (高级功能)
echo ═══════════════════════════════════════════════════════════════════════
echo.
echo   此功能允许 WireGuard 网络中的其他节点通过本机访问本地网络
echo   （例如：让远程节点访问本机所在的局域网设备）
echo.
echo   原理：启用 Windows NAT 转发，将 WG 网段流量转发到本地网络
echo.
echo ───────────────────────────────────────────────────────────────────────
echo.

:: 读取配置获取接口名
if exist "%CONFIG_FILE%" (
    setlocal DisableDelayedExpansion
    for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
    setlocal EnableDelayedExpansion
)
if not defined WG_INTERFACE set "WG_INTERFACE=wg0"

echo   当前 WireGuard 接口: %WG_INTERFACE%
echo.
echo   1) 启用网络共享 (配置 NAT)
echo   2) 禁用网络共享 (移除 NAT)
echo   3) 查看当前 NAT 状态
echo   4) 查看网络接口列表
echo   0) 返回主菜单
echo.
set /p ns_choice="请选择: "

if "%ns_choice%"=="1" goto enable_nat
if "%ns_choice%"=="2" goto disable_nat
if "%ns_choice%"=="3" goto show_nat_status
if "%ns_choice%"=="4" goto show_interfaces
if "%ns_choice%"=="0" goto main_menu
goto do_network_share

:enable_nat
cls
echo ═══════════════════════════ 启用网络共享 ═══════════════════════════
echo.
echo   请输入 WireGuard 网段 (例如: 10.8.0.0/24)
echo   这是您 WireGuard 配置中 Address 的网段
echo.
set /p WG_SUBNET="WireGuard 网段 [10.8.0.0/24]: "
if "%WG_SUBNET%"=="" set "WG_SUBNET=10.8.0.0/24"

echo.
echo   请输入 WireGuard 接口别名
echo   (可通过选项 4 查看，通常类似 "wg0" 或 "WGL-xxx")
echo.
set /p WG_ALIAS="接口别名 [%WG_INTERFACE%]: "
if "%WG_ALIAS%"=="" set "WG_ALIAS=%WG_INTERFACE%"

echo.
echo [INFO] 正在配置网络共享...
echo.

:: 1. 启用 IP 转发
echo [1/4] 启用 IP 转发...
powershell -Command "Set-NetIPInterface -Forwarding Enabled -InterfaceAlias '%WG_ALIAS%'" 2>nul
if %errorlevel%==0 (
    echo       [√] WireGuard 接口 IP 转发已启用
) else (
    echo       [×] 启用 IP 转发失败，接口可能不存在
)

:: 2. 设置网络配置文件为专用
echo [2/4] 设置网络配置文件...
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '%WG_ALIAS%' -NetworkCategory Private" 2>nul
if %errorlevel%==0 (
    echo       [√] 网络配置文件已设为专用
) else (
    echo       [×] 设置网络配置文件失败
)

:: 3. 移除旧的 NAT (如果存在)
echo [3/4] 配置 NAT...
powershell -Command "Remove-NetNat -Name 'WG-NAT' -Confirm:$false" 2>nul

:: 4. 创建新的 NAT
powershell -Command "New-NetNat -Name 'WG-NAT' -InternalIPInterfaceAddressPrefix '%WG_SUBNET%'"
if %errorlevel%==0 (
    echo       [√] NAT 规则已创建: WG-NAT (%WG_SUBNET%)
) else (
    echo       [×] 创建 NAT 失败
    echo       [×] 可能原因: 网段已被其他 NAT 使用，或需要重启
)

:: 5. 启用所有接口的转发
echo [4/4] 启用全局 IP 路由...
powershell -Command "Get-NetIPInterface | Where-Object {$_.ConnectionState -eq 'Connected'} | Set-NetIPInterface -Forwarding Enabled" 2>nul
echo       [√] 已尝试启用所有活动接口的转发

echo.
echo ───────────────────────────────────────────────────────────────────────
echo [√] 网络共享配置完成！
echo.
echo [INFO] 远程 WireGuard 节点现在可以通过本机访问本地网络
echo [INFO] 确保远程节点的 AllowedIPs 包含本地网段
echo.
echo [%date% %time%] 网络共享已启用: %WG_SUBNET% >> "%LOG_FILE%"
pause
goto do_network_share

:disable_nat
cls
echo ═══════════════════════════ 禁用网络共享 ═══════════════════════════
echo.
echo [INFO] 正在移除 NAT 配置...
echo.

:: 移除 NAT
powershell -Command "Remove-NetNat -Name 'WG-NAT' -Confirm:$false" 2>nul
if %errorlevel%==0 (
    echo [√] NAT 规则 'WG-NAT' 已移除
) else (
    echo [×] NAT 规则不存在或移除失败
)

echo.
echo [√] 网络共享已禁用
echo [%date% %time%] 网络共享已禁用 >> "%LOG_FILE%"
pause
goto do_network_share

:show_nat_status
cls
echo ═══════════════════════════ NAT 状态 ═══════════════════════════
echo.
echo [当前 NAT 规则]
echo.
powershell -Command "Get-NetNat | Format-Table Name, InternalIPInterfaceAddressPrefix, Active -AutoSize"
echo.
echo [IP 转发状态]
echo.
powershell -Command "Get-NetIPInterface | Where-Object {$_.Forwarding -eq 'Enabled'} | Format-Table InterfaceAlias, AddressFamily, Forwarding -AutoSize"
echo.
pause
goto do_network_share

:show_interfaces
cls
echo ═══════════════════════════ 网络接口列表 ═══════════════════════════
echo.
powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Format-Table Name, InterfaceDescription, Status, MacAddress -AutoSize"
echo.
echo [IP 地址信息]
echo.
powershell -Command "Get-NetIPAddress | Where-Object {$_.AddressState -eq 'Preferred' -and $_.AddressFamily -eq 'IPv4'} | Format-Table InterfaceAlias, IPAddress, PrefixLength -AutoSize"
echo.
pause
goto do_network_share

:: 静默同步模式（用于定时任务）
:silent_sync
if not exist "%CONFIG_FILE%" (
    echo [%date% %time%] 错误: 配置文件不存在 >> "%LOG_FILE%"
    exit /b 1
)
:: 临时禁用延迟扩展来读取配置
setlocal DisableDelayedExpansion
for /f "usebackq tokens=*" %%a in ("%CONFIG_FILE%") do set "%%a"
setlocal EnableDelayedExpansion

set "URL=!SERVER_ADDRESS!?peername=!PEER_NAME!"
set "URL=!URL!&config=!CONFIG_NAME!"
if not "!SECRET!"=="" set "URL=!URL!&secret=!SECRET!"

set "CONF_PATH=!WG_CONFIG_DIR!\!WG_INTERFACE!.conf"
set "TEMP_CONF=!WG_CONFIG_DIR!\!WG_INTERFACE!.conf.tmp"

echo [%date% %time%] 开始同步... >> "%LOG_FILE%"

curl.exe -s -m 15 "!URL!" -o "!TEMP_CONF!"
if not exist "!TEMP_CONF!" (
    echo [%date% %time%] 错误: 无法下载配置 >> "%LOG_FILE%"
    exit /b 1
)

:: 验证配置
findstr /i "\[Interface\]" "!TEMP_CONF!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [%date% %time%] 错误: 配置无效 >> "%LOG_FILE%"
    del "!TEMP_CONF!" 2>nul
    exit /b 1
)

:: 检查是否有变化
if exist "!CONF_PATH!" (
    fc /b "!TEMP_CONF!" "!CONF_PATH!" >nul 2>&1
    if !errorlevel!==0 (
        echo [%date% %time%] 配置无变化 >> "%LOG_FILE%"
        del "!TEMP_CONF!" 2>nul
        exit /b 0
    )
)

move /y "!TEMP_CONF!" "!CONF_PATH!" >nul

:: 热更新
"%WG_EXE%" show "!WG_INTERFACE!" >nul 2>&1
if !errorlevel!==0 (
    call :extract_wg_config "!CONF_PATH!" "!TEMP_CONF!.wg"
    "%WG_EXE%" syncconf "!WG_INTERFACE!" "!TEMP_CONF!.wg" 2>nul
    if !errorlevel!==0 (
        echo [%date% %time%] 配置已热更新 >> "%LOG_FILE%"
    ) else (
        echo [%date% %time%] 热更新失败 >> "%LOG_FILE%"
    )
    del "!TEMP_CONF!.wg" 2>nul
) else (
    echo [%date% %time%] 隧道未运行，配置已保存 >> "%LOG_FILE%"
)
exit /b 0

:end
echo.
echo 再见！
exit /b 0