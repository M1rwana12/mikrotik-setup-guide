# === Гостьова мережа через VLAN ===

# VLAN 10 для гостей
/interface vlan add name=vlan10 interface=bridge-local vlan-id=10
/ip address add address=192.168.10.1/24 interface=vlan10

# DHCP для гостей
/ip pool add name=guest-pool ranges=192.168.10.2-192.168.10.254
/ip dhcp-server add interface=vlan10 address-pool=guest-pool name=dhcp-guest
/ip dhcp-server network add address=192.168.10.0/24 gateway=192.168.10.1 dns-server=8.8.8.8

# Ізоляція: гості не бачать основну мережу
/ip firewall filter
add chain=forward action=drop src-address=192.168.10.0/24 dst-address=192.168.88.0/24 comment="Гості ≠ LAN"