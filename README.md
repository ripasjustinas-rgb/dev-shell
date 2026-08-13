# laptopui dotfiles

Arch Linux Hyprland ir Quickshell konfigūracija laptopui bei desktopui.

Desktop portavimo pradžia:

```sh
./scripts/install-desktop preflight --output /tmp/laptopui-desktop-preflight.md
```

Pilna prerequisites ir saugaus perkėlimo eiga aprašyta
[docs/PREREQUISITES.md](docs/PREREQUISITES.md) bei
[docs/DESKTOP_PORT.md](docs/DESKTOP_PORT.md).

Waybar konfigūracija išlaikoma tik kaip avarinis fallback. Aktyvus shell yra
Quickshell `laptopui`: panelė, wallpaper, launcher, control center,
notifications, OSD ir power dialogai veikia be Wofi. Panelė taip pat turi
MPRIS media kortelę, `cava` garso spektro vizualizaciją, CPU/RAM rodmenis ir
energijos profilio valdiklį. Centrinis datos ir vietos blokas papildytas didele
Nerd Font orų ikona kairėje, kuri skiria dieną, naktį, debesis, rūką,
kritulius, audrą ir stiprų vėją. Grojant media, kairysis vizualizatorius
persikelia prieš orų ikoną, o visa weather/clock/media grupė centruojama kartu.
Stiprūs žemų dažnių transientai paleidžia dvigubą max-rice bangą per centrinį
bloką ir trumpą visualizerio taškų burst efektą.
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
```

Panelės ikonoms reikalingi `ttf-jetbrains-mono-nerd` ir `noto-fonts-emoji`,
garso vizualizacijai — `cava`, o dinaminei paletei — `matugen` ir `jq`. Jie
įtraukti į bendrą paketų manifestą ir įdiegiami su `packages` komanda.

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
- `SUPER+A` — control center;
- `SUPER+N` — notification center / DND;
- multimedia klavišai — garsas, mikrofonas ir ryškumas su OSD;
- media kortelė — groti/pristabdyti ir pereiti prie kito MPRIS kūrinio;
- performance mygtukas — perjungti performance/balanced profilį, jei
  performance profilį pateikia aktyvus `powerprofilesctl` backend'as;
- update mygtukas — rodo laukiančių oficialių Arch paketų kiekį (nulio
  nerodo), o paspaudus atidaro spalvotą terminalo updaterį;
- panelės power mygtukas — logout, restart ir shutdown su patvirtinimu.

Notification serverį valdo Quickshell. `mako.service` šiame profilyje yra
išjungtas, kad nepradėtų konkuruojančio daemon'o.

Interaktyvi terminalo aplinka naudoja Zsh, Oh My Zsh ir Starship. Bash lieka
visų repo skriptų interpretatoriumi. Po paketų ir dotfiles įdiegimo Oh My Zsh
paruošiamas atskirai, o login shell pakeičiamas tik aiškiai paprašius:

```sh
./scripts/setup-zsh
./scripts/setup-zsh --set-default
```
