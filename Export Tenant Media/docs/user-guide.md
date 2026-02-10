# DGB Data Backup - User Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Configuring Table Exports](#configuring-table-exports)
5. [Exporting Images](#exporting-images)
6. [Viewing Export History](#viewing-export-history)
7. [Troubleshooting](#troubleshooting)
8. [Frequently Asked Questions](#frequently-asked-questions)

---

## Introduction

The **DGB Data Backup** extension enables you to export images and media files from any Business Central table to ZIP files. This is useful for:

- **Data backup and archival**
- **Migration to external systems**
- **Compliance and audit requirements**
- **Creating offline image libraries**

### Key Features

✅ **Flexible Configuration**: Export from any table with media fields  
✅ **Batch Processing**: Handle large datasets efficiently  
✅ **Custom File Naming**: Use meaningful file names based on your data  
✅ **Audit Trail**: Complete log of all exports  
✅ **Resume Capability**: Continue exports across multiple batches  
✅ **Duplicate Prevention**: Never export the same image twice  

---

## Prerequisites

### Permissions

You need the **DataBackup** permission set (90000) to use this extension.

**To verify permissions:**
1. Search for "Users" in Business Central
2. Open your user record
3. Check if "DataBackup" permission set is assigned
4. Contact your administrator if you don't have access

### Data Requirements

The source table must have:
- At least one **Media** or **MediaSet** field containing images
- The **SystemId** field (available on all BC tables)

---

## Initial Setup

### Step 1: Open Media Export Setup

1. Use the search function (Alt+Q / Cmd+Q)
2. Type **"Media Export Setup"**
3. Open the page

![Search for Media Export Setup](images/search-setup.png)

### Step 2: Configure Global Settings

![Media Export Setup Page](images/setup-page.png)

#### Batch Size

**What it does**: Controls how many records are processed in each export batch.

**Recommended values**:
- **Small datasets (< 100 records)**: 50-100
- **Medium datasets (100-1000 records)**: 25-50
- **Large datasets (> 1000 records)**: 10-25

**Example**: If you set Batch Size to 50 and have 150 images:
- First batch: 50 images → ZIP file downloaded
- Second batch: 50 images → ZIP file downloaded
- Third batch: 50 images → ZIP file downloaded

> **💡 Tip**: Start with 50 and adjust based on your network speed and file sizes.

#### Allow Export Log Deletion

**What it does**: Controls whether users can delete entries from the export log.

**When to enable**:
- Testing environment
- Need to re-export previously exported images
- Cleaning up old audit data

**When to disable**:
- Production environment
- Compliance requirements mandate audit trails
- Multi-user environment

> **⚠️ Warning**: Deleting log entries will allow the same images to be exported again.

### Step 3: Save Settings

Settings are automatically saved when you close the page.

---

## Configuring Table Exports

Before you can export images, you must configure which table and fields to use.

### Step 1: Open Media Export Configuration

1. Search for **"Media Export Configuration"**
2. Open the page

### Step 2: Add a New Configuration

Click **+ New** to create a configuration.

![New Configuration](images/new-configuration.png)

### Step 3: Select Source Table

1. **Table ID**: Enter the table number or use the lookup (F6)
   - The **Table Name** will automatically display

**Example**: For "Admission Card Owner DGB" table, enter **90003**

### Step 4: Select Image Field

1. **Image Field ID**: Click the lookup button (...)
2. A list of all Media and MediaSet fields appears
3. Select the field containing your images
   - The **Image Field Name** will automatically display

![Field Lookup](images/field-lookup.png)

> **Field Types**:
> - **Media**: Single image per record
> - **MediaSet**: Multiple images per record (all will be exported)

### Step 5: Configure File Naming (Optional)

By default, exported files are named using the record's System ID (a GUID like `a1b2c3d4-e5f6-...`).

**To use meaningful file names**:

1. **File Name Field ID**: Click the lookup button (...)
2. Select a Code or Text field that contains unique values
   - Examples: Customer No., Employee ID, Item No.
3. The **File Name Field Name** will display

**Example**:
- If you select "No." field containing "CARD-001"
- Exported file will be named: `CARD-001.jpg`
- Instead of: `a7b8c9d0-1234-5678-9abc-def012345678.jpg`

> **⚠️ Important**: If the selected field is blank for a record, the System ID will be used as fallback.

### Step 6: Save Configuration

Press **Enter** or click away from the row to save.

---

## Exporting Images

### Method 1: Using Media Export Status (Recommended)

This page provides an overview of all configured tables and their export status.

#### Step 1: Open Media Export Status

1. Search for **"Media Export Status"**
2. Open the page

![Media Export Status](images/status-overview.png)

#### Step 2: Review Export Status

The page displays:

| Column | Description |
|--------|-------------|
| **Table Name** | Name of the configured table |
| **Image Field Name** | Field containing images |
| **File Name Field Name** | Field used for file naming (or blank for System ID) |
| **Eligible Records Count** | Number of records with unexported images |
| **Exported Records Count** | Total number of images already exported |

> **Highlighting**: Rows with eligible records are highlighted for attention.

#### Step 3: Refresh Counts (If Needed)

If data has changed since opening the page:
- Click **Refresh** action
- All counts will be recalculated

#### Step 4: Start Export

1. Select the table row you want to export
2. Click **Export Images** action
3. The export process begins

### Method 2: Using Direct Table Export

You can also add export actions directly to source table pages using page extensions.

---

## The Export Process

### Step-by-Step Flow

#### 1. Export Initialization

A progress dialog appears:

```
Exporting images...
Processed 15 of 50
```

> The dialog updates in real-time as images are processed.

#### 2. First Batch Completion

When the batch completes:
- A ZIP file is automatically downloaded
- File name format: `Export_[TableID]_[Count]_[Timestamp].zip`
- Example: `Export_90003_50_20260210143022.zip`

#### 3. Continue Prompt

After download, you'll see:

```
Do you want to continue exporting the next batch of records?
[Yes] [No]
```

**Choose**:
- **Yes**: Continue with the next batch
- **No**: Stop exporting

> **💡 Tip**: It's safe to select "No" and resume later. Already-exported images won't be re-exported.

#### 4. Multiple Batches

If you choose "Yes", the process repeats:
- Progress dialog appears again
- Next ZIP file is downloaded
- Continue prompt appears

This continues until:
- All eligible records are exported, OR
- You choose "No" to stop

### What Happens During Export

For each record:

1. **✓ Check for media**: Only records with images are processed
2. **✓ Check for duplicates**: Skip if already exported (prevents duplicates)
3. **✓ Get file name**: Use configured field or System ID
4. **✓ Extract image**: Convert media field to JPEG
5. **✓ Add to ZIP**: Include in archive
6. **✓ Create log entry**: Record export details

### Understanding ZIP File Contents

**Single image per record**:
```
Export_90003_50_20260210143022.zip
├── CARD-001.jpg
├── CARD-002.jpg
├── CARD-003.jpg
└── ...
```

**Multiple images per record (MediaSet)**:
```
Export_90003_50_20260210143022.zip
├── CARD-001_1.jpg
├── CARD-001_2.jpg
├── CARD-001_3.jpg
├── CARD-002_1.jpg
└── ...
```

> **Note**: MediaSet images are numbered with `_1`, `_2`, `_3` suffixes.

---

## Viewing Export History

### Opening the Export Log

1. Search for **"Media Export Log"**
2. Open the page

**Or from Media Export Status**:
1. Open **Media Export Status**
2. Select a table row
3. Click **Export Log** action
4. Log is filtered to selected table

### Understanding Log Entries

![Export Log](images/export-log.png)

| Column | Description |
|--------|-------------|
| **Table ID** | Source table number |
| **System ID** | Unique record identifier (GUID) |
| **Record ID** | Human-readable record reference |
| **Export Timestamp** | Date and time of export |
| **Image File Name** | Name of image in ZIP file |
| **Zip File Name** | Name of ZIP file containing the image |

### Using the Log

**To find when a specific image was exported**:
1. Filter by **Image File Name**
2. Check **Export Timestamp**

**To find all images in a specific ZIP**:
1. Filter by **Zip File Name**
2. Review all entries

**To verify a record was exported**:
1. Note the record's System ID from the source table
2. Filter by **System ID** in the log
3. Check if entries exist

---

## Troubleshooting

### Problem: No Images Are Exported

**Symptoms**: Export completes but no files in ZIP, or "No images found to export" message.

**Solutions**:

1. **Check if images exist**:
   - Open the source table
   - Verify the image field shows a picture
   - If blank, there's nothing to export

2. **Check if already exported**:
   - Open Media Export Log
   - Filter by Table ID
   - If records exist, they've already been exported
   - To re-export: Delete log entries (if deletion is allowed)

3. **Check configuration**:
   - Open Media Export Configuration
   - Verify Image Field ID matches the correct field
   - Use the lookup to ensure field exists

### Problem: Wrong File Names

**Symptoms**: Files named with GUIDs instead of expected values.

**Solutions**:

1. **Check field configuration**:
   - Open Media Export Configuration
   - Verify File Name Field ID is set
   - Ensure it points to a field with data

2. **Check field values**:
   - Open source table
   - Check if the file name field has values
   - If blank, System ID is used as fallback

3. **Field type issues**:
   - File name field must be Code or Text type
   - Media or numeric fields won't work

### Problem: Export Is Slow

**Symptoms**: Progress dialog hangs or takes very long.

**Solutions**:

1. **Reduce batch size**:
   - Open Media Export Setup
   - Lower Batch Size to 10-25
   - Smaller batches process faster

2. **Network issues**:
   - Large images take time to download
   - Check network connection
   - Try during off-peak hours

3. **Image size**:
   - Very large images (> 5MB) slow processing
   - Consider image compression at source

### Problem: Cannot Delete Log Entries

**Symptoms**: Error when trying to delete from Export Log.

**Solutions**:

1. **Check deletion setting**:
   - Open Media Export Setup
   - Enable "Allow Export Log Deletion"
   - Try deletion again

2. **Permissions**:
   - Verify you have DataBackup permission set
   - Contact administrator if needed

### Problem: Export Timeout

**Symptoms**: "Execution timeout" or similar error.

**Solutions**:

1. **Reduce batch size significantly**:
   - Try Batch Size = 5 or 10
   - Very large images need smaller batches

2. **Export during off-hours**:
   - Server may be busy
   - Try early morning or late evening

3. **Filter source data**:
   - Use table filters to reduce total records
   - Export in smaller logical groups

---

## Frequently Asked Questions

### General Questions

**Q: Can I export images from custom tables?**  
**A**: Yes! Any table with Media or MediaSet fields can be configured for export.

**Q: Will this delete images from the database?**  
**A**: No. Export creates copies. Source data is never modified.

**Q: Can I export the same images again?**  
**A**: Only if you delete the log entries (if permitted). The system prevents duplicate exports.

**Q: What image format is used?**  
**A**: All images are exported as JPEG (.jpg) files.

**Q: Is there a limit to how many images I can export?**  
**A**: No hard limit, but batch processing is recommended for large datasets.

### Configuration Questions

**Q: Can I configure multiple tables?**  
**A**: Yes! Create separate configurations for each table.

**Q: What if I don't know my table ID?**  
**A**: Use the lookup (F6) on the Table ID field to search by name.

**Q: Can I change configuration after exporting?**  
**A**: Yes, but it won't affect already-exported images. Future exports use new settings.

**Q: Do I need a File Name Field?**  
**A**: No, it's optional. System ID will be used if not specified.

### Export Questions

**Q: Where do ZIP files go?**  
**A**: To your browser's download folder (same as any web download).

**Q: Can I pause and resume an export?**  
**A**: Yes! Choose "No" when prompted to continue, then run export again later.

**Q: Will stopping mid-export lose my progress?**  
**A**: No. Already-exported images are logged and won't be re-exported.

**Q: Can multiple users export simultaneously?**  
**A**: Yes, but they should export from different tables to avoid conflicts.

### Technical Questions

**Q: What is System ID?**  
**A**: A unique GUID assigned to every record in Business Central. Used for reliable record identification.

**Q: What happens with MediaSet fields?**  
**A**: All images in the set are exported with numbered suffixes (_1, _2, _3, etc.).

**Q: Can I schedule automatic exports?**  
**A**: Not currently. This is a manual process. Contact Bylov Consulting for custom solutions.

**Q: Are exports compressed?**  
**A**: Yes, all images are packaged in ZIP format for efficient download.

---

## Best Practices

### ✅ Do's

- **Test with small batches first** before exporting large datasets
- **Use meaningful file name fields** when available
- **Keep batch size reasonable** (25-50 for most cases)
- **Monitor eligible vs. exported counts** to track progress
- **Review export log regularly** for audit purposes
- **Document your configurations** for team members

### ❌ Don'ts

- **Don't delete log entries in production** without good reason
- **Don't use large batch sizes** (> 100) with high-resolution images
- **Don't configure the same table twice** with different settings
- **Don't export during peak usage hours** for large datasets
- **Don't ignore error messages** - they provide important information

---

## Getting Help

### Support Resources

- **Technical Documentation**: See `technical-design.md` in the docs folder
- **Contact**: Bylov Consulting
- **Version**: 1.2.0.0

### Reporting Issues

When reporting problems, include:
1. Table ID being exported
2. Approximate number of records
3. Batch size setting
4. Error message (if any)
5. Steps to reproduce

---

## Appendix: Common Table IDs

| Table Name | Table ID |
|------------|----------|
| Admission Card Owner DGB | 90003 |
| Customer | 18 |
| Vendor | 23 |
| Item | 27 |
| Employee | 5200 |

> **Note**: Your custom tables will have IDs in your assigned range.

---

**Document Version**: 1.0  
**Last Updated**: February 2026  
**For Extension Version**: 1.2.0.0  
**Publisher**: Bylov Consulting
