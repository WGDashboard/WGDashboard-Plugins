# WG Auto Script

当前脚本用于没有安装 WGDashBoard 的其它节点自动配置 Wireguard 网络，并定期同步配置。

## 步骤

1. 节点安装 Wireguard 。
2. 选择对应系统的脚本。
- Linux
```bash
sudo bash auto.sh
```

- Windows
```
右击脚本 -> 以管理员模式运行
```
*使用 Windows 脚本时注意 secret 只能是数字和字母，字符在`bat`文件里会发生不可预知的错误。*

3. 根据界面选择数字完成对应操作即可。

*目前界面只有中文，欢迎翻译！*

---
---

# WG Auto Script

This script is used for other nodes without WGDashboard installed to automatically configure the WireGuard network and periodically synchronize configurations.

## Steps

1. Install WireGuard on the node.

2. Select the script for the corresponding system.

- Linux

```bash
sudo bash auto.sh
```

- Windows

```
Right-click the script -> Run as administrator
```

*When using the Windows script, note that the secret can only contain numbers and letters; special characters may cause unpredictable errors in the `bat` file.*

3. Follow the interface prompts to select numbers and complete the corresponding operations.

*Currently, the interface is only in Chinese; translations are welcome!*