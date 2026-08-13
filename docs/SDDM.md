# LaptopUI SDDM tema

Tema atkartoja Quickshell stiklo, glow, Nerd Font ir aktyvaus wallpaperio
`matugen` paletę. SDDM lieka numatytame X11 greeter režime; Hyprland sesijos,
PAM, autologin ir display serverio nustatymai nekeičiami.

Vartotojo laukas iš anksto užpildomas `justas`, tačiau autologin nėra
įjungiamas ir slaptažodžio autentifikacija lieka nepakitusi.

Temai reikalingas `qt5-quickcontrols2`, nes šiame setup SDDM greeteris naudoja
Qt5. Paketas įtrauktas į `packages/arch-common.txt`; esamoje sistemoje jį galima
įdiegti atskirai:

```sh
sudo pacman -S --needed qt5-quickcontrols2
```

## Saugi eiga

Pirmiausia pasirinkti SDDM skirtą wallpaperį. Šis pasirinkimas yra atskiras nuo
Hyprland random wallpaperio ir nekeičia Quickshell, Kitty ar Hyprland spalvų:

```sh
./scripts/sddm-theme set-wallpaper ~/Wallpapers/login.jpg
```

Paruošti atskirą temos kopiją su pasirinktu wallpaperiu ir jo palete:

```sh
./scripts/sddm-theme prepare
./scripts/sddm-theme validate
```

Atidaryti oficialų SDDM testavimo režimą. Jame login, restart ir shutdown
veiksmai realios sistemos nekeičia:

```sh
./scripts/sddm-theme preview
```

Tik vizualiai patikrinus visus ekranus temą nukopijuoti ir pasirinkti:

```sh
./scripts/sddm-theme install
./scripts/sddm-theme status
```

`install` sąmoningai neperkrauna `sddm.service`, nes tai nutrauktų aktyvią
grafinę sesiją. Pirmą kartą atsijungiant arba perkraunant kompiuterį laikyk
pasiekiamą TTY (`Ctrl+Alt+F3`).

## Avarinis grąžinimas

Iš TTY prisijunk savo vartotoju ir vykdyk:

```sh
cd ~/dev-shell
./scripts/sddm-theme status
./scripts/sddm-theme restore
sudo reboot
```

`restore` be argumento paima naujausią backup. Konkretų backup galima nurodyti:

```sh
./scripts/sddm-theme restore 20260813T190000Z
```

Jei repo nepasiekiamas, custom temos pasirinkimą galima išjungti tiesiogiai:

```sh
sudo mv /etc/sddm.conf.d/10-laptopui-theme.conf \
  /etc/sddm.conf.d/10-laptopui-theme.conf.disabled
sudo reboot
```

SDDM tada grįžta prie integruotos numatytos temos.

## Wallpaperio ir spalvų atnaujinimas

SDDM vartotojas negali pasiekti `~`, nes vartotojo namų katalogas yra
užrakintas. Dėl to `prepare` saugiai nukopijuoja aktyvų wallpaperį ir spalvas į
atskirą staging katalogą, o `install` — į `/usr/share/sddm/themes/laptopui`.
SDDM wallpaperis lieka fiksuotas ir nepriklauso nuo kiekvienos Hyprland sesijos
random pasirinkimo.

Kai login fonas nusibos, rankinio atnaujinimo eiga yra:

```sh
./scripts/sddm-theme set-wallpaper ~/Wallpapers/kitas-login.png
./scripts/sddm-theme preview
./scripts/sddm-theme install
```

`set-wallpaper` sugeneruoja atskirą `matugen` paletę tik SDDM temai. `install`
vėl sukuria backup ir neperkrauna veikiančio SDDM.
