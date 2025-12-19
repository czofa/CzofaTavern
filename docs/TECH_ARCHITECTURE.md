# TECH ARCHITECTURE – Godot 4.5.1 javaslat

## Jelenlegi struktúra alapjai
- **Fő scene:** `scenes/main/Main.tscn` (`MainController`, `GameModeController`) – vált `TavernWorld` és `TownWorld` között, UI külön `CanvasLayer`.
- **Világ scene-ek:** `scenes/world/TavernWorld.tscn` (RTS kamera, spawn/target/seat markerek, vendég prefab), `scenes/world/TownWorld.tscn` (FPS player, interakció sugár, NPC-k).
- **UI:** `scenes/ui/UIRoot.tscn` – HUD (`HUDBarController`), BookMenu (`BookMenuController` + `BookkeepingPanel`), stock/price panelek, encounter modal, interaction prompt, toast feed.
- **Autoload minták (kommentben jelölve):** `EventBus1`, `GameKernel1`, `GameState1`, `TimeSystem1`, `InputRouter1`, `EconomySystem1`, `StockSystem1`/`KitchenSystem1`, `EncounterDirector1`, `EncounterCatalog1`, `EncounterSystem1`, `EncounterManager1`.
- **Bus stratégia:** `EventBus.gd` biztosít klasszikus signalokat + `bus(topic, payload)` generikus csatornát; rendszerek többsége a bus-t figyeli (topic switch). Ez maradjon a fő integrációs minta.

## Javasolt autoload réteg
1) **EventBus1** – központi jelrendszer (már kész).
2) **GameKernel1** – mód/nap állapot, szinkron a `GameModeController`-rel.
3) **GameState1** – gazdasági és reputációs statok, flags.
4) **TimeSystem1** – nap/perc skála, pause okok, nap végi trigger.
5) **InputRouter1** – globális input, lock/unlock, módváltás, könyvmenü toggle.
6) **EncounterDirector1 + EncounterCatalog1 + EncounterSystem1** – encounter adatok, megjelenítés és hatás-alkalmazás pipeline.
7) **EconomySystem1 + StockSystem1** – pénzmozgás, készlet, könyveletlen→könyvelt folyamat; később könyvelési napló/riport.
8) **EncounterManager1** – napi encounter esély időalapú triggerrel.

## Scene/Node szervezés
- **Main**: csak világok és UI instancing; logika a scriptekben maradjon.
- **WorldRoot**: külön `TavernWorld`/`TownWorld` scene-ek; mindegyik saját belső gyökérrel (Actors/Interactables/CameraRig) a könnyebb streaminghez.
- **UIRoot**: moduláris panelek (BookMenu, Bookkeeping_*, Shopkeeper panelek) külön script felelősséggel; modal stack külön `Modals` node alatt.
- **Vendég prefab**: `Guest.tscn` külön animáció/AI scriptre bontva (amint pótoljuk a hiányzó `Guest.gd`-t és `GuestSpawner.gd`-t).

## Event/Signal stratégia
- **Bus-first:** minden rendszer a `bus_emitted` signalról kapcsolódik; payload kulcsokat dokumentálni (pl. `mode.set`, `economy.buy`, `stock.buy`, `encounter.request`, `ui.modal.open`).
- **Közvetlen signalok ott, ahol UI reagál:** pl. `request_show_interaction_prompt`, `encounter_resolved`, `notification_requested` maradhatnak dedikált signalokként.
- **Fail-soft:** hiányzó autoload esetén warning, nem crash (minta: `GameModeController`).

## Adatkezelés (data-driven)
- **Item/recipe táblák:** Resource/JSON alapon (`res://data/items/*.tres` vagy JSON), betöltve `DataRepo1` vagy dedikált ItemCatalog autoload által.
- **Encounter/adó táblák:** `EncounterCatalog` bővíthető JSON/Tres forrással; hatáskulcsok (`effects`) egységes szótárral (money/reputation/frakció/risk/safety stb.).
- **Árképzés paraméterek:** config resource a fix költségek, ÁFA kulcsok, haszonkulcs és kockázati prémium számításhoz.
- **Riport cache:** időszaki számítások memoizálása (napi forgalom, cashflow) külön ReportService-ben, hogy UI gyors legyen.

## Fejlesztési szabályok
- Egy script = egy felelősség (pl. vendég AI külön a spawner/logikától).
- Scene path konzisztencia: csak létező node-ok használata; exportált NodePath-ekkel paraméterezni.
- `.godot/`, `.import/` és generált fájlok kizárása; magyar kommentek/szövegek.
- Rövid, ismételhető tesztterv minden PR-ben (pl. "játék elindul, módváltás, encounter modal megjelenik").
