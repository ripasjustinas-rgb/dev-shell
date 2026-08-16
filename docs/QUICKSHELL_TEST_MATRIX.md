# LaptopUI Quickshell priėmimo matrica

Vykdyk po `./scripts/check-quickshell --diff` ir aktyvioje Hyprland sesijoje.
Kiekviename scenarijuje patikrink, kad `qs -c laptopui list` rodo vieną
`laptopui` instanciją.

| Scenarijus | Veiksmas | Tikėtinas rezultatas |
|---|---|---|
| Laptopas | `SUPER+A` | Volume, microphone, brightness ir battery valdikliai matomi; `Escape` uždaro kortelę. |
| Desktopas | `SUPER+A` | Nėra battery/backlight eilučių ir jų backend’ai nepollinami. |
| Offline | Atidaryk calendar popup | Weather ir forecast rodo unavailable/offline būseną, panelės layout nesikeičia. |
| Be performance profilio | Atidaryk profile meniu | `performance` pasirinkimas nerodomas; keitimas veikia tik esantiems profiliams. |
| Wi-Fi/Bluetooth | Spausk panelės connectivity ikoną | Atsidaro vienas popup; rodomos tik realiai aptiktų adapterių sekcijos. Jei yra abu, panelėje matomos abi būsenos ikonos. |
| Bluetooth audio | Pair/connect ausines | Veiksmas prašo patvirtinimo; prisijungus audio įrenginių sąrašas atsinaujina. |
| Du monitoriai | Atidaryk overview su `SUPER+TAB` | Panelė yra abiejuose ekranuose; overview rodo workspace monitorių ir leidžia pereiti rodyklėmis bei `Enter`. |
| Notifications | Išsiųsk test notification | Panelėje atsiranda unread skaičius; `SUPER+N` jį išvalo, veiksmai veikia, DND išlieka po reload. |
| Launcher | `SUPER+R` | Recent ir paieškos rezultatus galima pasirinkti `Up/Down/Tab/Enter`; recent išlieka po reload. |
| Command palette | `SUPER+SHIFT+R` | Veikia keyboard navigacija, screenshot, connectivity, calm mode ir reload veiksmai. |
| Calm mode | Įjunk per control center ar palette | `cava` procesas sustoja, spectrum/glow efektai išnyksta, būsena išlieka po reload. |
