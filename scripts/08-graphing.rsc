# === МОНІТОРИНГ ТРАФІКУ (Graphing) ===
/tool graphing interface add interface=ether1 allow-address=192.168.88.0/24
/tool graphing interface add interface=ether2 allow-address=192.168.88.0/24
/tool graphing interface add interface=bridge-local allow-address=192.168.88.0/24

/tool graphing resource add
/tool graphing resource add
/tool graphing resource add

# Доступ: WinBox → Tools → Graphing
# Графіки: Трафік ether1/2, CPU, RAM