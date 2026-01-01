# Folder Comparison Tool

A comprehensive bash script for comparing two folder structures to identify differences and similarities after copying operations.

## Features

### Core Functionality
- **Size Comparison**: Compare folder and subfolder sizes at configurable depths
- **File Type Analysis**: Count and compare specific file types (case-insensitive option)
- **Total Counts**: Shows total count of each file type across both folders
- **File List Differences**: Identify files that exist in one folder but not the other
- **Summary Statistics**: Overall metrics including total size, file count, and directory count
- **Deep Scan Mode**: Detailed listing of all subfolders with size in GB and file counts
- **Multiple CSV Outputs**: Separate detailed reports for different comparison aspects

### Advanced Options
- Configurable subfolder depth (default: 2 levels)
- Deep scan mode with customizable depth for comprehensive subfolder analysis
- Case-insensitive file type matching
- Verbose logging with color-coded output
- Differences-only mode to filter out identical items
- Timestamped output files
- Human-readable size formats alongside raw bytes

## Installation

```bash
chmod +x folder_compare.sh
```

## Usage

### Basic Syntax
```bash
./folder_compare.sh [OPTIONS] <path1> <path2>
```

### Options

| Option | Description |
|--------|-------------|
| `-d, --depth DEPTH` | Depth of subdirectory comparison (default: 2) |
| `-t, --types TYPE1,TYPE2` | Comma-separated file types to count (e.g., mxf,mov,mp4) |
| `-i, --ignore-case` | Case-insensitive file type matching |
| `-l, --log FILE` | Custom log file path |
| `-o, --output-dir DIR` | Output directory for CSV files (default: /tmp) |
| `-v, --verbose` | Verbose output to console |
| `--diff-only` | Show only differences in output |
| `--deep DEPTH` | Deep scan: list all subfolders to specified depth with size & file count |
| `-x, --exclude PATTERNS` | Exclude patterns (e.g., `.git,Thumbs.db,*.tmp`). Note: `.DS_Store` always excluded |
| `-h, --help` | Display help message |

## Examples

### Individual Option Examples

#### Basic Comparison (No Options)
Compare two folders with default settings (depth 2, no file type tracking):
```bash
./folder_compare.sh /Volumes/Source/Project /Volumes/Backup/Project
```

**Output Files:**
- `compare_Project_vs_Project_YYYYMMDD_HHMMSS_summary.csv`
- `compare_Project_vs_Project_YYYYMMDD_HHMMSS_sizes.csv`
- `compare_Project_vs_Project_YYYYMMDD_HHMMSS_file_differences.csv`
- `folder_compare_YYYYMMDD_HHMMSS.log` (in /tmp)

#### Using `-d, --depth` (Depth Control)
Compare with 4 levels of subdirectory depth instead of default 2:
```bash
./folder_compare.sh -d 4 /Volumes/Source/Project /Volumes/Backup/Project
```
**Use when:** You have deeply nested folder structures and want more detailed subfolder size comparison.

#### Using `-t, --types` (File Type Tracking)
Track and compare counts of specific file types:
```bash
./folder_compare.sh -t mxf,mov,mp4 /Volumes/Source/Media /Volumes/Backup/Media
```
**Output:** Creates additional `*_filetypes.csv` file showing counts of .mxf, .mov, and .mp4 files in each folder.

#### Using `-i, --ignore-case` (Case-Insensitive File Types)
Match file types regardless of case (.MXF, .mxf, .Mxf all counted together):
```bash
./folder_compare.sh -t mxf,mov -i /Volumes/Source/Media /Volumes/Backup/Media
```
**Use when:** Working across platforms (Windows/Mac/Linux) where file extensions may have different cases.

#### Using `-l, --log` (Custom Log File)
Specify custom location and name for log file:
```bash
./folder_compare.sh -l /Users/xavier/logs/project_comparison.log /path/to/source /path/to/backup
```
**Default:** Without this option, log is created as `folder_compare_YYYYMMDD_HHMMSS.log` in /tmp.

#### Using `-o, --output-dir` (Custom Output Directory)
Save all CSV files to a specific directory:
```bash
./folder_compare.sh -o /Users/xavier/reports /path/to/source /path/to/backup
```
**Default:** Without this option, all CSV files are saved to /tmp.

#### Using `-v, --verbose` (Verbose Console Output)
Display detailed progress and results in terminal with color-coded output:
```bash
./folder_compare.sh -v /Volumes/Source/Project /Volumes/Backup/Project
```
**Use when:** You want to see real-time progress and immediate results in the console, not just log files.

#### Using `--diff-only` (Show Only Differences)
Filter output to show only items that differ between folders:
```bash
./folder_compare.sh --diff-only /Volumes/Source/Project /Volumes/Backup/Project
```
**Output:** CSV files will only contain rows where sizes differ, files are missing, or counts don't match. Identical items are excluded.

#### Using `--deep` (Deep Scan Mode)
Generate comprehensive subfolder listing with sizes in GB and file counts:
```bash
./folder_compare.sh --deep 6 /Volumes/Source/Archive /Volumes/Backup/Archive
```
**Output:** Creates additional `*_deep_scan.csv` file listing ALL subfolders to 6 levels deep with:
- Size in GB (3 decimal precision)
- File count per directory (immediate children only)
- Comparison status

#### Using `-x, --exclude` (Exclude Patterns)
Exclude specific files or patterns from all comparisons:
```bash
./folder_compare.sh -x ".git,*.tmp,Thumbs.db,*.cache" /path/to/source /path/to/backup
```
**Note:** `.DS_Store` is always excluded automatically. This adds additional exclusions.

### Combined Option Examples

#### Example 1: Video Production Workflow
Compare video project folders with 3 levels of depth, tracking specific media file types:
```bash
./folder_compare.sh \
  -d 3 \
  -t mxf,mov,mp4,wav,aiff \
  -i \
  -v \
  /Volumes/ProductionDrive/ProjectA \
  /Volumes/BackupDrive/ProjectA
```
**What this does:**
- Compares 3 levels of subfolders
- Tracks 5 media file types (case-insensitive)
- Shows verbose output in console
- Creates summary, sizes, file differences, and filetypes CSV files

#### Example 2: Backup Verification with Custom Outputs
Generate reports showing only differences, with custom log and output locations:
```bash
./folder_compare.sh \
  --diff-only \
  -t mxf,mov \
  -l /Users/xavier/logs/backup_verification.log \
  -o /Users/xavier/reports \
  /Volumes/Production/Project \
  /Volumes/Backup/Project
```
**What this does:**
- Shows only items that differ
- Tracks .mxf and .mov files
- Saves log to custom location
- Saves CSV reports to custom directory

#### Example 3: Deep Archive Analysis
Comprehensive comparison of large media archives, excluding cache files:
```bash
./folder_compare.sh \
  -d 5 \
  --deep 8 \
  -t mxf,mov,mp4,r3d,arri,dpx \
  -i \
  -x "*.cache,*.tmp,.git,Thumbs.db" \
  --diff-only \
  -v \
  /Volumes/Archive2023 \
  /Volumes/Archive2023_Backup
```
**What this does:**
- Regular size comparison to 5 levels
- Deep scan listing ALL subfolders to 8 levels with GB sizes
- Tracks 6 professional media file types (case-insensitive)
- Excludes cache, temp, and system files
- Shows only differences in output
- Displays verbose console feedback
- Creates: summary, sizes, filetypes, file_differences, AND deep_scan CSV files

#### Example 4: Migration Validation with All Options
Complete validation of a storage migration:
```bash
./folder_compare.sh \
  -d 4 \
  --deep 6 \
  -t mxf,mov,mp4,avi,r3d,arri,wav,aiff \
  -i \
  -x "*.cache,*.tmp,.git,*.bak,~*" \
  -l /Users/xavier/logs/migration_$(date +%Y%m%d).log \
  -o /Users/xavier/reports/migration \
  -v \
  /old/storage/MediaLibrary \
  /new/storage/MediaLibrary
```
**What this does:**
- Regular size comparison to 4 levels
- Deep scan to 6 levels for comprehensive folder listing
- Tracks 8 media file types (case-insensitive)
- Excludes cache, temp, backup, and system files
- Custom log with date in filename
- Custom output directory for reports
- Verbose console output
- Validates all files transferred correctly

#### Example 5: Quick Sync Verification
Fast check focusing only on differences:
```bash
./folder_compare.sh \
  --diff-only \
  -v \
  /local/project \
  /network/synced/project
```
**What this does:**
- Uses default depth (2 levels)
- Shows only differences
- Verbose output for immediate feedback
- No file type tracking (faster)
- Quick validation that sync completed

#### Example 6: Comprehensive Project Comparison
Maximum detail for critical project validation:
```bash
./folder_compare.sh \
  -d 10 \
  --deep 10 \
  -t mxf,mov,mp4,avi,r3d,arri,dpx,wav,aiff,aac,xml,edl,aaf,fcpxml \
  -i \
  -x ".git,node_modules,*.cache,*.tmp,Thumbs.db" \
  -l ~/Desktop/project_comparison.log \
  -o ~/Desktop/comparison_reports \
  -v \
  /Volumes/ProjectDrive/MainProject \
  /Volumes/BackupDrive/MainProject
```
**What this does:**
- Maximum depth (10 levels) for both regular and deep scan
- Tracks 14 different media and project file types
- Case-insensitive matching
- Excludes development and system files
- Saves log to Desktop for easy access
- Saves reports to Desktop folder
- Full verbose output
- Complete validation of complex project structure

## Output Files

### 1. Summary CSV (`*_summary.csv`)
High-level comparison metrics:
```csv
metric,SourceFolder,TargetFolder,difference,status
total_size_bytes,1073741824,1073741824,0,IDENTICAL
total_size_human,1.00GB,1.00GB,0B,
total_files,150,148,-2,DIFFERENT
total_directories,25,25,0,IDENTICAL
```

### 2. Size Comparison CSV (`*_sizes.csv`)
Detailed size breakdown by folder/subfolder:
```csv
relative_path,size_bytes_Source,size_human_Source,size_bytes_Target,size_human_Target,difference_bytes,difference_human,percent_diff,status
".",1073741824,1.00GB,1073741824,1.00GB,0,0B,0.00,IDENTICAL
"media",536870912,512.00MB,536870912,512.00MB,0,0B,0.00,IDENTICAL
"media/raw",268435456,256.00MB,268435456,256.00MB,0,0B,0.00,IDENTICAL
```

**Columns:**
- `relative_path`: Path relative to the root folder
- `size_bytes_*`: Size in bytes for each folder
- `size_human_*`: Human-readable size (KB, MB, GB)
- `difference_bytes`: Byte difference (positive = target larger)
- `difference_human`: Human-readable difference
- `percent_diff`: Percentage difference
- `status`: IDENTICAL, LARGER_IN_*, ONLY_IN_*

### 3. File Type Comparison CSV (`*_filetypes.csv`)
Count comparison for specified file types with totals:
```csv
file_type,count_Source,count_Target,total_combined,difference,percent_diff,status
mxf,45,45,90,0,0.00,IDENTICAL
mov,32,30,62,-2,-6.25,MORE_IN_Source
mp4,18,18,36,0,0.00,IDENTICAL
wav,55,55,110,0,0.00,IDENTICAL
"--- TOTAL ---",150,148,298,-2,-1.33,SUMMARY
```

**Features:**
- Individual counts for each file type
- `total_combined`: Total count across both folders
- Summary row showing totals for all tracked file types

### 4. File Differences CSV (`*_file_differences.csv`)
Files that exist in one folder but not the other:
```csv
relative_path,status,location
"./media/clip001.mov",ONLY_IN_SOURCE,SourceFolder
"./media/clip002.mov",ONLY_IN_TARGET,TargetFolder
"./docs/notes.txt",ONLY_IN_SOURCE,SourceFolder
```

### 5. Deep Scan CSV (`*_deep_scan.csv`)
Detailed listing of all subfolders to specified depth with sizes in GB and file counts:
```csv
relative_path,size_gb_Source,files_Source,size_gb_Target,files_Target,size_diff_gb,files_diff,status
".",128.543,0,128.543,0,0.000,0,IDENTICAL
"media",95.234,5,95.234,5,0.000,0,IDENTICAL
"media/raw",45.678,120,45.678,118,-0.000,-2,DIFFERENT
"media/proxy",25.123,80,25.123,80,0.000,0,IDENTICAL
"media/cache",24.433,150,24.433,150,0.000,0,IDENTICAL
"audio",18.234,45,18.234,45,0.000,0,IDENTICAL
"docs",0.125,32,0.125,32,0.000,0,IDENTICAL
```

**Features:**
- Lists every subfolder to the specified depth
- Sizes shown in GB (3 decimal places)
- File count per directory (non-recursive, immediate children only)
- Identifies missing folders with ONLY_IN_* status

**Note:** This is only generated when `--deep DEPTH` option is used.

### 6. Log File (`*.log`)
Timestamped execution log:
```
[2025-12-31 10:30:15] [INFO] =========================================
[2025-12-31 10:30:15] [INFO] Folder Comparison Tool
[2025-12-31 10:30:15] [INFO] Path 1: /Volumes/Source/Project
[2025-12-31 10:30:15] [INFO] Path 2: /Volumes/Backup/Project
[2025-12-31 10:30:15] [DEBUG] Analyzing /Volumes/Source/Project...
[2025-12-31 10:30:20] [INFO] Common files: 145
[2025-12-31 10:30:20] [INFO] Only in Project: 5
[2025-12-31 10:30:20] [INFO] Only in Project: 3
```

## Status Indicators

### Size Comparison
- `IDENTICAL`: Sizes match exactly
- `LARGER_IN_[folder]`: Indicates which folder is larger
- `ONLY_IN_[folder]`: Path exists only in specified folder

### File Type Comparison
- `IDENTICAL`: Same count in both folders
- `MORE_IN_[folder]`: More files in specified folder
- `NONE_FOUND`: No files of this type in either folder
- `SUMMARY`: Total row summing all tracked file types

### File List Comparison
- `ONLY_IN_SOURCE`: File exists only in first path
- `ONLY_IN_TARGET`: File exists only in second path

### Deep Scan
- `IDENTICAL`: Folder size and file count match exactly
- `DIFFERENT`: Size or file count differs
- `ONLY_IN_[folder]`: Folder exists only in specified path
- `BOTH_EMPTY`: Folder exists in both but is empty

## Use Cases

### 1. Backup Verification
Verify that a backup operation completed successfully:
```bash
./folder_compare.sh \
  -v \
  --diff-only \
  /Volumes/Production/CurrentProject \
  /Volumes/Backup/CurrentProject
```

### 2. Migration Validation
Ensure all media files were transferred during a storage migration, excluding cache files:
```bash
./folder_compare.sh \
  -d 4 \
  -t mxf,mov,mp4,avi,r3d,arri \
  -i \
  -x "*.cache,*.tmp,.git" \
  /old/storage/location \
  /new/storage/location
```

### 3. Archive Comparison
Compare archived projects with different depths:
```bash
./folder_compare.sh \
  -d 6 \
  -t "*" \
  -l archive_comparison.log \
  /Archives/2024/ProjectX \
  /BackupArchive/2024/ProjectX
```

### 4. Sync Troubleshooting
Identify discrepancies after a sync operation:
```bash
./folder_compare.sh \
  --diff-only \
  -v \
  -t all \
  /local/folder \
  /network/synced/folder
```

### 5. Large Media Archive Analysis
Deep scan a complex media archive to identify all subfolders and their sizes:
```bash
./folder_compare.sh \
  --deep 8 \
  -t mxf,mov,mp4,r3d,arri,dpx \
  -i \
  --diff-only \
  /Volumes/Archive2023 \
  /Volumes/Archive2023_Backup
```

## Improvements Over Original Script

1. **Configurable Depth**: Not limited to 2 levels
2. **File Type Analysis**: Track specific file types relevant to your workflow
3. **File Type Totals**: Shows total count of each file type across both folders
4. **Deep Scan Mode**: List all subfolders to any depth with GB sizes and file counts
5. **Smart Exclusions**: Always excludes `.DS_Store`, with optional custom patterns
6. **Multiple Reports**: Separate CSV files for different aspects
7. **Better Size Handling**: Both bytes and human-readable formats (plus GB for deep scan)
8. **File List Comparison**: Identify missing/extra files
9. **Status Indicators**: Clear labeling of differences
10. **Logging**: Full audit trail with timestamps
11. **Filtering**: `--diff-only` mode to focus on discrepancies
12. **Case Insensitive**: Useful for cross-platform comparisons
13. **Summary Statistics**: Quick overview of overall differences

## Additional Enhancement Ideas

### Potential Future Features

1. **MD5/SHA Checksum Comparison**
   - Compare file content, not just size
   - Detect corrupted files after transfer
   ```bash
   # Pseudocode enhancement
   -c, --checksum  # Enable checksum comparison
   ```

2. **Timestamp Analysis**
   - Compare modification dates
   - Identify newer/older versions
   ```bash
   # Pseudocode enhancement
   --check-timestamps  # Compare file modification times
   ```

3. **Permissions & Attributes**
   - Compare file permissions
   - Extended attributes (macOS)
   ```bash
   # Pseudocode enhancement
   --check-permissions  # Compare file permissions
   ```

4. **Parallel Processing**
   - Use GNU parallel for large directories
   - Faster comparison of huge datasets

5. **Interactive Mode**
   - Preview differences before generating reports
   - Select which comparisons to run

6. **HTML/JSON Output**
   - Web-based report viewing
   - Integration with other tools
   ```bash
   # Pseudocode enhancement
   --format html|csv|json
   ```

7. **Threshold Filtering**
   - Only report differences above certain size
   - Filter by percentage difference
   ```bash
   # Pseudocode enhancement
   --min-diff 1GB  # Only show differences >= 1GB
   --min-percent 5  # Only show >= 5% differences
   ```

8. **Exclusion Patterns**
   - Ignore certain folders (.git, .DS_Store, etc.)
   - Custom exclusion patterns
   ```bash
   # Pseudocode enhancement
   --exclude ".git,.DS_Store,Thumbs.db"
   ```

9. **Email Notifications**
   - Send report via email when complete
   - Alert on significant differences

10. **Database Storage**
    - Store comparison history
    - Track changes over time
    - Generate trend reports

11. **Visual Diff Tool Integration**
    - Launch GUI diff tools for specific folders
    - Integration with Beyond Compare, Meld, etc.

12. **Duplicate Detection**
    - Find duplicate files within and across folders
    - Space-saving recommendations

## Performance Tips

1. **Use appropriate depth**: Deeper comparisons take longer
2. **Limit file types**: Only specify types you need to track
3. **Use `--diff-only`**: Reduces output file size for large comparisons
4. **SSD vs HDD**: Comparisons are much faster on SSDs
5. **Network drives**: Local comparisons are faster; copy to local drive if possible

## Troubleshooting

### Permission Errors
If you get permission denied errors:
```bash
# Run with sudo if comparing system folders
sudo ./folder_compare.sh [options] path1 path2
```

### Large Directories
For very large directories (100k+ files):
```bash
# Use lower depth and specific file types
./folder_compare.sh -d 2 -t mxf,mov /large/path1 /large/path2
```

### Memory Issues
If the script runs out of memory:
- Reduce depth with `-d 1` or `-d 2`
- Use `--diff-only` to reduce output
- Compare subdirectories separately

## License

Copyright Mat X 2025 - All Rights Reserved

## Contributing

Suggestions for improvements:
1. Test with your specific workflows
2. Report any bugs or edge cases
3. Suggest additional comparison metrics
4. Share performance optimization ideas
