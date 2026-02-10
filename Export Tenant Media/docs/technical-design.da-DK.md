# DGB Data Backup - Teknisk Design

## Oversigt

DGB Data Backup-udvidelsen tilbyder en fleksibel, konfigurerbar ramme til eksport af medier (billeder) fra enhver Business Central-tabel til ZIP-filer. Systemet er designet til at håndtere store datasæt gennem batch-behandling og vedligeholder et omfattende sporingslog over alle eksporter.

## Arkitektur

### Komponentoversigt

```
┌─────────────────────────────────────────────────────────┐
│                   Brugergrænseflader                     │
├─────────────────────────────────────────────────────────┤
│  • Media Export Status (Oversigt & eksportudløser)      │
│  • Media Export Configuration (Opsætning pr. tabel)     │
│  • Media Export Setup (Global konfiguration)            │
│  • Media Export Log (Sporingslog)                       │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                 Forretningslogiklag                      │
├─────────────────────────────────────────────────────────┤
│  Media Export Mgt. Codeunit                             │
│  • Batch-behandlingsmotor                               │
│  • Dynamisk tabeladgang (RecordRef)                     │
│  • Medieekstraktion & ZIP-oprettelse                    │
│  • Eksportlogning                                       │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                    Datalag                               │
├─────────────────────────────────────────────────────────┤
│  • Media Export Configuration (Tabel 90004)             │
│  • Media Export Log (Tabel 90005)                       │
│  • Media Export Setup (Tabel 90006)                     │
└─────────────────────────────────────────────────────────┘
```

## Datamodel

### Entity Relationship Diagram

```
┌─────────────────────────────┐
│  Media Export Setup         │
│  (Singleton)                │
├─────────────────────────────┤
│  PK: (blank)                │
│  Batchstørrelse             │
│  Tillad log-sletning        │
└─────────────────────────────┘
                ↓ Refereret af
┌─────────────────────────────┐      1:N      ┌─────────────────────────────┐
│ Media Export Configuration  │───────────────→│    Media Export Log         │
├─────────────────────────────┤                ├─────────────────────────────┤
│  PK: Tabel-ID               │                │  PK: Tabel-ID +             │
│  Billedfelt-ID              │                │      System-ID +            │
│  Filnavnfelt-ID             │                │      Billedfilnavn          │
│  Antal berettigede poster   │                │  Eksporttidsstempel         │
│  Antal eksporterede poster  │                │  ZIP-filnavn                │
└─────────────────────────────┘                └─────────────────────────────┘
        ↓ Peger på enhver BC-tabel
┌─────────────────────────────┐
│   Enhver Business Central   │
│   tabel med mediefelt       │
│   (f.eks. Admission Card    │
│    Owner DGB)               │
└─────────────────────────────┘
```

### Tabeldefinitioner

#### 1. Media Export Configuration (90004)

**Formål**: Gemmer eksportkonfiguration for hver tabel, der indeholder medier til eksport.

| Felt # | Feltnavn | Type | Beskrivelse |
|---------|-----------|------|-------------|
| 1 | Table ID | Integer | Primærnøgle. ID'et for kildetabellen |
| 2 | Table Name | Text[100] | FlowField. Visningsnavn for tabellen |
| 3 | Image Field ID | Integer | Feltnummer for Media/MediaSet-feltet |
| 4 | Image Field Name | Text[100] | FlowField. Visningsnavn for mediefeltet |
| 5 | File Name Field ID | Integer | Valgfrit. Felt til brug for filnavngivning |
| 6 | File Name Field Name | Text[100] | FlowField. Visningsnavn for filnavnfeltet |
| 7 | Eligible Records Count | Integer | Cachet antal ikke-eksporterede poster |
| 8 | Exported Records Count | Integer | FlowField. Samlet antal eksporterede poster |

**Nøgle**: Primærnøgle (Table ID)

**Feltrelationer**:
- `Table ID` → AllObjWithCaption (Tabelliste)
- `Image Field ID` → Felttabel (filtreret til Media/MediaSet-typer)
- `File Name Field ID` → Felttabel (filtreret til Code/Text-typer)

#### 2. Media Export Log (90005)

**Formål**: Sporingslog over alle eksporterede billeder.

| Felt # | Feltnavn | Type | Beskrivelse |
|---------|-----------|------|-------------|
| 1 | Table ID | Integer | Del af PK. Kildetabel-ID |
| 2 | System ID | Guid | Del af PK. Postens SystemId |
| 3 | Export Timestamp | DateTime | Hvornår eksporten fandt sted |
| 4 | Zip File Name | Text[250] | Navn på ZIP-fil, der indeholder dette billede |
| 5 | Image File Name | Text[250] | Del af PK. Navn på billede i ZIP |

**Nøgle**: Primærnøgle (Table ID, System ID, Image File Name)

**Anvendelse**: 
- Forhindrer duplikateksporter
- Giver revisionsmulighed
- Linker eksporterede filer til kildeposter

#### 3. Media Export Setup (90006)

**Formål**: Globale konfigurationsindstillinger (singleton-mønster).

| Felt # | Feltnavn | Type | Beskrivelse |
|---------|-----------|------|-------------|
| 1 | Primary Key | Code[10] | Altid blank (singleton) |
| 2 | Batch Size | Integer | Poster pr. eksportbatch |
| 3 | Allow Export Log Deletion | Boolean | Kontrol af tilladelse til log-sletning |

**Nøgle**: Primærnøgle (Primary Key)

**Singleton-mønster**: Bruger blank primærnøgle. Enkelt post tilgås via `Get()` uden parametre.

## Behandlingslogik

### Eksportflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Brugerhandling: Eksporter billeder                      │
│    (Fra Media Export Status-side)                           │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Indlæs konfiguration                                     │
│    • Hent eksportkonfiguration for tabel                    │
│    • Hent batchstørrelse fra Media Export Setup             │
│    • Tæl berettigede poster                                 │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Batch-loop (mens berettigede poster > 0)                │
│    ┌───────────────────────────────────────────────────┐   │
│    │ 3.1 Udfør enkelt batch                            │   │
│    │     • Åbn kildetabel med RecordRef                │   │
│    │     • Filtrer poster (SystemId > LastSystemId)    │   │
│    │     • Behandl op til [Batchstørrelse] poster      │   │
│    │     ┌─────────────────────────────────────────┐   │   │
│    │     │ For hver post:                          │   │   │
│    │     │   • Tjek om medie findes                │   │   │
│    │     │   • Hent filnavn (tilpasset eller      │   │   │
│    │     │     SystemId)                           │   │   │
│    │     │   • Tjek om allerede eksporteret        │   │   │
│    │     │   • Udtræk medie til stream             │   │   │
│    │     │   • Tilføj til ZIP-arkiv                │   │   │
│    │     │   • Opret eksportlogpost                │   │   │
│    │     └─────────────────────────────────────────┘   │   │
│    │     • Opret ZIP-filnavn                           │   │
│    │     • Opdater log med ZIP-navn                    │   │
│    └───────────────────────────────────────────────────┘   │
│                                                             │
│ 3.2 Download ZIP                                            │
│     • Konverter til OutStream                               │
│     • Udløs browserdownload                                │
│                                                             │
│ 3.3 Prompt bruger                                           │
│     • Spørg om brugeren vil fortsætte med næste batch      │
│     • Hvis Nej: Forlad loop                                │
│     • Hvis Ja: Genberegn berettiget antal og fortsæt       │
└─────────────────────────────────────────────────────────────┘
```

### Nøglealgoritmer

#### 1. Dynamisk tabeladgang

Bruger RecordRef til runtime-tabeladgang:

```al
RecRef.Open(TableId);
RecRef.SetView('SORTING(SystemId)');
RecRef.SetFilter(SystemIdFilter, '>%1', LastSystemId);
if RecRef.FindSet() then
    repeat
        // Behandl post
        LastSystemId := RecRef.Field(SystemIdFieldNo).Value;
    until (RecRef.Next() = 0) or (ProcessedCount >= BatchSize);
```

**Fordele**:
- Ingen compile-time afhængighed til kildetabeller
- Virker med enhver tabel
- Dynamisk feltadgang via FieldRef

#### 2. Filnavnsgivningsstrategi

```
HVIS konfigurationen har filnavnfelt-ID SÅ
    Filnavn := GetFieldValue(FileNameFieldId)
    HVIS filnavn er blank SÅ
        Filnavn := SystemId
    SLUT
ELLERS
    Filnavn := SystemId
SLUT

HVIS MediaSet med flere billeder SÅ
    Filnavn := Filnavn + '_' + Indeks + '.jpg'
ELLERS
    Filnavn := Filnavn + '.jpg'
SLUT
```

**Fallback-kæde**: Tilpasset felt → SystemId → Fejl

#### 3. Duplikatforebyggelse

Før tilføjelse til ZIP:
1. Forespørg eksportlog for (Tabel-ID, System-ID, Billedfilnavn)
2. Hvis findes: Spring over
3. Hvis ikke findes: Eksporter og log

#### 4. Batch-behandling

**Formål**: Håndter store datasæt uden hukommelsesproblemer

**Strategi**:
- Behandl N poster pr. batch (konfigurerbar)
- Opret én ZIP pr. batch
- Brugerbekræftelse mellem batches
- Spor fremskridt via LastSystemId

**Fordele**:
- Forhindrer timeout ved store eksporter
- Tillader bruger at stoppe efter prøveudtagning
- Mindre, håndterbare ZIP-filer

## Fejlhåndtering

### Valideringspunkter

1. **Konfigurationsvalidering**
   - Tabel-ID skal findes
   - Billedfelt-ID skal findes og være Media/MediaSet-type
   - Filnavnfelt-ID (hvis angivet) skal være Code/Text-type

2. **Runtime-validering**
   - Batchstørrelse skal være > 0
   - Kildetabel skal være tilgængelig
   - Mediefelt skal indeholde data

3. **Feltadgangsvalidering**
   - Dynamisk feltadgang med try-catch
   - Valider felttyper ved runtime

### Fejlmeddelelser

Alle fejlmeddelelser er lokaliseret ved hjælp af Labels med Comment-egenskaber til oversætterkontekst.

## Ydeevneovervejelser

### Optimeringsteknikker

1. **Batch-behandling**: Begrænser hukommelsesforbrug og behandlingstid
2. **SystemId-filtrering**: Effektiv paginering uden læsninger
3. **Eksportlog-indeks**: Sammensat primærnøgle til hurtige duplikattjek
4. **FlowField-caching**: Antal berettigede poster gemt for at undgå genberegning
5. **Commit-strategi**: Commits efter hver batch for at bevare fremskridt

### Skalerbarhed

| Poster | Strategi |
|---------|----------|
| < 100 | Enkelt batch, in-memory ZIP |
| 100-1000 | Flere batches, brugerstyret |
| > 1000 | Anbefales at bruge filtrering eller planlagt behandling |

## Sikkerhed & tilladelser

### Tilladelsessæt: DataBackup (90000)

Giver RIMD (Read, Insert, Modify, Delete) adgang til:
- Media Export Configuration
- Media Export Log
- Media Export Setup
- Alle relaterede sider

### Dataklassifikation

Alle udvidelses-tabeller bruger `DataClassification = SystemMetadata`

### Sletningskontrol

Eksportlog-sletning styres af feltet `Allow Export Log Deletion` i opsætning:
- Forhindrer utilsigtet tab af sporingslog
- OnDeleteRecord-trigger håndhæver politik

## Udvidelsespunkter

### Hændelser

Ingen hændelser publiceres i øjeblikket. Fremtidig udvidelsesmulighed kunne omfatte:

1. **OnBeforeExportBatch**: Tillad ændring af filtre
2. **OnAfterExportRecord**: Tilpasset efterbehandling
3. **OnBeforeAddToZip**: Filnavns-transformation
4. **OnAfterDownload**: Yderligere logning eller notifikationer

### Tabeludvidelser

Enhver tabel med Media/MediaSet-felter kan konfigureres til eksport uden kodeændringer.

## Vedligeholdelse & overvågning

### Sundhedstjek

1. **Antal berettigede poster**: Overvåg for forældede data
2. **Eksportlog-vækst**: Implementer opbevaringspolitik om nødvendigt
3. **Mislykkede eksporter**: Ingen automatisk retry-mekanisme

### Fejlfinding

| Problem | Undersøgelse |
|-------|--------------|
| Ingen billeder eksporteret | Tjek eksportlog for duplikater |
| Forkerte filnavne | Verificer konfiguration af filnavnfelt-ID |
| Eksport timeout | Reducer batchstørrelse |
| Manglende billeder | Tjek at mediefelt har data |

## Lokalisering

### Understøttede sprog

- Engelsk (en-US) - Basissprog
- Dansk (da-DK) - Fuld oversættelse leveret

### Oversættelsesfiler

- `DGB Data Backup.g.xlf` - Auto-genereret basis
- `DGB Data Backup.da-DK.xlf` - Danske oversættelser

Alle brugervendte strenge bruger Labels med oversætter-kommentarer.

## Afhængigheder

### Påkrævede moduler

- System Application (Data Compression codeunit)
- Base Application (Temp Blob codeunit)
- System (RecordRef, FieldRef, Tenant Media)

### Ingen eksterne afhængigheder

Udvidelsen er selvstændig og afhænger ikke af eksterne tjenester eller API'er.

## Fremtidige forbedringer

### Potentielle funktioner

1. **Planlagte eksporter**: Support til baggrundsjob
2. **Eksport til Azure Blob**: Cloud storage-integration
3. **Inkrementelle eksporter**: Datobaseret filtrering
4. **Bulkkonfiguration**: Import/eksport af opsætningsdata
5. **Eksportskabeloner**: Præ-konfigurerede tabelopsætninger
6. **Kompressionsmuligheder**: PNG, kvalitetsindstillinger
7. **E-mail-levering**: Send ZIP via e-mail
8. **REST API**: Integration med eksterne systemer

---

**Version**: 1.2.0.0  
**Senest opdateret**: Februar 2026  
**Forfatter**: Bylov Consulting
