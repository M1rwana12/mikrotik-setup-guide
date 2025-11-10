# === ФАЄРВОЛ: Повний захист ===

# Очищення старих правил (опціонально)
/ip firewall filter remove [find]

# === INPUT (захист роутера) ===
/ip firewall filter
add chain=input action=accept connection-state=established,related,untracked comment="Встановлені з'єднання"
add chain=input action=drop connection-state=invalid comment="Відкинути невалідні"
add chain=input action=accept protocol=icmp comment="Дозволити ping"
add chain=input action=accept in-interface-list=LAN comment="Дозволити з LAN"
add chain=input action=drop protocol=tcp dst-port=80,443 in-interface-list=WAN comment="Блок веб ззовні"
add chain=input action=drop protocol=udp dst-port=53 in-interface-list=WAN comment="Блок DNS ззовні"
add chain=input action=accept protocol=tcp dst-port=22 in-interface-list=LAN limit=3,5 comment="SSH з LAN (обмеження)"
add chain=input action=drop protocol=tcp dst-port=22 comment="Блок SSH brute-force"
add chain=input action=drop in-interface-list=!LAN comment="Блок усе з WAN"

/ip firewall filter
add chain=forward action=fasttrack-connection connection-state=established,related comment="Прискорення"
add chain=forward action=accept connection-state=established,related,untracked comment="Встановлені з'єднання"
add chain=forward action=drop connection-state=invalid comment="Відкинути невалідні"
add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment="LAN → Інтернет"
add chain=forward action=drop src-address=192.168.0.0/16 comment="Анти-спуфінг"
add chain=forward action=drop src-address=10.0.0.0/8 comment="Анти-спуфінг"
add chain=forward action=drop src-address=172.16.0.0/12 comment="Анти-спуфінг"
add chain=forward action=drop protocol=tcp connection-nat-state=!dstnat connection-state=new comment="Блок нових без NAT"
add chain=forward action=drop protocol=tcp flags=syn connection-limit=50,32 comment="Проти SYN-flood"
add chain=forward action=drop protocol=icmp icmp-options=8:0 limit=1,5 comment="Обмежити ping"
add chain=forward action=drop dst-port=0-1023 protocol=tcp in-interface-list=WAN comment="Блок низьких портів"
add chain=forward action=drop protocol=udp dst-port=5060-5061 comment="Блок SIP (якщо не VoIP)"
add chain=forward action=drop in-interface-list=!LAN comment="Блок з WAN → LAN"