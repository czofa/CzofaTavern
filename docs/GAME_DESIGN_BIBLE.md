# GAME DESIGN BIBLE – Czofa: Egy kocsma története

## Játékvizion és hangulat
- Falusi kocsma-menedzsment valósághű magyar gazdasági környezettel, humoros, de realista tónusban.
- Hibrid műfaj: tycoon (layout + üzemeltetés), RPG/decision (encounter következmények), könnyed combat (bánya), Sims-szerű igénykezelés.
- Godot 4.5.1, 3D, RTS (kocsma) és FPS (falu/bánya) kamera módok váltása.

## Core loopok (nap 06:00–zárás, 45 perc valós idő)
1) **Napi előkészítés:** készlet és árak beállítása, konyhai adagképzés, akciók meghirdetése.
2) **Vendégforgalom:** vendégek érkeznek → várakoznak/ülnek → rendelnek → kiszolgálás → fogyasztás → fizetés → távozás/borravaló.
3) **Könyvelés és riport:** bevételek, költségek, ÁFA és készletmozgás rögzítése; nap végi összegzés (DayEndSummary) + mentés.
4) **Döntések és események:** napi encounter/quest döntések, frakciók és audit/razziák hatása.

## Idő és napciklus
- 45 perces nap = 1440 játékperc; nap 06:00-kor indul, záráskor DayEndSummary megállítja a játékot, gombbal lehet továbblépni.
- Autosave nap végén, manuális mentés a BookMenu/Beállítások fülön.
- Időzítés: encounter ellenőrzés napi fix órában; szezonális/ünnepi események adott napokon.

## Vendégrendszer
- Vendégtípusok frakciókhoz kötött preferenciákkal; ülésrend (szék marker-ek) és útvonaltervezés a zsúfoltság/komfort alapján.
- Elégedettség kalkuláció: várakozási idő, minőség (recept+adag), ár-érték arány, tisztaság/hangulat, balhék/razziák hatása.
- Kimenet: borravaló, visszatérési esély, pletyka (frakció reputáció módosító), panasz/eszkaláció.

## Menü, árképzés és akciók
- Recept-alapú termékek önköltséggel; árképzés: önköltség + fix költség + kockázati prémium + haszonkulcs.
- Akciók/kuponok: időszakos árleszállítások vagy csomagok frakció-kedvezménnyel.
- Ár- és akcióhatások a vendég elégedettségre és forgalomra.

## Supply chain és készletek
- Beszerzés → raktár → könyvelés → adagképzés → főzés → késztermék → kiszolgálás.
- Készletállapotok: könyveletlen raktár (új beszerzés), könyvelt raktár (felhasználható), konyhai adag, késztermék, selejt/romlás (mid/late game).
- Selejt mechanika: romlási idő, higiéniai szint és tárolás befolyásolja; konyhai veszteség könyvelésre kerül.

## Könyvelés és gazdaság
- Kettős könyvelés jellegű T/K napló: bevételek, költségek, készletmozgás, bér és rezsi.
- ÁFA: fizetendő és levonható áfa, időszaki bevallás, késedelmi bírság esély.
- Cégpénz vs. magánpénz: osztalék, tulajdonosi kivét, tiltott vegyes használat kockázattal.
- Bérek és járulékok: dolgozói bér, járulék, túlóra; automatikus hó végi fizetés.
- Audit/ellenőrzés: hatósági vizsgálat triggerelheti a könyvelési hibák büntetését vagy reputációt.
- Riportok: napi forgalom, árrés, cashflow, készletmozgás, bér/rezsi trend, frakció reputációs riport.

## Építés és layout
- Helyiség tárgyai: asztalok, székek, pult, konyha, raktár moduláris elhelyezése.
- Hatás: útvonalterv hatékonysága (kiszolgálási idő), zsúfoltság vs. komfort, dekoráció/hangulat.
- Fejlesztések: konyha eszközbővítés, raktár polcok, pult upgrade.

## Dolgozók
- Statok: gyorsaság, főzés, megbízhatóság, szociális készség, stressz-tűrés.
- Műszakbeosztás: nyitvatartási blokkok, szabadság, túlóra.
- Morál: fizetés, munkakörülmény, vendégkonfliktus, képzés.
- Képzés/fejlődés: stat növelés költséggel/idővel; fluktuáció kockázat magas stressznél.

## Események, encounterek, questek
- Felvehető, nem kötelező encounterek; nem teljesítés büntet, teljesítés jutalom/unlock.
- Encounter típusok: frakció-specifikus kérdések, audit/razziák, alvilági ajánlatok, különleges vendégek.
- Következmény pipeline: pénz, reputáció, frakció állás, risk/safety, állapot flag-ek; későbbi események branch-elése.

## Frakciók
- Falusiak, Hatóság, Alvilág, Kereskedők, Egyház/Iskola.
- Befolyás: vendégáramlás, audit esély, speciális eventek, kedvezmények vagy tiltások.
- Reputációs sáv és küszöbök: pozitív/negatív bónuszok, endings befolyásolása.

## Bánya (light combat)
- FPS-szerű, minimál run: loot ritka alapanyag/eszköz; stamina/HP; sérülés debuff és gyógyköltség.
- Kockázat/jutalom: idő- és erőforrásköltség, sérülés esély, loot érték.

## Kert és állattartás
- Saját alapanyag-termelés: magvetés, öntözés, aratás; állattartás (takarmány, egészség, termény).
- Feldolgozás (late): lepárló, füstölő, konzerváló lánc; minőség és romlás.
- Szezonfüggés: vetési/aratási idők, termény elérhetőség.

## Szezonok és ünnepek
- Évszak-specifikus kereslet, árak és termény elérhetőség.
- Fix események: falunap, szüret, karácsony, lakodalmak; extra vendégáradat és speciális encounterek.

## Progresszió
- Early: túlélés, alap készlet, kis forgalom; cél a csőd elkerülése.
- Mid: stabil üzlet, bővített menü, dolgozói csapat, audit/razziák kezelése.
- Late: birodalom-építés (lepárló, panzió, étterem), nagy frakció endingek, komplex gazdaság.

## Bukásállapotok
- Csőd (negatív cashflow, tartozások), hatósági bezárás, alvilági következmények, reputáció összeomlás, munkaerő elvándorlás.

## UI filozófia
- HUD minimalista; fő vezérlő a **BookMenu (M)** tabokkal: Leltár, Könyvelés, Riportok, Dolgozók, Frakciók, Questnapló, Beállítások/Mentés.
- Kontextusfüggő promptok (interakciók), toast feed értesítések, modal encounter kártyák.

## MVP (3 napos demo)
- 45 perces nap alap működéssel; napvégi összegző panel (statikus), kézi továbblépés + autosave stub.
- Alap vendég loop: 3–4 vendég spawn/ülés, egyszerű rendelés és fizetés, borravaló stub.
- Bolt/áruk: 2–3 alapanyag vásárlás, könyveletlen → könyvelt készlet könyvelés, egyszerű recept/termék logika.
- Könyvelési stub: pénzmozgás naplózás, alap riport szövegesen.
- Egy encounter (bíró) a hatás pipeline első lépésével (money/reputation módosítás).
- UI: BookMenu + könyvelési stock/price panel, HUD idő/pénz kijelzéssel, interakció prompt.

## Full game
- Teljes frakció- és reputáció-rendszer branch-elt encounterekkel, audit/razziákkal.
- Szezon/ünnep keresleti modell, kert/állattartás + feldolgozó lánc, lepárló/panzió/étterem bővítés.
- Dolgozói életciklus, képzés, morál és fluktuáció; műszak tervező.
- Részletes könyvelés (ÁFA, járulékok, cashflow-riportok), audit AI.
- Bánya run-ok felszerelés/loot metával; sérülés és gyógyítás költsége.
- Teljes bukás/endgame következmények és több befejezés (frakció endingek).
