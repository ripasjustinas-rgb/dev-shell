# laptopui prerequisites

Šis projektas skirtas Arch Linux su Hyprland. Diegiklis nekeičia bootloaderio,
initramfs, display managerio ar sisteminių servisų konfigūracijos. Tokie
veiksmai atliekami atskirai ir tik patikrinus konkretų hostą.

## Bazinė sistema

Prieš klonuojant repozitoriją reikia veikiančio interneto, `pacman`, paprasto
vartotojo su `sudo` teise ir `git`:

```sh
sudo pacman -Syu --needed git
git clone <dev-shell-repository-url> ~/dev-shell
cd ~/dev-shell
```

Nerekomenduojama pirmą kartą diegti iš vienintelės veikiančios grafinės sesijos.
Turėk atidarytą TTY (`Ctrl+Alt+F3`) arba kitą patikimą būdą grąžinti seną
konfigūraciją.

## Paketų grupės

`packages/arch-common.txt` aprašo abiem hostams bendrą aplinką:

- Hyprland, Quickshell ir XDG portalą;
- PipeWire/WirePlumber, NetworkManager, BlueZ ir UPower;
- launcher, notification, clipboard, screenshot ir lock/idle įrankius;
- `cava` media vizualizacijai;
- `matugen` ir `jq` dinaminei wallpaper paletei;
- Nerd Font ir emoji fontą.

Profilio manifestas pridedamas atskirai:

```sh
./install.sh packages --profile laptop
./scripts/install-desktop packages
```

Paketų komanda yra vienintelė diegimo dalis, kuri kviečia `sudo pacman`. Ji
nelinkina konfigūracijų ir neįjungia servisų.

## Reikalingi servisai

Po paketų diegimo patikrink ir, jei reikia, įjunk sisteminius servisus:

```sh
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now power-profiles-daemon.service
```

PipeWire ir WirePlumber paprastai aktyvuojami vartotojo socket'ais. Būseną galima
patikrinti taip:

```sh
systemctl --user status pipewire.service wireplumber.service
```

Vienu metu turi veikti tik vienas notification daemon ir vienas CPU profilių
backend'as. Jei naudojamas `power-profiles-daemon`, `tuned.service` neturi būti
aktyvus.

## NVIDIA desktop reikalavimai

Desktop manifestas šiuo metu parinktas standartiniam Arch `linux` branduoliui
ir RTX 2080 Ti (Turing) palaikomiems NVIDIA open kernel moduliams. Arch 2025 m.
pabaigoje Turing ir naujesnes kortas perkėlė nuo seno `nvidia` paketo į
`nvidia-open`:

- `nvidia-open`;
- `nvidia-utils`;
- `egl-wayland`;
- `xorg-xwayland`;
- `pciutils` inventorizacijai.

Jei desktop naudoja kitą kernelį, prieš diegiant reikia sąmoningai pakeisti
driverį į `nvidia-open-dkms` ir pridėti tam kernel'iui tinkamus headers. To
automatiškai nuspręsti negalima. Pascal ir senesnių kortų AUR 580xx eiga šiam
RTX 2080 Ti profiliui netaikoma.

Po driverio diegimo ir restarto privaloma gauti `Y`:

```sh
cat /sys/module/nvidia_drm/parameters/modeset
```

Šiuolaikiniuose Arch `nvidia-utils` paketuose DRM modeset įjungtas pagal
nutylėjimą. Early KMS įtraukimas į initramfs nėra automatinė šio projekto dalis;
jis sprendžiamas tik jei desktop realiai turi ankstyvo driverio užkrovimo
problemą, nes gali paveikti hibernaciją.

Desktop Hyprland profilis nustato tik dabartinėje Hyprland dokumentacijoje
rekomenduojamus `LIBVA_DRIVER_NAME=nvidia` ir
`__GLX_VENDOR_LIBRARY_NAME=nvidia`. Pasenęs `WLR_NO_HARDWARE_CURSORS`
nenaudojamas.

## Ko diegiklis sąmoningai nedaro

- nekeičia `/etc/default/grub`, systemd-boot ar kernel parametrų;
- nekeičia `/etc/mkinitcpio.conf` ir negeneruoja initramfs;
- neįjungia ir neišjungia systemd servisų;
- neparenka monitorių vardų, refresh rate ar pozicijų už vartotoją;
- neįjungia passwordless `sudo`;
- nesaugo raktų, tokenų ar machine-id.

Tolimesnė desktop eiga aprašyta [DESKTOP_PORT.md](DESKTOP_PORT.md).
