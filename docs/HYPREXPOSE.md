# Super+Tab live workspace overview

Ši instrukcija perkelia tą patį `SUPER+TAB` rezultatą į kitą Arch Linux
desktop: penkis workspace'us vienoje eilėje, gyvus Hyprland langų preview ir
paiešką pagal programos klasę arba lango pavadinimą.

Komponentas yra lokali, sąmoningai užfiksuota `hyprexpose` fork'o versija.
Ji nenaudoja AUR įdiegto binaro, todėl įprastas AUR atnaujinimas nepakeis
elgesio.

## Reikalavimai

- veikianti Hyprland Wayland sesija;
- šio repo desktop profilis ir aktyvus `SUPER+TAB` bind'as;
- `git`, Rust įrankynė bei build bibliotekos.

Pirma atlik bendrą desktop portavimo eigą iš
[DESKTOP_PORT.md](DESKTOP_PORT.md). Papildomai įdiek build priklausomybes:

```sh
sudo pacman -S --needed git rust pkgconf cairo pango glib2
```

Live preview naudoja Hyprland `hyprland-toplevel-export` protokolą. Jei
kompozitorius jo nepateikia, overview vis tiek veiks, bet langai bus rodomi
spalvinėmis kortelėmis, ne gyvais vaizdais.

## Įdiegimas

Tarkime, repo yra `$HOME/dev-shell`. Komandos sąmoningai nenaudoja `sudo`.
Jos gali būti kartojamos atnaujinus šį repo.

```sh
repo=$HOME/dev-shell
src=$HOME/.local/src/hyprexpose

mkdir -p "$HOME/.local/src" "$HOME/.local/bin" "$HOME/.config/systemd/user"
git clone https://github.com/ThiagoAVicente/hyprexpose "$src"
git -C "$src" checkout 9d74169bde43b2642edbdba69e627ec010af5ed5
git -C "$src" apply --unidiff-zero "$repo/patches/hyprexpose-laptopui.patch"
cargo build --release --manifest-path "$src/Cargo.toml"

ln -sfn "$src/target/release/hyprexpose" "$HOME/.local/bin/laptopui-hyprexpose"
ln -sfn "$repo/dotfiles/.config/systemd/user/hyprexpose.service" \
  "$HOME/.config/systemd/user/hyprexpose.service"
ln -sfn "$repo/dotfiles/.local/bin/laptopui-apply-hyprexpose-theme" \
  "$HOME/.local/bin/laptopui-apply-hyprexpose-theme"
```

Jei `git clone` praneša, kad `$src` jau yra, neatlik jo iš naujo. Pereik prie
`git -C "$src" apply --unidiff-zero ...`; jeigu patch jau pritaikytas, tęsk nuo build
komandos.

Repo diegiklis susieja Hyprland konfigūraciją, todėl desktop'e turi būti
įvykdytas įprastas diegimas:

```sh
cd "$repo"
./scripts/install-desktop install
```

Tada sugeneruok aktyvaus wallpaper'io Matugen spalvas ir įjunk daemon'ą:

```sh
"$HOME/.local/bin/laptopui-theme-generate" --current
systemctl --user daemon-reload
systemctl --user enable --now hyprexpose.service
hyprctl reload
```

Jei naujame kompiuteryje wallpaper'is dar nenustatytas, pirmiausia nustatyk jį
įprastu LaptopUI wallpaper helperiu. Kol nėra Matugen paletės,
`dotfiles/.config/hyprexpose/config.toml` gali būti nukopijuotas ranka į
`~/.config/hyprexpose/config.toml` kaip laikinas fallback.

## Naudojimas ir patikra

`SUPER+TAB` siunčia `SIGUSR1` persistentiniam daemon'ui. Overview atsidaro
be nuolatinės CPU/GPU apkrovos, kol jis paslėptas.

- rašyk programos klasę arba lango pavadinimą, pvz. `firefox`;
- `Backspace` trina paiešką;
- pirmas `Escape` išvalo paiešką, antras uždaro overview;
- rodyklės pasirenka kortelę, `Enter` perjungia į pasirinktą workspace;
- kairysis pelės paspaudimas perjungia workspace, dešinysis perkelia aktyvų
  langą.

Patikra:

```sh
systemctl --user status hyprexpose.service
systemctl --user show hyprexpose.service --property=ExecStart
hyprctl binds -j | jq -r '.[] | select(.key == "TAB") | [.modmask, .dispatcher] | @tsv'
```

Paslauga turi rodyti `laptopui-hyprexpose --allow-mouse`. Jei `SUPER+TAB`
nieko nedaro, patikrink, ar procesas tikrai turi tokį vardą:

```sh
ps -C laptopui-hyprex -o pid=,comm=,args=
```

Hyprland bind'as turi siųsti signalą būtent į sutrumpintą proceso vardą:

```lua
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("pkill -SIGUSR1 -x laptopui-hyprex"))
```

## Atnaujinimas ir atstatymas

Esamas sukompiliuotas binary nepasikeis nuo sisteminių ar AUR atnaujinimų.
Kai sąmoningai nori perkompiliuoti fork'ą:

```sh
repo=$HOME/dev-shell
src=$HOME/.local/src/hyprexpose

git -C "$src" checkout -- .
git -C "$src" checkout 9d74169bde43b2642edbdba69e627ec010af5ed5
git -C "$src" apply --unidiff-zero "$repo/patches/hyprexpose-laptopui.patch"
cargo build --release --manifest-path "$src/Cargo.toml"
systemctl --user restart hyprexpose.service
```

Jei po Hyprland atnaujinimo live preview neveiktų, diagnostikai paleisk
`journalctl --user -u hyprexpose.service -b --no-pager`. Paslaugos stabdymas
ar išjungimas tik grąžina ankstesnį Quickshell overview bind'ą tik tada, jei
jį ranka grąžini `bindings.lua`; tai nėra automatinis fallback.
