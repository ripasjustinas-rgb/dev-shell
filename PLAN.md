# laptopui / Arch dotfiles planas

## Tikslas

`dev-shell` yra vienintelis konfigūracijos šaltinis Hyprland aplinkai. Jame kuriamas
vienas vardinis Quickshell apvalkalas `laptopui`, veikiantis ir šiame ThinkPad, ir
Arch Linux desktop kompiuteryje. Į namų direktoriją diegiamos nuorodos į šį
repozitoriją; esami failai niekada neperrašomi be atsarginės kopijos.

## Atsakomybės

- **Hyprland**: monitoriai, workspace'ai, input, langų taisyklės, klavišų
  kombinacijos, Quickshell paleidimas ir sesijos aplinka.
- **Quickshell**: panelė, launcher'is, control center, notification center,
  OSD, system tray ir power/session UI.
- **Sistemos servisai**: NetworkManager, BlueZ, PipeWire/WirePlumber, UPower,
  power-profiles-daemon ir systemd/logind atlieka realius sistemos veiksmus.
- **hypridle + hyprlock**: idle eiga ir saugus ekrano užrakinimas. Quickshell
  gali rodyti veiksmą, tačiau pats nėra lock screen saugumo riba.

Quickshell pirmiausia naudoja savo Hyprland, PipeWire, UPower, MPRIS,
SystemTray ir Notifications API. Trumpi išoriniai procesai (`brightnessctl`,
`powerprofilesctl`, `systemctl`) naudojami tik ten, kur nėra tinkamos API.

## Būtini UI komponentai

### Pirmas veikiantis leidimas (MVP)

1. Panelė kiekvienam monitoriui turi tris aiškias zonas:
   - **kairė:** penki fiksuoti Hyprland workspace pasirinkimai (`1`–`5`),
     šeštas tokio pat dydžio mygtukas keičia wallpaper'į ir niekada neperjungia
     į workspace `6`; po jo rodoma atnaujinimų ikona su laukiančių atnaujinimų
     skaičiumi;
   - **centras:** data, konfigūruojama lokacija ir tos lokacijos orų
     temperatūra;
   - **dešinė:** Wi-Fi manager, baterijos ir energijos profilio valdiklis,
     system tray, klaviatūros išdėstymo pasirinkimas ir power meniu;
   - workspace'ai rodo active/urgent/fullscreen būsenas;
   - desktop kompiuteryje baterijos dalis pasislepia, tačiau energijos profilio
     valdiklis lieka matomas.
2. Programų launcher'is iš desktop entries, pakeičiantis Wofi launcher'į.
3. Control center:
   - garsumas ir mute;
   - Wi-Fi/tinklo santrauka;
   - Bluetooth santrauka;
   - ryškumas tik įrenginiuose su backlight;
   - baterija tik ją turinčiuose įrenginiuose;
   - power profile visuose hostuose, kuriems sukonfigūruotas profilių backend'as.
4. Volume, microphone ir brightness OSD, reaguojantis į Hyprland multimedia
   klavišus.
5. Notification daemon, toast'ai ir notification center. Vienu metu veikia
   tik vienas notification daemon.
6. Power meniu su trimis veiksmais ir patvirtinimu: restart, logout, shutdown.
   Lock ir suspend lieka Hyprland/hypridle veiksmai, bet nėra šio meniu dalis.
7. Vieninga tema: spalvų, tarpų, radius, tipografijos, animacijų ir ikonų
   tokenai; komponentai neturi savo atsitiktinių hard-coded reikšmių.
8. Wallpaper servisas: šeštas kairės zonos mygtukas parenka kitą paveikslą iš
   profilyje nurodyto katalogo, išsaugo pasirinkimą ir atkuria jį po login.
9. Update servisas:
   - periodiškai ir rankiniu būdu, be pacman DB užrakinimo, atnaujina laukiančių
     oficialių Arch paketų skaičių;
   - AUR skaičius pridedamas tik jei pasirinktame profilyje įjungtas AUR
     helper'is;
   - paspaudus ikoną terminale atidaromas interaktyvus repo `update` skriptas;
   - shell pats nevykdo privilegijuoto atnaujinimo fone.
10. Orų servisas saugo lokaciją profilyje, turi cache ir aiškią offline/error
    būseną; tinklo ar API klaida neturi paveikti likusios panelės.
11. Wi-Fi mygtukas atidaro tinklų sąrašą, leidžia įjungti/išjungti Wi-Fi,
    prisijungti ir atsijungti. Klaviatūros mygtukas rodo aktyvų layout ir leidžia
    pasirinkti vieną iš profilyje deklaruotų layout'ų.

### Po MVP

- media/MPRIS kortelė;
- kalendorius;
- clipboard history UI su `cliphist`;
- screenshot region/window/fullscreen eiga;
- išplėstas wallpaper picker'is;
- window/workspace overview, jeigu jis duoda daugiau vertės nei launcher'is.

### Įgyvendinta šioje sesijoje

- Quickshell background wallpaper sluoksnis su crossfade, be Hyprland splash;
- panelės audio popup ir bendras animuotas control center;
- volume, microphone ir brightness OSD per multimedia bind'us;
- Quickshell notification serveris, toast'ai, istorija ir DND;
- Quickshell desktop-entry launcher'is bei power dialogas su patvirtinimu;
- `mako.service` išjungtas, o Wofi nebenaudojamas aktyviuose keliuose.
- iš `NerdMini_shell` pritaikytas „high rice“ stiklo/glow stilius ir spring
  Hyprland animacijos;
- MPRIS media kortelė ir `cava` spektro vizualizacija panelės centre;
- gyvi CPU/RAM rodmenys ir saugus `powerprofilesctl` performance valdiklis;
- automatinė `matugen` Material You paletė iš aktyvaus wallpaper'io, gyvai
  pritaikoma Quickshell, Hyprland ir Kitty spalvoms;
- „high rice“ Kitty tema su permatomu fonu, Nerd Font, kompaktišku tab bar ir
  automatinio spalvų perkrovimo palaikymu;
- Zsh + Oh My Zsh aplinka su Starship promptu, kuris naudoja Kitty dinaminę
  ANSI paletę, autosuggestions ir syntax highlighting;
- patikimas oficialių Arch atnaujinimų counteris ir spalvotas ASCII updaterio
  terminalas su momentiniu panelės perskaičiavimu po atnaujinimo;
- didelė dinaminė Nerd Font orų ikona kairėje nuo datos ir vietos, su
  dienos/nakties bei pagrindinių oro sąlygų būsenomis;
- viena centruojama weather/clock/media grupė, kurios kairysis vizualizatorius
  rodomas prieš orų ikoną;
- iš seno max-rice atkurta adaptyvi bass transientų detekcija, dviguba per
  centrinį bloką nubėganti banga ir visualizerio peak burst efektas;
- clipboard istorijos perkėlimas sąmoningai atidėtas vėlesniam etapui.

## Laptopo ir desktopo profiliai

- `common`: visas bendras Hyprland elgesys ir vienas Quickshell kodas.
- `laptop`: vidinis `eDP` ekranas, touchpad, lid switch, baterija, ryškumas ir
  power profiles. Pradinis hostas: `archpad`, ThinkPad E16 Gen 3,
  `eDP-1` 1920x1200@60.
- `desktop`: Intel Core i7-8700 ir NVIDIA GeForce RTX 2080 Ti; konkretūs
  monitorių vardai, pozicijos, scale/refresh, NVIDIA sesijos parametrai ir
  desktopui būdingas input. Likusios reikšmės užpildomos inventorizavus
  desktopą.

QML nešakojamas pagal hostname. Panelės kuriamos iš `Quickshell.screens`, o
baterijos, backlight ir kiti widgetai įjungiami pagal realias sistemos
galimybes. Profiliai reikalingi tik tam, ko patikimai automatiškai nustatyti
negalima, pirmiausia monitorių išdėstymui ir input taisyklėms.

Desktopo i7-8700 **performance** režimas yra privalomas priėmimo kriterijus.
Profilio valdiklis turės keičiamą backend'ą:

1. pirmiausia naudojamas `powerprofilesctl`, jeigu `list` realiai pateikia
   `performance` profilį;
2. jei jis desktopo platformoje performance profilio nepateikia, naudojamas
   vienas aiškiai pasirinktas pakaitalas: rekomenduojamas `tuned` su
   `tuned-ppd`, arba paprastesnis `cpupower` profilis;
3. `power-profiles-daemon`, `tuned` ir kiti CPU power manager'iai negali veikti
   vienu metu;
4. diegimo `check` patikrina CPU scaling driver'į, galimus governor/EPP,
   aktyvų profilį ir tai, kad pasirinkus performance pasikeitė reali sistemos
   politika. Vien pasikeitęs UI tekstas nelaikomas sėkme.

## Numatoma repozitorijos struktūra

```text
dev-shell/
├── README.md
├── PLAN.md
├── install.sh
├── packages/
│   ├── arch-common.txt
│   ├── arch-laptop.txt
│   └── arch-desktop.txt
├── dotfiles/
│   ├── .config/
│   │   ├── hypr/
│   │   │   ├── hyprland.lua
│   │   │   └── modules/
│   │   ├── quickshell/laptopui/
│   │   │   ├── shell.qml
│   │   │   ├── components/
│   │   │   ├── modules/
│   │   │   ├── services/
│   │   │   └── theme/
│   │   ├── hypridle/
│   │   └── hyprlock/
│   └── .local/bin/
└── profiles/
    ├── laptop/
    └── desktop/
```

Quickshell konfigūracija yra vardinė: `~/.config/quickshell/laptopui`, ji
paleidžiama su `qs -c laptopui`. `shell.qml` turės pastovų `ShellId`, kad
Quickshell state/cache tapatybė nepasikeistų dėl symlink kelio.

## Diegimo įrankis

`install.sh` bus plonas, idempotentinis symlink diegiklis su profiliais:

```text
./install.sh check
./install.sh install --profile laptop
./install.sh install --profile desktop
./install.sh packages --profile laptop
./install.sh status
./install.sh restore <backup-id>
```

Reikalavimai diegikliui:

- nustato repo kelią pagal patį skriptą, ne pagal working directory;
- turi `--dry-run`;
- linkina tik aiškiai manifest'e išvardytus failus/katalogus;
- konfliktus prieš pakeitimą perkelia į
  `~/.local/state/dev-shell/backups/<timestamp>/`;
- niekada nelinkina viso `~/.config` ar `~/.local` medžio;
- paketų diegimas yra atskiras, aiškiai paleidžiamas veiksmas su
  `pacman --needed`;
- nerakina ir nesaugo secrets, SSH raktų, tokens ar machine-id;
- `status` parodo trūkstamus paketus, neteisingas nuorodas ir servisų būseną;
- `restore` leidžia grįžti prie prieš diegimą buvusios būsenos.

Pradiniai paketai: `quickshell`, `hyprland`, `hypridle`, `hyprlock`,
`xdg-desktop-portal-hyprland`, `pipewire`, `wireplumber`, `networkmanager`,
`bluez`, `upower`, `power-profiles-daemon`, `brightnessctl`, `playerctl`,
`wl-clipboard`, `cliphist`, `grim`, `slurp`, pasirinktas Nerd Font ir emoji
fontas. Update skaičiavimui pridedamas `pacman-contrib`. Laptopo/desktopo
manifestai prideda tik profiliui būtinus paketus; desktopo manifestas taip pat
aprašo pasirinktą NVIDIA driverį ir vieną CPU profilių backend'ą.

## Hyprland integracija

Hyprland konfigūracija dalijama į mažus Lua modulius: `monitors`, `env`,
`autostart`, `input`, `appearance`, `bindings`, `rules` ir aktyvus `profile`.

- Hyprland paleidžia vieną `qs -c laptopui` instanciją.
- `SUPER+R` atidaro Quickshell launcher'į.
- Atskiri bind'ai atidaro control center, notification center ir power meniu.
- Multimedia bind'ai keičia sistemos būseną; Quickshell ją stebi ir rodo OSD.
- Penki workspace bind'ai atitinka penkis kairės panelės pasirinkimus;
  wallpaper mygtukas nėra workspace ir turi atskirą veiksmą.
- Quickshell Hyprland modulis teikia workspace'us, monitorius ir
  dispatcher'ius be nuolatinio `hyprctl` polling.
- Panelės `PanelWindow` rezervuoja tikslų viršutinį plotą per exclusive zone.
- Layer taisyklės naudoja stabilius namespace'us animacijoms ir blur.
- Waybar išjungiamas tik patvirtinus, kad Quickshell panelė ir tray veikia.
- Wofi ir seni power skriptai šalinami iš aktyvios konfigūracijos tik po
  launcher/control center funkcijų pariteto.
- Polkit agentas turi būti tik vienas: pradžioje KDE agentas, vėliau galima
  sąmoningai pakeisti Quickshell Polkit implementacija.

## Įgyvendinimo etapai ir priėmimo kriterijai

### 0. Bazinė kopija ir Git

- Nukopijuoti dabartinius Hyprland, Waybar ir helper skriptus į repo.
- Inicializuoti Git ir padaryti nepakeistos būsenos commit'ą.
- Užrašyti dabartinius paketus ir hosto profilį.

Priimta, kai repo gali atkurti dabartinę veikiančią sesiją.

### 1. Dotfiles karkasas

- Sukurti struktūrą, paketų manifestus ir saugų `install.sh`.
- Išskaidyti Hyprland Lua konfigūraciją nepakeičiant jos elgesio.
- Patikrinti `check`, `dry-run`, backup, pakartotinį install ir restore.

Priimta, kai antras install nieko nekeičia, o restore grąžina pradinę būseną.

### 2. Quickshell pagrindas ir panelė

- Įdiegti oficialų Arch `quickshell` release, pradžioje nefiksuoti prie `-git`.
- Sukurti `ShellRoot`, temos tokenus, ekranų modelį ir vieną panelę ekranui.
- Įgyvendinti penkis workspace mygtukus, datos/orų centrą ir tray.
- Testavimo metu Waybar palikti kaip greitą fallback; tada jį išjungti.

Priimta, kai shell persikrauna be QML klaidų, langai nepalenda po panele,
workspace'ai veikia pele ir klaviatūra, o monitoriaus hotplug nesukuria dublikatų.

### 3. Sistemos būsenos ir iššokantys UI

- Audio, network, Bluetooth, battery, brightness ir power profile servisai.
- Trijų zonų panelė, wallpaper, update ir cache'inamas orų servisas.
- Control center, OSD, launcher'is, klaviatūros layout ir session meniu.
- Pakeisti Wofi ir esamus power helper skriptus tik pasiekus funkcijų paritetą.

Priimta, kai funkcijos veikia ir be baterijos/backlight, dingę DBus servisai
ar internetas nesugriauna shell, wallpaper pasirinkimas išlieka po login,
update skaičius atitinka update skripto rezultatą, o pavojingi power veiksmai
turi patvirtinimą.

### 4. Notifications ir sesijos gyvavimo ciklas

- Notification daemon, toast'ai, istorija ir DND.
- `hypridle` + `hyprlock`, suspend/resume ir lid elgsena.
- Patikrinti portalą, screen sharing ir vieną Polkit agentą.

Priimta, kai po logout/login ir suspend/resume lieka po vieną shell,
notification ir authentication agent instanciją.

### 5. Desktop profilis ir stabilizavimas

- Parengti read-only desktop hardware/session preflight ataskaitą, etapais
  vykdomą install wrapperį ir atskiras prerequisites/portavimo instrukcijas.
- Inventorizuoti desktopo monitorius/input ir užpildyti profilį.
- Patikrinti i7-8700 scaling driver'į ir įrodyti, kad UI pasirinktas performance
  profilis pakeičia realią CPU politiką; patikrinti NVIDIA RTX 2080 Ti sesiją.
- Iš švarios Arch vartotojo paskyros paleisti diegimą abiem profiliais.
- Patikrinti 1 ir kelių monitorių režimus, monitoriaus atjungimą, fullscreen,
  žaidimus, tray meniu, screen sharing ir rolling-release atnaujinimą.
- README aprašyti install, update, rollback ir troubleshooting.

Priimta, kai tas pats Quickshell kodas veikia abiejuose hostuose, o skiriasi
tik deklaratyvus profilis.

## Sąmoningai atidėti sprendimai

Prieš UI implementaciją reikia pasirinkti tik vizualinę kryptį: panelės vietą
(rekomenduojama viršuje), tankį/dydį, tamsią ar automatinę temą ir bendrą
estetiką. Šie pasirinkimai nekeičia architektūros ar diegimo plano.
