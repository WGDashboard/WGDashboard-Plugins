"""Full Mesh 配置生成器 - 重构版"""
from typing import Dict, List, Optional, Tuple
from modules.tag_parser import (
    parse_peer_groups, 
    get_endpoint_from_tag,
    has_ipv6_only
)
from modules.utils import safe_get


def generate_full_mesh_config(
    peer_name: str,
    config_name: str,
    wg_configs: dict
) -> str:
    wg_config = wg_configs[config_name]
    base_config = wg_config.toJson()  # type: ignore
    
    peers_list = wg_config.getPeersList()  # type: ignore
    peers_data = [p.toJson() if hasattr(p, 'toJson') else p for p in peers_list]  # type: ignore
    
    peers_endpoint = _get_real_endpoints(wg_config)
    
    peer_groups = safe_get(base_config, 'Info', 'PeerGroups', default={})
    peer_tags = parse_peer_groups(peer_groups)
    
    all_nodes = _build_all_nodes(base_config, peers_data, peer_tags)
    center_node_name = _find_center_node(all_nodes)
    target_node = all_nodes.get(peer_name)
    
    if not target_node:
        return ""
    
    result = _build_interface(target_node)
    result += "\n\n"
    
    if target_node['is_full_mesh']:
        result += _add_fullmesh_peers(target_node, all_nodes, peers_endpoint, base_config, center_node_name)
    else:
        result += _add_non_fullmesh_peers(target_node, all_nodes, peers_endpoint, base_config, center_node_name)
    
    return result


def _build_all_nodes(base_config: dict, peers_data: List[dict], peer_tags: Dict[str, List[str]]) -> Dict[str, dict]:
    all_nodes = {}
    main_pubkey = base_config.get('PublicKey')
    main_name = base_config.get('Name')
    
    main_allowed_ips = safe_get(base_config, 'Info', 'OverridePeerSettings', 'EndpointAllowedIPs')
    if not main_allowed_ips:
        main_allowed_ips = base_config.get('Address')

    all_nodes[main_name] = {
        'name': main_name,
        'pubkey': main_pubkey,
        'private_key': base_config.get('PrivateKey'),
        'interface_ip': base_config.get('Address'),
        'allowed_ips': main_allowed_ips,
        'dns': safe_get(base_config, 'Info', 'OverridePeerSettings', 'DNS', default=''),
        'mtu': base_config.get('MTU', 1420),
        'keepalive': 0,
        'preshared_key': '',
        'tags': [],
        'is_main': True,
        'is_full_mesh': True
    }
    
    for peer in peers_data:
        peer_name = peer.get('name')
        peer_pubkey = peer.get('id')
        tags = peer_tags.get(peer_pubkey, [])
        
        interface_ip = peer.get('allowed_ip', '')

        allowed_ips = peer.get('endpoint_allowed_ip')
        if not allowed_ips:
             allowed_ips = interface_ip
        
        all_nodes[peer_name] = {
            'name': peer_name,
            'pubkey': peer_pubkey,
            'private_key': peer.get('private_key'),
            'interface_ip': interface_ip,
            'allowed_ips': allowed_ips,
            'dns': peer.get('DNS', ''),
            'mtu': peer.get('mtu', 1420),
            'keepalive': peer.get('keepalive', 0),
            'preshared_key': peer.get('preshared_key', ''),
            'endpoint': peer.get('endpoint'),
            'tags': tags,
            'is_main': False,
            'is_full_mesh': 'full-mesh' in tags
        }
    
    return all_nodes


def _find_center_node(all_nodes: Dict[str, dict]) -> str:
    for node_name, node in all_nodes.items():
        if 'center' in node['tags']:
            return node_name
    
    for node_name, node in all_nodes.items():
        if node['is_main']:
            return node_name
    
    return list(all_nodes.keys())[0] if all_nodes else ""


def _calculate_allowed_ips_union(all_nodes: Dict[str, dict], exclude_node_name: str) -> str:
    allowed_ips_set = set()
    
    for node_name, node in all_nodes.items():
        if node_name == exclude_node_name:
            continue
        
        allowed_ips = node.get('allowed_ips', '')
        if not allowed_ips:
            continue
        
        if ',' in allowed_ips:
            ips = [ip.strip() for ip in allowed_ips.split(',')]
        else:
            ips = [allowed_ips.strip()]
        
        for ip in ips:
            if ip:
                allowed_ips_set.add(ip)
    
    return ', '.join(sorted(allowed_ips_set))


def _add_fullmesh_peers(
    target_node: dict,
    all_nodes: Dict[str, dict],
    peers_endpoint: dict,
    base_config: dict,
    center_node_name: str
) -> str:
    result = ""
    target_keepalive = target_node.get('keepalive', 0)
    is_center = (target_node['name'] == center_node_name)
    target_needs_ipv6 = has_ipv6_only(target_node['tags'])
    
    for peer_name, peer_node in all_nodes.items():
        if peer_name == target_node['name']:
            continue
        
        if not peer_node['is_full_mesh']:
            if is_center:
                result += f"\n[Peer]\n"
                result += f"PublicKey = {peer_node['pubkey']}\n"
                result += f"AllowedIPs = {peer_node['allowed_ips']}\n"
                
                if peer_node['preshared_key']:
                    result += f"PresharedKey = {peer_node['preshared_key']}\n"
            continue
        
        peer_needs_ipv6 = has_ipv6_only(peer_node['tags'])
        use_ipv6 = target_needs_ipv6 or peer_needs_ipv6
        endpoint = _resolve_endpoint(peer_node, peers_endpoint, base_config, use_ipv6=use_ipv6)
        
        result += f"\n[Peer]\n"
        result += f"PublicKey = {peer_node['pubkey']}\n"
        
        if endpoint:
            result += f"Endpoint = {endpoint}\n"
        
        allowed_ips_parts = [peer_node['allowed_ips']]
        
        if peer_name == center_node_name:
            for node_name, node in all_nodes.items():
                if not node['is_full_mesh'] and node_name != target_node['name']:
                    allowed_ips_parts.append(node['allowed_ips'])
        
        result += f"AllowedIPs = {', '.join(allowed_ips_parts)}\n"
        
        if target_keepalive > 0 and endpoint:
            result += f"PersistentKeepalive = {target_keepalive}\n"
        
        if peer_node['preshared_key']:
            result += f"PresharedKey = {peer_node['preshared_key']}\n"
    
    return result


def _add_non_fullmesh_peers(
    target_node: dict,
    all_nodes: Dict[str, dict],
    peers_endpoint: dict,
    base_config: dict,
    center_node_name: str
) -> str:
    result = ""
    target_keepalive = target_node.get('keepalive', 0)
    
    center_node = all_nodes.get(center_node_name)
    if not center_node:
        return result
    
    all_allowed_ips = _calculate_allowed_ips_union(all_nodes, target_node['name'])
    
    target_needs_ipv6 = has_ipv6_only(target_node['tags'])
    endpoint = _resolve_endpoint(center_node, peers_endpoint, base_config, use_ipv6=target_needs_ipv6)
    
    result += f"\n[Peer]\n"
    result += f"PublicKey = {center_node['pubkey']}\n"
    
    if endpoint:
        result += f"Endpoint = {endpoint}\n"
    
    result += f"AllowedIPs = {all_allowed_ips}\n"
    
    if target_keepalive > 0 and endpoint:
        result += f"PersistentKeepalive = {target_keepalive}\n"
    
    if center_node['preshared_key']:
        result += f"PresharedKey = {center_node['preshared_key']}\n"
    
    return result


def _resolve_endpoint(peer_node: dict, peers_endpoint: dict, base_config: dict, use_ipv6: bool = False) -> Optional[str]:
    """
    解析端点 (优先级: 标签 > 主节点配置 > 实时端点 > 配置端点)
    
    Args:
        peer_node: 对端节点信息
        peers_endpoint: 实时端点映射
        base_config: 主配置
        use_ipv6: 是否使用 IPv6 端点
    """
    # 1. 检查 endpoint% 标签
    tag_ipv4, tag_ipv6 = get_endpoint_from_tag(peer_node['tags'])
    if use_ipv6:
        if tag_ipv6:
            return tag_ipv6
        elif tag_ipv4:
            return tag_ipv4
    else:
        if tag_ipv4:
            return tag_ipv4
    
    # 2. 主节点端点
    if peer_node['is_main']:
        remote_endpoints = safe_get(base_config, 'Info', 'OverridePeerSettings', 'PeerRemoteEndpoint', default='127.0.0.1')
        port = base_config.get('ListenPort', '51820')
        
        if ',' in remote_endpoints:
            parts = remote_endpoints.split(',', 1)
            ipv4_addr = parts[0].strip()
            ipv6_addr = parts[1].strip()
            if use_ipv6:
                if ipv6_addr:
                    return f"{ipv6_addr}:{port}"
                else:
                    return "please set ipv6"
            else:
                return f"{ipv4_addr}:{port}"
        else:
            if use_ipv6:
                return "please set ipv6"
            return f"{remote_endpoints}:{port}"
    
    # 3. 实时端点 (full-mesh 节点才使用)
    if peer_node['is_full_mesh']:
        peer_pubkey = peer_node['pubkey']
        if peer_pubkey in peers_endpoint:
            endpoint = peers_endpoint[peer_pubkey]
            if endpoint and endpoint != "(none)" and "none" not in endpoint.lower():
                return endpoint
    
    # 4. 配置中的端点
    configured_endpoint = peer_node.get('endpoint')
    if configured_endpoint and configured_endpoint != "(none)":
        return configured_endpoint
    
    return None


def _build_interface(node: dict) -> str:
    result = "[Interface]\n"
    result += f"PrivateKey = {node['private_key']}\n"
    
    interface_ip = node['interface_ip']
    if node.get('is_main') and interface_ip and '/' in interface_ip:
        ip_addr = interface_ip.split('/')[0]
        interface_ip = f"{ip_addr}/32"
    
    result += f"Address = {interface_ip}\n"
    
    dns = node.get('dns', '')
    if dns:
        result += f"DNS = {dns}\n"
    
    mtu = node.get('mtu')
    if mtu:
        result += f"MTU = {mtu}\n"
    
    result += f"ListenPort = 51820\n"
    
    return result


def _get_real_endpoints(wg_config: object) -> dict:
    """获取实时端点"""
    try:
        endpoint_data = wg_config.getPeersEndpoint()  # type: ignore
        return endpoint_data if endpoint_data else {}
    except:
        return {}

