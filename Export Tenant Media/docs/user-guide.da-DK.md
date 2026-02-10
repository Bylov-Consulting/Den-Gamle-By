# DGB Data Backup - Brugervejledning

## Indholdsfortegnelse

1. [Introduktion](#introduktion)
2. [Forudsætninger](#forudsætninger)
3. [Initial opsætning](#initial-opsætning)
4. [Konfiguration af tabeleksporter](#konfiguration-af-tabeleksporter)
5. [Eksportering af billeder](#eksportering-af-billeder)
6. [Visning af eksporthistorik](#visning-af-eksporthistorik)
7. [Fejlfinding](#fejlfinding)
8. [Ofte stillede spørgsmål](#ofte-stillede-spørgsmål)

---

## Introduktion

**DGB Data Backup**-udvidelsen gør det muligt at eksportere billeder og mediefiler fra enhver Business Central-tabel til ZIP-filer. Dette er nyttigt til:

- **Datasikkerhedskopiering og arkivering**
- **Migration til eksterne systemer**
- **Compliance- og revisionskrav**
- **Oprettelse af offline billedbiblioteker**

### Nøglefunktioner

✅ **Fleksibel konfiguration**: Eksporter fra enhver tabel med mediefelter  
✅ **Batch-behandling**: Håndter store datasæt effektivt  
✅ **Tilpasset filnavngivning**: Brug meningsfulde filnavne baseret på dine data  
✅ **Sporingslog**: Komplet log over alle eksporter  
✅ **Genoptag-mulighed**: Fortsæt eksporter på tværs af flere batches  
✅ **Duplikatforebyggelse**: Eksporter aldrig det samme billede to gange  

---

## Forudsætninger

### Tilladelser

Du skal have tilladelsessættet **DataBackup** (90000) for at bruge denne udvidelse.

**Sådan verificerer du tilladelser:**
1. Søg efter "Brugere" i Business Central
2. Åbn din brugerpost
3. Tjek om tilladelsessættet "DataBackup" er tildelt
4. Kontakt din administrator, hvis du ikke har adgang

### Datakrav

Kildetabellen skal have:
- Mindst ét **Media**- eller **MediaSet**-felt, der indeholder billeder
- Feltet **SystemId** (tilgængeligt på alle BC-tabeller)

---

## Initial opsætning

### Trin 1: Åbn Media Export Setup

1. Brug søgefunktionen (Alt+Q / Cmd+Q)
2. Skriv **"Media Export Setup"**
3. Åbn siden

![Søg efter Media Export Setup](images/search-setup.png)

### Trin 2: Konfigurer globale indstillinger

![Media Export Setup-side](images/setup-page.png)

#### Batchstørrelse

**Hvad den gør**: Styrer hvor mange poster, der behandles i hver eksportbatch.

**Anbefalede værdier**:
- **Små datasæt (< 100 poster)**: 50-100
- **Mellemstore datasæt (100-1000 poster)**: 25-50
- **Store datasæt (> 1000 poster)**: 10-25

**Eksempel**: Hvis du sætter Batchstørrelse til 50 og har 150 billeder:
- Første batch: 50 billeder → ZIP-fil downloades
- Anden batch: 50 billeder → ZIP-fil downloades
- Tredje batch: 50 billeder → ZIP-fil downloades

> **💡 Tip**: Start med 50 og juster baseret på din netværkshastighed og filstørrelser.

#### Tillad eksportlog-sletning

**Hvad den gør**: Styrer om brugere kan slette poster fra eksportloggen.

**Hvornår skal den aktiveres**:
- Testmiljø
- Behov for at geneksportere tidligere eksporterede billeder
- Oprydning af gamle revisionsdata

**Hvornår skal den deaktiveres**:
- Produktionsmiljø
- Compliance-krav kræver revisionsspor
- Multi-bruger miljø

> **⚠️ Advarsel**: Sletning af logposter tillader, at de samme billeder eksporteres igen.

### Trin 3: Gem indstillinger

Indstillingerne gemmes automatisk, når du lukker siden.

---

## Konfiguration af tabeleksporter

Før du kan eksportere billeder, skal du konfigurere, hvilken tabel og felter der skal bruges.

### Trin 1: Åbn Media Export Configuration

1. Søg efter **"Media Export Configuration"**
2. Åbn siden

### Trin 2: Tilføj en ny konfiguration

Klik på **+ Ny** for at oprette en konfiguration.

![Ny konfiguration](images/new-configuration.png)

### Trin 3: Vælg kildetabel

1. **Table ID**: Indtast tabelnummeret eller brug opslag (F6)
   - **Table Name** vises automatisk

**Eksempel**: For tabellen "Admission Card Owner DGB" indtastes **90003**

### Trin 4: Vælg billedfelt

1. **Image Field ID**: Klik på opslagsknappen (...)
2. En liste over alle Media- og MediaSet-felter vises
3. Vælg det felt, der indeholder dine billeder
   - **Image Field Name** vises automatisk

![Feltopslag](images/field-lookup.png)

> **Felttyper**:
> - **Media**: Enkelt billede pr. post
> - **MediaSet**: Flere billeder pr. post (alle eksporteres)

### Trin 5: Konfigurer filnavngivning (valgfrit)

Som standard navngives eksporterede filer ved hjælp af postens System-ID (en GUID som `a1b2c3d4-e5f6-...`).

**For at bruge meningsfulde filnavne**:

1. **File Name Field ID**: Klik på opslagsknappen (...)
2. Vælg et Code- eller Text-felt, der indeholder unikke værdier
   - Eksempler: Debitornr., Medarbejder-ID, Varenr.
3. **File Name Field Name** vises

**Eksempel**:
- Hvis du vælger feltet "Nr." indeholdende "KORT-001"
- Eksporteret fil navngives: `KORT-001.jpg`
- I stedet for: `a7b8c9d0-1234-5678-9abc-def012345678.jpg`

> **⚠️ Vigtigt**: Hvis det valgte felt er tomt for en post, bruges System-ID som fallback.

### Trin 6: Gem konfiguration

Tryk på **Enter** eller klik væk fra rækken for at gemme.

---

## Eksportering af billeder

### Metode 1: Brug af Media Export Status (anbefales)

Denne side giver en oversigt over alle konfigurerede tabeller og deres eksportstatus.

#### Trin 1: Åbn Media Export Status

1. Søg efter **"Media Export Status"**
2. Åbn siden

![Media Export Status](images/status-overview.png)

#### Trin 2: Gennemse eksportstatus

Siden viser:

| Kolonne | Beskrivelse |
|--------|-------------|
| **Table Name** | Navn på den konfigurerede tabel |
| **Image Field Name** | Felt, der indeholder billeder |
| **File Name Field Name** | Felt brugt til filnavngivning (eller tomt for System-ID) |
| **Eligible Records Count** | Antal poster med ikke-eksporterede billeder |
| **Exported Records Count** | Samlet antal billeder allerede eksporteret |

> **Fremhævning**: Rækker med berettigede poster er fremhævet for opmærksomhed.

#### Trin 3: Opdater antal (hvis nødvendigt)

Hvis data er ændret siden åbning af siden:
- Klik på handlingen **Opdater**
- Alle antal genberegnes

#### Trin 4: Start eksport

1. Vælg den tabelrække, du vil eksportere
2. Klik på handlingen **Eksporter billeder**
3. Eksportprocessen begynder

### Metode 2: Brug af direkte tabeleksport

Du kan også tilføje eksporthandlinger direkte til kildetabelsider ved hjælp af sideudvidelser.

---

## Eksportprocessen

### Trin-for-trin flow

#### 1. Eksportinitialisering

En statusdialog vises:

```
Eksporterer billeder...
Behandlet 15 af 50
```

> Dialogen opdateres i realtid, efterhånden som billeder behandles.

#### 2. Første batch færdig

Når batchen er færdig:
- En ZIP-fil downloades automatisk
- Filnavnsformat: `Export_[TabelID]_[Antal]_[Tidsstempel].zip`
- Eksempel: `Export_90003_50_20260210143022.zip`

#### 3. Fortsæt-prompt

Efter download ser du:

```
Vil du fortsætte med at eksportere den næste batch poster?
[Ja] [Nej]
```

**Vælg**:
- **Ja**: Fortsæt med næste batch
- **Nej**: Stop eksportering

> **💡 Tip**: Det er sikkert at vælge "Nej" og genoptage senere. Allerede eksporterede billeder eksporteres ikke igen.

#### 4. Flere batches

Hvis du vælger "Ja", gentages processen:
- Statusdialog vises igen
- Næste ZIP-fil downloades
- Fortsæt-prompt vises

Dette fortsætter indtil:
- Alle berettigede poster er eksporteret, ELLER
- Du vælger "Nej" for at stoppe

### Hvad sker der under eksport

For hver post:

1. **✓ Tjek for medier**: Kun poster med billeder behandles
2. **✓ Tjek for duplikater**: Spring over, hvis allerede eksporteret (forhindrer duplikater)
3. **✓ Hent filnavn**: Brug konfigureret felt eller System-ID
4. **✓ Udtræk billede**: Konverter mediefelt til JPEG
5. **✓ Tilføj til ZIP**: Inkluder i arkiv
6. **✓ Opret logpost**: Registrer eksportdetaljer

### Forstå ZIP-filindhold

**Enkelt billede pr. post**:
```
Export_90003_50_20260210143022.zip
├── KORT-001.jpg
├── KORT-002.jpg
├── KORT-003.jpg
└── ...
```

**Flere billeder pr. post (MediaSet)**:
```
Export_90003_50_20260210143022.zip
├── KORT-001_1.jpg
├── KORT-001_2.jpg
├── KORT-001_3.jpg
├── KORT-002_1.jpg
└── ...
```

> **Bemærk**: MediaSet-billeder nummereres med suffikser `_1`, `_2`, `_3`.

---

## Visning af eksporthistorik

### Åbning af eksportloggen

1. Søg efter **"Media Export Log"**
2. Åbn siden

**Eller fra Media Export Status**:
1. Åbn **Media Export Status**
2. Vælg en tabelrække
3. Klik på handlingen **Eksportlog**
4. Loggen filtreres til den valgte tabel

### Forstå logposter

![Eksportlog](images/export-log.png)

| Kolonne | Beskrivelse |
|--------|-------------|
| **Table ID** | Kildetabelnummer |
| **System ID** | Unik postidentifikator (GUID) |
| **Record ID** | Menneskelæsbar postreference |
| **Export Timestamp** | Dato og tidspunkt for eksport |
| **Image File Name** | Navn på billede i ZIP-fil |
| **Zip File Name** | Navn på ZIP-fil, der indeholder billedet |

### Brug af loggen

**For at finde hvornår et specifikt billede blev eksporteret**:
1. Filtrer efter **Image File Name**
2. Tjek **Export Timestamp**

**For at finde alle billeder i en specifik ZIP**:
1. Filtrer efter **Zip File Name**
2. Gennemse alle poster

**For at verificere at en post blev eksporteret**:
1. Bemærk postens System-ID fra kildetabellen
2. Filtrer efter **System ID** i loggen
3. Tjek om poster findes

---

## Fejlfinding

### Problem: Ingen billeder eksporteres

**Symptomer**: Eksport færdig, men ingen filer i ZIP, eller meddelelse "Ingen billeder fundet til eksport".

**Løsninger**:

1. **Tjek om billeder findes**:
   - Åbn kildetabellen
   - Verificer at billedfeltet viser et billede
   - Hvis tomt, er der intet at eksportere

2. **Tjek om allerede eksporteret**:
   - Åbn Media Export Log
   - Filtrer efter Table ID
   - Hvis poster findes, er de allerede eksporteret
   - For at geneksportere: Slet logposter (hvis sletning er tilladt)

3. **Tjek konfiguration**:
   - Åbn Media Export Configuration
   - Verificer at Image Field ID matcher det korrekte felt
   - Brug opslag for at sikre at felt findes

### Problem: Forkerte filnavne

**Symptomer**: Filer navngivet med GUID'er i stedet for forventede værdier.

**Løsninger**:

1. **Tjek feltkonfiguration**:
   - Åbn Media Export Configuration
   - Verificer at File Name Field ID er sat
   - Sørg for at den peger på et felt med data

2. **Tjek feltværdier**:
   - Åbn kildetabel
   - Tjek om filnavnfeltet har værdier
   - Hvis tomt, bruges System-ID som fallback

3. **Felttypeproblemer**:
   - Filnavnfelt skal være Code- eller Text-type
   - Medie- eller numeriske felter virker ikke

### Problem: Eksport er langsom

**Symptomer**: Statusdialog hænger eller tager meget lang tid.

**Løsninger**:

1. **Reducer batchstørrelse**:
   - Åbn Media Export Setup
   - Sænk Batchstørrelse til 10-25
   - Mindre batches behandles hurtigere

2. **Netværksproblemer**:
   - Store billeder tager tid at downloade
   - Tjek netværksforbindelse
   - Prøv i off-peak timer

3. **Billedstørrelse**:
   - Meget store billeder (> 5MB) gør behandling langsommere
   - Overvej billedkomprimering ved kilden

### Problem: Kan ikke slette logposter

**Symptomer**: Fejl ved forsøg på at slette fra eksportlog.

**Løsninger**:

1. **Tjek sletningsindstilling**:
   - Åbn Media Export Setup
   - Aktiver "Tillad eksportlog-sletning"
   - Prøv sletning igen

2. **Tilladelser**:
   - Verificer at du har DataBackup-tilladelsessæt
   - Kontakt administrator om nødvendigt

### Problem: Eksport timeout

**Symptomer**: "Eksekveringstimeout" eller lignende fejl.

**Løsninger**:

1. **Reducer batchstørrelse betydeligt**:
   - Prøv Batchstørrelse = 5 eller 10
   - Meget store billeder kræver mindre batches

2. **Eksporter i off-peak timer**:
   - Server kan være travl
   - Prøv tidlig morgen eller sen aften

3. **Filtrer kildedata**:
   - Brug tabelfiltre til at reducere samlede poster
   - Eksporter i mindre logiske grupper

---

## Ofte stillede spørgsmål

### Generelle spørgsmål

**Sp: Kan jeg eksportere billeder fra brugerdefinerede tabeller?**  
**Sv**: Ja! Enhver tabel med Media- eller MediaSet-felter kan konfigureres til eksport.

**Sp: Vil dette slette billeder fra databasen?**  
**Sv**: Nej. Eksport opretter kopier. Kildedata ændres aldrig.

**Sp: Kan jeg eksportere de samme billeder igen?**  
**Sv**: Kun hvis du sletter logposterne (hvis tilladt). Systemet forhindrer duplikateksporter.

**Sp: Hvilket billedformat bruges?**  
**Sv**: Alle billeder eksporteres som JPEG (.jpg)-filer.

**Sp: Er der en grænse for hvor mange billeder jeg kan eksportere?**  
**Sv**: Ingen hård grænse, men batch-behandling anbefales til store datasæt.

### Konfigurationsspørgsmål

**Sp: Kan jeg konfigurere flere tabeller?**  
**Sv**: Ja! Opret separate konfigurationer for hver tabel.

**Sp: Hvad hvis jeg ikke kender mit tabel-ID?**  
**Sv**: Brug opslag (F6) på Table ID-feltet til at søge efter navn.

**Sp: Kan jeg ændre konfiguration efter eksportering?**  
**Sv**: Ja, men det påvirker ikke allerede eksporterede billeder. Fremtidige eksporter bruger nye indstillinger.

**Sp: Skal jeg have et filnavnfelt?**  
**Sv**: Nej, det er valgfrit. System-ID bruges, hvis ikke angivet.

### Eksportspørgsmål

**Sp: Hvor går ZIP-filer hen?**  
**Sv**: Til din browsers download-mappe (samme som enhver webdownload).

**Sp: Kan jeg pause og genoptage en eksport?**  
**Sv**: Ja! Vælg "Nej" når du bliver spurgt om at fortsætte, kør derefter eksport igen senere.

**Sp: Vil stopning midt i eksport miste min fremgang?**  
**Sv**: Nej. Allerede eksporterede billeder logges og eksporteres ikke igen.

**Sp: Kan flere brugere eksportere samtidigt?**  
**Sv**: Ja, men de bør eksportere fra forskellige tabeller for at undgå konflikter.

### Tekniske spørgsmål

**Sp: Hvad er System-ID?**  
**Sv**: En unik GUID tildelt hver post i Business Central. Bruges til pålidelig postidentifikation.

**Sp: Hvad sker der med MediaSet-felter?**  
**Sv**: Alle billeder i sættet eksporteres med nummererede suffikser (_1, _2, _3, osv.).

**Sp: Kan jeg planlægge automatiske eksporter?**  
**Sv**: Ikke i øjeblikket. Dette er en manuel proces. Kontakt Bylov Consulting for brugerdefinerede løsninger.

**Sp: Er eksporter komprimerede?**  
**Sv**: Ja, alle billeder pakkes i ZIP-format til effektiv download.

---

## Bedste praksis

### ✅ Gør dette

- **Test med små batches først** før eksport af store datasæt
- **Brug meningsfulde filnavnfelter** når tilgængelige
- **Hold batchstørrelse rimelig** (25-50 for de fleste tilfælde)
- **Overvåg berettigede vs. eksporterede antal** for at spore fremskridt
- **Gennemse eksportlog regelmæssigt** til revisionsformål
- **Dokumenter dine konfigurationer** til teammedlemmer

### ❌ Gør ikke dette

- **Slet ikke logposter i produktion** uden god grund
- **Brug ikke store batchstørrelser** (> 100) med højtopløselige billeder
- **Konfigurer ikke samme tabel to gange** med forskellige indstillinger
- **Eksporter ikke i spidsbelastningstimer** for store datasæt
- **Ignorer ikke fejlmeddelelser** - de giver vigtig information

---

## Få hjælp

### Supportressourcer

- **Teknisk dokumentation**: Se `technical-design.da-DK.md` i docs-mappen
- **Kontakt**: Bylov Consulting
- **Version**: 1.2.0.0

### Rapportering af problemer

Når du rapporterer problemer, inkluder:
1. Tabel-ID, der eksporteres
2. Omtrentligt antal poster
3. Batchstørrelse-indstilling
4. Fejlmeddelelse (hvis nogen)
5. Trin til at genskabe

---

## Bilag: Almindelige tabel-ID'er

| Tabelnavn | Tabel-ID |
|------------|----------|
| Admission Card Owner DGB | 90003 |
| Debitor | 18 |
| Kreditor | 23 |
| Vare | 27 |
| Medarbejder | 5200 |

> **Bemærk**: Dine brugerdefinerede tabeller har ID'er i dit tildelte område.

---

**Dokumentversion**: 1.0  
**Senest opdateret**: Februar 2026  
**Til udvidelsesversion**: 1.2.0.0  
**Udgiver**: Bylov Consulting
