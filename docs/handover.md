# Desktop PC perdavimas: pilna LaptopUI diegimo eiga

Šis failas yra praktinis runbook'as, skirtas perkelti dabartinę `main` versiją
į desktop PC. Tikslinis hostas: Intel Core i7-8700, NVIDIA GeForce RTX 2080 Ti
ir Xiaomi 2560×1440@180 Hz monitorius per `DP-3`.

Dabartinė versija apima:

- Hyprland ir Quickshell `laptopui` su high-rice stiklo/glow estetika;
- dinaminę desktop wallpaperio `matugen` paletę Quickshell, Hyprland ir Kitty;
- MPRIS media kortelę, `cava` vizualizaciją ir bass bangos efektą;
- CPU/RAM, performance profilius, orus, update counterį ir terminalo updaterį;
- Kitty, Zsh, Oh My Zsh ir Starship;
- fiksuotą, atskirai previewinamą LaptopUI SDDM temą;
- tokį pat SDDM stilių atkartojantį `hyprlock`;
- `hypridle`: 5 min. lock, 10 min. DPMS off, 20 min. suspend;
- laptopo lid eigą: ekranas off iškart, suspend po 5 min., atidarius atšaukiama.

## 0. Saugumo taisyklės

Pirmą diegimą vykdyk turėdamas veikiančią recovery TTY (`Ctrl+Alt+F3`).
Neperkrauk ir nestabdyk `sddm.service` iš aktyvios grafinės sesijos.

Yra du atskiri rollback mechanizmai:

- vartotojo dotfiles backup'ai: `~/.local/state/dev-shell/backups/`;
- SDDM backup'ai: `/var/lib/dev-shell/sddm-backups/`.

Installeris nekeičia bootloaderio, initramfs, kernel parametrų ar autologin.

## 1. Repo gavimas arba atnaujinimas

Naujame desktop PC:

```sh
sudo pacman -Syu --needed git
git clone https://github.com/ripasjustinas-rgb/dev-shell.git ~/dev-shell
cd ~/dev-shell
git switch main
git pull --ff-only origin main
```

Jeigu repo jau klonuotas ir jame yra vietinių pakeitimų, prieš `pull` jų
neperrašyk. Pirmiausia patikrink ir išsisaugok:

```sh
cd ~/dev-shell
git status -sb
git diff
```

## 2. Read-only desktop preflight

Prieš diegdamas paketus surink inventorizaciją:

```sh
./scripts/install-desktop preflight \
  --output /tmp/laptopui-desktop-preflight.md
```

Ataskaitoje patikrink:

- CPU turi atitikti `i7-8700`;
- GPU turi atitikti `RTX 2080 Ti`;
- aktyvus tik vienas CPU profilių backend'as;
- monitorius iš tikro yra `DP-3` ir palaiko `2560x1440@180`;
- išvardyti visi trūkstami manifestų paketai.

Jei monitoriaus output arba režimas skiriasi, prieš diegimą pataisyk
`dotfiles/.config/hypr/modules/profiles/desktop.lua`. Nekopijuok `DP-3` aklai
į kitą aparatūrą.

## 3. Paketai, NVIDIA ir sisteminiai servisai

Įdiek bendrus ir desktop profilio paketus:

```sh
./scripts/install-desktop packages
```

Manifestas įdiegia `nvidia-open`, `nvidia-utils`, `egl-wayland`, XWayland,
SDDM, Qt5 Quick Controls, Hyprland, Quickshell, hyprlock, hypridle ir visus UI
helperių paketus.

Įjunk reikalingus sisteminius servisus:

```sh
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now power-profiles-daemon.service
sudo systemctl enable sddm.service
sudo reboot
```

Po restarto patikrink NVIDIA:

```sh
nvidia-smi
cat /sys/module/nvidia_drm/parameters/modeset
```

`modeset` turi būti `Y`. Jei desktop naudoja ne standartinį Arch `linux`
kernelį, `nvidia-open` aklai netinka: rinkis `nvidia-open-dkms` ir to kernelio
headers paketą, tada atskirai patikrink initramfs bei modulio užsikrovimą.

Pakartok preflight:

```sh
./scripts/install-desktop preflight \
  --output /tmp/laptopui-desktop-after-packages.md
```

## 4. CPU performance ir monitoriaus priėmimas

Patikrink, kad UI naudojamas `power-profiles-daemon` keičia realią politiką:

```sh
powerprofilesctl list
powerprofilesctl set balanced
powerprofilesctl get
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null

powerprofilesctl set performance
powerprofilesctl get
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null
```

Vienu metu negali veikti ir `power-profiles-daemon`, ir `tuned`. Jei
`performance` neegzistuoja, portą sustabdyk ir pasirink vieną kitą backend'ą;
UI tekstas be realaus CPU politikos pokyčio nėra pakankamas.

Dabartiniame repo desktop profilis jau pažymėtas `DESKTOP_PORT_READY=1` ir
turi:

```lua
hl.monitor({ output = "DP-3", mode = "2560x1440@180", position = "0x0", scale = "1" })
```

Jei naujas preflight tam prieštarauja, grąžink `DESKTOP_PORT_READY=0`, pataisyk
profilį ir tik tada tęsk.

## 5. Dotfiles dry-run ir diegimas

Pirmiausia peržiūrėk visus numatomus pakeitimus:

```sh
./scripts/install-desktop dry-run
```

Tada įdiek symlinkus:

```sh
./scripts/install-desktop install
./install.sh status
```

Konfliktuojantys esami failai bus perkelti į
`~/.local/state/dev-shell/backups/<backup-id>/`. Aktyvus hosto profilis bus
`desktop`, todėl tas pats repo gali būti naudojamas ir laptope, ir desktope.

Paruošk terminalo shell:

```sh
./scripts/setup-zsh
./scripts/setup-zsh --set-default
```

Antra komanda pakeičia login shell; pakeitimas matysis po naujo login.

## 6. Pirmas Hyprland ir Quickshell startas

Iš TTY paleisk arba SDDM pasirink `Hyprland (uwsm-managed)` sesiją. Pirmo
starto metu:

- parenkamas random desktop wallpaperis;
- prieš pirmą Quickshell kadrą sugeneruojama jo `matugen` paletė;
- paleidžiamas vienas `qs --no-duplicate --config laptopui` procesas;
- per `systemd --user` paleidžiami `laptopui-hypridle.service` ir
  `laptopui-lid-inhibit.service`.

Patikrink:

```sh
hyprctl configerrors
hyprctl monitors
qs -c laptopui ipc show
systemctl --user daemon-reload
systemctl --user start \
  laptopui-hypridle.service laptopui-lid-inhibit.service
systemctl --user status \
  laptopui-hypridle.service laptopui-lid-inhibit.service
```

Desktop neturi lid įrenginio, todėl lid bind'ai ir inhibitorius kasdieniam
desktop veikimui nieko nedaro. Bendra konfigūracija išlieka tinkama laptopui.

## 7. Fiksuotas SDDM ir hyprlock wallpaperis

SDDM fonas nėra random desktop wallpaperis. Jis sąmoningai fiksuojamas ir
vėliau keičiamas tik rankine komanda. Įkelk norimą paveikslą į desktopą,
pavyzdžiui:

```text
~/Wallpapers/login.jpg
```

Priskirk jį tik SDDM/lock ekranams ir sugeneruok atskirą paletę:

```sh
cd ~/dev-shell
./scripts/sddm-theme set-wallpaper ~/Wallpapers/login.jpg
./scripts/sddm-theme prepare
./scripts/sddm-theme validate
```

Paleisk oficialų, sistemai nepavojingą SDDM test-mode:

```sh
./scripts/sddm-theme preview
```

Patikrink wallpaperį, laiką/datą, username `justas`, password lauką, session
ir keyboard layout. Tik jei preview atrodo gerai:

```sh
./scripts/sddm-theme install
./scripts/sddm-theme status
```

`install` sukuria backup, nukopijuoja vartotojo namų katalogo leidimų
nepriklausančius assets į `/usr/share/sddm/themes/laptopui` ir įrašo tik
`/etc/sddm.conf.d/10-laptopui-theme.conf`. Jis sąmoningai nestabdo ir
neperkrauna SDDM.

Username `justas` tik iš anksto įrašomas į lauką. Autologin neįjungiamas,
slaptažodis nesaugomas, PAM ir Hyprland sesija nekeičiami.

`hyprlock` automatiškai naudoja tą patį fiksuotą wallpaperį ir paletę. Jį
patikrink prieš logout:

```sh
laptopui-lock --grace 30
```

Grace metu pajudinus pelę lock užsidarys be slaptažodžio. Po to atlik tikrą
testą:

```text
SUPER + L
```

## 8. Lock, idle ir power elgsena

Aktyvi konfigūracija:

- 5 min. be aktyvumo — `hyprlock`;
- 10 min. — visi ekranai DPMS off;
- 20 min. — suspend;
- prieš suspend lock ekranas privalo būti pilnai užsikrovęs;
- po resume ekranai vėl įjungiami.

Laptopo profilyje papildomai:

- lid close — iškart DPMS off tik `eDP-1`;
- po 5 min. uždarytu lid — suspend;
- lid open iki 5 min. — timeris atšaukiamas ir `eDP-1` įjungiamas.

Patikra:

```sh
systemd-inhibit --list
systemctl --user list-timers --all | grep laptopui-lid || true
```

Jei liko nereikalingas lid timeris:

```sh
laptopui-lid open
```

## 9. Galutinė desktop priėmimo patikra

```sh
./scripts/install-desktop verify
./install.sh status
hyprctl configerrors
systemctl --user status pipewire wireplumber xdg-desktop-portal-hyprland
```

Rankiniu būdu patikrink:

- `DP-3` veikia 2560×1440@180 Hz, scale 1;
- nėra panelės ar Quickshell procesų dublikatų;
- launcher, notifications, tray, control center ir power dialogas;
- audio/mic/brightness OSD;
- MPRIS media valdymas, `cava`, peak burst ir bass banga;
- CPU/RAM ikonų geometrija ir performance profilio realus poveikis;
- orų ikona, temperatūra, data ir location centravimas;
- update counteris nerodo nulio, o updateris atidaro ASCII terminalą;
- wallpaperio pakeitimas gyvai atnaujina Quickshell, Hyprland ir Kitty spalvas;
- aktyvaus ir neaktyvaus lango borderiai bei shadow naudoja `matugen` paletę
  ir ją išlaiko po `hyprctl reload`;
- `SUPER+L`, slaptažodžio autentifikacija ir lock vaizdas;
- suspend/resume nepalieka Quickshell, hypridle ar Polkit dublikatų;
- NVIDIA fullscreen/XWayland žaidimai ir screen sharing;
- SDDM tema po logout/reboot, laikant recovery TTY pasiekiamą.

## 10. Rollback

Vartotojo dotfiles rollback:

```sh
cd ~/dev-shell
./install.sh status
./install.sh restore <backup-id>
```

SDDM rollback iš grafinės sesijos arba TTY:

```sh
cd ~/dev-shell
./scripts/sddm-theme status
./scripts/sddm-theme restore
sudo reboot
```

Jei repo helperis nepasiekiamas:

```sh
sudo mv /etc/sddm.conf.d/10-laptopui-theme.conf \
  /etc/sddm.conf.d/10-laptopui-theme.conf.disabled
sudo reboot
```

Po šio veiksmo SDDM grįš prie numatytos temos.

## 11. Vėlesnis login wallpaperio keitimas

Desktop random wallpaperiai SDDM nekeičia. Kai login/lock fonas nusibos:

```sh
cd ~/dev-shell
./scripts/sddm-theme set-wallpaper ~/Wallpapers/kitas-login.png
./scripts/sddm-theme preview
./scripts/sddm-theme install
```

Kiekvienas `install` vėl sukuria backup ir neperkrauna veikiančio SDDM.
