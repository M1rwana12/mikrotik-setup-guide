# === LAN: Міст, IP, DHCP ===
/interface bridge
add name=bridge-local comment="Локальна мережа (LAN)"

/interface bridge port
add bridge=bridge-local interface=ether2
add bridge=bridge-local interface=ether3
add bridge=bridge-local interface=ether4
add bridge=bridge-local interface=ether5
# Додайте wlan1, якщо використовується Wi-Fi:
# add bridge=bridge-local interface=wlan1

/ip address
add address=192.168.88.1/24 interface=bridge-local comment="LAN IP"

/ip pool
add name=lan-pool ranges=192.168.88.2-192.168.88.254

/ip dhcp-server
add interface=bridge-local address-pool=lan-pool name=dhcp-lan disabled=no

/ip dhcp-server network
add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,8.8.4.4 comment="LAN мережа"