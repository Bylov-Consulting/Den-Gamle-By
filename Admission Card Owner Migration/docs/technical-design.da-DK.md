# Admission Card Owner Migration - Teknisk Design

## Oversigt

Admission Card Owner Migration-udvidelsen leverer et engangsdatamigreringsværktøj til at kopiere poster fra kildetabellen "Admission Card Owner" til måltabellen "Admission Card Owner DGB". Migreringen inkluderer alle feltdata og opretter uafhængige kopier af medier (billeder) for at forhindre delte medierefer encer.

## Formål

Denne udvidelse letter overgangen fra det oprindelige JCD Retail - Admission-system til den brugerdefinerede DGB Data Backup-udvidelse og sikrer:
- Komplet dataoverførsel med alle felter bevaret
- Uafhængig medielagring (ingen delte referencer)
- Duplikatforebyggelse
- Fremskridtssporing og fejlhåndtering
- Mulighed for at kopiere alle poster eller individuelle poster

## Arkitektur

### Komponentoversigt

```
┌─────────────────────────────────────────────────────────┐
│                   Brugergrænseflader                     │
├─────────────────────────────────────────────────────────┤
│  • Admission Card Owners (Udvidet)                      │
│    - "Kopier til DGB-tabel" handling (bulk-migrering)   │
│    - "Kopier markeret til DGB-tabel" handling           │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                 Forretningslogiklag                      │
├─────────────────────────────────────────────────────────┤
│  Admission Card Owner Migration Codeunit (90011)        │
│  • CopyToDGBTable() - Bulk-migrering med fremskridt     │
│  • CopySingleToDGBTable(Code) - Enkelt postkopi         │
│  • TryCopySingleRecord() - Sikker postkopi              │
│  • CopyPicture() - Medieduplikering                     │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                    Datalag                               │
├─────────────────────────────────────────────────────────┤
│  Kilde: Admission Card Owner (JCD Retail - Admission)   │
│  Mål: Admission Card Owner DGB (DGB Data Backup)        │
└─────────────────────────────────────────────────────────┘
```

## Datamodel

### Kilde- og måltabeller

Migreringen foregår mellem to strukturelt identiske tabeller:

#### Kilde: Admission Card Owner (JCD-udvidelse)
- Del af "JCD Retail - Admission"-udvidelsen
- Indeholder originale admission card owner-data
- Mediefelt: Picture (Media-type)

#### Mål: Admission Card Owner DGB (Tabel 90003)
- Del af "DGB Data Backup"-udvidelsen
- Modtager migrerede data
- Mediefelt: Picture (Media-type)
- Ekstra funktioner fra DGB-udvidelsen

### Feltkortlægning

Migreringen bruger `TransferFields(Source, true)`, som automatisk kortlægger:

| Kildefelt | → | Målfelt | Bemærkninger |
|--------------|---|--------------|-------|
| Nr. | → | Nr. | Primærnøgle (bevaret) |
| Fornavn | → | Fornavn | Direkte kopi |
| Efternavn | → | Efternavn | Direkte kopi |
| Adresse | → | Adresse | Direkte kopi |
| By | → | By | Direkte kopi |
| Postnr. | → | Postnr. | Direkte kopi |
| E-mail | → | E-mail | Direkte kopi |
| Telefonnr. | → | Telefonnr. | Direkte kopi |
| Fødselsdato | → | Fødselsdato | Direkte kopi |
| Køn | → | Køn | Direkte kopi |
| Debitornr. | → | Debitornr. | Direkte kopi |
| Billede | → | Billede | **Særlig håndtering** (se nedenfor) |
| ... | → | ... | Alle andre felter |

### Særlig håndtering af mediefelt

**Problem**: Direkte TransferFields forårsager delte mediereference r.

**Løsning**: Tre-trins mediekopieringsproces:

```al
1. Ryd destinations billede-felt
   Clear(DestRecord.Picture);

2. Eksporter kildebillede til midlertidig blob
   SourceRecord.Picture.ExportStream(OutStream);

3. Importer som nyt medie til destination
   DestRecord.Picture.ImportStream(InStream, FileName);
```

**Resultat**: Hver post har uafhængig medielagring.

## Behandlingslogik

### Bulk-migreringsflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Brugerhandling: Kopier til DGB-tabel                    │
│    (Fra Admission Card Owners DGB-side)                     │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Initialiser migrering                                    │
│    • Tæl samlede poster i kildetabel                        │
│    • Initialiser tællere (Kopieret, Sprunget over, Fejlet) │
│    • Sæt commit-batchstørrelse (100 poster)                 │
│    • Åbn fremskridtsdialog                                  │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Behandlingsloop (for hver kildepost)                    │
│    ┌───────────────────────────────────────────────────┐   │
│    │ 3.1 Tjek om post findes i mål                    │   │
│    │     HVIS findes:                                  │   │
│    │        • Inkrementer Sprunget over-tæller         │   │
│    │        • Fortsæt til næste post                   │   │
│    │     ELLERS:                                       │   │
│    │        ↓                                          │   │
│    │ 3.2 Prøv at kopiere post                          │   │
│    │     • Kald TryCopySingleRecord()                  │   │  
│    │     • HVIS succesfuld: Inkrementer Kopieret-tæller│   │
│    │     • HVIS fejlet: Inkrementer Fejlet-tæller      │   │
│    │        ↓                                          │   │
│    │ 3.3 Opdater fremskridtsdialog                     │   │
│    │     • Vis postantal (X af Y)                      │   │
│    │     • Vis procent færdig                          │   │
│    │     • Vis Kopieret/Sprunget over/Fejlet antal     │   │
│    │        ↓                                          │   │
│    │ 3.4 Commit hver 100 poster                        │   │
│    │     • Bevar fremskridt i database                 │   │
│    │     • Tillad genoptagelse ved fejl                │   │
│    └───────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Færdiggørelse                                            │
│    • Luk fremskridtsdialog                                  │
│    • Vis resumémeddelelse med endelige antal                │
└─────────────────────────────────────────────────────────────┘
```

### Enkelt post-migreringsflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Valider kildepost                                        │
│    • Tjek om kildepost findes                               │
│    • Hvis ikke fundet: Vis fejlmeddelelse og afslut         │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Tjek for duplikater                                      │
│    • Tjek om målpost allerede findes                        │
│    • Hvis findes: Vis meddelelse og afslut                  │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Kopier postdata                                          │
│    • Init målpost                                           │
│    • TransferFields (alle felter undtagen Picture)          │
│    • Ryd Picture-felt (forhindre delt reference)            │
│    • Indsæt målpost                                         │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Kopier billede                                           │
│    • Tjek om kilde har billede                              │
│    • Eksporter til midlertidig blob                         │
│    • Importer til mål som nyt medie                         │
│    • Modificer målpost                                      │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Færdiggørelse                                            │
│    • Vis succesmeddelelse                                   │
│    • Returner true                                          │
└─────────────────────────────────────────────────────────────┘
```

## Nøglealgoritmer

### 1. Sikker postkopi med TryFunction

```al
[TryFunction]
local procedure TryCopySingleRecord(var SourceRecord: Record "Admission Card Owner")
var
    DestRecord: Record "Admission Card Owner DGB";
begin
    DestRecord.Init();
    DestRecord.TransferFields(SourceRecord, true);
    Clear(DestRecord.Picture);  // Kritisk: Forhindre delt medie
    DestRecord.Insert(true);
    
    CopyPictureToDestination(SourceRecord, DestRecord);
end;
```

**TryFunction-mønster**:
- Returnerer false ved enhver fejl (i stedet for at kaste undtagelse)
- Tillader bulk-migrering at fortsætte, selvom individuelle poster fejler
- Muliggør nøjagtig succes/fejl-tælling

### 2. Medieuafhængighedsstrategi

**Problem**: TransferFields kopierer mediefeltreference, ikke medieindhold.

```
Kildepost → Billede (Medie-ID: 123)
                    ↓ TransferFields
Målpost   → Billede (Medie-ID: 123)  ← Delt reference!
```

**Løsning**: Eksporter og gen-importer medie

```
Kildepost → Billede (Medie-ID: 123)
                    ↓ ExportStream til Blob
                Temp Blob (binære data)
                    ↓ ImportStream
Målpost   → Billede (Medie-ID: 456)  ← Uafhængig kopi!
```

**Kode**:
```al
// Eksporter
TempBlob.CreateOutStream(PictureOutStream);
SourceRecord.Picture.ExportStream(PictureOutStream);

// Importer
TempBlob.CreateInStream(PictureInStream);
DestRecord.Picture.ImportStream(PictureInStream, 'Picture_' + DestRecord."No." + '.jpg');
```

### 3. Fremskridtssporing

Realtids fremskridtsdialog med 6 datapunkter:

```al
ProgressDialog.Open(CopyingRecordsTxt);
// Tekstkonstant med pladsholdere:
// 'Kopierer poster...\\Behandlet #1#### af #2####. Fremskridt: #3##%\\
//  Kopieret: #4#### | Sprunget over: #5#### | Fejlet: #6####'

ProgressDialog.Update(1, Counter);          // Aktuelt postnummer
ProgressDialog.Update(2, TotalRecords);     // Samlede poster
ProgressDialog.Update(3, PercentComplete);  // Procent
ProgressDialog.Update(4, RecordsCopied);    // Succestæller
ProgressDialog.Update(5, RecordsSkipped);   // Oversprungne tæller
ProgressDialog.Update(6, RecordsFailed);    // Fejltæller
```

### 4. Commit-strategi

```al
if (RecordsCopied mod CommitBatchSize) = 0 then
    Commit();
```

**Formål**:
- Bevar fremskridt hver 100. post
- Tillad genoptagelse fra systemfejl
- Forhindre transaktionslog-overløb
- Muliggør parallelle operationer

**Kompromiser**:
- Kan ikke rulle batch tilbage ved senere fejl
- Acceptabelt til migreringsscenarier

## Fejlhåndtering

### Valideringslag

#### 1. Præ-migreringsvalidering

| Tjek | Placering | Handling hvis falsk |
|-------|----------|-----------------|
| Kildepost findes | CopySingleToDGBTable | Vis fejlmeddelelse, returner false |
| Målpost findes ikke | CopySingleToDGBTable | Vis meddelelse, returner false |
| Billede har værdi | CopyPicture | Afslut stiltiende (intet billede at kopiere) |

#### 2. Runtime-fejlhåndtering

**TryFunction-mønster**:
- Indpakker risikable operationer (Insert, Modify)
- Fanger alle fejl uden brugersynlige undtagelser
- Tillader bulk-operation at fortsætte
- Fejl tælles men detaljeres ikke

**Begrænsninger**:
- Ingen specifik fejllogning
- Bruger ser kun fejltælling, ikke årsager
- Acceptabelt til engangsmigre ring

### Fejlgenoptagelse

**Automatisk**:
- Duplikatposter springes over (tælles, ikke fejl)
- Manglende billeder ignoreres (ikke alle poster har dem)
- Fejlede poster stopper ikke batchbehandling

**Manuel**:
- Kør migrering igen (springer allerede migrerede poster over)
- Ret kildedataproblemer og prøv igen
- Brug enkelt postkopi til problempost er

## Ydeevneovervejelser

### Optimeringsteknikker

1. **Batch-commits**: Commit hver 100. post
   - Reducerer transaktionsomkostninger
   - Balancerer atomicitet vs. ydeevne

2. **Simpel validering**: Tjekker kun for duplikater
   - Hurtig primærnøgleopslag
   - Ingen kompleks valideringslogik

3. **Stream-baseret mediekopi**: Bruger TempBlob
   - Hukommelseseffektivt for store billeder
   - Ingen mellemfillagring

4. **Fremskridtsdialog**: Opdateres hver post
   - Holder bruger informeret
   - Minimal ydeevnepåvirkning

### Skalerbarhed

| Poster | Estimeret tid | Strategi |
|---------|---------------|----------|
| < 100 | < 1 minut | Direkte eksekvering |
| 100-1000 | 1-10 minutter | Overvåg fremskridt |
| 1000-5000 | 10-50 minutter | Kør i off-peak timer |
| > 5000 | > 1 time | Overvej filtrering eller etapevis migrering |

**Faktorer der påvirker hastighed**:
- Billedstørrelse (større billeder tager længere tid)
- Netværkslatens (cloud-miljøer)
- Serverbelastning (samtidige brugere)
- Database-svartid

## Duplikatforebyggelse

### Primærnøglebeskyttelse

```al
if AdmissionCardOwnerDGB.Get(CardOwnerNo) then begin
    Message(RecordAlreadyExistsMsg, CardOwnerNo);
    exit(false);
end;
```

**Mekanisme**:
- Bruger table.Get(Primærnøgle) til hurtig opslag
- Ingen duplikatindsættelser mulige (primærnøgle-unicitet)
- Fejlede indsættelsesforsøg fanges af TryFunction

### Idempotent migrering

Kørsel af migrering flere gange er sikkert:
- Allerede migrerede poster: Sprunget over (tælles)
- Nye poster: Kopieret (tælles)
- Tidligere fejlede poster: Prøvet igen

**Resultat**: Status quo bevaret, kun nye data tilføjet.

## Sideudvidelser

### ExportCardOwnerPictures (90011)

**Udvider**: Admission Card Owners (kilde-listeside)

**Tilføjer**:
- Handling: "Kopier til DGB-tabel"
- Handling: "Kopier markeret til DGB-tabel"
- Placering: Processing-handlingsområde (promoveret)
- Funktion: Udløser bulk- eller enkeltpost-migrering

## Afhængigheder

### Påkrævede udvidelser

1. **JCD Retail - Admission** (kildetabel)
   - Leverer "Admission Card Owner"-tabel
   - Skal installeres først

2. **DGB Data Backup** (måltabel)
   - Leverer "Admission Card Owner DGB"-tabel
   - Skal installeres før migrering

### Systemafhængigheder

- **Base Application**: TransferFields, Dialog
- **System Application**: Temp Blob
- **Platform**: RecordRef, Mediehåndtering

## Lokalisering

### Understøttede sprog

- Engelsk (en-US) - Basissprog
- Dansk (da-DK) - Oversættelse anbefalet

### Lokaliserbare strenge

Alle brugervendte meddelelser bruger Labels:
- CopyingRecordsTxt
- CopyCompletedMsg
- CardOwnerNotFoundMsg
- RecordAlreadyExistsMsg
- RecordCopiedMsg

## Migreringstjekliste

### Før migrering

- [ ] Verificer JCD Retail - Admission-udvidelse installeret
- [ ] Verificer DGB Data Backup-udvidelse installeret
- [ ] Tæl kildeposter: `SELECT COUNT(*) FROM "Admission Card Owner"`
- [ ] Sikkerhedskopier database (anbefales)
- [ ] Planlæg migreringsvindue (off-peak timer anbefales for > 1000 poster)

### Under migrering

- [ ] Overvåg fremskridtsdialog
- [ ] Bemærk eventuelle fejlmeddelelser
- [ ] Annuller ikke midt i migrering (sikkert at genoptage, men ineffektivt)

### Efter migrering

- [ ] Verificer at postantal matcher
- [ ] Stikprøvekontrol data i måltabel
- [ ] Verificer billeder synlige i mål
- [ ] Test DGB Data Backup-eksportfunktionalitet
- [ ] Dokumenter Kopieret/Sprunget over/Fejlet antal

## Fejlfinding

| Problem | Sandsynlig årsag | Løsning |
|-------|-------------|----------|
| "Tabel ikke fundet"-fejl | Udvidelse ikke installeret | Installer manglende udvidelse |
| Alle poster sprunget over | Allerede migreret | Forventet; ingen handling nødvendig |
| Højt fejlantal | Datavalideringsproblemer | Tjek kildedataintegritet |
| Langsom migrering | Store billeder eller mange poster | Vent eller kør i off-peak timer |
| Billeder mangler | Kilde havde ingen billeder | Forventet; ikke en fejl |

## Fremtidige forbedringer

### Potentielle forbedringer

1. **Detaljeret fejllogning**: Fejlmeddelelser på postniveau
2. **Selektiv migrering**: Filtrer efter dato, debitor, osv.
3. **Delta-migrering**: Kun nye/ændrede poster
4. **Fremskridtspersistering**: Genoptag fra afbrydelse
5. **Præ-migreringsvalidering**: Tjek datakvalitet først
6. **Post-migreringsrapport**: Detaljeret statistik
7. **Rollback-kapacitet**: Fortryd migrering

### Ikke planlagt

- **Kontinuert synkronisering**: Kun engangsmigre ring
- **Tovejs-synk**: Kun envejskopi
- **Planlagt migrering**: Kun manuel udløsning

Dette er et **migreringsværktøj**, ikke et synkroniseringsværktøj.

---

**Version**: 1.2.0.0  
**Senest opdateret**: Februar 2026  
**Forfatter**: Bylov Consulting
