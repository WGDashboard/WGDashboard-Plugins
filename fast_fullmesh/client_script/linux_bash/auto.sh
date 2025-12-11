#!/bin/bash
#
# Fast Fullmesh Client - Linux
# WireGuard Full Mesh 自动同步客户端
#

CONFIG_FILE="/usr/local/etc/wg-auto-sync.cfg"
SCRIPT_PATH="/usr/local/bin/wg-auto-sync"
LOG_FILE="/var/log/wg-auto-sync.log"
DEPENDENCIES=(wireguard openresolv net-tools iptables curl)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 打印函数
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║   ██╗    ██╗ ██████╗       █████╗ ██╗   ██╗████████╗ ██████╗  ║"
    echo "║   ██║    ██║██╔════╝      ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗ ║"
    echo "║   ██║ █╗ ██║██║  ███╗     ███████║██║   ██║   ██║   ██║   ██║ ║"
    echo "║   ██║███╗██║██║   ██║     ██╔══██║██║   ██║   ██║   ██║   ██║ ║"
    echo "║   ╚███╔███╔╝╚██████╔╝     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝ ║"
    echo "║    ╚══╝╚══╝  ╚═════╝      ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ║"
    echo "║                                                               ║"
    echo "║                 Fast Fullmesh Client                         ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要 root 权限运行"
        print_info "请使用: sudo $0"
        exit 1
    fi
}

# 读取当前配置
read_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

# 保存配置
save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
WG_INTERFACE="$WG_INTERFACE"
SERVER_ADDRESS="$SERVER_ADDRESS"
SECRET="$SECRET"
PEER_NAME="$PEER_NAME"
CONFIG_NAME="$CONFIG_NAME"
EOF
    chmod 600 "$CONFIG_FILE"
}

# 显示当前状态
show_status() {
    echo ""
    echo -e "${PURPLE}═══════════════════ 当前状态 ═══════════════════${NC}"
    echo ""
    
    # 检查安装状态
    if [[ -f "$SCRIPT_PATH" ]]; then
        print_success "脚本已安装: $SCRIPT_PATH"
    else
        print_warning "脚本未安装到系统"
    fi
    
    # 检查配置状态
    if read_config; then
        print_success "配置已设置"
        echo -e "    ${CYAN}接口名称:${NC} $WG_INTERFACE"
        echo -e "    ${CYAN}服务器:${NC} $SERVER_ADDRESS"
        echo -e "    ${CYAN}节点名称:${NC} $PEER_NAME"
        echo -e "    ${CYAN}配置名称:${NC} $CONFIG_NAME"
        echo -e "    ${CYAN}密钥:${NC} ${SECRET:0:8}********"
    else
        print_warning "尚未配置"
    fi
    
    # 检查 WireGuard 接口状态
    if read_config && [[ -n "$WG_INTERFACE" ]]; then
        if ip link show "$WG_INTERFACE" &> /dev/null; then
            print_success "WireGuard 接口 $WG_INTERFACE 运行中"
            # 显示连接数
            local peer_count=$(wg show "$WG_INTERFACE" peers 2>/dev/null | wc -l)
            echo -e "    ${CYAN}已连接节点:${NC} $peer_count"
        else
            print_warning "WireGuard 接口 $WG_INTERFACE 未运行"
        fi
    fi
    
    # 检查定时任务状态
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        print_success "定时同步已启用"
    else
        print_warning "定时同步未启用"
    fi
    
    echo ""
}

# 安装依赖
install_dependencies() {
    print_info "正在检查并安装依赖..."
    apt update -qq
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! dpkg -l | grep -q "^ii  $dep "; then
            print_info "安装 $dep..."
            apt install -y "$dep" > /dev/null 2>&1
        fi
    done
    mkdir -p /etc/wireguard
    print_success "依赖安装完成"
}

# 安装脚本到系统
do_install() {
    echo ""
    print_info "开始安装..."
    
    install_dependencies
    
    mkdir -p "$(dirname "$SCRIPT_PATH")"
    cp -f "$0" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    
    print_success "安装完成！"
    print_info "现在可以使用命令: ${GREEN}wg-auto-sync${NC}"
    echo ""
    read -p "按回车键继续..."
}

# 配置向导
do_configure() {
    echo ""
    echo -e "${PURPLE}═══════════════════ 配置向导 ═══════════════════${NC}"
    echo ""
    
    # 读取现有配置作为默认值
    read_config 2>/dev/null
    
    # 接口名称
    echo -e "${CYAN}[1/5] WireGuard 接口名称${NC}"
    echo -e "      用于标识本地 WireGuard 接口"
    echo -e "      示例: wg0, WGL"
    read -p "      请输入 [${WG_INTERFACE:-WGL}]: " input
    WG_INTERFACE="${input:-${WG_INTERFACE:-WGL}}"
    echo ""
    
    # 服务器地址
    echo -e "${CYAN}[2/5] 服务器地址${NC}"
    echo -e "      Fast Fullmesh API 的完整地址"
    echo -e "      示例: https://wg-api.example.com"
    echo -e "            http://192.168.1.1:18889"
    read -p "      请输入 [${SERVER_ADDRESS:-}]: " input
    SERVER_ADDRESS="${input:-$SERVER_ADDRESS}"
    if [[ -z "$SERVER_ADDRESS" ]]; then
        print_error "服务器地址不能为空"
        read -p "按回车键继续..."
        return 1
    fi
    # 自动补全协议
    if [[ ! "$SERVER_ADDRESS" =~ ^https?:// ]]; then
        SERVER_ADDRESS="http://${SERVER_ADDRESS}"
    fi
    echo ""
    
    # SECRET
    echo -e "${CYAN}[3/5] API 密钥 (SECRET)${NC}"
    echo -e "      用于 API 认证，与服务器端设置相同"
    echo -e "      留空表示服务器未启用认证"
    read -p "      请输入 [${SECRET:+********}]: " input
    SECRET="${input:-$SECRET}"
    echo ""
    
    # 节点名称
    echo -e "${CYAN}[4/5] 本机节点名称${NC}"
    echo -e "      在 WGDashboard 中配置的 Peer 名称"
    echo -e "      示例: WGL-home, WGL-office"
    read -p "      请输入 [${PEER_NAME:-}]: " input
    PEER_NAME="${input:-$PEER_NAME}"
    if [[ -z "$PEER_NAME" ]]; then
        print_error "节点名称不能为空"
        read -p "按回车键继续..."
        return 1
    fi
    echo ""
    
    # 配置名称
    echo -e "${CYAN}[5/5] WireGuard 配置名称${NC}"
    echo -e "      WGDashboard 中的配置名称"
    echo -e "      示例: WGL"
    read -p "      请输入 [${CONFIG_NAME:-WGL}]: " input
    CONFIG_NAME="${input:-${CONFIG_NAME:-WGL}}"
    echo ""
    
    # 确认配置
    echo -e "${PURPLE}═══════════════════ 配置确认 ═══════════════════${NC}"
    echo ""
    echo -e "    ${CYAN}接口名称:${NC} $WG_INTERFACE"
    echo -e "    ${CYAN}服务器:${NC} $SERVER_ADDRESS"
    echo -e "    ${CYAN}节点名称:${NC} $PEER_NAME"
    echo -e "    ${CYAN}配置名称:${NC} $CONFIG_NAME"
    echo -e "    ${CYAN}密钥:${NC} ${SECRET:-（无）}"
    echo ""
    
    read -p "确认保存配置? [Y/n]: " confirm
    if [[ "${confirm,,}" != "n" ]]; then
        save_config
        print_success "配置已保存到 $CONFIG_FILE"
    else
        print_warning "配置未保存"
    fi
    
    echo ""
    read -p "按回车键继续..."
}

# 执行同步
do_sync() {
    echo ""
    print_info "开始同步 WireGuard 配置..."
    echo ""
    
    if ! read_config; then
        print_error "配置文件不存在，请先进行配置"
        read -p "按回车键继续..."
        return 1
    fi
    
    # 构建 URL（SERVER_ADDRESS 已包含协议）
    local URL="${SERVER_ADDRESS}?peername=${PEER_NAME}&config=${CONFIG_NAME}"
    if [[ -n "$SECRET" ]]; then
        URL="${URL}&secret=${SECRET}"
    fi
    
    local CONFIG_PATH="/etc/wireguard/${WG_INTERFACE}.conf"
    local TEMP_CONFIG="/tmp/${WG_INTERFACE}.conf.tmp"
    
    print_info "正在从服务器获取配置..."
    print_info "URL: ${SERVER_ADDRESS}?peername=${PEER_NAME}&config=${CONFIG_NAME}&secret=***"
    
    # 下载配置
    if ! curl -s -f -m 15 "${URL}" -o "${TEMP_CONFIG}" 2>/dev/null; then
        print_error "无法连接服务器或下载配置"
        rm -f "${TEMP_CONFIG}"
        read -p "按回车键继续..."
        return 1
    fi
    
    # 检查文件
    if [[ ! -s "${TEMP_CONFIG}" ]]; then
        print_error "下载的配置文件为空"
        rm -f "${TEMP_CONFIG}"
        read -p "按回车键继续..."
        return 1
    fi
    
    # 检查是否为 HTML 页面（Nginx 错误页等）
    if grep -qi "<html>\|<!DOCTYPE" "${TEMP_CONFIG}"; then
        print_error "服务器返回了 HTML 页面而非配置文件"
        print_error "请检查 API 地址是否正确，或服务器是否正常运行"
        head -5 "${TEMP_CONFIG}"
        rm -f "${TEMP_CONFIG}"
        echo ""
        read -p "按回车键继续..."
        return 1
    fi
    
    # 检查是否包含有效的 WireGuard 配置
    if ! grep -q "\[Interface\]" "${TEMP_CONFIG}"; then
        print_error "响应不是有效的 WireGuard 配置:"
        cat "${TEMP_CONFIG}"
        rm -f "${TEMP_CONFIG}"
        echo ""
        read -p "按回车键继续..."
        return 1
    fi
    
    # 检查 API 错误信息
    if grep -qi "forbidden\|not found\|error\|please set" "${TEMP_CONFIG}"; then
        print_error "服务器返回错误:"
        cat "${TEMP_CONFIG}"
        rm -f "${TEMP_CONFIG}"
        echo ""
        read -p "按回车键继续..."
        return 1
    fi
    
    # 检查是否有变化
    if [[ -f "${CONFIG_PATH}" ]] && diff -q "${TEMP_CONFIG}" "${CONFIG_PATH}" > /dev/null 2>&1; then
        print_info "配置无变化，无需更新"
        rm -f "${TEMP_CONFIG}"
        read -p "按回车键继续..."
        return 0
    fi
    
    # 保存配置
    mv "${TEMP_CONFIG}" "${CONFIG_PATH}"
    chmod 600 "${CONFIG_PATH}"
    print_success "配置已保存到 ${CONFIG_PATH}"
    
    # 应用配置
    if ip link show "${WG_INTERFACE}" &> /dev/null; then
        print_info "接口已存在，尝试热更新..."
        if wg syncconf "${WG_INTERFACE}" <(wg-quick strip "${CONFIG_PATH}") 2>/dev/null; then
            print_success "配置热更新成功（连接未中断）"
        else
            print_warning "热更新失败，正在重启接口..."
            wg-quick down "${WG_INTERFACE}" 2>/dev/null
            if wg-quick up "${WG_INTERFACE}"; then
                print_success "接口已重启"
            else
                print_error "接口启动失败"
                read -p "按回车键继续..."
                return 1
            fi
        fi
    else
        print_info "正在创建接口..."
        if wg-quick up "${WG_INTERFACE}"; then
            print_success "接口创建成功"
        else
            print_error "接口创建失败"
            read -p "按回车键继续..."
            return 1
        fi
    fi
    
    echo ""
    print_success "同步完成！"
    echo ""
    
    # 显示简要状态
    print_info "当前连接状态:"
    wg show "${WG_INTERFACE}" 2>/dev/null | head -20
    
    echo ""
    read -p "按回车键继续..."
}

# 管理定时任务
do_crontab() {
    echo ""
    echo -e "${PURPLE}═══════════════════ 定时同步 ═══════════════════${NC}"
    echo ""
    
    local cron_exists=0
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        cron_exists=1
        print_success "定时同步当前状态: 已启用"
    else
        print_warning "定时同步当前状态: 未启用"
    fi
    
    echo ""
    echo "  1) 启用定时同步 (每2分钟)"
    echo "  2) 启用定时同步 (每5分钟)"
    echo "  3) 启用定时同步 (每10分钟)"
    echo "  4) 禁用定时同步"
    echo "  5) 查看日志"
    echo "  0) 返回"
    echo ""
    
    read -p "请选择 [0-5]: " choice
    
    case $choice in
        1)
            (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "*/2 * * * * $SCRIPT_PATH sync >> $LOG_FILE 2>&1") | crontab -
            print_success "已启用: 每2分钟同步一次"
            ;;
        2)
            (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "*/5 * * * * $SCRIPT_PATH sync >> $LOG_FILE 2>&1") | crontab -
            print_success "已启用: 每5分钟同步一次"
            ;;
        3)
            (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "*/10 * * * * $SCRIPT_PATH sync >> $LOG_FILE 2>&1") | crontab -
            print_success "已启用: 每10分钟同步一次"
            ;;
        4)
            crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
            print_success "定时同步已禁用"
            ;;
        5)
            echo ""
            if [[ -f "$LOG_FILE" ]]; then
                print_info "最近的日志 (按 q 退出):"
                tail -50 "$LOG_FILE" | less
            else
                print_warning "日志文件不存在"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "按回车键继续..."
}

# 查看 WireGuard 状态
do_wg_status() {
    echo ""
    echo -e "${PURPLE}═══════════════════ WireGuard 状态 ═══════════════════${NC}"
    echo ""
    
    read_config 2>/dev/null
    
    if [[ -n "$WG_INTERFACE" ]] && ip link show "$WG_INTERFACE" &> /dev/null; then
        wg show "$WG_INTERFACE"
    else
        print_warning "WireGuard 接口未运行"
        echo ""
        echo "可用的 WireGuard 接口:"
        ls /etc/wireguard/*.conf 2>/dev/null | xargs -I {} basename {} .conf || echo "  无"
    fi
    
    echo ""
    read -p "按回车键继续..."
}

# 启动/停止接口
do_interface_control() {
    echo ""
    echo -e "${PURPLE}═══════════════════ 接口控制 ═══════════════════${NC}"
    echo ""
    
    read_config 2>/dev/null
    local iface="${WG_INTERFACE:-WGL}"
    
    if ip link show "$iface" &> /dev/null; then
        print_success "接口 $iface 当前状态: 运行中"
    else
        print_warning "接口 $iface 当前状态: 已停止"
    fi
    
    echo ""
    echo "  1) 启动接口"
    echo "  2) 停止接口"
    echo "  3) 重启接口"
    echo "  0) 返回"
    echo ""
    
    read -p "请选择 [0-3]: " choice
    
    case $choice in
        1)
            if wg-quick up "$iface" 2>/dev/null; then
                print_success "接口已启动"
            else
                print_error "启动失败"
            fi
            ;;
        2)
            if wg-quick down "$iface" 2>/dev/null; then
                print_success "接口已停止"
            else
                print_error "停止失败"
            fi
            ;;
        3)
            wg-quick down "$iface" 2>/dev/null
            if wg-quick up "$iface" 2>/dev/null; then
                print_success "接口已重启"
            else
                print_error "重启失败"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    echo ""
    read -p "按回车键继续..."
}

# 卸载
do_uninstall() {
    echo ""
    print_warning "即将卸载 wg-auto-sync"
    echo ""
    echo "将删除:"
    echo "  - $SCRIPT_PATH"
    echo "  - $CONFIG_FILE"
    echo "  - 定时任务"
    echo ""
    
    read -p "确认卸载? [y/N]: " confirm
    if [[ "${confirm,,}" == "y" ]]; then
        crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
        rm -f "$SCRIPT_PATH" "$CONFIG_FILE"
        print_success "卸载完成"
    else
        print_info "已取消"
    fi
    
    echo ""
    read -p "按回车键继续..."
}

# 主菜单
main_menu() {
    while true; do
        print_banner
        show_status
        
        echo -e "${PURPLE}═══════════════════ 主菜单 ═══════════════════${NC}"
        echo ""
        echo "  1) 📦 安装到系统"
        echo "  2) ⚙️  配置参数"
        echo "  3) 🔄 立即同步"
        echo "  4) ⏰ 定时同步设置"
        echo "  5) 📊 WireGuard 状态"
        echo "  6) 🔌 接口控制"
        echo "  9) 🗑️  卸载"
        echo "  0) 退出"
        echo ""
        
        read -p "请选择 [0-9]: " choice
        
        case $choice in
            1) do_install ;;
            2) do_configure ;;
            3) do_sync ;;
            4) do_crontab ;;
            5) do_wg_status ;;
            6) do_interface_control ;;
            9) do_uninstall ;;
            0) 
                echo ""
                print_info "再见！"
                exit 0
                ;;
            *)
                print_error "无效选项"
                sleep 1
                ;;
        esac
    done
}

# 静默同步模式（用于定时任务）
silent_sync() {
    if ! read_config; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误: 配置文件不存在"
        exit 1
    fi
    
    # SERVER_ADDRESS 已包含协议
    local URL="${SERVER_ADDRESS}?peername=${PEER_NAME}&config=${CONFIG_NAME}"
    if [[ -n "$SECRET" ]]; then
        URL="${URL}&secret=${SECRET}"
    fi
    
    local CONFIG_PATH="/etc/wireguard/${WG_INTERFACE}.conf"
    local TEMP_CONFIG="/tmp/${WG_INTERFACE}.conf.tmp"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始同步..."
    
    if ! curl -s -f -m 15 "${URL}" -o "${TEMP_CONFIG}" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误: 无法下载配置"
        rm -f "${TEMP_CONFIG}"
        exit 1
    fi
    
    # 检查是否为 HTML 或无效配置
    if [[ ! -s "${TEMP_CONFIG}" ]] || \
       grep -qi "<html>\|<!DOCTYPE" "${TEMP_CONFIG}" || \
       ! grep -q "\[Interface\]" "${TEMP_CONFIG}" || \
       grep -qi "forbidden\|not found\|error" "${TEMP_CONFIG}"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误: 配置无效"
        rm -f "${TEMP_CONFIG}"
        exit 1
    fi
    
    if [[ -f "${CONFIG_PATH}" ]] && diff -q "${TEMP_CONFIG}" "${CONFIG_PATH}" > /dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 配置无变化"
        rm -f "${TEMP_CONFIG}"
        exit 0
    fi
    
    mv "${TEMP_CONFIG}" "${CONFIG_PATH}"
    chmod 600 "${CONFIG_PATH}"
    
    if ip link show "${WG_INTERFACE}" &> /dev/null; then
        if wg syncconf "${WG_INTERFACE}" <(wg-quick strip "${CONFIG_PATH}") 2>/dev/null; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 配置已热更新"
        else
            wg-quick down "${WG_INTERFACE}" 2>/dev/null
            wg-quick up "${WG_INTERFACE}"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 接口已重启"
        fi
    else
        wg-quick up "${WG_INTERFACE}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 接口已创建"
    fi
}

# 入口
check_root

case "${1:-}" in
    sync)
        # 静默同步模式（用于 cron）
        silent_sync
        ;;
    *)
        # 交互式菜单
        main_menu
        ;;
esac
