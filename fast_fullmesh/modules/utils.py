"""工具函数模块"""
from datetime import datetime


def log_info(message: str):
    """输出信息日志"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] [INFO] {message}")


def log_error(message: str):
    """输出错误日志"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] [ERROR] {message}")


def safe_get(data: dict, *keys, default=None):
    """安全获取嵌套字典的值"""
    result = data
    for key in keys:
        if isinstance(result, dict):
            result = result.get(key, default)
        else:
            return default
    return result if result is not None else default
