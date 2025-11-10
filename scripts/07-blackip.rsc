# === BLACKIPFORFIREWALL — БЛОКУВАННЯ ПОГАНИХ IP ===
# Джерело: trskrbz/BlackIPforFirewall (malware, spam, botnets)
# Автооновлення щотижня — створює правило в firewall raw + scheduler

# 1. Створюємо address-list для поганих IP
/ip firewall address-list
add list=bad-ip comment="BlackIP: malware / spam / botnets"

# 2. Завантажуємо merged список (оптимізований, ~17% менше)
:local url "https://raw.githubusercontent.com/trskrbz/BlackIPforFirewall/main/dash-merged-ip.txt"
/tool fetch url=$url mode=https dst-path=blackip.txt

# 3. Імпортуємо в address-list (розбиваємо по тире)
:local content [/file get [/file find name=blackip.txt] contents]
:foreach line in=$content do={
  :if ([:len $line] > 0 && [:pick $line 0 1] != "#") do={
    :local ips [:toarray $line]
    :foreach ip in=$ips do={
      /ip firewall address-list add list=bad-ip address=$ip timeout=30d comment="BlackIP автооновлення"
    }
  }
}

# 4. Додаємо правило в firewall raw (drop на початку)
 /ip firewall raw
add chain=prerouting action=drop src-address-list=bad-ip comment="BlackIP — блок вхід"
add chain=prerouting action=drop dst-address-list=bad-ip comment="BlackIP — блок вихід"

# 5. Автооновлення щотижня (понеділок 04:00)
/system scheduler
add name=update-blackip interval=7d on-event="\
  /tool fetch url=\"$url\" mode=https dst-path=blackip.txt; \
  /ip firewall address-list remove [find list=bad-ip]; \
  :local c [/file get [/file find name=blackip.txt] contents]; \
  :foreach l in=$c do={ \
    :if ([:len $l] > 0 && [:pick $l 0 1] != \"#\") do={ \
      :local ips [:toarray $l]; \
      :foreach ip in=$ips do={ \
        /ip firewall address-list add list=bad-ip address=$ip timeout=30d \
      } \
    } \
  } \
" start-time=04:00:00 start-date=nov/11/2025

# 6. Логування (опційно)
/system logging add topics=firewall action=memory action=memory action=memory action=syslog