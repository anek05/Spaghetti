# Lägg upp Spaghetti på GitHub

1. Skapa ett **tomt repository** i ditt GitHub-konto. Välj Public eller Private. Lägg inte till README, licens eller gitignore via GitHub; de finns redan i projektet.
2. Öppna PowerShell i projektroten och kör:

```powershell
Set-Location 'C:\Users\Andreas\Documents\ChatGPT\Spaghetti'
git branch -M main
git add .
git commit -m "Initial Spaghetti development version"
$spaghettiRepoUrl = Read-Host 'Klistra in GitHub-URL till det tomma repo du skapade'
git remote add origin $spaghettiRepoUrl
git push -u origin main
```

Git kan be dig logga in på GitHub eller konfigurera ditt Git-namn och din e-post om detta inte redan är gjort. Använd dina egna uppgifter.

3. Öppna repot på GitHub och kontrollera den första **Actions**-körningen för Windows och Linux. Dessa jobb blir verifierade först när de faktiskt körts.
4. Bjud vid behov in medutvecklaren under repots Settings → Collaborators.

Den ifyllda originaltestplanen ligger kvar lokalt och är Git-ignorerad; den tomma offentliga mallen följer med. Lokala backuper, ZIP, forskningskopior och WoW-profiler är också undantagna. Ingen extra filstädning behövs för stegen ovan.
