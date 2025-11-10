# === FAILOVER (2 провайдери) ===
/interface list add name=WAN1
/interface list add name=WAN2
/interface list member add list=WAN1 interface=ether1
/interface list member add list=WAN2 interface=ether2

/ip dhcp-client add interface=ether1 disabled=no add-default-route=yes distance=1 use-peer-dns=yes
/ip dhcp-client add interface=ether2 disabled=no add-default-route=yes distance=2 use-peer-dns=yes

/ip route add dst-address=0.0.0.0/0 gateway=ether1,ether2 check-gateway=ping distance=1
/tool netwatch add host=8.8.8.8 interval=10s up-script="" down-script="/ip route set [find gateway=ether1] disabled=yes"