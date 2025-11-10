# === WAN: PPPoE ===
/interface list
add name=WAN
add name=LAN

/interface list member
add list=WAN interface=pppoe-out1
add list=LAN interface=bridge-local

/interface pppoe-client
add interface=ether1 user=ваш_логін password=ваш_пароль \
  add-default-route=yes use-peer-dns=yes disabled=no name=pppoe-out1 comment="PPPoE від провайдера"