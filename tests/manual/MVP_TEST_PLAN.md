# Spaghetti – manuell MVP-testmall

Återanvändbar testmall för utvecklingsversion 0.3.1. Alla resultatfält i denna mall är tomma. Den är inte ett nytt testutfall.

## Använd i små pass

Gör **3–5 tester per tillfälle**, eller färre om det räcker. Varje test har egna förutsättningar. Testgrafer får sparas och återanvändas; du behöver inte minnas dem mellan passen. Anteckna var du slutar. **Du behöver inte göra hela planen på en gång.**

| Förslag på pass | Tester | Fokus |
| --- | --- | --- |
| 1 | T01–T03 | Öppna, koppla, visa combatreminder |
| 2 | T04–T06 | Macro, lagring, validering |
| 3 | T07–T09 | Karaktärer, combatgränser, NOT |
| 4 | T10–T13 | Buffdiagnostik och pickers |
| 5 | T14–T16 | Utkast, native uppdatering, klickbara reminders |
| 6 | T17–T19 | Import, placering, zoom |
| 7, valfritt | T20–T21 | Focus och modifiergren |

**Nästa test att fortsätta med:** ______  **Senast testat datum:** ______

**P0:** blockerande grundfunktioner. **P1:** viktiga funktioner och säker återkoppling. **P2:** sekundära/regressionstester. Om en P0 blockerar: skriv FEL, avbryt just det flödet och välj ett oberoende test. Provocera inte fel genom att ändra SavedVariables eller kod.

**Resultat:** OK = hela förväntningen uppfylld; FEL = avvikelse; DELVIS = bara delar kontrollerade; EJ TESTBAR = nödvändiga förutsättningar saknas. Kryssa Testat när försöket är dokumenterat. EJ TESTBAR är inte ett godkännande. Skriv gärna ”inga” i Lua-fältet om inget fel visades.

## Startkort – fyll i för din testkopia

- Datum: ______
- Version laddad i WoW och commit/ändringsidentifiering: ______
- Klientversion/build och språk: ______
- Klass A och eventuell klass B (karaktärsnamn behövs inte): ______
- Upplösning/UI-skala: ______
- Övriga addons avstängda respektive påslagna: ______

Starta om klienten helt efter byte av testversion. Visa Lua-fel med `/console scriptErrors 1` och öppna `/spaghetti`. Använd egna ofarliga testfall och avsluta normalt så att lagringstesterna blir meningsfulla. Ändra aldrig live-SavedVariables för att skapa testdata.

## Läsnyckel för grafer

**Ny reminder:** välj läget `Reminder / CD`, klicka `New`, skriv grafnamn. **Nytt macro:** välj `Macro`, klicka `New`, skriv grafnamn. Klicka `+ nodnamn` i vänsterbiblioteket. Dra från utport till inport. **Blå** portar är event/flöde, **gröna** är villkor. Högerklick på en port tar bort dess kopplingar. Nodens lilla `x` tar bort noden.

En standard-Show i testen har text enligt instruktionen, `Icon = No icon`, `Clickable = av`, `Enabled = på`. `Test / Preview` är bara en femsekunders förhandsvisning och räknas inte som ett fungerande livevillkor. `Save` sparar; `Apply reminder` sparar och aktiverar. Save på en redan aktiverad graf uppdaterar också dess körning. WoW skriver lagringen till disk vid `/reload` eller normal utloggning.

## P0 – grundfunktioner och blockerare

### T01 – Toppknappar och stängning

**Prioritet:** P0 · **Funktion:** native musklick.

**Förutsättning:** utanför combat, editorn öppen.

**Steg:**
1. Om importdialog visas, välj `Keep separate` för att fortsätta utan import.
2. Om `Import account data` finns: klicka och välj `Keep separate`. Finns den inte, anteckna ”redan importerat/ingen äldre data”.
3. Klicka `Examples` och välj `Combat event demo`.
4. Klicka huvudfönstrets `X`; öppna igen med `/spaghetti`.
5. Klicka tom canvas och tryck Escape; öppna igen.

**Förväntat:** befintliga toppknappar reagerar. Exemplet läggs till. X/Escape stänger och återöppning fungerar utan Lua-fel eller kvarvarande osynlig editor. Saknad villkorlig importknapp är inget fel; importen täcks separat i T17.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T02 – Flytta noder och koppla om

**Prioritet:** P0 · **Funktion:** editor och grundläggande grafkopplingar.

**Förutsättning:** ny reminder `MVP-editor`.

**Steg:**
1. Lägg till `Combat State` och standard-`Show Reminder`, text `I combat`.
2. Behåll State `In Combat`. Dra grön utport `Is in combat` till Shows gröna `Condition`.
3. Flytta Combat State genom att dra nodens titel.
4. Högerklicka Shows Condition-port; koppla sedan samma portar igen.
5. Klicka `Save`, välj en annan graf och välj sedan `MVP-editor` igen.

**Förväntat:** noden följer musen, linjen följer portarna, frånkoppling/återkoppling fungerar. Nodläge och koppling finns kvar efter grafbyte. Ingen automatisk aktivering förväntas.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T03 – Enter Combat, aktivering och femsekunderspuls

**Prioritet:** P0 · **Funktion:** händelsestyrd live-reminder.

**Förutsättning:** ny reminder `MVP-event`, utanför combat.

**Steg:**
1. Lägg till `Combat State`; välj State `Enter Combat` innan du kopplar.
2. Lägg till standard-Show, text `Combat startar`, Duration `5`.
3. Koppla blå `Enter Combat event` till Shows blå `Run`; klicka `Save`.
4. Kontrollera `Active Reminders`; klicka därefter `Apply reminder`.
5. Stäng editorn med X och gå in i combat. Observera i minst fem sekunder.

**Förväntat:** Save visar sparad/ej aktiverad status. Apply aktiverar. Texten visas vid combatstart och försvinner efter ungefär fem sekunder även om combat fortsätter. Stängd editor stoppar inte påminnelsen. Preview behövs inte.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T04 – Equip test hela vägen till action bar

**Prioritet:** P0 · **Funktion:** generering, macronamn, native skapande och dragning.

**Förutsättning:** nytt macro `Equip test`, utanför combat, ledig karaktärsmacroplats. Ha ett tillåtet vapen i väskan; välj Axe of Orgrimmar om du har det. Använd ett ledigt action bar-fack och lås upp action bars vid behov.

**Steg:**
1. Lägg till `Macro Start` och `Equip Slot`; koppla blå `Next` → `Run`.
2. Välj vapnet med itemfältet och slot `Main Hand`. Behåll standardnamnet från grafen och `Character-specific` på.
3. Läs genererad text och klicka `Save`. Kontrollera `Macro Action`.
4. Klicka `Create macro`. Dra sedan **Macro Action-ikonen** direkt till det lediga action bar-facket.
5. Tryck action bar-knappen och kontrollera Main Hand.

**Förväntat:** Save ger `Not created`. Texten är `#showtooltip` följt av `/equipslot 16 item:<valt ID>`; Axe of Orgrimmar ger `item:15424`. Create ger `Created` och native namn `Equip test`. Direkt dragning fungerar utan att hämta macrot ur Blizzards macrofönster. Endast knapptrycket utrustar vapnet. Macrotooltip eller frivillig inspektion i WoW:s macrofönster kan användas för namnkontroll. Om valt vapen redan satt i Main Hand har själva utrustningsbytet inte verifierats: notera DELVIS eller prova ett annat tillåtet vapen.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T05 – Sparad graf över reload och full omstart

**Prioritet:** P0 · **Funktion:** verklig beständig lagring.

**Förutsättning:** ny reminder `MVP-lagring` på karaktär A.

**Steg:**
1. Bygg `Combat State (In Combat)` grön utport → standard-Shows `Condition`, text `Sparad A`.
2. Flytta Combat State till ett tydligt eget läge, klicka `Save` och sedan `Apply reminder`.
3. Skriv `/reload`; öppna grafen och kontrollera text, nodläge, koppling och aktivering.
4. Avsluta WoW normalt helt; starta igen på samma karaktär och öppna samma graf.
5. Kontrollera samma innehåll och gå in/ur combat.

**Förväntat:** sparad graf och aktivering finns kvar efter båda återstarterna. `Sparad A` visas i combat och göms utanför. Anteckna reload och full omstart var för sig; ett lyckat reload räcker inte för OK.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T06 – Validering utan förlorade kopplingar

**Prioritet:** P0 · **Funktion:** feltyper och återhämtning.

**Förutsättning:** ny reminder `MVP-validering`.

**Steg:**
1. Lägg bara till standard-Show, text `Validering`; kontrollera feltext och att Apply inte kan aktivera grafen.
2. Lägg till `Combat State`, välj `Enter Combat`; försök koppla blå eventport till Shows gröna `Condition`.
3. Koppla i stället eventporten till blå `Run`.
4. Försök ändra State till `In Combat` medan denna koppling finns.
5. Högerklicka `Run`, ändra till In Combat och koppla grön utport → Condition.

**Förväntat:** saknad ingång och fel porttyp förklaras. Felaktig lägesändring nekas med röd återkoppling; gamla State och kopplingen behålls. Efter korrekt omkoppling går grafen att aktivera och avvisningsfelet försvinner. Inga tysta borttagningar.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T07 – Två karaktärer har egna profiler

**Prioritet:** P0 · **Funktion:** karaktärsisolering.

**Förutsättning:** två tillgängliga karaktärer A och B. Importera inte äldre data under detta test.

**Steg:**
1. På A: skapa `MVP-profil-A`: `Player` grön `Value` → standard-Shows `Condition`, text `Bara A`; Apply.
2. Logga ut normalt och logga in på B. Välj Keep separate om import erbjuds.
3. Öppna Spaghetti; leta efter `MVP-profil-A` i graflistan och `Bara A` på skärmen.
4. På B: skapa och Save samma enkla Player→Show-graf med namn `MVP-profil-B`, text `Bara B`, utan Apply.
5. Logga tillbaka till A och kontrollera graflista och `Bara A`.

**Förväntat:** A:s nya graf/reminder finns inte på B; B:s nya graf finns inte på A. A behåller sin aktivering. Ingen andra karaktär = EJ TESTBAR, inte OK. Stäng av `Bara A` via Active Reminders när testet är klart.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T08 – Combat blockerar macroåtgärder men tillåter stängning

**Prioritet:** P0 · **Funktion:** lockdown och vanlig editor.

**Förutsättning:** skapat och synkat macro med Macro Action `Created`. Använd T04:s graf, eller bygg och skapa `Macro Start → Equip Slot` med eget tillåtet föremål enligt T04. Ha ett ledigt action bar-fack.

**Steg:**
1. Öppna macrografen och gå in i combat.
2. Kontrollera Create/Update-knappen; försök dra Macro Action till det lediga facket.
3. Klicka X och öppna igen med `/spaghetti`, fortfarande i combat.
4. Klicka tom canvas och tryck Escape; öppna igen.
5. Lämna combat och kontrollera att dragning blir tillgänglig igen.

**Förväntat:** native skapande/uppdatering och dragning blockeras under combat med begriplig status. Inget macro placeras där. X/Escape fungerar utan skyddsfel. Efter combat kan verifierat macro dras igen. Testet kräver inga klickbara reminders.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

## P1 – viktiga funktioner

### T09 – NOT och text utan ikon

**Prioritet:** P1 · **Funktion:** villkorsriktning och textreminder.

**Förutsättning:** ny reminder `MVP-NOT`.

**Steg:**
1. Lägg till Combat State med `In Combat`, `NOT` och standard-Show med text `Utanför combat`.
2. Koppla grön combatutport → NOT `Condition`, sedan NOT `Inverted result` → Show `Condition`.
3. Apply utanför combat.
4. Gå in i combat, lämna sedan combat.

**Förväntat:** texten visas utanför, göms i combat och återkommer efteråt. Ingen ikon eller castspell krävs. Observera att `Player → NOT → Combat State` är en annan graf med alltid falsk Gate; bygg inte den här.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T10 – Buff Missing utanför combat

**Prioritet:** P1 · **Funktion:** läsbar aura och Spell Picker.

**Förutsättning:** en egen inlärd, ofarlig självbuff som du kan lägga på och ta bort. Hela testet utanför combat. Warrior kan använda Battle Shout om den finns.

**Steg:**
1. Skapa reminder `MVP-buff`; lägg `Buff Active / Missing` och standard-Show, text `Buff saknas`.
2. Välj buff i nodens Spell Picker; State `Missing`. Koppla grön `Value` → Show `Condition`; Apply.
3. Se till att buffen är borta och observera påminnelsen.
4. Kasta buffen normalt via spelets vanliga knapp och observera igen.
5. Ta bort buffen och observera återkomsten; läs Live Status om resultatet avviker.

**Förväntat:** om datan är läsbar: visas saknad → göms aktiv → visas saknad. Om API:t är otillgängligt/hemligt ska orsaken visas som Unknown utan påhittad frånvaro. Det senare verifierar diagnostik men ger DELVIS för detta funktionstest. Anteckna exakt spell/rank och status. Saknad lämplig buff = EJ TESTBAR.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T11 – Buff under combat: korrekt status framför gissning

**Prioritet:** P1 · **Funktion:** secret/Unknown-gränsen; historiskt Battle Shout-problem.

**Förutsättning:** reminder `Buff Active / Missing (Missing, egen inlärd självbuff)` grön `Value` → standard-Show `Condition`, text `Buffdiagnos`. Bygg ny graf eller använd T10. Ingen Combat Gate behövs i detta diagnostiktest.

**Steg:**
1. Apply och lägg på buffen utanför combat.
2. Gå in i combat; öppna grafen och läs `VALIDATION / LIVE STATUS` samt Active Reminders.
3. Om möjligt, ta bort buffen manuellt i combat och läs status igen. Annars anteckna att det momentet inte gick att prova.
4. Lämna combat och kontrollera att läsbar status återkommer.

**Förväntat:** hemlig/otillgänglig data ger `Unsupported / unknown` med buffnamn och orsak; ingen Missing-påminnelse får härledas från Unknown. Om klienten verkligen tillåter läsning kan aktiv/saknad ge motsvarande korrekt visning. En generell begränsningsvarning kan finnas även för läsbara spells; anteckna liveutfallet. OK betyder att observerat beteende följer denna gräns, **inte** att Battle Shout Missing generellt fungerar i combat. Har varken hemlig data eller ett verifierbart buffbyte observerats, välj DELVIS.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T12 – Spell Picker, rankval och spellbook-drop

**Prioritet:** P1 · **Funktion:** spellidentitet och valdialog.

**Förutsättning:** nytt macro `MVP-spell`, `Macro Start Next → Cast Spell Run`, egen inlärd aktiv spell.

**Steg:**
1. Öppna Cast Spell-fältet; sök på del av din spells namn och välj rätt rad.
2. Kontrollera namn/ikon och `/cast`-text. Öppna igen, välj `Keep this exact rank` och samma spell/rank.
3. Kontrollera ranktext i genereringen om klienten erbjuder ranker. Saknas ranker, anteckna det.
4. Dra en inlärd aktiv spell från WoW:s Spellbook till Cast Spell-fältet.
5. Save, byt graf och återvänd.

**Förväntat:** sökning och native drop väljer rätt spell; valet överlever grafbyte. Passiva spells erbjuds inte för cast. Exakt rank återges när ranktext finns. Auto följer högsta rank bara med verifierbar familj; annars visas fallbackvarning. Nyinlärning av en rank ingår inte och kan testas senare när tillfälle finns. Skapa inget native macro för detta test.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T13 – Item Picker och föremål från väskan

**Prioritet:** P1 · **Funktion:** itemval, filter och drop.

**Förutsättning:** nytt macro `MVP-item`, `Macro Start Next → Equip Slot Run`; utrustningsbart föremål i väskan.

**Steg:**
1. Öppna itemfältet, sök på del av föremålets namn och hovra rätt rad.
2. Välj raden och kontrollera genererad `item:ID`-text med passande slot.
3. Dra samma föremål från väskan till itemfältet.
4. Försök dra ett icke utrustningsbart föremål, exempelvis Hearthstone, till samma fält.
5. Save, byt graf och återvänd.

**Förväntat:** ikon, namn, kvalitet och tooltip motsvarar ägt föremål. Utrustningsfilter fungerar. Rätt drop accepteras; fel drop ger orsak och bevarar föregående val. Valet återkommer efter grafbyte. Ingen utrustning sker av val/drop/Save. Bank och global föremålssökning ingår inte.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T14 – Utkast över reload påverkar inte aktiv regel

**Prioritet:** P1 · **Funktion:** separata utkast och sparad runtime.

**Förutsättning:** ny reminder `MVP-utkast`: `Player Value → standard-Show Condition`, text `Sparad text`; Apply utanför combat.

**Steg:**
1. Ändra Show-text till `Utkast text` utan Save/Apply.
2. Byt graf och återvänd; kontrollera fältet och den synliga livepåminnelsen.
3. Skriv `/reload` och öppna grafen igen.
4. Kontrollera att fältet visar utkastet medan livepåminnelsen fortfarande visar den sparade texten.
5. Klicka Save; kontrollera livepåminnelsen. Stäng av raden i Active Reminders efter testet.

**Förväntat:** utkast överlever byte/reload. Runtime visar `Sparad text` tills Save, därefter `Utkast text`. Detta är avsiktligt: Save uppdaterar en redan aktiv graf; nytt Apply behövs inte.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T15 – Native macro uppdateras med bekräftelse

**Prioritet:** P1 · **Funktion:** namn, synkstatus och säkert uppdateringsflöde.

**Förutsättning:** eget skapat macro med Macro Action `Created`, utanför combat. Använd T04 eller skapa motsvarande Start→Equip Slot-graf. Testa bara ett eget testmacro.

**Steg:**
1. Ändra grafnamnet till `MVP-nytt`; behåll standardnamn för macrot.
2. Läs statusraden vid **Macro Action** längst ned i Macro-läget. `Out of sync` betyder att grafens avsedda namn/text inte längre stämmer med macrot i WoW; det är en status, ingen knapp. Kontrollera att ikonen inte går att dra.
3. Klicka `Update macro` och sedan `Cancel`; kontrollera att det befintliga native macrot behåller sitt tidigare namn.
4. Klicka Update igen och bekräfta. Kontrollera native namn `MVP-nytt` och `Created`.
5. Sätt Macro name till `MVP-eget`; ändra grafnamnet till `MVP-graf`. Kontrollera att Macro name är kvar; klicka `Use graph name` och kontrollera `MVP-graf`.

**Förväntat:** avbruten uppdatering lämnar native macrot orört; bekräftad uppdatering återställer verifierad dragberedskap. Eget macronamn är oberoende av grafnamnet. Sista namnändringen får ge Out of sync tills ny bekräftad uppdatering; den ska inte ändra WoW-macrot automatiskt.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T16 – Klickbar reminder endast utanför combat

**Prioritet:** P1 · **Funktion:** secure-klick, synlig ikon och combatgräns.

**Förutsättning:** ny reminder `MVP-klick`: Player Value → Show Condition. Välj egen ofarlig självbuff som Icon och Spell to cast; text `Klicktest`, Clickable/Enabled på. Utanför combat, tillräcklig resurs och ingen cooldown.

**Steg:**
1. Apply; stäng editorn och klicka på den synliga ikonen.
2. Gå in i combat: kontrollera att den skyddade klickfunktionen inte går att använda; vanlig text/visuell reminder får finnas kvar.
3. Lämna combat, låt regeln utvärderas och kontrollera att klick fungerar igen.
4. Välj No icon, behåll texten och Apply. Klicka där ikonen tidigare låg.
5. Välj åter en ikon, använd Test / Preview samt Edit placement utan att Apply ändringar; kontrollera att dessa provytor inte castar. Avsluta placering med Cancel och stäng av testremindern.

**Förväntat:** ett giltigt självcast från verkligt klick utanför combat. Ingen skyddad handling eller Lua-/taintvarning i combat, inga osynliga klickmål utan ikon, ingen cast från preview/placering. Klickbart i combat är inget krav. Den aktiva riktiga remindern kan visas igen efter Cancel; förväxla inte dess ikon med provytan. Anteckna spelets inställning för handling vid knappnedtryck; andra inställningsläget är ett senare återtest.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T17 – Legacyimport, endast om äldre data finns

**Prioritet:** P1 · **Funktion:** explicit kopia och inaktiva importerade regler.

**Förutsättning:** karaktär där import ännu inte genomförts, befintliga äldre kontografer och säkerhetskopia av SavedVariables efter normal utloggning. Ingen data ska raderas för att möjliggöra testet. Saknas förutsättning: EJ TESTBAR.

**Steg:**
1. Öppna Spaghetti; välj Keep separate om dialogen visas. Anteckna namn på en befintlig karaktärsgraf.
2. Klicka `Import account data` och därefter `Import copy`.
3. Kontrollera att äldre grafer har tillkommit och den befintliga karaktärsgrafen är kvar.
4. Öppna en importerad reminder: kontrollera både grafstatus och varje Show Enabled. Öppna ett importerat macro och kontrollera Character-specific.
5. `/reload`, öppna igen och kontrollera att ingen automatisk ny import görs.

**Förväntat:** import är explicit och sker en gång; befintliga karaktärsgrafer behålls. Importerade reminders är ej aktiverade och Show-utgångar avstängda; macros får karaktärsscope. Ingen automatisk native macroändring. Kontodatans oförändrade innehåll är kod/mocktestat, men full filjämförelse ingår inte i detta korta UI-test; hävda inte att det bevisats här. Aktivera inget importerat för att klara testet.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T18 – Active Reminders och separat placering

**Prioritet:** P1 · **Funktion:** översikt, av/på och layout.

**Förutsättning:** ny reminder `MVP-placering`: Player Value → standard-Show Condition, text `Placera mig`; Apply utanför combat.

**Steg:**
1. I Active Reminders: slå av och på testets rad och kontrollera visning/status.
2. Klicka radens `Open` och därefter `Edit placement`.
3. Dra provrutan åt sidan, klicka `+` en gång och välj `Save placement`.
4. Öppna placering igen, flytta till annan plats och välj `Cancel`.
5. `/reload`; kontrollera den sparade platsen och samma logik/text. Stäng av testremindern.

**Förväntat:** raden styr rätt reminder, Open öppnar rätt graf. Save placement behåller ny position/storlek; Cancel återställer senast sparade layout. Reload bevarar den. Text/portkoppling ändras inte. Text-only-provytan kan se annorlunda ut än den riktiga påminnelsen; anteckna den skillnaden som UX-avvikelse, inte förlorad logik.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

## P2 – sekundärt och riktad regression

### T19 – Zoom, fönsterstorlek och dialoger

**Prioritet:** P2 · **Funktion:** träffytor och läsbarhet.

**Förutsättning:** reminder med Combat State (In Combat) → Show Condition och valfri text. Behöver inte vara aktiverad. Anteckna ursprunglig UI-skala/fönsterstorlek.

**Steg:**
1. Använd zoomknappar/Ctrl+hjul till 50 %, 100 % och 150 %; dra en nod vid varje nivå.
2. Scrolla och kontrollera att linjer ansluter till rätt portar; koppla loss/åter vid 50 %.
3. Ändra editorstorlek med nedre högra hörnet och prova Examples och X igen.
4. Öppna en spell-/itemdialog i lämplig graf och stäng med Escape, sedan genom klick utanför. Prova tom dialogyta över en ofarlig editorkontroll.
5. Återställ önskad zoom/storlek.

**Förväntat:** inga felriktade portar/linjer eller blockerade knappar. Dialogstängning fungerar utan kvarvarande ytor. Tom dialogyta ska inte oavsiktligt aktivera kontroller bakom; anteckna om det händer, särskilt i Item Picker. Full canvas/stora grafer behöver inte stresstestas här.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T20 – Direkt cast på befintlig Focus

**Prioritet:** P2 · **Funktion:** målkrav och native execution.

**Förutsättning:** egen inlärd spell för en vänlig levande enhet; giltig vänlig Focus i räckvidd, annan aktuell target. Använd WoW:s vanliga fokusfunktion för att sätta Focus. Om klient/klass inte ger ett lämpligt fall: EJ TESTBAR.

**Steg:**
1. Skapa Macro `MVP-focus`: Macro Start Next → Cast Spell Run; välj din spell.
2. Välj Cast on `Focus`, Target must be `Friendly`, Alive på och Exists på.
3. Kontrollera genererad `/cast [@focus,help,nodead,exists] <lokalt spellnamn>`.
4. Create macro, dra Macro Action till ledigt action bar-fack och tryck den när spellen får kastas.
5. Ta bort Focus med WoW:s fokusfunktion och prova knappen igen.

**Förväntat:** giltig Focus får spellen utan att current target ändras. Utan Focus sker ingen fallbackcast på aktuell target. GCD, resurs, range och line of sight kan hindra cast och ska antecknas som testförutsättningar. Noden `Set Focus` är en separat handling och testas inte här.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

### T21 – En modifiergren med två spells

**Prioritet:** P2 · **Funktion:** kompilatorns stödda grenform.

**Förutsättning:** två egna aktiva spells som kan provas på Self utan farlig effekt; båda tillåtna i aktuell situation. Ingen nästlad gren.

**Steg:**
1. Skapa Macro `MVP-shift`; lägg Macro Start, Modifier Key (shift), Conditional Branch och två Cast Spell.
2. Koppla Start Next → Branch Run; Modifier Value → Branch Condition; Branch True/False → respektive Cast Run.
3. Välj spell A/B och `Self` för båda; lämna samma målkrav och båda terminala utan vidare koppling.
4. Kontrollera `/cast [@player,mod:shift] <A>; [@player] <B>`; Create macro och dra till ledigt action bar-fack.
5. Musklicka knappen med respektive utan Shift, med cooldown/GCD redo.

**Förväntat:** Shift väljer A, utan Shift väljs B. En knapptryckning väljer en gren. Texten följer de valda spellsens lokala namn. Nästlade grenar, olika kommandon/mål och obegränsade castkedjor ingår inte i stödet.

- [ ] Testat
- **Resultat (OK / FEL / DELVIS / EJ TESTBAR):** ______
- **Observation, relevanta inställningar och Lua-fel:** ______
- **Reproduktionssteg vid avvikelse:** ______

## När du är färdig för dagen

Skriv nästa test-ID överst. Inaktivera eventuella störande testreminders via deras rader i Active Reminders. Behåll testgraferna om du vill återanvända dem. Återställ egna action bars/inställningar vid behov. Avsluta WoW normalt så att resultaten av lagringstesterna blir meningsfulla.

Efter grundpassen: gör ett kort återtest av T01, T03 och T04 med din vanliga addonuppsättning. Anteckna eventuella nya fel här: ______

**Viktigaste blockerande test-ID:** ______  **Nästa rimliga test:** ______

Omfattningen är avsiktligt begränsad. Fulla slots, duplicerade native identiteter, extern macro-radering/indexomordning, korrupt lagring, alla inventoryslots, alla språk och långtidsprestanda har främst modelltest-/granskningsstöd eller behöver särskilda framtida tester. De är inte manuellt godkända genom denna plan. Testa dem först om resultat eller vald releasefunktion motiverar det.
