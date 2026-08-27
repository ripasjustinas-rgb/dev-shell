# Hyprlock ir hypridle

`hyprlock` atkartoja LaptopUI SDDM temos wallpaperį, spalvas, laikrodį ir stiklo
kortelę. `laptopui-lock` prieš kiekvieną paleidimą paima fiksuotą SDDM
wallpaperį bei jo `matugen` paletę, todėl rankiniu būdu pakeitus login foną
lock ekranas atsinaujina kartu.

Rankinis užrakinimas:

```text
SUPER + L
```

arba terminale:

```sh
laptopui-lock
```

## Idle eiga

- naudojant bateriją po 5 min. neveiklumo užrakinama sesija, po 10 min.
  išjungiami ekranai, o po 20 min. kompiuteris suspenduojamas;
- prijungus įkroviklį po 10 min. užrakinama sesija, tačiau ekranai neišjungiami
  ir kompiuteris dėl neveiklumo nesuspenduojamas;
- kiekvienas idle veiksmas patikrina tuo metu naudojamą maitinimo šaltinį, todėl
  prijungus ar atjungus įkroviklį taikoma atitinkama eiga;
- aktyvumas po DPMS išjungimo ekranus vėl įjungia;
- prieš kiekvieną suspend `hypridle` pirmiausia paleidžia `hyprlock` ir laiko
  sleep inhibitorių, kol Wayland patvirtina užrakintą sesiją;
- po resume ekranai įjungiami.

## Laptopo dangtis

Kol veikia Hyprland sesija, `laptopui-lid-inhibit.service` perduoda lid valdymą
LaptopUI:

- uždarius dangtį iškart išjungiamas tik `eDP-1` ekranas;
- sukuriamas atskiras 5 min. suspend timeris;
- atidarius dangtį timeris atšaukiamas ir `eDP-1` įjungiamas;
- pasibaigus sesijai inhibitorius dingsta ir lid valdymas saugiai grįžta
  `systemd-logind`.

Aktyvius procesus ir inhibitorius galima patikrinti:

```sh
pgrep -af 'hypridle|systemd-inhibit.*handle-lid-switch'
systemd-inhibit --list
systemctl --user status laptopui-hypridle.service laptopui-lid-inhibit.service
```

Likusį lid timerį galima atšaukti atidarymo veiksmu:

```sh
laptopui-lid open
```
