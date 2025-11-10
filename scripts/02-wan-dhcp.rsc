# === WAN: DHCP від провайдера ===
/interface list
add name=WAN
add name=LAN

/interface list member
add list=WAN interface=ether1
add list=LAN interface=bridge-local

/ip dhcp-client
add interface=ether1 disabled=no add-default-route=yes use-peer-dns=yes comment="WAN DHCP"