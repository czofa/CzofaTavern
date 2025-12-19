# Project Map – Czofa: Egy kocsma története

## Fő belépési pontok
- **Main scene:** `scenes/main/Main.tscn` – `MainController` indítja a módot, `GameModeController` vált RTS/FPS nézet között, a világ root alatt `TavernWorld` és `TownWorld` instance-ekkel.
- **UI réteg:** `scenes/ui/UIRoot.tscn` – HUD, BookMenu, könyvelési panelek, encounter modal és interaction prompt. Külső script hivatkozás: `scripts/ui/UIRootController.gd` (hiányzik a repo-ban).
- **Világok:**
  - `scenes/world/TavernWorld.tscn` – alap navigációs grid, spawn/target pontok, szék marker-ek, `GuestSpawner` script hivatkozás (hiányzik), RTS kamera.
  - `scenes/world/TownWorld.tscn` – FPS karaktervezérlés (`FPSPlayerController.gd`), interakció sugár (`InteractRaycaster.gd`), falu- és bolt-NPC-k, átjáró a kocsmához.

## Szereplők és interakciók
- **Vendég prefab:** `scenes/characters/Guest.tscn` – `Guest.gd` script hivatkozás (hiányzik), alap karakterbody kapszula kolliderrel és NavigationAgenttel.
- **Town NPC-k:** `scripts/town/VillageManagerNPC.gd`, `scripts/town/ShopkeeperNPC.gd` vezérlik a faluvezető és bolt NPC logikáját.

## Rendszer-scriptek (autoloadnak jelölve a kommentben)
- **core:** `EventBus.gd` (bus + signal hub), `GameKernel.gd` (globális mód/nap állapot), `DataRepo.gd` (stub encounter adat).
- **state:** `GameState.gd` (pénz/reputáció/flag-ek, bus-on keresztüli state műveletek).
- **input:** `InputRouter.gd` (globális input + lock, módváltás, könyv menü, encounter trigger debug).
- **systems/time:** `TimeSystem.gd` (játékidő, pause okok, bus hookok).
- **systems/economy:** `EconomySystem.gd` (buy/sell, pénz és stock bus hívások).
- **systems/stock & kitchen:** `StockSystem.gd`, `KitchenSystem.gd` (készlet és könyveletlen készlet kezelése, naplózás, bus integráció).
- **systems/encounters:** `EncounterSystem.gd` (bus → UI modal), `EncounterDirector.gd` (encounter open + apply pipeline), `EncounterCatalog.gd` (adatregiszter, director feltöltés), `EncounterOutcomeSystem.gd`, `EncounterEffectsApplier.gd` (jövőbeli hatás pipeline stubok), `EncounterManager.gd` (napi random encounter trigger, TimeSystem függés).
- **events/tools:** `tools/DebugHotkeys.gd` (debug toasthoz), `events/EncounterManager.gd` mint napi trigger.
- **guests:** `SeatManager.gd`, `GuestServingSystem.gd` (szék- és kiszolgálás-kezelő stubok).

## UI scriptek
- `scripts/ui/BookMenuController.gd` – főkönyv menü nyit/zár, könyvelési panel hivatkozás.
- `scripts/ui/panels/BookkeepingPanel.gd`, `Bookkeeping_StockPanel.gd`, `Bookkeeping_PricePanel.gd` – könyvelés alpanelek.
- `scripts/ui/shop/*.gd` – bolt kategória/seed/recipe/állat stb. panelek.
- `scripts/ui/EncounterModalController.gd`, `EncounterCardUI.gd.gd`, `InteractionPromptController.gd`, `HUDBarController.gd`, `HudActionsController.gd`, `GuestReportGenerator.gd` – encounter modal és HUD/tooltip komponensek.

## Hiányzó / figyelendő elemek a jelenlegi állapotban
- `project.godot` nincs a repo-ban, ezért az autoload lista a scriptek kommentjeire támaszkodik.
- `scripts/ui/UIRootController.gd`, `scripts/world/Guest.gd`, `scripts/world/GuestSpawner.gd` hiányoznak, pedig a scene-ek hivatkoznak rájuk.
- `.godot/` és `.import/` könyvtárak nincsenek jelen – továbbra is kerülendő a verziókezelésben.
