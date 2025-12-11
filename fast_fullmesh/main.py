"""EasyWGSync Full Mesh Plugin - WGDashboard 插件入口"""
import http.server
import socketserver
import os
from urllib.parse import urlparse, parse_qs

from modules.config_generator import generate_full_mesh_config
from modules.utils import log_info, log_error


# 从环境变量读取 SECRET，如果未设置则为空（不验证）
API_SECRET = os.environ.get('FAST_FULLMESH_SECRET', '')


def main(WireguardConfigurations: dict[str, object]):
    """
    插件主函数 - 启动 HTTP 服务器
    
    注意: WGDashboard 已将每个插件的 main() 函数在独立线程中运行,
         因此不需要额外创建后台线程。WireguardConfigurations 参数
         会自动获取最新数据。
    """
    PORT = 18889
    
    class RequestHandler(http.server.BaseHTTPRequestHandler):
        def _send_error_utf8(self, code: int, message: str):
            """发送错误响应 (UTF-8 编码到 body)"""
            self.send_response(code)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(message.encode('utf-8'))
        
        def do_GET(self):
            """处理 GET 请求"""
            try:
                # 解析 URL 参数
                parsed = urlparse(self.path)
                params = parse_qs(parsed.query)
                
                # 获取客户端 IP
                real_ip = self.headers.get('X-Real-IP') or \
                         self.headers.get('X-Forwarded-For') or \
                         self.client_address[0]
                
                # 验证 SECRET（如果配置了）
                if API_SECRET:
                    secret = params.get('secret', [None])[0]
                    if secret != API_SECRET:
                        log_error(f"来自 {real_ip} 的未授权访问: secret 不匹配")
                        self._send_error_utf8(403, "API Forbidden: Invalid secret")
                        return
                    log_info(f"来自 {real_ip} 的请求已通过 secret 验证")
                
                peer_name = params.get('peername', [None])[0]
                config_name = params.get('config', [None])[0]
                
                # 验证参数
                if not peer_name or not config_name:
                    self._send_error_utf8(400, "Missing parameters: peername and config are required")
                    return
                
                # 验证配置是否存在
                if config_name not in WireguardConfigurations:
                    self._send_error_utf8(404, f"Config '{config_name}' not found")
                    return
                
                # 生成配置
                log_info(f"生成配置: peername={peer_name}, config={config_name} (来自 {real_ip})")
                result = generate_full_mesh_config(
                    peer_name=peer_name,
                    config_name=config_name,
                    wg_configs=WireguardConfigurations
                )
                
                if not result:
                    self._send_error_utf8(404, f"Peer '{peer_name}' not found")
                    return
                
                # 返回配置文件
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(result.encode('utf-8'))
                
            except Exception as e:
                log_error(f"请求处理失败: {str(e)}")
                import traceback
                log_error(traceback.format_exc())
                self._send_error_utf8(500, f"Server error: {str(e)}")
        
        def log_message(self, format, *args):
            """禁用默认日志"""
            pass
    
    # 启动 HTTP 服务器 (阻塞运行，支持并发)
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("0.0.0.0", PORT), RequestHandler) as server:
        log_info(f"✅ EasyWGSync Full Mesh API 已启动: http://0.0.0.0:{PORT}/")
        log_info(f"📝 用法: http://服务器IP:{PORT}/?peername=xxx&config=xxx&secret=xxx")
        if API_SECRET:
            log_info(f"🔒 SECRET 认证已启用")
        else:
            log_info(f"⚠️  SECRET 认证未启用 (请设置环境变量 EASYWGSYNC_SECRET)")
        log_info(f"🔄 配置自动同步 (WGDashboard 提供最新数据)")
        server.serve_forever()