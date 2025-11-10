# === БЛОКУВАННЯ РОСІЙСЬКИХ IP ===
:local url "https://raw.githubusercontent.com/zapret-info/z-i/master/dump.rsc"
/tool fetch url=$url mode=https dst-path=block-ru.rsc

:if ([:len [/file find name=block-ru.rsc]] > 0) do={
  /import file=block-ru.rsc
  /ip firewall address-list add list=block-ru address=0.0.0.0/0
  /ip firewall filter add chain=forward src-address-list=block-ru action=drop comment="Блок РФ"
  /ip firewall filter add chain=forward dst-address-list=block-ru action=drop comment="Блок РФ"
}

# Автооновлення щодня
/system scheduler add name=update-block-ru interval=1d on-event="/tool fetch url=$url mode=https dst-path=block-ru.rsc; /import file=block-ru.rsc"