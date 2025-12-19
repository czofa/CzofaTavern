# MASTER SPEC – 1 oldal

## Pillérek
- Falusi kocsma menedzsment + döntésalapú encounterek, realisztikus magyar gazdasággal.
- Két mód: RTS (kocsma) és FPS (falu/bánya) váltás; minimalista HUD, BookMenu mint fő vezérlő.

## Napi ciklus
- 45 perces nap (06:00–zárás), DayEndSummary megállítja a játékot, autosave + manuális mentés.
- Időkezelés: TimeSystem perces skála, pause okokkal; EncounterManager napi triggerrel.

## Vendégek és kiszolgálás
- Vendégek spawn → ülés → rendel → kiszolgálás → fogyasztás → fizetés/tip → távozás.
- Elégedettség komponensek: várakozás, minőség/recept, ár-érték, tisztaság/hangulat, balhé/razziák.
- Kimenetek: borravaló, visszatérés, pletyka (reputáció), panasz/escalation.

## Supply chain és gazdaság
- Beszerzés → könyveletlen raktár → könyvelt raktár → konyhai adag → késztermék → kiszolgálás.
- Ár/akció: önköltség + fix + kockázati prémium + haszon; akciók frakciókedvezménnyel.
- EconomySystem/StockSystem: buy/sell, készletmozgás, napló; később ÁFA, bérek, cashflow riportok.

## Encounter/quest rendszer
- EncounterCatalog + Director + Modal UI: ID-alapú adat, bus-on kért megjelenítés.
- Következmény pipeline: pénz/reputáció/frakció/flag módosítók, későbbi események feloldása vagy büntetése.
- Frakciók: Falusiak, Hatóság, Alvilág, Kereskedők, Egyház/Iskola – vendégáramlás, audit esély, event módosítók.

## Progresszió és tartalom
- Early: túlélés, alapmenü, egyszerű encounter.
- Mid: stabil készletlánc, dolgozók, audit/razziák, szezonális kereslet.
- Late: lepárló/panzió/étterem, kert/állattartás + feldolgozás, bánya loot meta, frakció endings.
- Bukás: csőd, hatósági bezárás, alvilági retorzió, reputáció összeomlás.

## UI
- HUD: idő/pénz/állapot; toast értesítések; interakció prompt.
- BookMenu tabok: Leltár, Könyvelés, Riportok, Dolgozók, Frakciók, Questnapló, Beállítások/Mentés.
- Encounter modal kártyák, bolt panelek (összesen 8 kategória: alapanyag, recept, mag, állat, eszköz, kiszolgáló eszköz, építőanyag, eladás).

## MVP fókusz (3 napos demo)
- Stabil napi időzítés + DayEndSummary stub.
- Mini vendég loop 3–4 vendéggel, alap rendelés/kifizetés.
- Bolt + könyveletlen → könyvelt készlet könyvelés; egy recept/termék.
- Egy encounter (bíró) hatás alkalmazással.
- BookMenu + könyvelési stock panel + HUD idő/pénz kijelzéssel.
