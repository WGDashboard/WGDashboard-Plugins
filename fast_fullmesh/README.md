# Fast Full Mesh Plugin

[English](README_EN.md)

WGDashboard 插件,用于自动生成 WireGuard 配置(Half Mesh)并集中管理。

该插件已作为项目开源：[fast_fullmesh](https://github.com/xinghenLuyus/fast_fullmesh)，后续不在此处更新。

## 特性

- 基于标签的自动化配置，无需UI，所有操作都在 WGDashboard 中完成。
- 支持全节点 Full Mesh，也支持在fullmesh节点中找一个节点接入其它 peer (非 Full Mesh 节点)，组成 Half Mesh 网络，全节点互联。
- 客户端主动订阅配置，实现配置统一集中管理。

## 安装部署

1. 将 `fast_fullmesh` 文件夹复制到 WGDashboard 插件目录
2. 设置系统环境变量`FAST_FULLMESH_SECRET`用于加密 API
3. 重启 WGDashboard
4. 使用 `Nginx` 或别的反向代理启用 `https` ，防止秘钥明文传输。
5. 从 `client_script` 中找到对应接收端脚本，按照提示操作即可。

**WARING：默认部署有 WGDashBoard 的设备本身就是 Wireguard 网络的节点之一(以下统称主节点，和中心节点不同)，而且必须是 Full Mesh 网络的节点。**

![exm](exm.png)

## 标签说明

- `full-mesh` ： 使节点参与全网状（Full Mesh）网络。如果节点有此标签，将与其他所有有标签的节点建立双向连接。该标签可存在多个，且主节点自带。
- `endpoint%ipv4:port` 或 `endpoint%ipv4:port,ipv6:port` ： 自定义端点配置，用于覆盖默认的端点末端地址。支持IPv4和IPv6地址。所有 `full-mesh` 节点都应有专属于自己的 `endpoint` 标签。
- `ipv6` ： 表示节点仅支持IPv6连接。此时该节点可以使用 `endpoint%ipv6:port` 标签，其余节点都应使用 `endpoint%ipv4:port,ipv6:port` 。因为 `ipv4` 连接是默认的。
- `center` ： 将节点标记为中心节点。该标签唯一存在。如果没有节点有 `center` 标签，则默认使用主节点作为中心节点。
- `xTo%节点名` ： 已废除。

## 功能介绍

### [Interface]

1. `Address` ： 字段来自 `允许的IP地址`；针对部署有 WGDashBoard 的节点(主节点)，字段来自`IP 地址/前缀长度`，并修改子网掩码为`/32`。

*如果你将主节点配置 `IP 地址/前缀长度` 设置成 `IP/32` ，那么 WGDashBoard 将不能正常添加节点，这就是我做特殊处理的原因*

2. `PrivateKey`,`DNS`,`MTU`,`ListenPort` ： 均来自 WGDashBoard 相同配置。

### [Peer]

在开始之前，先讲一下 Wireguard 的 网络逻辑。Wireguard 会在当前节点设备自动劫持 `AllowedIPs` 配置中的所有流量，也就是出站流量，发往当前 `Peer` 的节点。Wireguard 在设计初就不区分 Server 和 Client ，支持多个 `Peer` ，天然支持 Mesh 互联、混联(只要路由逻辑正确)。

1. `Peer数量1`： 假设所有标记 **`full-mesh`** 标签的节点（主节点默认）数量总计为 `N` ，其所在配置的 [Peer]块 数量应当为 `N-1` ,即全部互联。

2. `Peer数量2`： 如果当前节点为标记 **`center`** 标签的节点(如果没有标签，默认是主节点)，即**中心节点**，其所在配置的 [Peer]块 应该包含所有 非 Full Mesh 节点 的对等块。

3. `Peer数量3`： 如果当前节点**没有**标记 **`full-mesh`** 标签，即 **非 Full Mesh 节点** ，其所在配置的 [Peer]块 应该**只包含** 中心节点 的对等块。

4. `Endpoint`： 主节点来自配置 `端点末端地址` ，其余端点来自来自标签 **`endpoint%ipv4:port`** 或**`endpoint%ipv4:port,ipv6:port`**。

5. `AllowedIPs`： `Full Mesh节点` 来自各自对等节点的 `终结点允许的 IP 地址` ，对于中心节点，还要加上所有 非 Full Mesh 节点 的IP确保流量正常穿透。 `非 Full Mesh 节点` 则填写所有 `终结点允许的 IP 地址` 的并集。

6. `PublicKey`,`PersistentKeepalive`： 均来自 WGDashBoard 相同配置，暂不支持 `PresharedKey` 共享密钥。

*这一段只讲原理，看不懂逻辑没关系。*

## 文件结构

```
fast_fullmesh/
├── main.py                  # 插件入口, HTTP 服务器
├── modules/
│   ├── config_generator.py  # 配置生成核心逻辑
│   ├── tag_parser.py        # PeerGroups 标签解析
│   └── utils.py             # 工具函数 (日志, 安全取值)
├── client_script/           # 客户端自动化订阅插件
└── README.md
```

## API 接口

**示例(仅测试):**
```bash
curl "http://服务器IP:18889/?peername=********&config=********&secret=********" > wg0.conf
```

正式使用时应该启用 `https` ，避免秘以明文形式在公网传输。

## Thanks

- `ChenYFan`提供的思路以及原项目地址：[EasyWGSync](https://github.com/ChenYFan/EasyWGSync)
- `WGDashBoard`的插件平台：[WGDashboard-Plugins](https://github.com/WGDashboard/WGDashboard-Plugins)

