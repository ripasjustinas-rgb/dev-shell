# Dinaminės `matugen` paletės pataisymo perdavimas laptopui

## Problema

Quickshell wallpaper mygtukas paleidžia `laptopui-wallpaper-next` absoliučiu
keliu, tačiau šis skriptas anksčiau kvietė `laptopui-theme-generate` tik pagal
komandos vardą. `laptopui-theme-generate` tokiu pačiu būdu kvietė
`laptopui-apply-hypr-theme`.

Grafinė systemd / Hyprland / Quickshell sesija nebūtinai turi
`$HOME/.local/bin` savo `PATH`. Tokiu atveju abu kvietimai nepavykdavo, o
`>/dev/null 2>&1 || true` paslėpdavo klaidą. Pats `matugen` veikė tinkamai.

## Repo pakeitimas

Abu bendri helperiai dabar kviečiami iš stabilios diegimo vietos:

```sh
"$HOME/.local/bin/laptopui-theme-generate"
"$HOME/.local/bin/laptopui-apply-hypr-theme"
```

Klaidos tebėra nelemtingos UI veikimui, bet jų `stderr` išsaugomas čia:

```text
~/.local/state/laptopui/theme-errors.log
```

Pakeisti failai:

- `dotfiles/.local/bin/laptopui-wallpaper-next`
- `dotfiles/.local/bin/laptopui-theme-generate`
- `dotfiles/.local/bin/laptopui-wallpaper-random`
- `dotfiles/.config/hypr/modules/autostart.lua`
- `install.sh`

Pakeitimas bendras laptopo ir desktopo profiliams; profilių konfigūracijų
keisti nereikia.

## Pritaikymas laptope

Laptopo repo kopijoje pasiimti šį pakeitimą ir atnaujinti valdomus symlinkus:

```sh
git pull
./install.sh check --profile laptop
./install.sh install --profile laptop
```

Jeigu `~/.local/bin/laptopui-wallpaper-next` ir kiti helperiai jau yra
symlinkai į tą pačią repo kopiją, pakeitimas pradės galioti iš karto po
`git pull`; pakartotinis `install` vis tiek yra saugus būdas patikrinti ir
suvienodinti valdomus kelius.

Quickshell ar Hyprland perkrauti nebūtina. Paletę galima iškart sugeneruoti
aktyviam wallpaperiui:

```sh
~/.local/bin/laptopui-theme-generate --current
```

Nuo šio pakeitimo kiekvienos naujos Hyprland sesijos pradžioje
`laptopui-wallpaper-random` parenka atsitiktinį paveikslą. Kai kataloge yra
daugiau nei vienas paveikslas, ankstesnės sesijos paveikslas nekartojamas.
Paletė sugeneruojama prieš paleidžiant Quickshell, todėl pirmas jo kadras jau
naudoja naujo wallpaperio spalvas. Rankinis panelės „next wallpaper“ mygtukas
veikia kaip anksčiau.

## Patikrinimas

Perjungti wallpaperį Quickshell panelėje ir patikrinti:

```sh
stat ~/.local/state/laptopui/colors.json
stat ~/.local/state/laptopui/kitty-colors.conf
jq -e 'all(.[]; type == "string" and test("^#[0-9a-fA-F]{6}$"))' \
  ~/.local/state/laptopui/colors.json
```

Abiejų sugeneruotų failų modifikavimo laikas turi atsinaujinti. Quickshell
spalvos turi pasikeisti be restarto, Hyprland spalvos pritaikomos per
`hyprctl`, o veikiančios Kitty instancijos persikrauna gavusios `SIGUSR1`.

Jeigu paletė neatsinaujina, peržiūrėti išsaugotą klaidą:

```sh
tail -n 100 ~/.local/state/laptopui/theme-errors.log
```

Random parinkimą nelaukiant kito prisijungimo galima patikrinti rankiniu būdu:

```sh
before=$(cat ~/.local/state/laptopui/wallpaper)
~/.local/bin/laptopui-wallpaper-random
after=$(cat ~/.local/state/laptopui/wallpaper)
printf 'before=%s\nafter=%s\n' "$before" "$after"
```
