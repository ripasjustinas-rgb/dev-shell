# Desktop PC perdavimas: pilna LaptopUI diegimo eiga

Šis failas yra praktinis runbook'as, skirtas perkelti dabartinę `main` versiją
į desktop PC. Tikslinis hostas: Intel Core i7-8700, NVIDIA GeForce RTX 2080 Ti
ir Xiaomi 2560×1440@180 Hz monitorius per `DP-3`.

Media/seek, tinklo telemetrijos, kompaktiškų išplečiamų kortelių ir clipboard
3 → 50 įrašų elgesys: [SHELL_CONTROLS.md](SHELL_CONTROLS.md). Naujas
`laptopui-network-info` helperis įtrauktas į diegiklį; reikalingi `python`,
`iproute2`, `iputils`, `nmcli` ir `curl`. `speedtest-cli`, `iw` ir hyprsunset
yra neprivalomi, jų nebuvimas turi matomą fallback.

Dabartinė versija apima:

- Hyprland ir Quickshell `laptopui` su high-rice stiklo/glow estetika;
- dinaminę desktop wallpaperio `matugen` paletę Quickshell, Hyprland ir Kitty;
- MPRIS media kortelę, `cava` vizualizaciją ir bass bangos efektą;
- CPU/RAM rodmenis, kurių paspaudimas atidaro `btop`, performance profilius,
  orus, update counterį ir terminalo updaterį; centrinį paspaudžiamą
  kalendorių su penkių dienų Open-Meteo prognoze;
- Kitty, Zsh, Oh My Zsh ir Starship;
- fiksuotą, atskirai previewinamą LaptopUI SDDM temą;
- tokį pat SDDM stilių atkartojantį `hyprlock`;
- `hypridle`: baterijoje 5 min. lock, 10 min. DPMS off ir 20 min. suspend;
  prijungus įkroviklį tik 10 min. lock;
- laptopo lid eigą: ekranas off iškart, suspend po 5 min., atidarius atšaukiama.
- `SUPER+A` clipboard history su tekstu ir vaizdų thumbnail per `cliphist`.
- `SUPER+S` viso ekrano ir `SUPER+SHIFT+S` regiono screenshot'ai į
  `Pictures/Screenshots` bei clipboard.
- capability-driven control center: desktop'e be baterijos ar backlight šie
  valdikliai nerodomi ir nevykdo backend užklausų;
- vieną Wi-Fi/Bluetooth connectivity popup, `SUPER+TAB` langų overview ir
  `SUPER+SHIFT+R` command palette;
- persistuojamą DND bei calm mode; calm mode sustabdo `cava` procesą.
- wallpaper pickerį kairėje panelės pusėje: miniatiūrų tinklelis, konkretus
  pasirinkimas bei „Next“ ir „Random“ veiksmai.
- pasirinktinį `wayland-vpets` Bongo Cat po wallpaper ir update mygtukų,
  reaguojantį į klaviatūrą ir nedidinantį panelės `exclusiveZone`.

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
SDDM, Qt5 Quick Controls, Hyprland, Quickshell, hyprlock, hypridle, `cliphist`,
`wl-clipboard`, `grim`, `slurp`, `btop` ir visus UI helperių paketus.
`curl` ir `jq` taip pat yra bendrame manifeste: jie reikalingi dabartiniams
orams ir penkių dienų Open-Meteo prognozei. Prognozė nereikalauja API rakto,
tačiau jai būtinas veikiantis DNS ir interneto ryšys.

CPU arba RAM rodmuo atidaro `kitty btop`. Valdoma `btop` konfigūracija palieka
jo foną skaidrų, todėl matomas tas pats Kitty wallpaper blur ir spalvinis
kontekstas, o ne atskiras juodas blokas.

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
- per `systemd --user` paleidžiami `laptopui-hypridle.service`,
  `laptopui-lid-inhibit.service` ir `laptopui-clipboard.service`.
- jei įdiegtas pasirinktinis `wpets`, Quickshell paleidžia
  `laptopui-vpet.service`; cat telpa esamoje panelėje ir papildomo ekrano
  aukščio nerezervuoja. Jei sukurtas `~/.local/lib/laptopui/wpets-themed`,
  jo kūnas naudoja dabartinės `matugen` paletės `secondary` spalvą.

Patikrink:

```sh
hyprctl configerrors
hyprctl monitors
qs -c laptopui ipc show
systemctl --user daemon-reload
systemctl --user start \
  laptopui-hypridle.service laptopui-lid-inhibit.service laptopui-clipboard.service
systemctl --user status \
  laptopui-hypridle.service laptopui-lid-inhibit.service laptopui-clipboard.service
```

Patikrink centrinį panelės valdiklį: paspaudus datą ir orus turi atsidaryti
kalendorius su mėnesio navigacija bei penkiomis prognozės eilutėmis. Jei vietoj
jų rodoma unavailable, patikrink helperį ir ryšį:

```sh
~/.local/bin/laptopui-weather --forecast
```

### Pasirinktinis Bongo Cat

Kairės panelės seka yra penki workspace'ai, wallpaper mygtukas, update
counteris ir Bongo Cat. Cat piešiamas atskirame skaidriame Wayland overlay,
tačiau QML rezervuoja jo horizontalų plotį. Overlay aukštis lieka toks pats
kaip panelės — 48 px — todėl naudojamas ekrano plotas nesumažėja.
wpets paviršius naudoja `overlay_layer=top`, kaip ir įprasta panelė, todėl
fullscreen langas uždengia ir panelę, ir cat. `overlay` sluoksnio čia naudoti
negalima, nes jis tyčia liktų matomas virš fullscreen lango.

`wpets` yra AUR paketas ir nėra bendrame `pacman` manifeste:

```sh
yay -S wpets
sudo usermod -a -G input "$USER"
```

Pasirinktinis teminis variantas išsaugo native Bongo Cat paw mapping, bet
grayscale kūną paleidimo metu tonuoja iš `colors.json`. Jis statomas iš AUR
cache esančio to paties wpets source archive:

```sh
sudo pacman --needed -S cmake
laptopui-vpet-build-themed
```

Rezultatas įrašomas į `~/.local/lib/laptopui/wpets-themed`; helperis jį renkasi
pirmiau už `/usr/bin/wpets-all`. `laptopui-theme-generate` po naujos paletės
įrašymo perstartuoja servisą, todėl nauja spalva pritaikoma iškart. wpets
atnaujinus builderį reikia paleisti dar kartą.

`profiles/laptop/profile.env` nustato `eDP-1`, 40 px cat ir 8 px vertikalų
offset; `profiles/desktop/profile.env` nustato `DP-3`, 40 px cat ir −3 px
vertikalų offset. Abiejų profilių 232 px horizontalus offset pritaikytas
galutinei wallpaper → updates → cat sekai. `./install.sh install --profile ...` šias
reikšmes įrašo į `~/.local/state/laptopui/vpet-profile.env`.

Klaviatūrą kiekviename hoste aptik atskirai. `wpets-find-devices` komentare
parodo `/dev/input/eventN`; į lokalų, netrackinamą failą įrašyk kelią, ne
įrenginio pavadinimą:

```sh
mkdir -p ~/.config/laptopui
printf '%s\n' 'keyboard_device=/dev/input/eventN' \
  > ~/.config/laptopui/vpet.local.conf
systemctl --user daemon-reload
systemctl --user restart laptopui-vpet.service
```

Servisas per `newgrp input` įeina tik į vartotojui jau suteiktą grupę. Jis
nekoreguoja `/dev/input` teisių ir nenaudoja root proceso. Patikrink:

```sh
systemctl --user status laptopui-vpet.service
journalctl --user -u laptopui-vpet.service -n 50 --no-pager
```

Žurnale turi būti `Opened input device` ir sėkmingas `1/1 input devices`
rezultatas. Jei `wpets` neįdiegtas, QML nerodo nei cat, nei tuščio tarpo. Calm
mode arba reduced motion sustabdo servisą, bet nekeičia panelės išdėstymo.
Numatytoji išvaizda yra veidrodinėta; ramybės kadre abi letenos nuleistos,
idle seka kas maždaug 7,4 s trumpam parodo užmerktų akių kadrą, o po 5 min.
neveiklos cat pereina į nuolatinę sleep būseną. Teminis binary keičia tik
grayscale kūno spalvą į paletės
`secondary`; rausvos detalės, juodi kontūrai ir animacijos lieka originalūs.
Same-side typing kadrai lokaliai stabilizuoti: greito input burst metu wpets
nebekaitalioja aktyvios letenos su abiejų letenų pakėlimo kadru.
Po letenomis buvę raudoni SVG impact brūkšniai pašalinami prieš sprite
sumažinimą, kad jų kraštai nebūtų įmaišyti kaip tamsūs artefaktai ant šviesaus
wallpaperio. `enable_antialiasing=1` įjungia bilinear scaling, todėl mažo cat
letenų ir galvos kontūrai lieka glotnūs. Teminis buildas Bongo SVG pirmiausia
rasterizuoja 2× raiška ir tik tada bilinear būdu sumažina iki galutinio dydžio.

#### Kaip atkuriamos teminės ir išvalytos Bongo Cat sprite'ų versijos

Visa lokali wpets elgsena laikoma dviejuose repo patch'uose, todėl jos nereikia
rankomis kartoti AUR source medyje:

- `patches/wpets-bongocat-body-color.patch` prideda temos spalvą, idle/resting
  kadrus, same-side typing stabilizavimą ir įjungia idle animaciją;
- `patches/wpets-bongocat-supersample.patch` prideda 2× SVG rasterizavimą,
  bilinear sumažinimą ir nustato teisingą artefaktų šalinimo eiliškumą.

Temos spalvos kelias yra toks:

1. `laptopui-theme-generate` iš matugen rezultato įrašo
   `~/.local/state/laptopui/colors.json`; reikalinga reikšmė yra `.secondary`
   ir turi būti `#RRGGBB` formato.
2. `laptopui-vpet` patikrina reikšmę su `jq` ir eksportuoja ją kaip
   `WPETS_BONGOCAT_BODY_COLOR` prieš paleisdamas teminį binary.
3. `parse_bongocat_body_color()` paverčia reikšmę į RGB. Sprite pikseliuose
   tonuojami tik beveik grayscale pikseliai, kurių didžiausio ir mažiausio RGB
   kanalo skirtumas neviršija 2. Jų šviesumas dauginamas iš `.secondary`
   spalvos, todėl išlieka originalus šešėliavimas. Rausvos letenų detalės
   neliečiamos, o juodas kontūras lieka juodas.
4. Sugeneravus naują paletę, `laptopui-theme-generate` vykdo
   `systemctl --user try-restart laptopui-vpet.service`; nauja spalva todėl
   pritaikoma be wpets perkompiliavimo.

Tamsūs blokai po nuleistomis letenomis nėra kontūro dalis. Originaliuose
wpets SVG ten yra raudonos smūgio linijos. Jų šalinimo tvarka yra svarbi:

1. Dar pilnos 2× raiškos RGBA sprite'e aptinkami aiškiai raudoni pikseliai
   (`R > 140`, `R > G + 70`, `R > B + 70`) ir visi keturi jų kanalai
   nustatomi į nulį.
2. Tik po to kiekvienas iš penkių kadrų atskirai, nuo savo lokalaus `(0, 0)`,
   bilinear būdu sumažinamas iki vienodo galutinio kadro dydžio. Negalima vienu
   kartu mažinti viso sprite sheet: 40 px cat atveju 2× kadras yra 145 px
   pločio, todėl penkių kadrų 725 px plotis dalijant iš dviejų palieka apvalinimo
   likutį. Dėl jo keistųsi sampling fazė ir tarp kadrų atsirastų 1 px šoninis
   poslinkis. Atskiras mažinimas visus kadrus įrašo į tą patį 72 px tinklelį.
   Jei smūgio linijos būtų šalinamos po sumažinimo, filtras jų kraštus jau būtų
   sumaišęs su skaidriu fonu; likę mažo alpha tamsūs pikseliai ir sudarytų
   matomus blob'us.
3. `enable_antialiasing=1` paliekamas runtime konfigūracijoje. Jis glotnina
   galutinį piešimą, o 2× rasterizavimas glotnina patį mažą SVG sprite'ą.

Patch'ų tvarka builderyje taip pat yra fiksuota: pirmiausia taikomas
`wpets-bongocat-body-color.patch`, tada `wpets-bongocat-supersample.patch`, nes
antras patch'as kviečia pirmame pridėtą pikselių apdorojimo funkciją. Po wpets
atnaujinimo arba pakeitus patch'us atkurk binary ir servisą:

```sh
laptopui-vpet-build-themed
systemctl --user restart laptopui-vpet.service
```

Patikrink, kad žurnale nėra sprite load klaidų, `vpet.conf` turi
`enable_antialiasing=1`, o ant šviesaus wallpaperio po abiem resting letenomis
lieka visiškai skaidrus plotas:

```sh
rg '^(cat_height|cat_y_offset|enable_antialiasing)=' \
  ~/.local/state/laptopui/vpet.conf
journalctl --user -u laptopui-vpet.service -n 50 --no-pager
```

### Wallpaper pickeris

Kairysis mygtukas su wallpaper ikona atidaro didelį, prie ekrano prisitaikantį
pickerį. Jis iš `LAPTOPUI_WALLPAPER_DIR` (numatytai `~/Wallpapers`) nuskaito
PNG, JPG/JPEG ir WebP failus, rodo jų miniatiūras ir pažymi aktyvų pasirinkimą.
Kortelė išsiplečia iki 820 px pločio ir 760 px aukščio, neperžengdama ekrano;
stulpelių skaičius prisitaiko prie turimos vietos.

- Paspaudus miniatiūrą iškviečiamas `laptopui-wallpaper-set`.
- „Next“ išlaiko deterministinį rikiuotės ciklą, o „Random“ neparenka šiuo
  metu aktyvaus fono, jei yra daugiau nei vienas failas.
- Visi trys keliai įrašo `~/.local/state/laptopui/wallpaper`, sugeneruoja
  `matugen` paletę ir atnaujina veikiantį Quickshell foną su crossfade. Jei
  Quickshell neveikia, tas pats helperis pritaiko foną per `hyprpaper`.

Po atnaujinimo įdiek naują helperį per įprastą profilinį diegimą, pvz.:

```sh
cd ~/dev-shell
./install.sh install --profile desktop
```

Greitam QML pakeitimų pritaikymui veikiamoje sesijoje:

```sh
~/.local/bin/laptopui-reload
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

- naudojant bateriją: 5 min. be aktyvumo — `hyprlock`, 10 min. — DPMS off,
  20 min. — suspend;
- prijungus įkroviklį: 10 min. — `hyprlock`; DPMS off ir idle suspend nevykdomi;
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
- `SUPER+A` clipboard istorija: nukopijuotas tekstas ir vaizdas pasirodo
  sąraše, vaizdas turi thumbnail preview, paspaudus jie grąžinami į clipboard,
  o „Clear“ išvalo istoriją;
- `SUPER+S` išsaugo visų ekranų PNG, `SUPER+SHIFT+S` leidžia pažymėti regioną;
  abu failai yra `Pictures/Screenshots`, nukopijuojami į clipboard ir rodomi
  control center thumbnail;
- audio/mic/brightness OSD;
- MPRIS media valdymas, `cava`, peak burst ir bass banga;
- CPU/RAM ikonų geometrija, jų paspaudimu Kitty atsidarantis `btop` ir
  performance profilio realus poveikis;
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
