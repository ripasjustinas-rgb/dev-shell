# laptopui dotfiles

Arch Linux Hyprland ir Quickshell konfigūracija laptopui bei desktopui.

Desktop portavimo pradžia:

```sh
./scripts/install-desktop preflight --output /tmp/laptopui-desktop-preflight.md
```

Pilna prerequisites ir saugaus perkėlimo eiga aprašyta
[docs/PREREQUISITES.md](docs/PREREQUISITES.md) bei
[docs/DESKTOP_PORT.md](docs/DESKTOP_PORT.md).

SDDM login ekranui paruošta atskirai previewinama ir atkuriama LaptopUI tema.
Jos saugi diegimo eiga aprašyta [docs/SDDM.md](docs/SDDM.md); tema nėra
aktyvuojama kartu su įprastu dotfiles diegimu.

Tą patį wallpaperį ir paletę naudojantis `hyprlock`, 5/10/20 min. idle eiga
bei atidėtas lid suspend aprašyti [docs/LOCK_IDLE.md](docs/LOCK_IDLE.md).

Waybar konfigūracija išlaikoma tik kaip avarinis fallback. Aktyvus shell yra
Quickshell `laptopui`: panelė, wallpaper, launcher, control center,
notifications, OSD ir power dialogai veikia be Wofi. Panelė taip pat turi
MPRIS media kortelę, `cava` garso spektro vizualizaciją, CPU/RAM rodmenis ir
energijos profilio valdiklį. Paspaudus CPU arba RAM rodmenį atidaromas Kitty
terminalas su `btop`. Centrinis datos ir vietos blokas papildytas didele
Nerd Font orų ikona kairėje, kuri skiria dieną, naktį, debesis, rūką,
kritulius, audrą ir stiprų vėją. Grojant media, kairysis vizualizatorius
persikelia prieš orų ikoną, o visa weather/clock/media grupė centruojama kartu.
Paspaudus datos ir orų bloką atsidaro kompaktiškas kalendorius su mėnesio
navigacija ir penkių dienų prognoze. Prognozė rodoma kairėje, kalendorius —
dešinėje; kiekvienai dienai paliekama piktograma, min./max. temperatūra ir
angliška trumpa data, pvz. `Mon, August 16`. Dabartines sąlygas centrinėje
panelėje teikia `wttr.in`, o penkių dienų prognozę — Open-Meteo. Abu šaltiniai
pasiekiami tik esant interneto ryšiui; nesėkmės atveju panelė lieka veikianti,
o prognozės dalyje parodomas prieinamumo pranešimas.
Stiprūs žemų dažnių transientai paleidžia dvigubą max-rice bangą per centrinį
bloką ir trumpą visualizerio taškų burst efektą.
`SUPER+A` control center taip pat rodo iki aštuonių `cliphist` clipboard
įrašų: tekstas pateikiamas trumpu fragmentu, o vaizdai — thumbnail preview.
Paspaudimas nukopijuoja įrašą, o „Clear“ išvalo istoriją. Ji automatiškai
saugoma tiek tekstui, tiek vaizdams per vartotojo `laptopui-clipboard.service`.
Vizualinis pagrindas naudoja iš
`NerdMini_shell` pritaikytą „high rice“ stiklo, glow ir animacijų stilių, o
`matugen` kiekvienam wallpaper'iui sukuria bendrą Quickshell, Hyprland ir Kitty
paletę. Kitty tema turi permatomą foną, kompaktišką tab bar ir automatiškai
persikrauna pakeitus wallpaperį.
Aktyvios namų direktorijos konfigūracijos nekeičiamos, kol neįvykdomas:

```sh
./install.sh install --profile laptop
```

Pradinis saugus patikrinimas:

```sh
./install.sh check --profile laptop
./install.sh install --profile laptop --dry-run
./scripts/check-quickshell --diff
```

Pilna laptop/desktop priėmimo scenarijų matrica yra
[docs/QUICKSHELL_TEST_MATRIX.md](docs/QUICKSHELL_TEST_MATRIX.md).

Panelės ikonoms reikalingi `ttf-jetbrains-mono-nerd` ir `noto-fonts-emoji`,
garso vizualizacijai — `cava`, o dinaminei paletei — `matugen` ir `jq`. Jie
įtraukti į bendrą paketų manifestą ir įdiegiami su `packages` komanda.
Orų kalendoriui naudojami tame pačiame manifeste esantys `curl` ir `jq`;
`laptopui-weather` helperis susiejamas į `~/.local/bin` vykdant `install`.
Sistemos rodmenų paspaudimui reikalingas `btop`; jis taip pat yra bendrame
paketų manifeste.
`btop` konfigūracija nepiešia savo fono, todėl šiame lange išlieka Kitty
skaidrumas ir wallpaper blur.
Clipboard istorijai naudojami jau tame manifeste esantys `wl-clipboard` ir
`cliphist`; screenshot'ams — `grim` ir `slurp`. Atskiro paketo ar serviso
įjungimo nereikia: diegiklis susieja `laptopui-screenshot` ir
`laptopui-clipboard-preview` helperius į `~/.local/bin`.

Diegiklis prieš konfliktų pakeitimą juos perkelia į
`~/.local/state/dev-shell/backups/`. `restore` grąžina pasirinktą backup:

```sh
./install.sh status
./install.sh restore <backup-id>
```

Paketai diegiami tik atskirai paprašius:

```sh
./install.sh packages --profile laptop
./scripts/install-desktop packages
```

Kasdieniai klavišai:

- `SUPER+R` — programų launcher;
- `SUPER+SHIFT+R` — command palette sistemos veiksmams;
- `SUPER+A` — control center;
- `SUPER+N` — notification center / DND;
- `SUPER+TAB` — workspace ir langų overview (paieška, `ESC` uždaro);
- `SUPER+S` — viso ekrano (-ų) screenshot į `Pictures/Screenshots` ir clipboard;
- `SUPER+SHIFT+S` — pažymėto regiono screenshot į `Pictures/Screenshots` ir clipboard;
- `SUPER+A` — clipboard vaizdams rodo thumbnail; screenshot taip pat čia
  atsiranda automatiškai;
- multimedia klavišai — garsas, mikrofonas ir ryškumas su OSD;
- media kortelė — groti/pristabdyti ir pereiti prie kito MPRIS kūrinio;
- performance mygtukas — perjungti performance/balanced profilį, jei
  performance profilį pateikia aktyvus `powerprofilesctl` backend'as;
- CPU arba RAM rodmuo — atidaro Kitty terminalą su interaktyviu `btop`;
- update mygtukas — rodo laukiančių oficialių Arch paketų kiekį (nulio
  nerodo), o paspaudus atidaro spalvotą terminalo updaterį;
- panelės power mygtukas — logout, restart ir shutdown su patvirtinimu.

Notification serverį valdo Quickshell. `mako.service` šiame profilyje yra
išjungtas, kad nepradėtų konkuruojančio daemon'o.
Panelės notification ikona rodo unread kiekį tik kai jis nėra nulis; atidarius
notification centrą jis pažymimas perskaitytu. Command palette gali saugiai
perkrauti Quickshell per `laptopui-reload` helperį.

UI prisitaiko pagal realias galimybes: desktop'e be baterijos ir backlight
atitinkami control center valdikliai nesikrauna. Panelės connectivity mygtukas
atidaro vieną Wi-Fi/Bluetooth popup ir rodo tik realiai aptiktą adapterį.
Bluetooth veiksmai vykdomi per vieną `bluetoothctl` servisą. DND ir „calm
mode“ būsena išsaugoma `~/.local/state/laptopui/settings`; calm mode išjungia
nebūtinus efektus ir gali būti perjungtas control center'yje.

Interaktyvi terminalo aplinka naudoja Zsh, Oh My Zsh ir Starship. Bash lieka
visų repo skriptų interpretatoriumi. Po paketų ir dotfiles įdiegimo Oh My Zsh
paruošiamas atskirai, o login shell pakeičiamas tik aiškiai paprašius:

```sh
./scripts/setup-zsh
./scripts/setup-zsh --set-default
```
