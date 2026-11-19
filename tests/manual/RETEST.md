# Fokuserade manuella återtest

Använd tillsammans med den [tomma MVP-testmallen](MVP_TEST_PLAN.md). Prova efter att testkopian laddats med full omstart. Anteckna build, språk, UI-skala, övriga addons och eventuell Lua-/skyddsfeltext. Ingen av kontrollerna är ännu spelgodkänd.

Datum: ______ · Klient/build: ______ · Testkopia/ändringsidentifiering: ______ · Övriga addons/UI-skala: ______

## 1. T08 efter combat, editor kvar öppen

Använd eget skapat, synkat testmacro med Macro Action Created. Öppna grafen, gå in i combat och försök dra ikonen; skapa/uppdatera får inte fungera då. Lämna combat med editorn **fortfarande öppen**, utan grafbyte, reopen, Apply eller reload. Läs separat övre notisrad, validation och Macro Action; prova sedan att dra samma macro till ett ledigt action bar-fack.

Förväntat: blockerat under combat, sedan aktuell Created/status och dragning efter att native lockdown har släppt. Det gamla combatfelet ska inte stå kvar som aktuell notis. Ny combat blockerar igen. Anteckna om bara texten eller även handlingen avviker.

Utfall: ______ · Status/dragning/Lua-fel: ______

## 2. T16 klickbar reminder efter combat

Använd Player Value → Show Condition med Enabled/Clickable på och en egen ofarlig, tillåten självbuff vald som ikon och castspell. Apply utanför combat. Stäng editorn och prova klick med resurs/GCD redo. Gå in och ur combat; prova samma synliga ikon igen utan ny Apply/reload. Avsluta med No icon och Apply; kontrollera att den gamla ikonplatsen inte castar. Preview/placering ska inte kasta.

Förväntat: cast från verkligt klick utanför combat före och efter; ingen klickcast eller skyddsfelsvarning i combat, inga osynliga targets eller castande provytor. Notera handling vid knappnedtryck, spell och eventuella resurs-/GCD-hinder.

Utfall: ______ · Spell/knappinställning/Lua-fel: ______

## 3. Nodbibliotekets hover/leave

Notera bibliotekstext utan mus över. Hovra och lämna flera rader upprepade gånger, byt graf och växla Reminder / CD ↔ Macro, och upprepa på återanvända rader.

Förväntat: vit normalt, gul bara under hover, vit efter leave även efter byte. Övriga knappar ska behålla sin befintliga stil.

Utfall: ______ · Färg/bild/Lua-fel: ______
