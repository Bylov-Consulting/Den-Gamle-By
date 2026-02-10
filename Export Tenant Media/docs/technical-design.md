# DGB Data Backup - Technical Design

## Overview

The DGB Data Backup extension provides a flexible, configurable framework for exporting media (images) from any Business Central table to ZIP files. The system is designed to handle large datasets through batch processing and maintains a comprehensive audit trail of all exports.

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                   User Interfaces                        │
├─────────────────────────────────────────────────────────┤
│  • Media Export Status (Overview & Export Trigger)      │
│  • Media Export Configuration (Setup per table)         │
│  • Media Export Setup (Global configuration)            │
│  • Media Export Log (Audit trail)                       │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                 Business Logic Layer                     │
├─────────────────────────────────────────────────────────┤
│  Media Export Mgt. Codeunit                             │
│  • Batch processing engine                              │
│  • Dynamic table access (RecordRef)                     │
│  • Media extraction & ZIP creation                      │
│  • Export logging                                       │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
├─────────────────────────────────────────────────────────┤
│  • Media Export Configuration (Table 90004)             │
│  • Media Export Log (Table 90005)                       │
│  • Media Export Setup (Table 90006)                     │
└─────────────────────────────────────────────────────────┘
```

## Data Model

### Entity Relationship Diagram

```
┌─────────────────────────────┐
│  Media Export Setup         │
│  (Singleton)                │
├─────────────────────────────┤
│  PK: (blank)                │
│  Batch Size                 │
│  Allow Log Deletion         │
└─────────────────────────────┘
                ↓ Referenced by
┌─────────────────────────────┐      1:N      ┌─────────────────────────────┐
│ Media Export Configuration  │───────────────→│    Media Export Log         │
├─────────────────────────────┤                ├─────────────────────────────┤
│  PK: Table ID               │                │  PK: Table ID +             │
│  Image Field ID             │                │      System ID +            │
│  File Name Field ID         │                │      Image File Name        │
│  Eligible Records Count     │                │  Export Timestamp           │
│  Exported Records Count (FC)│                │  Zip File Name              │
└─────────────────────────────┘                └─────────────────────────────┘
        ↓ Points to any BC table
┌─────────────────────────────┐
│   Any Business Central      │
│   Table with Media Field    │
│   (e.g., Admission Card     │
│    Owner DGB)               │
└─────────────────────────────┘
```

### Table Definitions

#### 1. Media Export Configuration (90004)

**Purpose**: Stores export configuration for each table that contains media to export.

| Field # | Field Name | Type | Description |
|---------|-----------|------|-------------|
| 1 | Table ID | Integer | Primary key. The ID of the source table |
| 2 | Table Name | Text[100] | FlowField. Display name of the table |
| 3 | Image Field ID | Integer | Field number of the Media/MediaSet field |
| 4 | Image Field Name | Text[100] | FlowField. Display name of media field |
| 5 | File Name Field ID | Integer | Optional. Field to use for file naming |
| 6 | File Name Field Name | Text[100] | FlowField. Display name of file name field |
| 7 | Eligible Records Count | Integer | Cached count of unexported records |
| 8 | Exported Records Count | Integer | FlowField. Total exported records |

**Key**: Primary Key (Table ID)

**Field Relationships**:
- `Table ID` → AllObjWithCaption (Table list)
- `Image Field ID` → Field table (filtered to Media/MediaSet types)
- `File Name Field ID` → Field table (filtered to Code/Text types)

#### 2. Media Export Log (90005)

**Purpose**: Audit trail of all exported images.

| Field # | Field Name | Type | Description |
|---------|-----------|------|-------------|
| 1 | Table ID | Integer | Part of PK. Source table ID |
| 2 | System ID | Guid | Part of PK. Record's SystemId |
| 3 | Export Timestamp | DateTime | When the export occurred |
| 4 | Zip File Name | Text[250] | Name of ZIP file containing this image |
| 5 | Image File Name | Text[250] | Part of PK. Name of image in ZIP |

**Key**: Primary Key (Table ID, System ID, Image File Name)

**Usage**: 
- Prevents duplicate exports
- Provides auditability
- Links exported files to source records

#### 3. Media Export Setup (90006)

**Purpose**: Global configuration settings (singleton pattern).

| Field # | Field Name | Type | Description |
|---------|-----------|------|-------------|
| 1 | Primary Key | Code[10] | Always blank (singleton) |
| 2 | Batch Size | Integer | Records per export batch |
| 3 | Allow Export Log Deletion | Boolean | Control log deletion permission |

**Key**: Primary Key (Primary Key)

**Singleton Pattern**: Uses blank primary key. Single record accessed via `Get()` with no parameters.

## Processing Logic

### Export Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Action: Export Images                              │
│    (From Media Export Status page)                          │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Load Configuration                                       │
│    • Get Export Configuration for table                     │
│    • Get batch size from Media Export Setup                 │
│    • Count eligible records                                 │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Batch Loop (while eligible records > 0)                 │
│    ┌───────────────────────────────────────────────────┐   │
│    │ 3.1 Execute Single Batch                          │   │
│    │     • Open source table with RecordRef            │   │
│    │     • Filter records (SystemId > LastSystemId)    │   │
│    │     • Process up to [Batch Size] records          │   │
│    │     ┌─────────────────────────────────────────┐   │   │
│    │     │ For each record:                        │   │   │
│    │     │   • Check if media exists               │   │   │
│    │     │   • Get file name (custom or SystemId)  │   │   │
│    │     │   • Check if already exported           │   │   │
│    │     │   • Extract media to stream             │   │   │
│    │     │   • Add to ZIP archive                  │   │   │
│    │     │   • Create export log entry             │   │   │
│    │     └─────────────────────────────────────────┘   │   │
│    │     • Create ZIP file name                        │   │
│    │     • Update log with ZIP name                    │   │
│    └───────────────────────────────────────────────────┘   │
│                                                             │
│ 3.2 Download ZIP                                            │
│     • Convert to OutStream                                  │
│     • Trigger browser download                             │
│                                                             │
│ 3.3 Prompt User                                             │
│     • Ask if user wants to continue with next batch        │
│     • If No: Exit loop                                     │
│     • If Yes: Recalculate eligible count and continue      │
└─────────────────────────────────────────────────────────────┘
```

### Key Algorithms

#### 1. Dynamic Table Access

Uses RecordRef for runtime table access:

```al
RecRef.Open(TableId);
RecRef.SetView('SORTING(SystemId)');
RecRef.SetFilter(SystemIdFilter, '>%1', LastSystemId);
if RecRef.FindSet() then
    repeat
        // Process record
        LastSystemId := RecRef.Field(SystemIdFieldNo).Value;
    until (RecRef.Next() = 0) or (ProcessedCount >= BatchSize);
```

**Benefits**:
- No compile-time dependency on source tables
- Works with any table
- Dynamic field access via FieldRef

#### 2. File Naming Strategy

```
IF Configuration has File Name Field ID THEN
    FileName := GetFieldValue(FileNameFieldId)
    IF FileName is blank THEN
        FileName := SystemId
    END
ELSE
    FileName := SystemId
END

IF MediaSet with multiple images THEN
    FileName := FileName + '_' + Index + '.jpg'
ELSE
    FileName := FileName + '.jpg'
END
```

**Fallback Chain**: Custom Field → SystemId → Error

#### 3. Duplicate Prevention

Before adding to ZIP:
1. Query Export Log for (Table ID, System ID, Image File Name)
2. If exists: Skip
3. If not exists: Export and log

#### 4. Batch Processing

**Purpose**: Handle large datasets without memory issues

**Strategy**:
- Process N records per batch (configurable)
- Create one ZIP per batch
- User confirmation between batches
- Track progress via LastSystemId

**Benefits**:
- Prevents timeout on large exports
- Allows user to stop after sampling
- Smaller, manageable ZIP files

## Error Handling

### Validation Points

1. **Configuration Validation**
   - Table ID must exist
   - Image Field ID must exist and be Media/MediaSet type
   - File Name Field ID (if specified) must be Code/Text type

2. **Runtime Validation**
   - Batch size must be > 0
   - Source table must be accessible
   - Media field must contain data

3. **Field Access Validation**
   - Dynamic field access with try-catch
   - Validate field types at runtime

### Error Messages

All error messages are localized using Labels with Comment properties for translator context.

## Performance Considerations

### Optimization Techniques

1. **Batch Processing**: Limits memory usage and processing time
2. **SystemId Filtering**: Efficient pagination without reads
3. **Export Log Index**: Composite primary key for fast duplicate checks
4. **FlowField Caching**: Eligible Records Count stored to avoid recalculation
5. **Commit Strategy**: Commits after each batch to preserve progress

### Scalability

| Records | Strategy |
|---------|----------|
| < 100 | Single batch, in-memory ZIP |
| 100-1000 | Multiple batches, user-controlled |
| > 1000 | Recommended to use filtering or scheduled processing |

## Security & Permissions

### Permission Set: DataBackup (90000)

Grants RIMD (Read, Insert, Modify, Delete) access to:
- Media Export Configuration
- Media Export Log
- Media Export Setup
- All related pages

### Data Classification

All extension tables use `DataClassification = SystemMetadata`

### Deletion Control

Export Log deletion is controlled by `Allow Export Log Deletion` field in setup:
- Prevents accidental audit trail loss
- OnDeleteRecord trigger enforces policy

## Extension Points

### Events

Currently no events published. Future extensibility could include:

1. **OnBeforeExportBatch**: Allow modification of filters
2. **OnAfterExportRecord**: Custom post-processing
3. **OnBeforeAddToZip**: File name transformation
4. **OnAfterDownload**: Additional logging or notifications

### Table Extensions

Any table with Media/MediaSet fields can be configured for export without code changes.

## Maintenance & Monitoring

### Health Checks

1. **Eligible Records Count**: Monitor for stale data
2. **Export Log Growth**: Implement retention policy if needed
3. **Failed Exports**: No automatic retry mechanism

### Troubleshooting

| Issue | Investigation |
|-------|--------------|
| No images exported | Check Export Log for duplicates |
| Wrong file names | Verify File Name Field ID configuration |
| Export timeout | Reduce batch size |
| Missing images | Check media field has data |

## Localization

### Supported Languages

- English (en-US) - Base language
- Danish (da-DK) - Full translation provided

### Translation Files

- `DGB Data Backup.g.xlf` - Auto-generated base
- `DGB Data Backup.da-DK.xlf` - Danish translations

All user-facing strings use Labels with translator comments.

## Dependencies

### Required Modules

- System Application (Data Compression codeunit)
- Base Application (Temp Blob codeunit)
- System (RecordRef, FieldRef, Tenant Media)

### No External Dependencies

The extension is self-contained and does not depend on external services or APIs.

## Future Enhancements

### Potential Features

1. **Scheduled Exports**: Background job support
2. **Export to Azure Blob**: Cloud storage integration
3. **Incremental Exports**: Date-based filtering
4. **Bulk Configuration**: Import/export setup data
5. **Export Templates**: Pre-configured table setups
6. **Compression Options**: PNG, quality settings
7. **Email Delivery**: Send ZIP via email
8. **REST API**: External system integration

---

**Version**: 1.2.0.0  
**Last Updated**: February 2026  
**Author**: Bylov Consulting
