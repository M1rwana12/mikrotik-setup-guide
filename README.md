# Посібник з Налаштування MikroTik (RouterOS) — КІБЕРБЕЗПЕКА ПЕРШ ЗА ВСЕ  
**Репозиторій:** [github.com/M1rwana12/mikrotik-setup-guide](https://github.com/M1rwana12/mikrotik-setup-guide)  
**Автор:** [@M1rwana12](https://github.com/M1rwana12)  
**Мова:** Українська  
**Оновлено:** 10 листопада 2025, 13:08 EET (UA)  

---

> **Для підлеглих, ІТ-фахівців, системних адміністраторів**  
> **Повний, безпечний, готовий до розгортання гайд** — від підключення до фаєрволу.  
> **Кожна команда + пояснення + кібербезпека**.  
> Готово до копіювання у **WinBox → Terminal**.

---

## Зміст
- [УВАГА: Wi-Fi — ВИМКНУТИ!](#увага-wi-fi)
- [Початкове Налаштування](#початкове-налаштування)
- [LAN: Міст + IP + DHCP](#lan-мережа)
- [WAN: Інтернет (DHCP, Static, PPPoE)](#wan-інтернет)
- [NAT](#nat)
- [Фаєрвол: Повний захист](#фаєрвол)
- [КІБЕРБЕЗПЕКА: Жорсткі правила](#кібербезпека)
- [Топологія мережі](#топологія-мережі)
- [Структура Репозиторію](#структура-репозиторію)
- [Як використовувати скрипти](#як-використовувати-скрипти)

---

## УВАГА: Wi-Fi — ВИМКНУТИ!

> **Негайно вимкніть Wi-Fi!**  
> За замовчуванням — **відкритий доступ, слабкий пароль, вразливість**.

```bash
/interface wireless disable wlan1
```
> **Пояснення**: Вимикає бездротовий інтерфейс.  
> **Увімкнете пізніше через CAPsMAN (якщо потрібно)**.

---

## Початкове Налаштування

### Підключення
1. **Провайдер → `ether1` (WAN)**  
2. **ПК → `ether2` (LAN)**  
3. Увімкніть роутер

### Доступ через WinBox
1. Завантажте [WinBox](https://mikrotik.com/download)  
2. **Neighbors** → знайдіть за MAC → **Connect**  
3. Логін: `admin` | Пароль: *(порожній)*

```bash
/user set admin password=ТвійСильнийПароль123! full-name="Admin" group=full
```
> **Пояснення**:  
> - 12+ символів (великі, малі, цифри, символи)  
> - `group=full` — повний доступ  
> - `full-name` — для логів

---

## LAN Мережа

```bash
# Міст
/interface bridge add name=bridge-local comment="Локальна мережа (LAN)"

/interface bridge port
add bridge=bridge-local interface=ether2
add bridge=bridge-local interface=ether3
add bridge=bridge-local interface=ether4
add bridge=bridge-local interface=ether5

# IP + DHCP
/ip address add address=192.168.88.1/24 interface=bridge-local
/ip pool add name=lan-pool ranges=192.168.88.2-192.168.88.254

/ip dhcp-server add interface=bridge-local address-pool=lan-pool name=dhcp-lan lease-time=1d
/ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,1.1.1.1
```

---

## WAN: Інтернет

```bash
/interface list add name=WAN
/interface list add name=LAN
/interface list member add list=WAN interface=ether1
/interface list member add list=LAN interface=bridge-local
```

### Варіант 1: DHCP (найпоширеніший)
```bash
/ip dhcp-client add interface=ether1 disabled=no add-default-route=yes use-peer-dns=yes
```

### Варіант 2: Статичний IP
```bash
/ip address add address=203.0.113.50/24 interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=203.0.113.1
/ip dns set servers=8.8.8.8,1.1.1.1 allow-remote-requests=no
```

### Варіант 3: PPPoE
```bash
/interface pppoe-client add interface=ether1 user=ваш_логін password=ваш_пароль \
  add-default-route=yes use-peer-dns=yes disabled=no name=pppoe-out1
```

---

## NAT

```bash
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="LAN → Інтернет"
```
> Для PPPoE: замініть `WAN` на `pppoe-out1`

---

## Фаєрвол: Повний захист

```bash
/ip firewall filter
# === INPUT (захист роутера) ===
add chain=input action=accept connection-state=established,related,untracked comment="Встановлені з'єднання"
add chain=input action=drop connection-state=invalid comment="Відкинути невалідні"
add chain=input action=accept protocol=icmp icmp-options=8:0 limit=1,5 comment="Ping (обмежено)"
add chain=input action=accept in-interface-list=LAN comment="Дозволити з LAN"
add chain=input action=drop in-interface-list=!LAN comment="БЛОК УСЕ З WAN"

# === FORWARD (захист LAN) ===
add chain=forward action=fasttrack-connection connection-state=established,related comment="Прискорення"
add chain=forward action=accept connection-state=established,related,untracked
add chain=forward action=drop connection-state=invalid
add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment="LAN → Інтернет"
add chain=forward action=drop in-interface-list=!LAN comment="БЛОК З WAN → LAN"

# Анти-спуфінг
add chain=forward action=drop src-address=192.168.0.0/16 comment="Анти-спуфінг"
add chain=forward action=drop src-address=10.0.0.0/8
add chain=forward action=drop src-address=172.16.0.0/12

# Захист від атак
add chain=forward action=drop protocol=tcp flags=syn connection-limit=50,32 comment="Проти SYN-flood"
add chain=forward action=drop dst-port=0-1023 protocol=tcp in-interface-list=WAN comment="Блок низьких портів"
add chain=forward action=drop protocol=udp dst-port=5060-5061 comment="Блок SIP (якщо не VoIP)"
```

---

## КІБЕРБЕЗПЕКА: Жорсткі правила

```bash
# Вимкнути небезпечні сервіси
/ip service
disable telnet,ftp,www,api,api-ssl
set ssh address=192.168.88.0/24 port=2222
set winbox address=192.168.88.0/24

# Приховати від сканування
/ip neighbor discovery-settings set discover-interface-list=LAN
/tool mac-server set allowed-interface-list=LAN
/tool mac-server mac-winbox set allowed-interface-list=LAN

# DNS — без запитів ззовні
/ip dns set allow-remote-requests=no servers=8.8.8.8,1.1.1.1

# Оновлення (обов’язково!)
/system package update check-for-updates
/system package update install
/system reboot
```

---

## Топологія мережі

![Топологія мережі](diagrams/digrams.drawio.png)

> **Редагуйте деталі:** [diagrams/topology.drawio](./diagrams/topology.drawio)  
> Відкрийте в [app.diagrams.net](https://app.diagrams.net)

---

## Структура Репозиторію

```
mikrotik-setup-guide/
│
├── README.md
├── scripts/
│   ├── 01-lan.rsc
│   ├── 02-wan-dhcp.rsc
│   ├── 02-wan-static.rsc
│   ├── 02-wan-pppoe.rsc
│   ├── 03-nat.rsc
│   ├── 04-firewall-full.rsc
│   └── 05-security.rsc
├── diagrams/
│   ├── digrams.drawio.png     ← PNG-версія
│   └── topology.drawio        ← Редактор
└── examples/
    └── guest-vlan.rsc         ← Гостьова мережа
```

---

## Як використовувати скрипти

1. Завантажте `.rsc` файл  
2. WinBox → **Files** → перетягніть  
3. Terminal:  
```bash
/import file=04-firewall-full.rsc
```

---

**© 2025 M1rwana12. Вільне використання з посиланням на репозиторій.**  
**Зірочка (star) — мотивація для оновлень!**
```