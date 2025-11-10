# === БЕЗПЕКА: Сервіси, доступ, оновлення ===

# Вимкнути небезпечні сервіси
/ip service
disable telnet,ftp,www,api,api-ssl
set ssh address=192.168.88.0/24
set winbox address=192.168.88.0/24

# Обмежити виявлення
/ip neighbor discovery-settings set discover-interface-list=LAN
/tool mac-server set allowed-interface-list=LAN
/tool mac-server mac-winbox set allowed-interface-list=LAN

# Змінити пароль (обов'язково!)
/user set admin password=ТвійСильнийПароль123!

# Оновлення (виконати вручну)
/system package update check-for-updates