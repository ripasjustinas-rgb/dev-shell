# Desktop portavimo instrukcija

Tikslinis kompiuteris: Intel Core i7-8700 ir NVIDIA GeForce RTX 2080 Ti.
Portavimas padalintas į inventorizaciją, paketų diegimą, profilio užpildymą,
saugų dry-run, pirmą testą ir priėmimo patikrą.

## 1. Pasiruošimas ir inventorizacija

Perskaityk [PREREQUISITES.md](PREREQUISITES.md), klonuok repo ir prieš ką nors
keisdamas surink ataskaitą:

```sh
cd ~/dev-shell
./scripts/install-desktop preflight --output /tmp/laptopui-desktop-preflight.md
```

`preflight` nenaudoja `sudo` ir nekeičia sistemos. Ataskaitoje turi būti:

- tikslus CPU modelis, scaling driver, governor ir EPP;
- `powerprofilesctl` profiliai bei konfliktuojančių backend'ų būsena;
- GPU, aktyvus NVIDIA driveris ir DRM modeset;
- kiekvieno monitoriaus output vardas, režimas, pozicija ir scale;
- svarbių systemd servisų būsena;
- trūkstami repo manifestų paketai.

Pirmas paleidimas gali baigtis `REVIEW`; prieš paketų diegimą tai normalu.

## 2. Paketų diegimas

```sh
./scripts/install-desktop packages
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon
sudo reboot
```

Po restarto pakartok inventorizaciją:

```sh
./scripts/install-desktop preflight --output /tmp/laptopui-desktop-after-packages.md
```

NVIDIA priėmimo minimumas:

```sh
nvidia-smi
cat /sys/module/nvidia_drm/parameters/modeset  # turi būti Y
```

Jei naudojamas custom kernelis, sustok ir pakeisk `nvidia-open` į
`nvidia-open-dkms` bei pridėk tinkamą kernel headers paketą. Nemaišyk kelių
NVIDIA kernel modulių variantų.

## 3. Monitorių profilio užpildymas

Ataskaitos `Displays` lentelės reikšmes perkelk į
`dotfiles/.config/hypr/modules/profiles/desktop.lua`:

```lua
hl.monitor({
  output = "DP-1",
  mode = "2560x1440@144",
  position = "0x0",
  scale = "1",
})

hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@60",
  position = "2560x0",
  scale = "1",
})
```

Pavyzdžio output vardų nekopijuok aklai. Naudok tik to desktopo `hyprctl
monitors` parodytus vardus ir realiai palaikomus režimus. Bendras
`preferred/auto` monitoriaus įrašas lieka saugus fallback atjungtam arba naujam
ekranui.

## 4. Performance profilio patikra

Pradinis backend'as yra `power-profiles-daemon`. Patikrink, ar jis pateikia
`performance`:

```sh
powerprofilesctl list
powerprofilesctl get
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null
```

Tada perjunk ir pakartok sysfs rodmenis:

```sh
powerprofilesctl set performance
powerprofilesctl get
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null
```

Priimama tik jei `performance` egzistuoja ir keičiasi reali CPU politika, ne
vien UI tekstas. Jei performance profilis nepateikiamas, desktop diegimo
netęsk: pirmiau reikia atskiro commit'o, kuris manifestą ir QML backend'ą
perjungia į vieną pasirinktą alternatyvą (`tuned`/`tuned-ppd` arba `cpupower`).
Keli power manageriai vienu metu neleidžiami.

## 5. Profilio atrakinimas ir dry-run

Kai monitoriai ir performance patikrinti, pakeisk:

```dotenv
DESKTOP_PORT_READY=1
```

faile `profiles/desktop/profile.env`. Tada:

```sh
./scripts/install-desktop dry-run
```

Peržiūrėk kiekvieną `dry-run:` eilutę. Diegiklis linkina tik manifeste
išvardytus kelius. Esami konfliktuojantys failai realaus diegimo metu būtų
perkelti į `~/.local/state/dev-shell/backups/<backup-id>/`.

## 6. Diegimas ir pirmas startas

Turėdamas veikiančią TTY:

```sh
./scripts/install-desktop install
./install.sh status
```

Diegimas įrašo `desktop` į
`~/.local/state/dev-shell/active-profile`. Hyprland Lua loaderis pagal šį
markerį užkrauna `modules/profiles/desktop.lua`; Git checkout'e nereikia
perjunginėti bendro symlink'o, todėl laptop ir desktop gali naudoti tą patį
repo skirtinguose hostuose.

Pirmam testui paleisk naują Hyprland sesiją iš TTY arba pasirink ją display
manager'yje. Neuždaryk recovery TTY, kol nepatvirtinti panelė, input ir visi
monitoriai.

## 7. Priėmimo patikra

```sh
./scripts/install-desktop verify
qs -c laptopui ipc show
systemctl --user status pipewire wireplumber xdg-desktop-portal-hyprland
```

Rankiniu būdu patikrink:

- visi monitoriai turi teisingą poziciją, refresh rate ir scale;
- monitoriaus atjungimas nesukuria panelės dublikatų;
- launcher, tray, notification center ir power meniu;
- garsas, mikrofonas, MPRIS ir `cava` vizualizacija;
- dinaminė `matugen` paletė pakeitus wallpaperį;
- `balanced ↔ performance` keičia realią CPU politiką;
- NVIDIA žaidimai/fullscreen, XWayland ir screen sharing;
- desktop neturint baterijos jos valdiklis pasislepia.

Tik po šių patikrų desktop portą laikyk baigtu.

## Rollback

Rask paskutinį backup ID:

```sh
./install.sh status
```

Grąžink prieš diegimą buvusius kelius ir ankstesnį aktyvų profilį:

```sh
./install.sh restore <backup-id>
```

Jeigu grafinė sesija nepasileidžia, šias komandas vykdyk iš recovery TTY.
