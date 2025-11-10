# MikroTik RouterOS — **Ultimate Secure Setup Guide 2025**  
**Complete Configuration Manual for Admins & Users**

[![Last Commit](https://img.shields.io/github/last-commit/M1rwana12/mikrotik-setup-guide?color=green&style=for-the-badge&logo=github)](https://github.com/M1rwana12/mikrotik-setup-guide/commits/main)  
[![Stars](https://img.shields.io/github/stars/M1rwana12/mikrotik-setup-guide?style=social&logo=github)](https://github.com/M1rwana12/mikrotik-setup-guide/stargazers)  
[![License](https://img.shields.io/github/license/M1rwana12/mikrotik-setup-guide?color=blue&style=for-the-badge)](LICENSE)  
[![RouterOS](https://img.shields.io/badge/RouterOS-v7.15+-blueviolet?style=for-the-badge&logo=mikrotik)](https://mikrotik.com/download)  
[![Language](https://img.shields.io/badge/Primary-English-1f8feb?style=for-the-badge)](README.md)  
[![Українська](https://img.shields.io/badge/Українська-FFD700?style=for-the-badge&logo=ukraine)](README.ua.md)

<div align="center" style="margin: 35px 0; padding: 20px; background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); border-radius: 20px; color: white; box-shadow: 0 10px 25px rgba(0,0,0,0.3);">

<img src="https://github.com/M1rwana12.png" width="120" alt="M1rwana12" style="border-radius:50%; border: 4px solid #FFD700; box-shadow: 0 0 20px rgba(255,215,0,0.6);">

<h2 style="margin: 15px 0 5px; font-size: 28px; text-shadow: 0 2px 5px rgba(0,0,0,0.5);">Author: @M1rwana12</h2>
<p style="margin: 0; font-size: 16px;"><strong>Telegram:</strong> <a href="https://t.me/imSenya" style="color: #FFD700; text-decoration: none;">@imSenya</a></p>
<p style="margin: 8px 0 0; font-size: 15px;"><strong>Updated:</strong> November 10, 2025, 16:29 EET (UA)</p>
<p style="margin: 8px 0 0; font-size: 15px;"><strong>Devices:</strong> CCR1036, RB760iGS, hEX, RB4011</p>

</div>

---

> **Production-Ready • Secure • Clear**  
> From ISP connection → to **hardened firewall + BlackIP protection**  
> **Every command + explanation + cybersecurity**  
> Ready for **WinBox → Terminal**

---

## Table of Contents
- [Wi-Fi — DISABLED!](#wi-fi--disabled)
- [Initial Setup](#initial-setup)
- [LAN: Bridge + IP + DHCP](#lan-network)
- [WAN: DHCP / Static / PPPoE](#wan-internet)
- [NAT](#nat)
- [Firewall: Full Protection](#firewall)
- [Cybersecurity](#cybersecurity)
- [Network Topology](#network-topology)
- [Repository Structure](#repository-structure)
- [How to Use Scripts](#how-to-use-scripts)
- [Advanced Features](#advanced-features)
- [For Administrators](#for-administrators)

---

## Wi-Fi — DISABLED!

> **Disable Wi-Fi immediately!**  
> Default: **open access, weak password, vulnerability**.

```bash
/interface wireless disable wlan1
```
> **Explanation**: Disables wireless interface.  
> **Re-enable later via CAPsMAN if needed.**

---

## Initial Setup

### Connection
1. **ISP → `ether1` (WAN)**  
2. **PC → `ether2` (LAN)**  
3. Power on the router

### Access via WinBox
1. Download [WinBox](https://mikrotik.com/download)  
2. **Neighbors** → find by MAC → **Connect**  
3. Login: `admin` | Password: *(empty)*

```bash
/user set admin password=YourStrongPass123! full-name="Admin" group=full
```
> **Explanation**:  
> - 12+ chars (upper, lower, digits, symbols)  
> - `group=full` — full access  
> - `full-name` — for logs

---

## LAN Network

```bash
# Bridge
/interface bridge add name=bridge-local comment="Local Network (LAN)"

/interface bridge port
add bridge=bridge-local interface=ether2
add bridge=bridge-local interface=ether3
add bridge=bridge-local interface=ether4
add bridge=bridge-local interface=ether5

# IP + DHCP
/ip address add address=192.168.88.1/24 interface=bridge-local
/ip pool add name=lan-pool ranges=192.168.88.2-192.168.88.254

/ip dhcp-server add interface=bridge-local address-pool=lan-pool name=dhcp-lan lease-time=1d
/ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,1.1.1.1
```

---

## WAN: Internet

```bash
/interface list add name=WAN
/interface list add name=LAN
/interface list member add list=WAN interface=ether1
/interface list member add list=LAN interface=bridge-local
```

### Option 1: DHCP (most common)
```bash
/ip dhcp-client add interface=ether1 disabled=no add-default-route=yes use-peer-dns=yes
```

### Option 2: Static IP
```bash
/ip address add address=203.0.113.50/24 interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=203.0.113.1
/ip dns set servers=8.8.8.8,1.1.1.1 allow-remote-requests=no
```

### Option 3: PPPoE
```bash
/interface pppoe-client add interface=ether1 user=your_login password=your_password \
  add-default-route=yes use-peer-dns=yes disabled=no name=pppoe-out1
```

---

## NAT

```bash
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="LAN → Internet"
```
> For PPPoE: replace `WAN` with `pppoe-out1`

---

## Firewall: Full Protection

```bash
/ip firewall filter
# === INPUT (router protection) ===
add chain=input action=accept connection-state=established,related,untracked comment="Established connections"
add chain=input action=drop connection-state=invalid comment="Drop invalid"
add chain=input action=accept protocol=icmp icmp-options=8:0 limit=1,5 comment="Ping (limited)"
add chain=input action=accept in-interface-list=LAN comment="Allow from LAN"
add chain=input action=drop in-interface-list=!LAN comment="BLOCK ALL FROM WAN"

# === FORWARD (LAN protection) ===
add chain=forward action=fasttrack-connection connection-state=established,related comment="FastTrack"
add chain=forward action=accept connection-state=established,related,untracked
add chain=forward action=drop connection-state=invalid
add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment="LAN → Internet"
add chain=forward action=drop in-interface-list=!LAN comment="BLOCK FROM WAN → LAN"

# Anti-Spoofing
add chain=forward action=drop src-address=192.168.0.0/16 comment="Anti-Spoofing"
add chain=forward action=drop src-address=10.0.0.0/8
add chain=forward action=drop src-address=172.16.0.0/12

# Attack Protection
add chain=forward action=drop protocol=tcp flags=syn connection-limit=50,32 comment="Anti SYN-flood"
add chain=forward action=drop dst-port=0-1023 protocol=tcp in-interface-list=WAN comment="Block low ports"
add chain=forward action=drop protocol=udp dst-port=5060-5061 comment="Block SIP (if not VoIP)"
```

---

## Cybersecurity: Hardened Rules

```bash
# Disable dangerous services
/ip service
disable telnet,ftp,www,api,api-ssl
set ssh address=192.168.88.0/24 port=2222
set winbox address=192.168.88.0/24

# Hide from scanning
/ip neighbor discovery-settings set discover-interface-list=LAN
/tool mac-server set allowed-interface-list=LAN
/tool mac-server mac-winbox set allowed-interface-list=LAN

# DNS — no external requests
/ip dns set allow-remote-requests=no servers=8.8.8.8,1.1.1.1

# Update (mandatory!)
/system package update check-for-updates
/system package update install
/system reboot
```

---

## Network Topology

<div align="center">

![Network Topology — CCR + RB760iGS + Failover + BlackIP](diagrams/topology-failover.drawio.png)

> **Updated Nov 10, 2025**  
> - **CCR1036**: Failover, NAT, Firewall, Scheduler  
> - **RB760iGS**: PoE, SFP, VLAN, Graphing  
> - **BlackIPforFirewall**: ~45k IPs (malware/spam) → `raw drop`  
> - **Failover**: 2 ISPs (primary + backup)  
>  
> **Edit:** [diagrams/topology-failover.drawio](./diagrams/topology-failover.drawio)  
> Open in [app.diagrams.net](https://app.diagrams.net)

</div>

---

## Repository Structure

```
mikrotik-setup-guide/
│
├── README.md
├── README.ua.md
├── LICENSE
├── scripts/
│   ├── 01-lan.rsc
│   ├── 02-wan-dhcp.rsc
│   ├── 02-wan-static.rsc
│   ├── 02-wan-pppoe.rsc
│   ├── 03-nat.rsc
│   ├── 04-firewall-full.rsc
│   ├── 05-security.rsc
│   ├── 06-failover.rsc
│   ├── 07-blackip.rsc          ← BlackIPforFirewall (malware/spam)
│   └── 08-graphing.rsc
├── diagrams/
│   ├── topology-failover.drawio
│   └── topology-failover.drawio.png
└── examples/
    └── guest-vlan.rsc
```

---

## How to Use Scripts

1. Download `.rsc` file  
2. WinBox → **Files** → drag & drop  
3. Terminal:  
```bash
/import file=01-lan.rsc
```

---

## Advanced Features

| Feature | File |
|--------|------|
| Guest VLAN | `examples/guest-vlan.rsc` |
| **Failover (2 ISPs)** | `scripts/06-failover.rsc` |
| **Block Malicious IPs (malware, spam, botnets)** | `scripts/07-blackip.rsc` |
| **Traffic Monitoring** | `scripts/08-graphing.rsc` |
| **Speed Limiting** | [See below](#speed-limiting-queue) |

---

## Speed Limiting (Queue)

```bash
/queue tree add name="User-Limit" parent=global max-limit=10M/10M
/ip firewall mangle add chain=prerouting src-address=192.168.88.100 action=mark-packet new-packet-mark=user-192.168.88.100
/queue tree add name="192.168.88.100" parent="User-Limit" packet-mark=user-192.168.88.100 max-limit=10M/10M
```

---

## For Administrators

### Weekly Backup to Email
```bash
/system scheduler add name=weekly-backup interval=7d on-event="/system backup save name=auto-backup; /tool e-mail send to=admin@company.com subject=\"MikroTik Backup\" file=auto-backup.backup"
```

### Attack Logging
```bash
/system logging action add name=syslog remote-address=192.168.88.10 target=remote
/system logging add topics=firewall action=syslog
```

---

<div align="center" style="margin: 60px 0; padding: 30px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 25px; color: white; box-shadow: 0 15px 30px rgba(0,0,0,0.3);">

<h2 style="margin: 0; font-size: 30px; text-shadow: 0 3px 6px rgba(0,0,0,0.5);">Your Guide — #1 in Ukraine 2025</h2>
<p style="margin: 15px 0 0; font-size: 18px;"><strong>Production-ready for CCR, RB760iGS, and all modern MikroTik devices.</strong></p>

**Star (star) — motivation for updates!**  
**Questions? Open [Issues](https://github.com/M1rwana12/mikrotik-setup-guide/issues) or contact Telegram: <a href="https://t.me/imSenya" style="color: #FFD700;">@imSenya</a>**

</div>

---

**© 2025 M1rwana12. Free to use with attribution.**  
**License:** [MIT](LICENSE)
```