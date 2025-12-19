# ROADMAP – prioritásos backlog

## 3 napos demo (vertical slice)
1) **Idő- és napzár stabilizálás**
   - Cél: 45 perces nap korrekt idősztringgel, DayEndSummary stub, napváltás állapot mentéssel.
   - Fájlok: `scripts/systems/time/TimeSystem.gd`, `scripts/core/GameKernel.gd`, `scenes/ui/UIRoot.tscn` (napvégi panel), esetleg új `scenes/ui/DayEndSummary.tscn`.
   - Elfogadás: idő fut, pause okok működnek, napváltás esemény jelzi a UI-nak; napvégi gombbal folytatható.

2) **Vendég loop minimál**
   - Cél: 3–4 vendég spawn, ülőhely foglalás, rendelés stub és kifizetés alap pénzmozgással.
   - Fájlok: `scenes/world/TavernWorld.tscn`, hiányzó `scripts/world/Guest.gd`, `scripts/world/GuestSpawner.gd`, `scripts/guests/SeatManager.gd`, `scripts/systems/economy/EconomySystem.gd`.
   - Elfogadás: vendégek érkeznek/ülnek, rendelés esemény pénzt ad, ülés felszabadul távozáskor.

3) **Könyveletlen → könyvelt készlet + könyvelési UI**
   - Cél: bolt panelről vásárlás könyveletlen készletre, könyvelés gomb átvezeti könyvelt készletbe és pénzben elszámolja.
   - Fájlok: `scripts/systems/stock/StockSystem.gd`, `scripts/systems/economy/EconomySystem.gd`, `scripts/ui/panels/Bookkeeping_StockPanel.gd`, `scenes/ui/Shopkeeper*.tscn` panelek.
   - Elfogadás: UI-ból kiválasztott termék vásárlás után megjelenik a könyveletlen listában, könyvelés csökkenti a könyveletlent és növeli a könyveltet, tranzakció naplózva.

4) **Encounter pipeline első lépése**
   - Cél: bíró encounter UI-ból felugrik, választás hatásai (money/reputation) alkalmazódnak, toast megerősítés.
   - Fájlok: `scripts/systems/encounters/EncounterDirector.gd`, `EncounterCatalog.gd`, `EncounterEffectsApplier.gd`, `scripts/ui/EncounterModalController.gd`.
   - Elfogadás: encounter kérhető (debug vagy napi trigger), modal megjelenik, választás után state módosul és toast jelzi.

## 2 hetes stabilizálás
1) **UI/UX tisztítás** – BookMenu fókuszkezelés, popup stack, interaction prompt lock-ok; fájlok: `scripts/ui/*`, `scripts/input/InputRouter.gd`.
2) **Gazdasági riportok** – napi/összesített forgalom és készletnapló megjelenítés; fájlok: `scripts/systems/economy/*`, új riport UI scene.
3) **NPC/Encounter bővítés** – 3–5 új encounter adat, frakció flag-ek; fájlok: `scripts/systems/encounters/*`, `scripts/core/DataRepo.gd`.
4) **Mentés/betöltés stub** – alap state és készlet mentése JSON-be; fájlok: `scripts/state/GameState.gd`, `scripts/systems/stock/StockSystem.gd`.

## Full game fázisok
1) **Kert + állattartás rendszer** – vetés/aratás ciklus, állategészség; új scene-ek a kerthez/ólhoz, adat resource-ok.
2) **Bánya run** – FPS harc/loot, sérülés debuff és gyógyköltség; fájlok: `scenes/world/TownWorld.tscn` kiegészítés, új bánya scene + combat script.
3) **Dolgozó életciklus** – stat növekedés, képzés, stressz/morál, műszaktervező UI; fájlok: `scripts/systems/*` új WorkerSystem, UI tab a BookMenu-ban.
4) **Audit/adó modul** – ÁFA, járulék, hatósági ellenőrzés; fájlok: `scripts/systems/economy/*`, új Encounter/Események.
5) **Birodalom bővítések** – lepárló/panzió/étterem új scene-ekkel és gazdasági lánccal; frakció-specifikus endingek.
