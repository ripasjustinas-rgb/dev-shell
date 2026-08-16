# LaptopUI Quickshell vystymo planas

## Tikslas

Šis dokumentas aprašo darbus po dabartinio `laptopui` funkcijų rinkinio:
stabilizaciją, pagal realias įrenginio galimybes prisitaikantį UI, Bluetooth
valdymą, langų ir workspace'ų overview, notification centro bei launcher'io
patobulinimus ir papildomą „rice“ sluoksnį.

Planas taikomas vienam bendram Quickshell kodui laptopo ir desktopo
profiliuose. Naujos funkcijos neturi būti šakojamos pagal hostname. Jos turi
remtis Quickshell API, realiai aptiktais įrenginiais ir profilyje esančiais
deklaratyviais nustatymais.

## Dabartinė bazė

Prieš pradedant šį planą jau veikia:

- kelių ekranų panelė, workspace'ai, system tray ir dinaminis wallpaper'is;
- programų launcher'is, control center, notification center, OSD ir power UI;
- Wi-Fi, baterija, power profiles, audio bei audio įrenginių pasirinkimas;
- MPRIS, `cava`, CPU/RAM, orai, kalendorius ir atnaujinimų skaičius;
- `matugen` spalvos Quickshell, Hyprland, Kitty, SDDM ir `hyprlock`;
- clipboard istorija, pilno ekrano ir regiono screenshot'ai;
- laptopo ir desktopo profiliai bei saugus symlink diegiklis.

Kalendoriaus, clipboard istorijos ir audio įrenginių pasirinkimo pakeitimai
šio plano rašymo metu yra darbo medyje. Juos reikia užbaigti ir patikrinti
prieš pradedant naujas dideles funkcijas.

## Bendri reikalavimai

- Kiekvienas komponentas turi naudoti `Theme` tokenus; naujos atsitiktinės
  spalvos, radius ar animacijų trukmės neturi būti hard-coded komponentuose.
- Funkcija, kurios backend'as ar aparatinė galimybė nepasiekiama, pasislepia
  arba parodo aiškią disabled būseną. Ji neturi nuolat vykdyti klaidą
  grąžinančių procesų.
- Išoriniai procesai naudojami tik kai nėra tinkamo Quickshell API. Ilgai
  veikiantys procesai turi turėti vieną aiškų savininką ir būti sustabdomi arba
  pristabdomi, kai jų rezultatas nereikalingas.
- Visi overlay turi vienodai elgtis paspaudus `Escape`, paspaudus už kortelės
  ribų, pakeitus ekraną ar persikrovus Quickshell konfigūracijai.
- Funkcijos turi veikti ir su vienu, ir su keliais monitoriais, nepalikdamos
  kelių vienu metu aktyvių notification serverių ar kitų singleton servisų.
- „Rice“ efektai negali mažinti teksto kontrasto, kliudyti input'ui ar laikyti
  CPU/GPU apkrautų tada, kai UI nematomas.

## 0 etapas: dabartinio darbo užbaigimas

### Darbai

1. Užbaigti ir atskirai patikrinti:
   - kalendorių ir penkių dienų prognozę;
   - clipboard tekstų bei paveikslų istoriją;
   - audio output/input įrenginių pasirinkimą;
   - screenshot integraciją su clipboard istorija.
2. Patikrinti `git diff --check`, shell skriptų sintaksę ir QML paleidimą
   realioje Hyprland sesijoje.
3. Atnaujinti `README.md` ir `docs/handover.md`, jeigu galutinis elgesys
   skiriasi nuo dabartinio aprašymo.
4. Užfiksuoti vieną švarią bazinę versiją prieš didesnius architektūrinius
   pakeitimus.

### Priėmimo kriterijai

- `./install.sh check --profile laptop` praeina.
- Desktop preflight neturi naujų su Quickshell pakeitimais susijusių klaidų.
- Clipboard paveikslų preview nelieka neteisingas pasirinkus kitą įrašą arba
  persikrovus shell'ui.
- Audio įrenginių sąraše nerodomi neprijungti HDMI/DisplayPort output'ai.
- Offline orų būsena nepažeidžia panelės ar calendar popup išdėstymo.

## 1 etapas: stabilizacija ir capability-driven UI

Tai yra aukščiausio prioriteto etapas. Jis turi būti baigtas prieš Bluetooth,
overview ar papildomus grafinius efektus.

### 1.1 Galimybių modelis

Sukurti bendrą servisą, pavyzdžiui `services/Capabilities.qml`, kuris pateikia:

- `hasBacklight`;
- `hasBattery`;
- `hasWifi`;
- `hasBluetooth`;
- `hasAudioSink` ir `hasAudioSource`;
- `powerProfilesAvailable` ir aktyvų profilį;
- `performanceProfileAvailable`;
- monitorių skaičių ir ar yra išorinis monitorius;
- priklausomybių, tokių kaip `brightnessctl`, `powerprofilesctl`, `cliphist`,
  `cava` ir `btop`, prieinamumą.

Komponentai turi vartoti šį modelį, o ne kiekvienas atskirai poll'inti tą pačią
būseną.

### 1.2 Control center adaptacija

- Slėpti brightness eilutę hoste be backlight.
- Slėpti bateriją desktop'e; power profile palikti tik kai backend'as veikia.
- Power profile meniu rodyti tik backend'o grąžinamus profilius.
- Nerodyti `performance`, jeigu jo backend'as nepateikia.
- Rodyti aiškią, bet neįkyrią būseną, kai nėra mikrofono, Wi-Fi ar audio
  output'o.
- Išlaikyti stabilų kortelės aukštį ir animaciją, kai eilutės atsiranda arba
  pasislepia.

### 1.3 Kokybės patikros

Pridėti repo patikros skriptą, pavyzdžiui `scripts/check-quickshell`, kuris:

- patikrina QML failų formatavimo arba sintaksės bazines klaidas;
- paleidžia `bash -n` repo shell helperiams;
- paleidžia `git diff --check` tik CI ar rankinio verify režime;
- pateikia aiškų rezultatą, kai grafinio smoke test negalima atlikti be
  Hyprland/Wayland sesijos.

Papildyti rankinę testavimo matricą:

| Scenarijus | Tikėtinas rezultatas |
|---|---|
| Laptopas su baterija ir backlight | Matomi abu valdikliai ir reali būsena |
| Desktopas be baterijos ir backlight | Abu valdikliai paslėpti |
| Nėra interneto | Weather ir forecast rodo offline būseną |
| Nėra `performance` profilio | UI jo nesiūlo |
| Atjungtas HDMI audio | Įrenginys pašalinamas iš pasirinkimo |
| Du monitoriai | Panelė rodoma abiejuose, overlay fokusas prognozuojamas |
| Trūksta neprivalomo helperio | Likęs shell veikia, rodoma aiški būsena |

### Priėmimo kriterijai

- Nė vienas paslėptas valdiklis periodiškai nepaleidžia neegzistuojančio
  backend'o komandos.
- Laptopo ir desktopo control center sudėtis atitinka realias galimybes.
- Power profilio pasirinkimas keičia realią sistemos politiką, ne tik UI
  tekstą.
- QML ir helperių patikra turi vieną dokumentuotą paleidimo komandą.

## 2 etapas: bendras Wi-Fi ir Bluetooth valdymas

### Vienas connectivity popup

Wi-Fi ir Bluetooth valdymas turi būti pateikiamas viename bendrame
`Connectivity` popup. Jį atidaro dabartinis Wi-Fi mygtukas dešinėje panelės
pusėje; atskiro Bluetooth mygtuko ar antro konkuruojančio popup panelėje
neturi būti.

Popup viršuje turi būti pagal realiai aptiktus adapterius rodomos sekcijos arba
perjungiamieji skirtukai:

- `Wi-Fi` — dabartinis tinklas, Wi-Fi būsena ir pasiekiamų tinklų sąrašas;
- `Bluetooth` — adapterio būsena, prijungti, suporuoti ir aptikti įrenginiai.

Sekcija rodoma tik tada, kai kompiuteryje aptiktas atitinkamas adapteris. Jei
yra tik Wi-Fi, rodomas tik Wi-Fi valdymas; jei yra tik Bluetooth, rodomas tik
Bluetooth valdymas. Kai yra abu adapteriai, tame pačiame popup rodomos abi
sekcijos.

Abiejų ryšio tipų pagrindiniai įjungimo/išjungimo veiksmai turi būti pasiekiami
neuždarant popup. Sąrašų scan būsena, klaidos ir vykstantis connect/pair
veiksmas turi būti rodomi savo sekcijoje, kad vieno backend'o problema
neužblokuotų kito.

Panelės connectivity mygtukas turi likti dabartinio Wi-Fi mygtuko vietoje ir
rodyti tik kompiuteryje realiai esančio ryšio tipo ikoną:

- jei yra Wi-Fi, bet nėra Bluetooth, visose būsenose rodoma tik Wi-Fi ikona;
- jei yra Bluetooth, bet nėra Wi-Fi, visose būsenose rodoma tik Bluetooth
  ikona;
- trūkstamo adapterio ikona niekada nerodoma net kaip išjungta būsena;
- jei yra abu adapteriai, vis tiek rodoma viena ikona: prijungto Wi-Fi signalo
  ikona turi prioritetą, kitu atveju rodoma prijungto Bluetooth būsena;
- jei abu esantys adapteriai išjungti arba neprijungti, rodoma neutrali
  connectivity/offline būsena, neapsimetant, kad hoste yra trūkstamas
  adapteris;
- tooltip išvardija tik aptiktus adapterius: Wi-Fi tinklą ir/ar prijungtų
  Bluetooth įrenginių skaičių.

### Funkcinė apimtis

- Bendrame popup išlaikyti esamą Wi-Fi scan, connect, disconnect ir adapterio
  įjungimo/išjungimo funkcionalumą.
- Tame pačiame popup rodyti Bluetooth įjungimo būseną.
- Leisti įjungti ir išjungti Bluetooth adapterį.
- Rodyti suporuotus, prijungtus ir aptiktus įrenginius.
- Leisti pradėti/nutraukti scan, pair, trust, connect, disconnect ir forget.
- Rodyti įrenginio tipą, signalą ir baterijos procentą, kai informacija
  prieinama.
- Pairing PIN ar patvirtinimą pateikti aiškiame modal dialoge; nebandyti slapta
  automatizuoti autorizacijos.
- Audio įrenginiui prisijungus atnaujinti PipeWire output/input pasirinkimą.

### Architektūra

Esamą `components/WifiMenu.qml` refaktorinti į
`components/ConnectivityMenu.qml`, išsaugant veikiančią Wi-Fi logiką ir prie
jos pridedant Bluetooth sekciją. `SystemGroup.qml` dabartinis `wifiButton`
gali būti pervadintas į `connectivityButton`, tačiau jo vieta ir pagrindinis
naudojimo būdas nesikeičia.

Pirmiausia naudoti tuo metu įdiegto Quickshell release Bluetooth API, jei jis
pakankamas. Jei ne, sukurti vieną izoliuotą `BluetoothState` servisą virš
`bluetoothctl` arba D-Bus, kad UI komponentai neparsintų CLI output'o atskirai.

### Priėmimo kriterijai

- Dabartinis panelės Wi-Fi mygtukas atidaro vieną bendrą Wi-Fi ir Bluetooth
  popup.
- Panelėje nėra atskiro Bluetooth mygtuko ar atskiro konkuruojančio popup.
- Hoste tik su Wi-Fi panelėje ir popup nerodoma jokia Bluetooth ikona ar
  sekcija.
- Hoste tik su Bluetooth panelėje ir popup nerodoma jokia Wi-Fi ikona ar
  sekcija.
- Wi-Fi galima įjungti, išjungti, prijungti ir atjungti iš bendro popup.
- Galima suporuoti ir prijungti naują ausinių įrenginį nepaliekant Quickshell.
- Jau suporuotas įrenginys prisijungia ir atsijungia vienu paspaudimu.
- Išjungus adapterį UI iškart pereina į teisingą būseną.
- Hoste be Bluetooth adapterio paslepiama tik Bluetooth sekcija; bendras
  connectivity popup ir Wi-Fi valdymas lieka pasiekiami.
- Hoste be Wi-Fi adapterio paslepiama tik Wi-Fi sekcija; tas pats panelės
  mygtukas rodo Bluetooth ikoną ir atidaro Bluetooth valdymą.
- Nesėkmingas pair/connect turi matomą klaidą ir neužšaldo UI.

## 3 etapas: workspace ir langų overview

### UX

- Pridėti atskirą bind'ą, rekomenduojama `SUPER+TAB`.
- Atidaryti viso ekrano overlay su workspace'ų juosta ir jų langais.
- Aktyvų workspace ir aktyvų langą pažymėti `Theme.accent`.
- Paspaudus langą pereiti į jo workspace ir suteikti jam fokusą.
- Leisti vilkti langą tarp workspace'ų tik po stabilaus pasirinkimo/fokuso
  MVP; drag-and-drop nėra pirmo leidimo reikalavimas.
- Tuščius workspace'us rodyti kompaktiškai, bet leisti į juos pereiti.
- Teksto paieška filtruoja langus pagal programą ir title.

### Įgyvendinimo seka

1. Sukurti bendrą Hyprland langų/workspace'ų modelį be nuolatinio
   `hyprctl` polling.
2. Įgyvendinti tekstinį/grid MVP be screenshot thumbnail.
3. Pridėti thumbnail tik jeigu pasirinktas metodas stabilus Wayland'e ir
   nekelia privatumo ar našumo problemų.
4. Pridėti animuotą perėjimą bei keyboard navigation.

### Priėmimo kriterijai

- Overview atsidaro ir užsidaro klaviatūra be pelės.
- Fokusas teisingai persijungia tarp workspace'ų ir langų.
- Uždarytas ar perkeltas langas iš sąrašo dingsta be shell reload.
- Keliuose monitoriuose aišku, kuriam monitoriui priklauso workspace/langas.
- Atidarytas overview neturi pastebimai kelti idle CPU naudojimo.

## 4 etapas: notification centro užbaigimas

### Darbai

- Pridėti notification laiko žymą.
- Grupuoti pranešimus pagal programą arba conversation key, kai jis yra.
- Pridėti `Clear all` ir atskiro pranešimo uždarymo veiksmą.
- Atvaizduoti notification veiksmų mygtukus ir perduoti jų aktyvavimą.
- Persistuoti DND būseną į `~/.local/state/laptopui/`.
- DND būsena turi atsikurti po Quickshell reload ir login.
- Apsvarstyti maksimalų istorijos dydį ir seniausių įrašų pašalinimą.
- Rodyti unread skaičių arba indikatorių panelėje, bet nulio nerodyti.

### Priėmimo kriterijai

- Vienu metu veikia tik Quickshell notification serveris.
- DND blokuoja toast'us, bet nepraranda istorijos.
- Veiksmų mygtukai veikia, o paspaudimas ant kortelės jų neužgožia.
- `Clear all` pašalina tik notification istoriją ir nekeičia DND.
- Per didelis notification kiekis neaugina UI be ribos.

## 5 etapas: launcher kaip command palette

### Launcher MVP patobulinimai

- Įdėti fuzzy paiešką vietoje paprasto `includes()` filtro.
- Pridėti `Up`, `Down`, `Enter`, `Tab` ir `Escape` navigaciją.
- Enter paleidžia aktyviai pažymėtą rezultatą, o ne tik vienintelį match.
- Recent aplikacijas persistuoti ir rikiuoti pagal realų naudojimą.
- Išlaikyti pinned aplikacijas bei jų valdymą dešiniu pelės mygtuku.

### Command palette plėtinys

Tame pačiame overlay arba aiškiai atskirtame rezultate pridėti shell veiksmus:

- lock, logout, restart ir shutdown;
- full/region screenshot;
- DND perjungimas;
- power profile pasirinkimas;
- audio output/input pasirinkimas;
- Bluetooth connect/disconnect;
- Wi-Fi valdymas;
- wallpaper next/random ir calm mode;
- Quickshell reload bei nustatymų/diagnostikos veiksmai.

Veiksmai turi turėti aiškius prefiksus arba kategorijas, kad aplikacija tokiu
pačiu pavadinimu neužgožtų sistemos veiksmo. Destruktyvūs power veiksmai turi
naudoti jau esantį patvirtinimo dialogą.

### Priėmimo kriterijai

- Visą launcher'į galima naudoti tik klaviatūra.
- Paieškos rezultatai stabiliai rikiuojami ir nešokinėja renkant tekstą.
- Recent sąrašas išlieka po shell reload.
- Sistemos veiksmai nedubliuoja privilegijuotos logikos; jie kviečia esamus
  servisus arba IPC veiksmus.

## 6 etapas: „rice“ ir vizualinis užbaigimas

Šis etapas atliekamas tik tada, kai ankstesni komponentai stabilūs. Kiekvienas
efektas turi turėti išjungimo arba sumažinimo kelią.

### 6.1 Aktyvaus lango akcentas

- Iš aktyvaus `matugen` temos akcento kurti ploną Hyprland border/shadow.
- Fullscreen langui glow išjungti arba sumažinti.
- Urgent langui naudoti atskirą `Theme.danger` būseną.
- Spalvos pakeitimas keičiant wallpaper'į turi būti sklandus ir nereikalauti
  sesijos perkrovimo.

### 6.2 Workspace capsules

- Išlaikyti penkis fiksuotus workspace'us.
- Kiekvienoje kapsulėje rodyti subtilią occupancy būseną arba langų skaičių.
- Active, occupied, urgent ir fullscreen būsenos turi skirtis ne vien spalva.
- Wallpaper mygtukas vizualiai lieka šeštas tokio pat dydžio elementas, bet
  niekada neatrodo kaip aktyvus workspace `6`.

### 6.3 Wallpaper sluoksnis

- Pridėti labai subtilų noise/grain sluoksnį.
- Parallax efektą taikyti tik overlay/dashboard, ne nuolat visam desktopui.
- Efektas turi sustoti, kai overlay uždarytas.
- Gerbti `reduced motion` arba repo nustatymą, jeigu toks pridedamas.

### 6.4 Calm mode

Pridėti vieną persistuojamą `calmMode` nustatymą, kuris:

- sustabdo `cava` ir audio spectrum helperį;
- išjungia bass wave, peak burst ir shimmer animacijas;
- sumažina glow ir ilgesnes spring animacijas;
- nepakeičia funkcionalumo, temos spalvų ar panelės išdėstymo.

Calm mode turi būti pasiekiamas per command palette ir, jei yra vietos,
control center.

### Priėmimo kriterijai

- Visi efektai naudoja temos tokenus ir atrodo nuosekliai su SDDM/Kitty.
- Calm mode būsena išlieka po login ir shell reload.
- Calm mode išjungus vizualizerį nelieka veikiančio `cava` proceso.
- Nė vienas efektas neužstoja teksto, tooltip ar paspaudimo zonų.

## Siūloma failų struktūra

Tiksli struktūra gali keistis pagal Quickshell API, tačiau atsakomybės turėtų
likti atskirtos:

```text
dotfiles/.config/quickshell/laptopui/
├── components/
│   ├── ConnectivityMenu.qml
│   ├── CommandPalette.qml
│   ├── Overview.qml
│   ├── OverviewWindow.qml
│   └── WorkspaceCapsule.qml
├── services/
│   ├── BluetoothState.qml
│   ├── Capabilities.qml
│   ├── NotificationState.qml
│   ├── SettingsState.qml
│   └── WindowState.qml
└── theme/
    ├── Theme.qml
    └── ThemeLoader.qml
```

`SettingsState` turėtų būti vienintelis persistuojamų UI pasirinkimų, tokių
kaip DND, calm mode ir galimi animation/reduced-motion nustatymai, savininkas.

## Darbų eiliškumas

Rekomenduojama darbų seka:

1. Užbaigti dabartinį necommittintą calendar/clipboard/audio darbą.
2. Sukurti capabilities servisą ir adaptuoti control center.
3. Pridėti repo QML/helper smoke patikrą ir atlikti laptop/desktop matricą.
4. Esamą Wi-Fi popup išplėsti į bendrą Wi-Fi ir Bluetooth connectivity popup.
5. Įgyvendinti overview tekstinį/grid MVP, tada spręsti dėl thumbnail.
6. Užbaigti notification centro istoriją, veiksmus ir DND persistenciją.
7. Patobulinti launcher keyboard UX ir paversti jį command palette.
8. Pridėti calm mode.
9. Po vieną pridėti aktyvaus lango, workspace capsule ir wallpaper efektus,
   po kiekvieno matuojant idle resursų naudojimą.

## Galutinis priėmimas

Planas laikomas įgyvendintu, kai:

- ta pati Quickshell konfigūracija prisitaiko prie laptopo ir desktopo be
  hostname sąlygų;
- kasdienėms Wi-Fi, Bluetooth, audio, notification, launcher, overview ir
  power operacijoms nereikia atskiro fallback UI;
- visi pagrindiniai overlay pilnai valdomi klaviatūra;
- offline, trūkstamos priklausomybės ir nepalaikoma aparatinė funkcija
  nesugadina likusio shell;
- calm mode realiai sustabdo nereikalingus vizualinius procesus;
- `install.sh check`, Quickshell/helper patikra ir laptop/desktop rankinė
  matrica praeina;
- README ir perdavimo dokumentai atitinka galutinę veikiančią būseną.
