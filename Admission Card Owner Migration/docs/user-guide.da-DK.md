# Admission Card Owner Migration - Brugervejledning

## Introduktion

Denne vejledning forklarer, hvordan du bruger Admission Card Owner Migration-udvidelsen til at kopiere dine admission card owner-data fra det oprindelige JCD Retail - Admission-system til det nye DGB Data Backup-system.

### Hvad denne udvidelse gør

Admission Card Owner Migration-udvidelsen:
- Kopierer alle admission card owner-poster fra den gamle tabel til den nye tabel
- Kopierer alle billeder og opretter uafhængige mediefiler
- Forhindrer duplikatposter
- Viser realtidsfremskridt under migrering
- Tillader dig at prøve igen om nødvendigt uden at oprette duplikater

### Hvornår skal denne udvidelse bruges

Brug dette migreringsværktøj når:
- Du skifter fra JCD Retail - Admission til DGB Data Backup
- Du skal bevare alle admission card owner-data og billeder
- Du ønsker en engangsbulkkopieringsoperation
- Du skal migrere få eller mange poster (virker for begge)

### Hvad du skal bruge før start

**Påkrævet**:
- Begge udvidelser installeret:
  - JCD Retail - Admission (kildesystem)
  - DGB Data Backup (destinationssystem)
- Passende tilladelser til begge tabeller
- Poster i "Admission Card Owner"-tabellen til migrering

**Anbefalet**:
- Database-sikkerhedskopi (især til store migre ringer)
- Migrering i off-peak timer (for > 1000 poster)
- Et par minutters uafbrudt tid

---

## Lynstartvejledning

### Migrering i 3 simple trin

1. **Åbn destinationssiden**: Søg efter "Admission Card Owners DGB"
2. **Klik på handlingen**: Vælg "Kopier til DGB-tabel" fra båndet
3. **Vent på færdiggørelse**: Se fremskridtsdialogen og vis resultaterne

Det er det! Migreringen håndterer alt automatisk.

---

## Detaljerede migre ringsprocedurer

### Mulighed 1: Bulk-migrering (alle poster)

Brug denne tilgang til at kopiere alle admission card owners på én gang.

#### Trin-for-trin instruktioner

**Trin 1: Åbn Admission Card Owners DGB-side**

1. Tryk på `Alt + Q` for at åbne søgeboksen
2. Skriv: `Admission Card Owners DGB`
3. Tryk på `Enter` eller klik på resultatet

eller

1. Naviger gennem menuen:
   - Hovedmenu → DGB Data Backup → Admission Card Owners DGB

**Trin 2: Start migreringen**

1. I båndmenuen klik på `Handlinger` → `Funktioner`
2. Klik på `Kopier til DGB-tabel`
3. Fremskridtsdialogen vises straks

**Trin 3: Overvåg fremskridt**

En fremskridtsdialog viser realtidsinformation:

```
Kopierer poster...

Behandlet 237 af 450. Fremskridt: 52%

Kopieret: 215 | Sprunget over: 20 | Fejlet: 2
```

**Hvad tallene betyder**:
- **Behandlet**: Hvor mange poster der er blevet gennemgået
- **Kopieret**: Succesfuldt kopierede nye poster
- **Sprunget over**: Poster, der allerede fandtes (ingen handling nødvendig)
- **Fejlet**: Poster, der ikke kunne kopieres (sjældent)

**Trin 4: Gennemse resultater**

Når færdig, ser du en resumémeddelelse:

```
Migrering færdig!
Kopieret: 215 poster
Sprunget over: 20 poster
Fejlet: 2 poster
```

**Forstå resultaterne**:

| Antal | Betydning | Handling nødvendig |
|-------|---------|---------------|
| Kopieret | Nye poster succesfuldt migreret | ✅ Ingen |
| Sprunget over | Poster findes allerede i destination | ✅ Ingen (sikkert at ignorere) |
| Fejlet | Poster kunne ikke kopieres | ⚠️ Undersøg (se Fejlfinding) |

#### Hvor lang tid tager det?

| Antal poster | Estimeret tid |
|-------------------|---------------|
| 1-100 | Mindre end 1 minut |
| 100-500 | 1-5 minutter |
| 500-1000 | 5-10 minutter |
| 1000-5000 | 10-50 minutter |
| 5000+ | Mere end 1 time |

**Tip**: Migreringstiden stiger hvis poster har store billeder.

---

### Mulighed 2: Enkeltpost-migrering

Brug denne tilgang til at kopiere en specifik admission card owner.

#### Hvornår skal enkeltpost-migrering bruges

- Du skal kun migrere én ny person
- Du vil prøve en specifik fejlet post igen
- Du tester migreringen før bulk-kørsel

#### Trin-for-trin instruktioner

**Trin 1: Få kortejerens nummer**

1. Åbn "Admission Card Owners" (kildetabel)
2. Find den post, du vil kopiere
3. Bemærk "Nr."-feltets værdi (f.eks. "00001234")

**Trin 2: Udløs enkelt kopi**

Dette kræver en tilpasset handling eller brug af codeunit direkte fra kode.

**Fra AL-kode**:
```al
var
    Migration: Codeunit "Admission Card Owner Migration";
    CardOwnerNo: Code[20];
begin
    CardOwnerNo := '00001234';  // Erstat med faktisk nummer
    if Migration.CopySingleToDGBTable(CardOwnerNo) then
        Message('Post kopieret succesfuldt')
    else
        Message('Post kunne ikke kopieres');
end;
```

**Bemærk**: Enkeltpostkopi er primært til udvikling/test. Til normal brug anbefales bulk-migrering.

---

## Efter migrering

### Verificer migreringen

Følg disse trin for at sikre, at alt blev kopieret korrekt:

**Trin 1: Tjek postantal**

1. **Tæl kildeposter**:
   - Åbn "Admission Card Owners"
   - Se nederst til højre for samlet antal
   - Bemærk nummeret (f.eks. 450)

2. **Tæl destinationsposter**:
   - Åbn "Admission Card Owners DGB"
   - Se nederst til højre for samlet antal
   - Bør matche kildeantal (minus eventuelle præ-eksisterende poster)

**Trin 2: Tjek forventede antal**

```
Kildeposter: 450
Destinationsposter før: 20
Kopieret under migrering: 215
Sprunget over under migrering: 20
Fejlet under migrering: 2

Forventet destinationsantal: 20 + 215 = 235 ✅
(450 - 215 = 235 ikke kopieret: 20 sprunget over + 2 fejlet + 213 der fandtes før)
```

**Trin 3: Stikprøvekontroller data**

Vælg et par tilfældige poster og verificer:

1. **Basisdata**:
   - Åbn en post i kildetabel
   - Åbn samme post (efter Nr.) i destinationstabel
   - Sammenlign: Fornavn, Efternavn, E-mail, Telefon, osv.
   - Bør være identiske

2. **Billeder**:
   - Tjek at billeder vises i destinationsposter
   - Verificer billeder matcher kilden
   - Billeder bør være synlige, selvom du sletter fra kilde (uafhængige kopier)

---

## Almindelige scenarier

### Scenarie 1: Første gangs migrering

**Situation**: Du har netop installeret DGB Data Backup og skal migrere alle historiske data.

**Trin**:
1. Sikkerhedskopier din database
2. Brug bulk-migrering (Mulighed 1)
3. Alle poster kopieres (Sprunget over-antal bør være 0 eller meget lavt)
4. Verificer antal og stikprøvekontrol
5. Begynd at bruge DGB Data Backup

**Forventet resultat**: 
- Kopieret: ~alle poster
- Sprunget over: 0-5
- Fejlet: 0

---

### Scenarie 2: Tilføjelse af nye poster efter initial migrering

**Situation**: Du migrerede for måneder siden, og har nu nye admission card owners at migrere.

**Trin**:
1. Brug bulk-migrering (Mulighed 1)
2. Tidligere migrerede poster springes automatisk over
3. Kun nye poster kopieres

**Forventet resultat**:
- Kopieret: Antal nye poster
- Sprunget over: Alle tidligere migrerede poster
- Fejlet: 0

**Hvorfor det virker**: Migreringen tjekker om hver post allerede findes og springer den over. Sikkert at køre flere gange.

---

### Scenarie 3: Migrering fejlede halvvejs

**Situation**: Migrering blev afbrudt (strømafbrydelse, systemnedbrud, bruger annullerede).

**Trin**:
1. Kør migreringen igen (Mulighed 1)
2. Allerede kopierede poster springes over
3. Resterende poster kopieres

**Forventet resultat**: 
- Kopieret: Resterende poster ikke kopieret endnu
- Sprunget over: Poster kopieret før afbrydelse
- Fejlet: 0 (medmindre dataproblemer findes)

**Vigtigt**: Migreringen committer hver 100. post, så det meste fremskridt gemmes, selvom den afbrydes.

---

### Scenarie 4: Nogle poster fejlede

**Situation**: Migrering færdig, men et par poster fejlede.

**Trin**:
1. Bemærk fejltællingen (f.eks. "Fejlet: 3")
2. Identificer hvilke poster der fejlede (tjek destination for manglende numre)
3. Tjek kildeposter for dataproblemer
4. Ret eventuelle dataproblemer
5. Kør migrering igen (springer succesfulde poster over, prøver fejlede igen)

**Almindelige årsager til fejl**:
- Ugyldige data i kildefelter
- Systemtilladelsesproblem er
- Korrupte billeddata

---

## Ofte stillede spørgsmål (FAQ)

### Generelle spørgsmål

**Sp: Kan jeg køre migreringen flere gange?**  
**Sv**: Ja! Migreringen springer automatisk over poster, der allerede findes. Det er helt sikkert at køre gentagne gange.

**Sp: Vil denne migrering påvirke mine kildedata?**  
**Sv**: Nej. Kilde-"Admission Card Owner"-tabellen læses kun fra, aldrig ændret eller slettet.

**Sp: Hvad sker der hvis jeg annullerer migreringen halvvejs?**  
**Sv**: Poster kopieret før annullering forbliver i destinationen. Migreringen committer hver 100. post, så du mister ikke meget fremskridt. Kør bare igen for at fortsætte.

**Sp: Kan jeg fortryde migreringen?**  
**Sv**: Ikke automatisk. Du skal manuelt slette poster fra "Admission Card Owner DGB"-tabellen eller gendanne fra sikkerhedskopi.

### Billedspørgsmål

**Sp: Tager billeder ekstra tid at migrere?**  
**Sv**: Ja, lidt. Større billeder tager længere tid at kopiere. De fleste billeder kopieres på < 1 sekund hver.

**Sp: Er billeder delt mellem kilde og destination?**  
**Sv**: Nej! Migreringen opretter uafhængige kopier. Du kan sikkert slette kildeposter uden at påvirke destinationsbilleder.

**Sp: Hvad hvis en kortejer ikke har et billede?**  
**Sv**: Intet problem. Migreringen håndterer tomme billeder elegant og kopierer bare datafelterne.

**Sp: Vil billedkvaliteten blive påvirket?**  
**Sv**: Nej. Billeder kopieres i fuld kvalitet ved hjælp af binær stream-overførsel.

### Tekniske spørgsmål

**Sp: Hvad sker der hvis destinationsposten allerede findes, men har forskellige data?**  
**Sv**: Den eksisterende destinationspost efterlades uændret. Migreringen opretter kun nye poster; den opdaterer aldrig eksisterende.

**Sp: Kan andre brugere arbejde i Business Central under migrering?**  
**Sv**: Ja, men til store migre ringer (> 1000 poster) anbefales off-peak timer for bedre ydeevne.

**Sp: Hvor meget diskplads kræves til migrerede billeder?**  
**Sv**: Samme som kildebilleder (uafhængige kopier oprettes). Hvis kildebilleder i alt er 500 MB, bruger destination yderligere 500 MB.

**Sp: Kan jeg kun migrere specifikke poster (f.eks. efter debitor)?**  
**Sv**: Ikke med standard bulk-migrering. Dette kræver brugerdefineret udvikling eller manuel enkeltpostkopie ring.

### Fejlspørgsmål

**Sp: Hvad betyder "Post findes allerede"?**  
**Sv**: Destinationstabellen har allerede en post med det "Nr." Dette tælles som "Sprunget over", ikke en fejl. Den eksisterende post bevares.

**Sp: Hvorfor ville poster ikke kunne kopieres?**  
**Sv**: Sjældent, men mulige årsager inkluderer:
- Datavalideringsfejl
- Tilladelsesproblem er
- Systemressourcer udmattede
- Korrupte billeddata

**Sp: Hvordan finder jeg ud af hvilke specifikke poster der fejlede?**  
**Sv**: Sammenlign postantal eller tjek manuelt for manglende poster i destinationstabellen. Fremtidige versioner kan inkludere detaljerede fejllogs.

---

## Fejlfinding

### Problem: "Tabel ikke fundet"-fejl

**Symptomer**: Fejlmeddelelse når der forsøges at kopiere

**Mulige årsager**:
- DGB Data Backup-udvidelse ikke installeret
- JCD Retail - Admission-udvidelse ikke installeret
- Udvidelser ikke aktiveret for dit firma

**Løsninger**:
1. Verificer begge udvidelser installeret:
   - Åbn Udvidelsesstyring
   - Søg efter "DGB Data Backup" → Bør vises som Installeret
   - Søg efter "JCD Retail - Admission" → Bør vises som Installeret
2. Aktiver udvidelser for dit firma om nødvendigt
3. Tjek med systemadministrator hvis problemerne fortsætter

---

### Problem: Alle poster vises som "Sprunget over"

**Symptomer**: Migrering færdig straks, alle poster sprunget over, Kopieret antal = 0

**Mulige årsager**:
- Poster er allerede blevet migreret
- Du kører migrering på et allerede migreret datasæt

**Løsninger**:
1. **Dette er normalt ikke et problem!** Det betyder, at alle poster allerede findes i destinationen.
2. Tjek destinationstabel for poster
3. For at gen-migrere (overskrive):
   - Slet poster fra "Admission Card Owner DGB"-tabel
   - Kør migrering igen

**Hvornår er dette forventet**:
- Kørsel af migrering anden gang
- Test af migrering flere gange

---

### Problem: Højt antal fejlede poster

**Symptomer**: Mange poster fejler at kopiere (f.eks. Fejlet: 50 ud af 500)

**Mulige årsager**:
- Datakvalitetsproblemer i kildetabel
- Systemtilladelsesproblem er
- Database-begrænsninger

**Løsninger**:
1. **Identificer fejlede poster**:
   - Sammenlign kilde- og destinations-postnumre
   - Led efter huller i destination (manglende numre)

2. **Tjek kildedata**:
   - Åbn fejlede poster i kildetabel
   - Led efter usædvanlige eller ugyldige data
   - Tjek for meget store billedfiler

3. **Tjek tilladelser**:
   - Sørg for at du har Insert-tilladelse på destinationstabel
   - Verificer tabeltilladelser i Udvidelsesstyring

4. **Prøv igen efter rettelser**:
   - Ret eventuelle identificerede dataproblemer
   - Kør migrering igen (prøver kun fejlede poster)

5. **Kontakt support**:
   - Hvis problemet fortsætter med rene data
   - Angiv fejltælling og eksempel-postnumre

---

### Problem: Migrering meget langsom

**Symptomer**: Migrering tager meget længere tid end forventet

**Mulige årsager**:
- Store billedfiler
- Høj serverbelastning
- Netværkslatens (cloud-miljø)
- Database-ydeevneproblemer

**Løsninger**:
1. **Vær tålmodig**: Store billeder kan tage tid
2. **Kør i off-peak timer**: Mindre serverbelastning = hurtigere migrering
3. **Tjek serverressourcer**: CPU, hukommelse, disk I/O
4. **Annuller ikke**: Annullering og genstart spilder tid
5. **Overvej etapeinddeling**: Hvis > 5000 poster, overvej at migrere i batches

**Ydel sestips**:
- Kør migre ringer i lavbrugsperioder
- Luk unødvendige programmer på server
- Sørg for god netværksforbindelse
- Tillad uafbrudt tid

---

### Problem: Billeder mangler efter migrering

**Symptomer**: Poster kopieret succesfuldt, men billeder vises ikke i destination

**Mulige årsager**:
- Kildeposter havde ingen billeder
- Billedkopi fejlede (men post kopieret)
- Billedrenderingsproblem

**Løsninger**:
1. **Tjek kildeposter**:
   - Åbn kilde-"Admission Card Owner"
   - Verificer poster faktisk har billeder
   - Hvis kilde ikke har billede, vil destination heller ikke

2. **Tjek for specifikke fejl**:
   - Se på Fejlet-antal
   - Hvis kun få poster: kan være individuelle billedproblemer
   - Kør migrering igen for at prøve igen

3. **Verificer destinationsvisning**:
   - Opdater destinationssiden
   - Tjek om Picture FactBox er synlig
   - Prøv at se i forskellige sidelayouts

4. **Test ny upload**:
   - Upload et testbillede til en destinationspost
   - Hvis dette virker, migrering færdig, men kilde var tom
   - Hvis dette fejler, tjek tilladelser på medielagring

---

### Problem: "Kopierer poster"-dialog lukker ikke

**Symptomer**: Fremskridtsdialog frosset på skærmen efter migrering færdig

**Mulige årsager**:
- UI-renderingsproblem
- Baggrundsproces kører stadig

**Løsninger**:
1. **Vent et par sekunder**: Kan være ved at afslutte
2. **Klik OK**: Dialog bør lukke
3. **Opdater side**: Luk og genåbn "Admission Card Owners DGB"
4. **Tjek om migrering færdig**:
   - Sammenlign postantal
   - Led efter resumémeddelelse
5. **Hvis virkelig fastlåst**:
   - Luk Business Central-webklient
   - Genåbn og verificer migre ringsresultater

---

## Bedste praksis

### Før migrering

✅ **Gør dette**:
- Sikkerhedskopier din database
- Tæl kildeposter til sammenligning
- Planlæg tilstrækkelig tid (skynd dig ikke)
- Kør i off-peak timer for store datasæt
- Verificer begge udvidelser installeret

❌ **Gør ikke dette**:
- Migrer i spidsbelastningstimer (> 1000 poster)
- Start migrering uden sikkerhedskopi (for store datasæt)
- Luk dialog eller browser under migrering
- Antag alle poster skal have billeder

---

### Under migrering

✅ **Gør dette**:
- Se fremskridtsdialogen
- Bemærk de endelige antal (Kopieret/Sprunget over/Fejlet)
- Lad den fuldføre uafbrudt

❌ **Gør ikke dette**:
- Annuller medmindre absolut nødvendigt
- Luk browseren eller Business Central
- Modificer kilde- eller destinationstabeller
- Kør flere migre ringer samtidigt

---

### Efter migrering

✅ **Gør dette**:
- Verificer postantal matcher forventninger
- Stikprøvekontroller flere poster
- Test eksportfunktionalitet (hvis du bruger DGB Data Backup)
- Dokumenter resultater (Kopieret/Sprunget over/Fejlet antal)
- Behold kildedata i nogen tid som sikkerhedskopi

❌ **Gør ikke dette**:
- Slet kildedata straks
- Antag migrering er perfekt uden verificering
- Ignorer fejlede poster (undersøg)
- Kør migrering igen medmindre nødvendigt (spilder tid)

---

## Yderligere ressourcer

### Relaterede udvidelser

- **DGB Data Backup**: Destinationssystemet med eksportkapaciteter (Påkrævet)
  - Se: DGB Data Backup Brugervejledning
- **JCD Retail - Admission**: Kildesystemet (Påkrævet)

### Få hjælp

**Til migre ringsspørgsmål**:
- Gennemse denne brugervejledning
- Tjek Fejlfinding-sektionen
- Kontakt din Business Central-administrator

**Til tekniske problemer**:
- Kontakt Bylov Consulting support
- Angiv:
  - Antal poster (kilde og destination)
  - Kopieret/Sprunget over/Fejlet antal
  - Eventuelle fejlmeddelelser
  - Skærmbilleder af problemer

### Videre læsning

- [Teknisk designdokument](technical-design.da-DK.md) - Detaljeret arkitektur og algoritmer
- DGB Data Backup Brugervejledning - Hvordan man bruger eksportfunktionaliteten
- Business Central Dokumentation - Arbejde med mediefelter

---

## Bilag: Migreringstjekliste

Brug denne tjekliste til at sikre en glat migrering:

### Før-migreringsfunktionelt tjekliste

- [ ] Begge udvidelser installeret og aktiveret
- [ ] Database-sikkerhedskopi færdig (for store migre ringer)
- [ ] Kildepostantal dokumenteret: ___________
- [ ] Destinationspostantal dokumenteret: ___________
- [ ] Tilstrækkelig tid allokeret baseret på postantal
- [ ] Migrering planlagt i off-peak timer (hvis > 1000 poster)

### Migreringstjekliste

- [ ] Åbn "Admission Card Owners DGB"-side
- [ ] Klik "Kopier til DGB-tabel"
- [ ] Overvåg fremskridtsdialog
- [ ] Bemærk endelige antal:
  - Kopieret: ___________
  - Sprunget over: ___________
  - Fejlet: ___________
- [ ] Fremskridtsdialog lukket succesfuldt

### Efter-migreringsfunktionelt tjekliste

- [ ] Destinationspostantal matcher forventning
- [ ] Beregning verificeret:
  - Tidligere destinationsantal: ___________
  - + Kopieret antal: ___________
  - = Nyt destinationsantal: ___________
- [ ] Stikprøvekontrolleret 5-10 tilfældige poster
- [ ] Verificeret billeder synlige i destination
- [ ] Testet DGB Data Backup-eksport (hvis relevant)
- [ ] Undersøgt eventuelle fejlede poster
- [ ] Dokumenteret migre ringsresultater
- [ ] Informeret brugere migrering færdig

---

**Dokumentversion**: 1.2.0  
**Senest opdateret**: Februar 2026  
**Udgiver**: Bylov Consulting  
**Support**: Kontakt din Business Central-administrator eller Bylov Consulting

**Bemærk**: Denne vejledning er til Admission Card Owner Migration-udvidelsen. For dokumentation om brug af DGB Data Backup-eksportfunktionerne, se DGB Data Backup Brugervejledning.
