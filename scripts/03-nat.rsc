# === NAT: Masquerade для виходу в інтернет ===
/ip firewall nat
add chain=srcnat out-interface-list=WAN action=masquerade comment="Дозволити LAN в інтернет"

# Якщо PPPoE — замініть WAN на pppoe-out1:
# add chain=srcnat out-interface=pppoe-out1 action=masquerade