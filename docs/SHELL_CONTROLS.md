# Išplečiami shell valdikliai

## Media panelės centre

Paspaudus media kortelės tekstą arba albumo miniatiūrą atsidaro centrinė
kortelė su 132 px albumo viršeliu, didesniu 32 juostų Cava vizualizatoriumi,
previous/play/next ir player pasirinkimu. Shuffle bei repeat rodomi tik tada,
kai player juos palaiko. Mažosios panelės play/next mygtukai lieka atskiri.

Seek juosta turi du režimus:

- kai MPRIS pateikia trukmę ir poziciją — įprasta laiko juosta su laiko žymomis;
- kai player leidžia seek, bet nepateikia trukmės — santykinis −60…+60 s
  slankiklis, kuris po atleidimo grįžta į centrą.

Jei seek nepalaikomas, juosta išjungta ir rodoma priežastis. Firefox metaduomenys
gali skirtis tarp takelių; trukmė nėra spėjama. Pozicija atnaujinama kas 500 ms
tik atidarytoje, grojančio player kortelėje. `Escape`, Close arba paspaudimas
už kortelės uždaro ją. IPC: `qs -c laptopui ipc call laptopui toggleMedia`.

Abu vizualizatoriai naudoja tą patį Cava feed (50–20000 Hz, 32 juostos).
Panelės bass akcentas naudoja pirmų šešių juostų RMS energiją, kad tylios
žemiausios juostos nenuslopintų kick/bass reakcijos. Pauzė, calm mode arba reduced
motion jį sustabdo. Daemono paleidimai serializuojami su `flock`; prieš naują
paleidimą išvalomas ankstesnis spectrum failas, kad jo gale neliktų seno kadro.
Diagnostikai: `qs -c laptopui ipc call media status`.

## Connectivity

Popup plotis yra 410 px, mažesniame ekrane prisitaiko. Wi-Fi ir Bluetooth
sąrašai išplečiami atskirai, adapterių jungikliai lieka matomi. Wi-Fi scan
vyksta tik išplėtus sekciją; uždarius popup sustabdomas ir Bluetooth scan.

Viršutinė kortelė rodo numatytojo maršruto sąsają, connection pavadinimą,
aktyvias NetworkManager VPN/tun/wireguard jungtis, dabartinį download/upload
srautą ir iki 60 paskutinių mėginių grafiką. Visas shell turi vieną
`NetworkState` servisą: `/proc/net/dev` skaitomas kas sekundę tik atidarius
connectivity arba control center, metaduomenys — kas 5 s. Uždarius abi
korteles periodinės tinklo užklausos sustoja.

Details išplečia IP, gateway, DNS, IPv4/IPv6 connectivity būseną, link speed,
Wi-Fi signalą/dažnį/kanalą/saugumą ir sąsajos baitų skaitiklius. Reikšmes
galima nukopijuoti paspaudus. Totals yra nuo sąsajos skaitiklio reset, o ne
nuo prisijungimo ar kalendorinio mėnesio. `nmcli RATE` nėra pateikiamas kaip
derybomis nustatytas link speed: Wi-Fi greitis gaunamas iš `iw`, jei prieinama,
kitu atveju rodoma „Not reported“.

Check connection pagal pareikalavimą atlieka tris riboto laiko patikras:
gateway ICMP, `example.com` DNS ir HTTPS HEAD. ICMP atsakymo nebuvimas nėra
automatiškai laikomas interneto gedimu. Speed test yra atskiras, duomenis
siunčiantis veiksmas ir reikalauja neprivalomo `speedtest-cli`; be jo mygtukas
išjungtas. Testų rezultatai nepriskiriami kitai sąsajai, jei ji pasikeičia
testo metu. Pradėtas testas gali užsibaigti uždarius popup (maks. 90 s).

Suporuotų Bluetooth įrenginių baterija rodoma, kai ją teikia BlueZ.
Prisijungus audio įrenginiui, jo options turi „Use for audio“ arba aktyvaus
output būseną; naudojamas native PipeWire default sink pasirinkimas.

## SUPER+A

- CPU/RAM/baterijos santrauka ir paspaudžiamas tinklo srautas.
- Esamas per-app mixer, bendras volume, mikrofonas ir brightness.
- Focus įjungia DND bei calm mode; išjungus atkuriamos prieš tai buvusios
  abiejų parinkčių reikšmės. Focus būsena ir atkūrimo reikšmės persistuojamos.
- Displays lieka suskleistas: išplėtus rodomi monitoriai, raiška, Hz ir scale.
  Veikiantis hyprsunset papildomai įjungia Normal/Warm/Warmer pasirinkimus.
  Be jo rodoma aiški neprieinamumo būsena. Reduced motion persistuojamas.
  Raiškos, refresh rate ir scale ši kortelė nekeičia.
- Clipboard iš karto rodo paskutinius **3** įrašus; More išplečia iki 50
  naujausių, su riboto aukščio scroll sąrašu. Less grąžina tris įrašus.

Kortelės aukštis priklauso nuo turinio, bet neviršija ekrano; ilgas turinys
slenka. Control center ir connectivity atsidaro fokusuotame monitoriuje.
Popup turi atskirą beveik nepermatomą temos tokeną teksto kontrastui; panelė
išlaiko savo skaidrumą. Bendri mygtukai turi keyboard focus ir accessibility
pavadinimus, o reduced motion išjungia komponentų perėjimų animacijas.

## Patikros

```sh
./scripts/check-quickshell --diff
python3 tests/test_shell_helpers.py
python3 tests/test_media_ui.py
./install.sh check --profile laptop
```

Media/clipboard testas naudoja atskirą QML konfigūraciją, fake player ir
nerodomą langą; reikalauja Quickshell bei Wayland, nekeičia tikro playback.
Helperių testai nenaudoja išorinio tinklo ir tikrina escaped SSID, IPv6-only,
offline/timeout, link speed semantiką bei Cava seno kadro regresiją.

Rankiniu būdu patikrinti abiejų kortelių išplėtimą su trumpu/ilgu turiniu,
seek pelės ir klaviatūros veiksmus, Cava pauzę/restart, display atjungimą,
Bluetooth audio routing ir neprivalomų backend'ų nebuvimą. Kelių monitorių,
tikro Bluetooth routing ir hyprsunset valdymo patikrai reikia atitinkamos
aparatinės įrangos/backend'o.

API nuorodos: [MPRIS](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Mpris/MprisPlayer/),
[PipeWire default sink](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Pipewire/Pipewire/),
[hyprsunset IPC](https://wiki.hypr.land/0.51.0/Hypr-Ecosystem/hyprsunset/).
