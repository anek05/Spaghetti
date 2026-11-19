# Bidra till Spaghetti

Börja med [kända begränsningar och planerat arbete](docs/BACKLOG.md). Versionen är 0.3.1 och ännu inte en godkänd MVP. Håll ändringar små och koppla dem till en felrapport eller överenskommen uppgift.

## Kom igång

1. Klona repot när det har publicerats och läs [README](README.md).
2. För speltest: kopiera endast addonmappen `Spaghetti/` till din egen Forever-klients `Interface/AddOns/Spaghetti/`. Behåll `Spaghetti/LICENSE`. Säkerhetskopiera egna SavedVariables efter normal utloggning före byte av testversion.
3. Starta om WoW helt, kontrollera laddad version och öppna `/spaghetti`. Kopiera inte projektroten som addonmapp.
4. För en ny fix, skapa en separat branch, exempelvis `codex/post-combat-status`. Testa inte genom att skriva över någon annans profiler eller ändra SavedVariables för hand.

Det befintliga `tools/install.ps1` är valfritt och har en lokal standardsökväg som sannolikt inte passar din dator. Läs det först och ange din egen AddOnsPath. Workflowen installerar aldrig addonet i en WoW-klient.

## Automatiska tester

Krav: Python 3.13 för samma Pythonversion som CI. Lua 5.1 och LuaJIT 2.1 tillhandahålls av den låsta Lupa-dependensen; separat Lua-installation behövs inte för denna svit.

Kör från projektroten i PowerShell, med testmiljön utanför projektet:

```powershell
py -3.13 -m venv "$env:TEMP\spaghetti-dev-venv"
& "$env:TEMP\spaghetti-dev-venv\Scripts\python.exe" -m pip install --only-binary=:all: -r requirements-dev.txt
& "$env:TEMP\spaghetti-dev-venv\Scripts\python.exe" -B tests/run.py
```

På macOS/Linux, också från projektroten:

```sh
python3.13 -m venv /tmp/spaghetti-dev-venv
/tmp/spaghetti-dev-venv/bin/python -m pip install --only-binary=:all: -r requirements-dev.txt
/tmp/spaghetti-dev-venv/bin/python -B tests/run.py
```

Sviten läser projektfiler och använder mockade WoW-API:er. Förväntat för oförändrad 0.3.1: 222 modellkontroller per runtime samt UI-mocksviten. Vid nya meningsfulla tester kan antalet öka. `python -B` undviker lokal Python-cache. Testa gärna i en separat kopia om du behöver garantera att din arbetskopia förblir orörd.

GitHub Actions kör samma kommando på Windows och Linux vid push/PR samt manuellt. CI har bara läsrättighet till repots innehåll, använder inga egna hemligheter och gör ingen release eller installation. Ett lokalt PASS innebär inte att GitHub-körningen redan har passerat.

## Speltest utan långa testpass

- Välj 3–5 små kontroller ur [MVP-testmallen](tests/manual/MVP_TEST_PLAN.md), eller färre.
- Ändra inte ägarens redan ifyllda resultat. Skriv ditt eget datum/build/commit och utfall i en separat rapport eller issue.
- Anteckna både projektversion och commit när en sådan finns. Flera utvecklingsbyggen kan fortfarande visa samma TOC-version.
- Skriv exakt graf, noder, portar, spell/item, före–under–efter combat och eventuella Lua-fel. Skilj verklig handling från preview.
- Om ett fel kan bero på annan addon: gör ett kort återtest med övriga addons avstängda och redovisa båda miljöerna. Dra inte slutsatsen att integration fungerar i alla miljöer från ett test.

Först att återtesta: [tre korta kontroller](tests/manual/RETEST.md) för T08/T16 efter combat och nodbibliotekets textfärg. Vid macrouppdatering betyder Out of sync att grafens avsedda namn/text/scope skiljer sig från det befintliga WoW-macrot; kontrollera Cancel och bekräftad Update separat. Import och P2 är fortfarande öppna.

## Krav på ändringar

- Behåll Unknown skilt från Missing. Försök inte kringgå secret values eller skyddade handlingar.
- Klickbara reminders behöver bara fungera utanför combat. En återhämtningsfix får inte börja ändra secure-knappar under lockdown.
- Ändringar i draft/runtime, import eller native macroidentitet behöver bevara befintliga data och identifiera exakt vad som uppdateras.
- Håll en PR till en tydlig ändring. Beskriv synligt före/efter, automatisk verifiering och vad som faktiskt speltestats.
- Uppdatera relevanta dokument när beteendet ändras. Rotens README är projektets enda ingång. Tekniska utvecklardokument och CHANGELOG finns bara i roten. Paketet har en kort `Spaghetti/README.md` och den enda användarguiden i `Spaghetti/docs/USER_GUIDE.md`, som även rotens README länkar till. Uppdatera relevant guide och kända begränsningar samtidigt med beteendet; skapa inga dubbla tekniska dokumentkopior.
- Lägg bara till tester som fångar beteendet eller en verklig regression. Mockar för native färgväxling och eventtiming är ofullständiga; ange speltest även när mocktest passerar.

## Vad som hör hemma i repot

Källkod, TOC, tester, dokumentation, licens och repositorykonfiguration. `.gitignore` undantar forskningskopior, backuper, ZIP, Python-cache, lokala virtuella miljöer, vanliga credentials-/envfiler, WTF/SavedVariables och lokala loggar. WoW:s installation, `WTF/`, personliga SavedVariables, tokenfiler, `.env` och lokala virtuella miljöer hör inte hit. Ofarliga `.env.example` och `.env.sample` kan ingå. Använd en extern testmiljö och granska alltid vilka filer som faktiskt läggs till.

Inkludera inte tredjepartskod från forskningsmappen i en fix utan separat kontroll av rättigheter och behov. Projektets egen kod och dokumentation ligger under [MIT](LICENSE); externa länkade källor har egna villkor. Behåll upphovsrätts- och licenstexten vid distribution.

## Dokumentationens plats

`docs/` innehåller bestående dokumentation om projektets arkitektur, API-gränser, testmetod och planerade funktioner. Användarguiden ligger i `Spaghetti/docs/` så att den följer med addonpaketet. Delbara, tomma testmallar finns under `tests/manual/`. Ägarens ursprungliga ifyllda `Spaghetti_MVP_Testplan.md` är lokalt bevarad och Git-ignorerad; den ingår inte vid en normal uppladdning. Spara privata nya resultat under den ignorerade `tests/manual/local/` eller utanför repot. Publicera endast avsiktligt delade, avidentifierade resultat.

Körsammanfattningar, agentrapporter, uppdragsprompter, sessionshistorik och lokala verifieringsloggar ska sparas **utanför repot**. Lägg dem inte i `docs/`, andra mappar i repot eller nya daterade statusfiler. README och CHANGELOG ska beskriva projektet och dess förändringar, inte hur en agent utförde arbetet.
