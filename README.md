# Посібник з Налаштування MikroTik (RouterOS)  
**Репозиторій:** [github.com/M1rwana12/mikrotik-setup-guide](https://github.com/M1rwana12/mikrotik-setup-guide)  
**Автор:** [@M1rwana12](https://github.com/M1rwana12)  
**Мова:** Українська  
**Оновлено:** 10 листопада 2025  

---

> **Для початківців та підлеглих** — покроковий гайд від підключення до провайдера до потужного фаєрволу.  
> Кожна команда терміналу + **пояснення українською**.  
> Готово до копіювання у WinBox → Terminal.  

---

## Зміст
- [Початкове Налаштування](#початкове-налаштування)
- [Скидання Конфігурації](#скидання-конфігурації)
- [LAN: Міст + IP + DHCP](#lan-мережа)
- [WAN: Інтернет від провайдера](#wan-інтернет)
- [NAT: Доступ до інтернету](#nat)
- [Фаєрвол: Базовий + Розширений захист](#фаєрвол)
- [Безпека: Сервіси, оновлення, доступ](#безпека)
- [Усунення Проблем](#усунення-проблем)
- [Топологія мережі](#топологія-мережі)
- [Структура Репозиторію](#структура-репозиторію)
- [Як використовувати скрипти](#як-використовувати-скрипти)
- [Як залити через Git](#як-залити-через-git)

---

## Початкове Налаштування

### Підключення
1. **Кабель провайдера → `ether1`** (WAN)  
2. **Ваш ПК → `ether2`** (LAN)  
3. Увімкніть роутер

### Доступ через WinBox
1. Завантажте [WinBox](https://mikrotik.com/download)  
2. Відкрийте → вкладка **Neighbors**  
3. Знайдіть роутер за MAC-адресою → **Connect**  
4. Логін: `admin` | Пароль: *(порожній)*

```bash
/user set admin password=ТвійСильнийПароль123!
```
> **Пояснення**: Змінює пароль за замовчуванням. Використовуйте 12+ символів (великі, малі, цифри, символи).

---

## Скидання Конфігурації

```bash
/system reset-configuration no-defaults=yes skip-backup=yes
```
> **Пояснення**: Повне скидання до "чистого аркуша". Після перезавантаження підключайтесь через MAC.  
> **Увага**: Втрачаються всі налаштування!

---

## LAN Мережа

### 1. Створення мосту
```bash
/interface bridge add name=bridge-local comment="Локальна мережа (LAN)"
```

### 2. Додавання портів
```bash
/interface bridge port add bridge=bridge-local interface=ether2
/interface bridge port add bridge=bridge-local interface=ether3
/interface bridge port add bridge=bridge-local interface=ether4
/interface bridge port add bridge=bridge-local interface=ether5
```
> Додайте `wlan1`, якщо використовуєте Wi-Fi.

### 3. IP-адреса мосту
```bash
/ip address add address=192.168.88.1/24 interface=bridge-local comment="LAN IP"
```

### 4. DHCP-сервер (автоматична видача IP)
```bash
/ip dhcp-server setup
```
> Відповідайте:  
> - `bridge-local`  
> - `192.168.88.0/24`  
> - `192.168.88.1`  
> - `192.168.88.2-192.168.88.254`  
> - `8.8.8.8,8.8.4.4`  
> - `1d`

**Або вручну:**
```bash
/ip pool add name=lan-pool ranges=192.168.88.2-192.168.88.254
/ip dhcp-server add interface=bridge-local address-pool=lan-pool name=dhcp-lan
/ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,8.8.4.4
```

---

## WAN: Інтернет

### Списки інтерфейсів
```bash
/interface list add name=WAN
/interface list add name=LAN
/interface list member add list=WAN interface=ether1
/interface list member add list=LAN interface=bridge-local
```

---

### Варіант 1: DHCP від провайдера (найпоширеніший)
```bash
/ip dhcp-client add interface=ether1 disabled=no add-default-route=yes use-peer-dns=yes
```
> Перевірка: `/ip dhcp-client print` → статус `bound`

---

### Варіант 2: Статичний IP
```bash
/ip address add address=203.0.113.50/24 interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=203.0.113.1
/ip dns set servers=8.8.8.8,8.8.4.4
```

---

### Варіант 3: PPPoE
```bash
/interface pppoe-client add interface=ether1 user=ваш_логін password=ваш_пароль \
  add-default-route=yes use-peer-dns=yes disabled=no name=pppoe-out1
```
> Інтерфейс буде `pppoe-out1` — використовуйте його в NAT та фаєрволі.

---

### Тест інтернету
```bash
/ping 8.8.8.8 count=5
```

---

## NAT

```bash
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="Інтернет для LAN"
```
> Замініть `out-interface-list=WAN` на `out-interface=pppoe-out1`, якщо PPPoE.

---

## Фаєрвол (Базовий + Розширений)

### Input (захист роутера)
```bash
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
```

---

### Forward (захист LAN)
```bash
add chain=forward action=fasttrack-connection connection-state=established,related comment="Прискорення"
add chain=forward action=accept connection-state=established,related,untracked comment="Встановлені"
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
```

---

## Безпека

### Вимкнення небезпечних сервісів
```bash
/ip service disable telnet,ftp,www,api,api-ssl
/ip service set ssh address=192.168.88.0/24
/ip service set winbox address=192.168.88.0/24
```

### Приховати від сканування
```bash
/ip neighbor discovery-settings set discover-interface-list=LAN
/tool mac-server set allowed-interface-list=LAN
/tool mac-server mac-winbox set allowed-interface-list=LAN
```

### Оновлення
```bash
/system package update check-for-updates
/system package update install
/system reboot
```

---

## Усунення Проблем

| Проблема | Команда |
|--------|--------|
| Немає інтернету | `/ip dhcp-client print` |
| Не бачить роутер | WinBox → Neighbors |
| Помилки | `/log print` |
| Зберегти конфіг | `/export hide-sensitive file=config.rsc` |

---

## Топологія мережі

```mermaid
graph TD
    A[Інтернет\nISP] -->|ether1 (WAN)| B(MikroTik Router)
    B -->|bridge-local| C[LAN\n192.168.88.0/24\nether2-5, wlan1]
    B -->|VLAN 10| D[Гостьова мережа\n192.168.10.0/24]
    C --> E[ПК, ноутбуки,\nпринтери]
    D --> F[Гостьові\nпристрої]
    style B fill:#4CAF50,stroke:#333,color:white
    style C fill:#2196F3,stroke:#333,color:white
    style D fill:#FF9800,stroke:#333,color:white
```

> **Детальна діаграма (редагується):** [diagrams/topology.drawio](./diagrams/topology.drawio)  
> Відкрийте в [app.diagrams.net](https://app.diagrams.net) → редагуйте → експортуйте як PNG.

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
│   └── topology.drawio
└── examples/
    └── guest-vlan.rsc
```

---

## Як використовувати скрипти

1. Завантажте `.rsc` файл  
2. У WinBox: **Files** → перетягніть файл  
3. Terminal:  
```bash
/import file=04-firewall-full.rsc
```

---

## Як залити через Git (Git Bash)

```bash
# 1. Відкрийте Git Bash у папці mikrotik-setup-guide
cd путь/до/mikrotik-setup-guide

# 2. Ініціалізація (якщо ще немає)
git init

# 3. Додати всі файли
git add .

# 4. Коміт
git commit -m "feat: повний гайд MikroTik + діаграма + скрипти"

# 5. Додати віддалений репозиторій
git remote add origin https://github.com/M1rwana12/mikrotik-setup-guide.git

# 6. Залити
git push -u origin main
```

> Якщо вже є `origin`:
> ```bash
> git add .
> git commit -m "update: виправлено Mermaid + додана діаграма"
> git push
> ```

---

## Додаткові Ідеї (Pull Request Welcome!)

- [ ] VLAN для гостьової мережі  
- [ ] Queue — обмеження швидкості по IP  
- [ ] CAPsMAN — централізоване Wi-Fi  
- [ ] Auto-backup на email  
- [ ] Моніторинг через The Dude  

---

**Питання? Пишіть у Issues або Telegram: @M1rwana12**  
**Зірочка (star) — мотивація для оновлень!**

---

**© 2025 M1rwana12. Вільне використання з посиланням на репозиторій.**
