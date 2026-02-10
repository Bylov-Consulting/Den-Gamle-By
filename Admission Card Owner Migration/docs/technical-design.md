# Admission Card Owner Migration - Technical Design

## Overview

The Admission Card Owner Migration extension provides a one-time data migration utility to copy records from the source "Admission Card Owner" table to the target "Admission Card Owner DGB" table. The migration includes all field data and creates independent copies of media (pictures) to prevent shared media references.

## Purpose

This extension facilitates the transition from the original JCD Retail - Admission system to the custom DGB Data Backup extension, ensuring:
- Complete data transfer with all fields preserved
- Independent media storage (no shared references)
- Duplicate prevention
- Progress tracking and error handling
- Ability to copy all records or individual records

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                   User Interfaces                        │
├─────────────────────────────────────────────────────────┤
│  • Admission Card Owners (Extended)                     │
│    - "Copy to DGB Table" action (bulk migration)        │
│    - "Copy Selected to DGB Table" action                │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                 Business Logic Layer                     │
├─────────────────────────────────────────────────────────┤
│  Admission Card Owner Migration Codeunit (90011)        │
│  • CopyToDGBTable() - Bulk migration with progress      │
│  • CopySingleToDGBTable(Code) - Single record copy      │
│  • TryCopySingleRecord() - Safe record copy             │
│  • CopyPicture() - Media duplication                    │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
├─────────────────────────────────────────────────────────┤
│  Source: Admission Card Owner (JCD Retail - Admission)  │
│  Target: Admission Card Owner DGB (DGB Data Backup)     │
└─────────────────────────────────────────────────────────┘
```

## Data Model

### Source and Target Tables

The migration occurs between two structurally identical tables:

#### Source: Admission Card Owner (JCD Extension)
- Part of "JCD Retail - Admission" extension
- Contains original admission card owner data
- Media field: Picture (Media type)

#### Target: Admission Card Owner DGB (Table 90003)
- Part of "DGB Data Backup" extension
- Receives migrated data
- Media field: Picture (Media type)
- Additional features from DGB extension

### Field Mapping

Migration uses `TransferFields(Source, true)` which automatically maps:

| Source Field | → | Target Field | Notes |
|--------------|---|--------------|-------|
| No. | → | No. | Primary key (preserved) |
| First Name | → | First Name | Direct copy |
| Last Name | → | Last Name | Direct copy |
| Address | → | Address | Direct copy |
| City | → | City | Direct copy |
| Post Code | → | Post Code | Direct copy |
| E-Mail | → | E-Mail | Direct copy |
| Phone No. | → | Phone No. | Direct copy |
| Birth Date | → | Birth Date | Direct copy |
| Gender | → | Gender | Direct copy |
| Customer No. | → | Customer No. | Direct copy |
| Picture | → | Picture | **Special handling** (see below) |
| ... | → | ... | All other fields |

### Media Field Special Handling

**Problem**: Direct TransferFields causes shared media references.

**Solution**: Three-step media copy process:

```al
1. Clear destination Picture field
   Clear(DestRecord.Picture);

2. Export source picture to temporary blob
   SourceRecord.Picture.ExportStream(OutStream);

3. Import as new media into destination
   DestRecord.Picture.ImportStream(InStream, FileName);
```

**Result**: Each record has independent media storage.

## Processing Logic

### Bulk Migration Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Action: Copy to DGB Table                          │
│    (From Admission Card Owners DGB page)                    │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Initialize Migration                                     │
│    • Count total records in source table                    │
│    • Initialize counters (Copied, Skipped, Failed)          │
│    • Set commit batch size (100 records)                    │
│    • Open progress dialog                                   │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Process Loop (for each source record)                   │
│    ┌───────────────────────────────────────────────────┐   │
│    │ 3.1 Check if record exists in target             │   │
│    │     IF exists:                                    │   │
│    │        • Increment Skipped counter                │   │
│    │        • Continue to next record                  │   │
│    │     ELSE:                                         │   │
│    │        ↓                                          │   │
│    │ 3.2 Try to copy record                            │   │
│    │     • Call TryCopySingleRecord()                  │   │  
│    │     • IF successful: Increment Copied counter     │   │
│    │     • IF failed: Increment Failed counter         │   │
│    │        ↓                                          │   │
│    │ 3.3 Update progress dialog                        │   │
│    │     • Show record count (X of Y)                  │   │
│    │     • Show percentage complete                    │   │
│    │     • Show Copied/Skipped/Failed counts           │   │
│    │        ↓                                          │   │
│    │ 3.4 Commit every 100 records                      │   │
│    │     • Preserve progress in database               │   │
│    │     • Allow recovery from errors                  │   │
│    └───────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Completion                                               │
│    • Close progress dialog                                  │
│    • Show summary message with final counts                 │
└─────────────────────────────────────────────────────────────┘
```

### Single Record Migration Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Validate Source Record                                   │
│    • Check if source record exists                          │
│    • If not found: Show error message and exit              │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Check for Duplicates                                     │
│    • Check if target record already exists                  │
│    • If exists: Show message and exit                       │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Copy Record Data                                         │
│    • Init target record                                     │
│    • TransferFields (all fields except Picture)             │
│    • Clear Picture field (prevent shared reference)         │
│    • Insert target record                                   │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Copy Picture                                             │
│    • Check if source has picture                            │
│    • Export to temporary blob                               │
│    • Import to target as new media                          │
│    • Modify target record                                   │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Completion                                               │
│    • Show success message                                   │
│    • Return true                                            │
└─────────────────────────────────────────────────────────────┘
```

## Key Algorithms

### 1. Safe Record Copy with TryFunction

```al
[TryFunction]
local procedure TryCopySingleRecord(var SourceRecord: Record "Admission Card Owner")
var
    DestRecord: Record "Admission Card Owner DGB";
begin
    DestRecord.Init();
    DestRecord.TransferFields(SourceRecord, true);
    Clear(DestRecord.Picture);  // Critical: Prevent shared media
    DestRecord.Insert(true);
    
    CopyPictureToDestination(SourceRecord, DestRecord);
end;
```

**TryFunction Pattern**:
- Returns false on any error (instead of throwing exception)
- Allows bulk migration to continue even if individual records fail
- Enables accurate success/failure counting

### 2. Media Independence Strategy

**Problem**: TransferFields copies media field reference, not media content.

```
Source Record → Picture (Media ID: 123)
                    ↓ TransferFields
Target Record → Picture (Media ID: 123)  ← Shared reference!
```

**Solution**: Export and re-import media

```
Source Record → Picture (Media ID: 123)
                    ↓ ExportStream to Blob
                Temp Blob (binary data)
                    ↓ ImportStream
Target Record → Picture (Media ID: 456)  ← Independent copy!
```

**Code**:
```al
// Export
TempBlob.CreateOutStream(PictureOutStream);
SourceRecord.Picture.ExportStream(PictureOutStream);

// Import
TempBlob.CreateInStream(PictureInStream);
DestRecord.Picture.ImportStream(PictureInStream, 'Picture_' + DestRecord."No." + '.jpg');
```

### 3. Progress Tracking

Real-time progress dialog with 6 data points:

```al
ProgressDialog.Open(CopyingRecordsTxt);
// Text constant with placeholders:
// 'Copying records...\\Processed #1#### of #2####. Progress: #3##%\\
//  Copied: #4#### | Skipped: #5#### | Failed: #6####'

ProgressDialog.Update(1, Counter);          // Current record number
ProgressDialog.Update(2, TotalRecords);     // Total records
ProgressDialog.Update(3, PercentComplete);  // Percentage
ProgressDialog.Update(4, RecordsCopied);    // Success count
ProgressDialog.Update(5, RecordsSkipped);   // Skipped count
ProgressDialog.Update(6, RecordsFailed);    // Error count
```

### 4. Commit Strategy

```al
if (RecordsCopied mod CommitBatchSize) = 0 then
    Commit();
```

**Purpose**:
- Preserve progress every 100 records
- Allow recovery from system errors
- Prevent transaction log overflow
- Enable parallel operations

**Trade-offs**:
- Can't rollback batch if later errors occur
- Acceptable for migration scenarios

## Error Handling

### Validation Layers

#### 1. Pre-Migration Validation

| Check | Location | Action if False |
|-------|----------|-----------------|
| Source record exists | CopySingleToDGBTable | Show error message, return false |
| Target record doesn't exist | CopySingleToDGBTable | Show message, return false |
| Picture has value | CopyPicture | Exit silently (no picture to copy) |

#### 2. Runtime Error Handling

**TryFunction Pattern**:
- Wraps risky operations (Insert, Modify)
- Catches all errors without user-visible exceptions
- Allows bulk operation to continue
- Errors are counted but not detailed

**Limitations**:
- No specific error logging
- User only sees failed count, not reasons
- Acceptable for one-time migration

### Error Recovery

**Automatic**:
- Duplicate records are skipped (counted, not error)
- Missing pictures are ignored (not all records have them)
- Failed records don't stop batch processing

**Manual**:
- Re-run migration (skips already-migrated records)
- Fix source data issues and retry
- Use single record copy for problem records

## Performance Considerations

### Optimization Techniques

1. **Batch Commits**: Commit every 100 records
   - Reduces transaction overhead
   - Balances atomicity vs. performance

2. **Simple Validation**: Only checks for duplicates
   - Fast primary key lookup
   - No complex validation logic

3. **Stream-Based Media Copy**: Uses TempBlob
   - Memory efficient for large images
   - No intermediate file storage

4. **Progress Dialog**: Updates every record
   - Keeps user informed
   - Minimal performance impact

### Scalability

| Records | Estimated Time | Strategy |
|---------|---------------|----------|
| < 100 | < 1 minute | Direct execution |
| 100-1000 | 1-10 minutes | Monitor progress |
| 1000-5000 | 10-50 minutes | Run during off-hours |
| > 5000 | > 1 hour | Consider filtering or staged migration |

**Factors affecting speed**:
- Image size (larger images take longer)
- Network latency (cloud environments)
- Server load (concurrent users)
- Database response time

## Duplicate Prevention

### Primary Key Protection

```al
if AdmissionCardOwnerDGB.Get(CardOwnerNo) then begin
    Message(RecordAlreadyExistsMsg, CardOwnerNo);
    exit(false);
end;
```

**Mechanism**:
- Uses table.Get(PrimaryKey) for fast lookup
- No duplicate inserts possible (primary key uniqueness)
- Failed insert attempts are caught by TryFunction

### Idempotent Migration

Running migration multiple times is safe:
- Already-migrated records: Skipped (counted)
- New records: Copied (counted)
- Failed previous records: Retried

**Result**: Status quo preserved, only new data added.

## Page Extensions

### ExportCardOwnerPictures (90011)

**Extends**: Admission Card Owners (source list page)

**Adds**:
- Action: "Copy to DGB Table"
- Action: "Copy Selected to DGB Table"
- Location: Processing action area (promoted)
- Function: Triggers bulk or single-record migration

## Dependencies

### Required Extensions

1. **JCD Retail - Admission** (source table)
   - Provides "Admission Card Owner" table
   - Must be installed first

2. **DGB Data Backup** (target table)
   - Provides "Admission Card Owner DGB" table
   - Must be installed before migration

### System Dependencies

- **Base Application**: TransferFields, Dialog
- **System Application**: Temp Blob
- **Platform**: RecordRef, Media handling

## Localization

### Supported Languages

- English (en-US) - Base language
- Danish (da-DK) - Translation recommended

### Localizable Strings

All user-facing messages use Labels:
- CopyingRecordsTxt
- CopyCompletedMsg
- CardOwnerNotFoundMsg
- RecordAlreadyExistsMsg
- RecordCopiedMsg

## Migration Checklist

### Pre-Migration

- [ ] Verify JCD Retail - Admission extension installed
- [ ] Verify DGB Data Backup extension installed
- [ ] Count source records: `SELECT COUNT(*) FROM "Admission Card Owner"`
- [ ] Backup database (recommended)
- [ ] Plan migration window (off-hours recommended for > 1000 records)

### During Migration

- [ ] Monitor progress dialog
- [ ] Note any error messages
- [ ] Don't cancel mid-migration (safe to resume, but inefficient)

### Post-Migration

- [ ] Verify record counts match
- [ ] Spot-check data in target table
- [ ] Verify pictures visible in target
- [ ] Test DGB Data Backup export functionality
- [ ] Document Copied/Skipped/Failed counts

## Troubleshooting

| Issue | Likely Cause | Solution |
|-------|-------------|----------|
| "Table not found" error | Extension not installed | Install missing extension |
| All records skipped | Already migrated | Expected; no action needed |
| High failure count | Data validation issues | Check source data integrity |
| Slow migration | Large images or many records | Wait or run off-hours |
| Pictures missing | Source had no pictures | Expected; not an error |

## Future Enhancements

### Potential Improvements

1. **Detailed Error Logging**: Record-level error messages
2. **Selective Migration**: Filter by date, customer, etc.
3. **Delta Migration**: Only new/changed records
4. **Progress Persistence**: Resume from interruption
5. **Pre-Migration Validation**: Check data quality first
6. **Post-Migration Report**: Detailed statistics
7. **Rollback Capability**: Undo migration

### Not Planned

- **Continuous Synchronization**: One-time migration only
- **Bidirectional Sync**: One-way copy only
- **Scheduled Migration**: Manual trigger only

This is a **migration utility**, not a synchronization tool.

---

**Version**: 1.2.0.0  
**Last Updated**: February 2026  
**Author**: Bylov Consulting
