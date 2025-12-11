"""PeerGroups 标签解析模块"""
from typing import Dict, List, Tuple


def parse_peer_groups(peer_groups: dict) -> Dict[str, List[str]]:
    """
    解析 PeerGroups, 返回 {PublicKey: [tags]} 的映射
    
    Args:
        peer_groups: Info.PeerGroups 字典
        
    Returns:
        {peer_pubkey: [tag1, tag2, ...]}
    """
    peer_tags_map = {}
    
    for group_id, group_info in peer_groups.items():
        group_name = group_info.get('GroupName', '')
        peers = group_info.get('Peers', [])
        
        for peer_pubkey in peers:
            if peer_pubkey not in peer_tags_map:
                peer_tags_map[peer_pubkey] = []
            peer_tags_map[peer_pubkey].append(group_name)
    
    return peer_tags_map


def is_full_mesh_peer(tags: List[str], is_main: bool = False) -> bool:
    """
    判断 Peer 是否参与 Full Mesh
    
    Args:
        tags: Peer 的标签列表
        is_main: 是否是主节点 (主节点默认参与 Full Mesh)
        
    Returns:
        True 如果参与 Full Mesh
    """
    if is_main:
        return True
    return 'full-mesh' in tags


def parse_to_targets(tags: List[str]) -> List[Tuple[int, str]]:
    """
    解析 xTo%节点名 标签
    
    Args:
        tags: Peer 的标签列表
        
    Returns:
        [(priority, peer_name), ...] 按优先级排序 (数字越小优先级越高)
        
    示例:
        ['1To%WGL', '3To%WGL-home'] -> [(1, 'WGL'), (3, 'WGL-home')]
        ['2To%node1'] -> [(2, 'node1')]  # 缺失优先级1,将由调用者补充主节点
    """
    targets = []
    
    for tag in tags:
        if 'To%' in tag:
            # 格式: "1To%WGL-home"
            parts = tag.split('To%')
            if len(parts) == 2:
                try:
                    priority = int(parts[0])
                    peer_name = parts[1]
                    targets.append((priority, peer_name))
                except ValueError:
                    pass  # 忽略无效格式
    
    return sorted(targets)  # 按优先级数字升序排序


def should_add_main_node_default(to_targets: List[Tuple[int, str]]) -> bool:
    """
    判断是否需要自动添加主节点作为默认连接
    
    规则:
    - 无任何 xTo% 标签: 需要添加 (优先级1)
    - 有 xTo% 但缺失优先级1: 需要添加 (优先级1)
    
    Args:
        to_targets: parse_to_targets() 的返回值
        
    Returns:
        True 如果需要自动添加主节点
    """
    if not to_targets:
        return True  # 无任何标签,需要添加
    
    # 检查是否有优先级1的连接
    has_priority_1 = any(priority == 1 for priority, _ in to_targets)
    return not has_priority_1  # 缺失优先级1,需要添加


def get_endpoint_from_tag(tags: List[str]) -> tuple:
    """
    从标签中提取自定义端点
    
    Args:
        tags: Peer 的标签列表
        
    Returns:
        (ipv4_endpoint, ipv6_endpoint) 元组
        格式: endpoint%ipv4:port,ipv6:port 或 endpoint%ipv4:port
    """
    for tag in tags:
        if tag.startswith('endpoint%'):
            endpoint_str = tag.replace('endpoint%', '')
            if ',' in endpoint_str:
                parts = endpoint_str.split(',', 1)
                return (parts[0].strip(), parts[1].strip())
            else:
                return (endpoint_str.strip(), None)
    return (None, None)


def has_ipv6_only(tags: List[str]) -> bool:
    """
    判断节点是否只支持 IPv6
    
    Args:
        tags: Peer 的标签列表
        
    Returns:
        True 如果节点有 ipv6 标签
    """
    return 'ipv6' in tags
