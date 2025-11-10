# === WAN: Статичний IP ===
/interface list
add name=WAN
add name=LAN

/interface list member
add list=WAN interface=ether1
add list=LAN interface=bridge-local

/ip address
add address=203.0.113.50/24 interface=ether1 comment="Статичний WAN IP"

/ip route
add dst-address=0.0.0.0/0 gateway=203.0.113.1 comment="Шлюз за замовчуванням"

/ip dns
set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes
