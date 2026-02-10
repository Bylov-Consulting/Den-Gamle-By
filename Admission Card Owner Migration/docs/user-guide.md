# Admission Card Owner Migration - User Guide

## Introduction

This guide explains how to use the Admission Card Owner Migration extension to copy your admission card owner data from the original JCD Retail - Admission system to the new DGB Data Backup system.

### What This Extension Does

The Admission Card Owner Migration extension:
- Copies all admission card owner records from the old table to the new table
- Copies all pictures and creates independent media files
- Prevents duplicate records
- Shows real-time progress during migration
- Allows you to retry if needed without creating duplicates

### When to Use This Extension

Use this migration tool when:
- You're transitioning from JCD Retail - Admission to DGB Data Backup
- You need to preserve all admission card owner data and pictures
- You want a one-time bulk copy operation
- You need to migrate a few or many records (works for both)

### What You Need Before Starting

**Required**:
- Both extensions installed:
  - JCD Retail - Admission (source system)
  - DGB Data Backup (destination system)
- Appropriate permissions to both tables
- Records in the "Admission Card Owner" table to migrate

**Recommended**:
- Database backup (especially for large migrations)
- Migration during off-hours (for > 1000 records)
- A few minutes of uninterrupted time

---

## Quick Start Guide

### Migration in 3 Simple Steps

1. **Open the destination page**: Search for "Admission Card Owners DGB"
2. **Click the action**: Select "Copy to DGB Table" from the ribbon
3. **Wait for completion**: Watch the progress dialog and view the results

That's it! The migration handles everything automatically.

---

## Detailed Migration Procedures

### Option 1: Bulk Migration (All Records)

Use this approach to copy all admission card owners at once.

#### Step-by-Step Instructions

**Step 1: Open Admission Card Owners DGB Page**

1. Press `Alt + Q` to open the search box
2. Type: `Admission Card Owners DGB`
3. Press `Enter` or click the result

or

1. Navigate through the menu:
   - Main Menu → DGB Data Backup → Admission Card Owners DGB

**Step 2: Start the Migration**

1. In the ribbon menu, click `Actions` → `Functions`
2. Click `Copy to DGB Table`
3. The progress dialog will appear immediately

**Step 3: Monitor Progress**

A progress dialog shows real-time information:

```
Copying records...

Processed 237 of 450. Progress: 52%

Copied: 215 | Skipped: 20 | Failed: 2
```

**What the numbers mean**:
- **Processed**: How many records have been reviewed
- **Copied**: Successfully copied new records
- **Skipped**: Records that already existed (no action needed)
- **Failed**: Records that couldn't be copied (rare)

**Step 4: Review Results**

When complete, you'll see a summary message:

```
Migration completed!
Copied: 215 records
Skipped: 20 records
Failed: 2 records
```

**Understanding the Results**:

| Count | Meaning | Action Needed |
|-------|---------|---------------|
| Copied | New records successfully migrated | ✅ None |
| Skipped | Records already exist in destination | ✅ None (safe to ignore) |
| Failed | Records couldn't be copied | ⚠️ Investigate (see Troubleshooting) |

#### How Long Will It Take?

| Number of Records | Estimated Time |
|-------------------|---------------|
| 1-100 | Less than 1 minute |
| 100-500 | 1-5 minutes |
| 500-1000 | 5-10 minutes |
| 1000-5000 | 10-50 minutes |
| 5000+ | More than 1 hour |

**Tip**: Migration time increases if records have large pictures.

---

### Option 2: Single Record Migration

Use this approach to copy one specific admission card owner.

#### When to Use Single Record Migration

- You only need to migrate one new person
- You want to retry a specific failed record
- You're testing the migration before doing bulk

#### Step-by-Step Instructions

**Step 1: Get the Card Owner Number**

1. Open "Admission Card Owners" (source table)
2. Find the record you want to copy
3. Note the "No." field value (e.g., "00001234")

**Step 2: Trigger Single Copy**

This requires a custom action or using the codeunit directly from code.

**From AL Code**:
```al
var
    Migration: Codeunit "Admission Card Owner Migration";
    CardOwnerNo: Code[20];
begin
    CardOwnerNo := '00001234';  // Replace with actual number
    if Migration.CopySingleToDGBTable(CardOwnerNo) then
        Message('Record copied successfully')
    else
        Message('Record could not be copied');
end;
```

**Note**: Single record copy is primarily for development/testing. For normal use, bulk migration is recommended.

---

## After Migration

### Verify the Migration

Follow these steps to ensure everything copied correctly:

**Step 1: Check Record Counts**

1. **Count source records**:
   - Open "Admission Card Owners"
   - Look at bottom-right corner for total count
   - Note the number (e.g., 450)

2. **Count destination records**:
   - Open "Admission Card Owners DGB"
   - Look at bottom-right corner for total count
   - Should match source count (minus any pre-existing records)

**Step 2: Check Expected Counts**

```
Source Records: 450
Destination Records Before: 20
Copied During Migration: 215
Skipped During Migration: 20
Failed During Migration: 2

Expected Destination Count: 20 + 215 = 235 ✅
(450 - 215 = 235 not copied: 20 skipped + 2 failed + 213 that existed before)
```

**Step 3: Spot-Check Data**

Pick a few random records and verify:

1. **Basic Data**:
   - Open a record in source table
   - Open same record (by No.) in destination table
   - Compare: First Name, Last Name, Email, Phone, etc.
   - Should be identical

2. **Pictures**:
   - Check that pictures appear in destination records
   - Verify pictures match the source
   - Pictures should be visible even if you delete from source (independent copies)

**Step 4: Test Export Functionality**

If using DGB Data Backup to export pictures:

1. Open "Admission Card Owners DGB"
2. Set up Media Export Configuration (see DGB Data Backup User Guide)
3. Run a test export on a few records
4. Verify images export correctly

---

## Common Scenarios

### Scenario 1: First-Time Migration

**Situation**: You've just installed DGB Data Backup and need to migrate all historical data.

**Steps**:
1. Backup your database
2. Use bulk migration (Option 1)
3. All records will be copied (Skipped count should be 0 or very low)
4. Verify counts and spot-check
5. Begin using DGB Data Backup

**Expected Result**: 
- Copied: ~all records
- Skipped: 0-5
- Failed: 0

---

### Scenario 2: Adding New Records After Initial Migration

**Situation**: You migrated months ago, and now have new admission card owners to migrate.

**Steps**:
1. Use bulk migration (Option 1)
2. Previously migrated records will be skipped automatically
3. Only new records will be copied

**Expected Result**:
- Copied: Number of new records
- Skipped: All previously migrated records
- Failed: 0

**Why This Works**: The migration checks if each record already exists and skips it. Safe to run multiple times.

---

### Scenario 3: Migration Failed Partway Through

**Situation**: Migration was interrupted (power outage, system crash, user cancelled).

**Steps**:
1. Re-run the migration (Option 1)
2. Already-copied records will be skipped
3. Remaining records will be copied

**Expected Result**: 
- Copied: Remaining records not yet copied
- Skipped: Records copied before interruption
- Failed: 0 (unless data issues exist)

**Important**: The migration commits every 100 records, so most progress is saved even if interrupted.

---

### Scenario 4: Some Records Failed

**Situation**: Migration completed but a few records failed.

**Steps**:
1. Note the failed count (e.g., "Failed: 3")
2. Identify which records failed (check destination for missing numbers)
3. Check source records for data issues
4. Fix any data problems
5. Re-run migration (will skip successful records, retry failed ones)

**Common Causes of Failures**:
- Invalid data in source fields
- System permission issues
- Corrupted picture data

---

## Frequently Asked Questions (FAQ)

### General Questions

**Q: Can I run the migration multiple times?**  
**A**: Yes! The migration automatically skips records that already exist. It's completely safe to run repeatedly.

**Q: Will this migration affect my source data?**  
**A**: No. The source "Admission Card Owner" table is only read from, never modified or deleted.

**Q: What happens if I cancel the migration partway through?**  
**A**: Records copied before cancellation remain in the destination. The migration commits every 100 records, so you won't lose much progress. Simply re-run to continue.

**Q: Can I undo the migration?**  
**A**: Not automatically. You would need to manually delete records from "Admission Card Owner DGB" or restore from backup.

### Picture Questions

**Q: Do pictures take extra time to migrate?**  
**A**: Yes, slightly. Larger pictures take longer to copy. Most pictures copy in < 1 second each.

**Q: Are pictures shared between source and destination?**  
**A**: No! The migration creates independent copies. You can safely delete source records without affecting destination pictures.

**Q: What if a card owner doesn't have a picture?**  
**A**: No problem. The migration handles empty pictures gracefully and just copies the data fields.

**Q: Will picture quality be affected?**  
**A**: No. Pictures are copied at full quality using binary stream transfer.

### Technical Questions

**Q: What happens if the destination record already exists but has different data?**  
**A**: The existing destination record is left unchanged. The migration only creates new records; it never updates existing ones.

**Q: Can other users work in Business Central during migration?**  
**A**: Yes, but for large migrations (> 1000 records), off-hours are recommended for better performance.

**Q: How much disk space is needed for migrated pictures?**  
**A**: Same as source pictures (independent copies are created). If source pictures total 500 MB, destination will use another 500 MB.

**Q: Can I migrate only specific records (e.g., by customer)?**  
**A**: Not with the standard bulk migration. This would require custom development or manual single-record copying.

### Error Questions

**Q: What does "Record already exists" mean?**  
**A**: The destination table already has a record with that "No." This is counted as "Skipped," not an error. The existing record is preserved.

**Q: Why would records fail to copy?**  
**A**: Rare, but possible causes include:
- Data validation errors
- Permission issues
- System resources exhausted
- Corrupted picture data

**Q: How do I find out which specific records failed?**  
**A**: Compare record counts or manually check for missing records in the destination table. Future versions may include detailed error logs.

---

## Troubleshooting

### Issue: "Table not found" Error

**Symptoms**: Error message when trying to copy

**Possible Causes**:
- DGB Data Backup extension not installed
- JCD Retail - Admission extension not installed
- Extensions not activated for your company

**Solutions**:
1. Verify both extensions installed:
   - Open Extension Management
   - Search for "DGB Data Backup" → Should show as Installed
   - Search for "JCD Retail - Admission" → Should show as Installed
2. Activate extensions for your company if needed
3. Check with system administrator if issues persist

---

### Issue: All Records Show as "Skipped"

**Symptoms**: Migration completes immediately, all records skipped, Copied count = 0

**Possible Causes**:
- Records have already been migrated
- You're running migration on an already-migrated dataset

**Solutions**:
1. **This is usually not a problem!** It means all records already exist in the destination.
2. Check destination table for records
3. To re-migrate (overwrite):
   - Delete records from "Admission Card Owner DGB" table
   - Re-run migration

**When This Is Expected**:
- Running migration a second time
- Testing migration multiple times

---

### Issue: High Number of Failed Records

**Symptoms**: Many records fail to copy (e.g., Failed: 50 out of 500)

**Possible Causes**:
- Data quality issues in source table
- System permission problems
- Database constraints

**Solutions**:
1. **Identify failed records**:
   - Compare source and destination record numbers
   - Look for gaps in destination (missing numbers)

2. **Check source data**:
   - Open failed records in source table
   - Look for unusual or invalid data
   - Check for very large picture files

3. **Check permissions**:
   - Ensure you have Insert permission on destination table
   - Verify table permissions in Extension Management

4. **Retry after fixes**:
   - Fix any data issues identified
   - Re-run migration (will retry failed records only)

5. **Contact Support**:
   - If issue persists with clean data
   - Provide failure count and sample record numbers

---

### Issue: Migration Very Slow

**Symptoms**: Migration takes much longer than expected

**Possible Causes**:
- Large picture files
- High server load
- Network latency (cloud environment)
- Database performance issues

**Solutions**:
1. **Be patient**: Large pictures can take time
2. **Run during off-hours**: Less server load = faster migration
3. **Check server resources**: CPU, memory, disk I/O
4. **Don't cancel**: Canceling and restarting wastes time
5. **Consider staging**: If > 5000 records, consider migrating in batches

**Performance Tips**:
- Run migrations during low-usage periods
- Close unnecessary programs on server
- Ensure good network connection
- Allow uninterrupted time

---

### Issue: Pictures Missing After Migration

**Symptoms**: Records copied successfully, but pictures don't show in destination

**Possible Causes**:
- Source records had no pictures
- Picture copy failed (but record copied)
- Picture rendering issue

**Solutions**:
1. **Check source records**:
   - Open source "Admission Card Owner"
   - Verify records actually have pictures
   - If source has no picture, destination won't either

2. **Check for specific failures**:
   - Look at Failed count
   - If only a few records: may be individual picture issues
   - Re-run migration to retry

3. **Verify destination display**:
   - Refresh the destination page
   - Check if Picture FactBox is visible
   - Try viewing in different page layouts

4. **Test new upload**:
   - Upload a test picture to a destination record
   - If this works, migration completed but source was empty
   - If this fails, check permissions on Media storage

---

### Issue: "Copying records" Dialog Won't Close

**Symptoms**: Progress dialog frozen on screen after migration completes

**Possible Causes**:
- UI rendering issue
- Background process still running

**Solutions**:
1. **Wait a few seconds**: May be finalizing
2. **Click OK**: Dialog should close
3. **Refresh page**: Close and reopen "Admission Card Owners DGB"
4. **Check if migration completed**:
   - Compare record counts
   - Look for summary message
5. **If truly stuck**:
   - Close Business Central web client
   - Reopen and verify migration results

---

## Best Practices

### Before Migration

✅ **Do**:
- Backup your database
- Count source records for comparison
- Plan for adequate time (don't rush)
- Run during off-hours for large datasets
- Verify both extensions installed

❌ **Don't**:
- Migrate during peak business hours (> 1000 records)
- Start migration without backup (for large datasets)
- Close dialog or browser during migration
- Assume all records must have pictures

---

### During Migration

✅ **Do**:
- Watch the progress dialog
- Note the final counts (Copied/Skipped/Failed)
- Let it complete uninterrupted

❌ **Don't**:
- Cancel unless absolutely necessary
- Close the browser or Business Central
- Modify source or destination tables
- Run multiple migrations simultaneously

---

### After Migration

✅ **Do**:
- Verify record counts match expectations
- Spot-check several records
- Test export functionality (if using DGB Data Backup)
- Document results (Copied/Skipped/Failed counts)
- Keep source data for some time as backup

❌ **Don't**:
- Delete source data immediately
- Assume migration is perfect without verification
- Ignore failed records (investigate)
- Run migration again unless needed (wastes time)

---

## Additional Resources

### Related Extensions

- **DGB Data Backup**: The destination system with export capabilities (Required)
  - See: DGB Data Backup User Guide
- **JCD Retail - Admission**: The source system (Required)

### Getting Help

**For Migration Questions**:
- Review this user guide
- Check Troubleshooting section
- Contact your Business Central administrator

**For Technical Issues**:
- Contact Bylov Consulting support
- Provide:
  - Number of records (source and destination)
  - Copied/Skipped/Failed counts
  - Any error messages
  - Screenshots of issues

### Further Reading

- [Technical Design Document](technical-design.md) - Detailed architecture and algorithms
- DGB Data Backup User Guide - How to use the export functionality
- Business Central Documentation - Working with Media fields

---

## Appendix: Migration Checklist

Use this checklist to ensure a smooth migration:

### Pre-Migration Checklist

- [ ] Both extensions installed and activated
- [ ] Database backup completed (for large migrations)
- [ ] Source record count documented: ___________
- [ ] Destination record count documented: ___________
- [ ] Sufficient time allocated based on record count
- [ ] Migration scheduled during off-hours (if > 1000 records)

### Migration Checklist

- [ ] Open "Admission Card Owners DGB" page
- [ ] Click "Copy to DGB Table"
- [ ] Monitor progress dialog
- [ ] Note final counts:
  - Copied: ___________
  - Skipped: ___________
  - Failed: ___________
- [ ] Progress dialog closed successfully

### Post-Migration Checklist

- [ ] Destination record count matches expectation
- [ ] Calculation verified:
  - Previous destination count: ___________
  - + Copied count: ___________
  - = New destination count: ___________
- [ ] Spot-checked 5-10 random records
- [ ] Verified pictures visible in destination
- [ ] Tested DGB Data Backup export (if applicable)
- [ ] Investigated any failed records
- [ ] Documented migration results
- [ ] Informed users migration complete

---

**Document Version**: 1.2.0  
**Last Updated**: February 2026  
**Publisher**: Bylov Consulting  
**Support**: Contact your Business Central administrator or Bylov Consulting

**Note**: This guide is for the Admission Card Owner Migration extension. For documentation on using the DGB Data Backup export features, see the DGB Data Backup User Guide.
