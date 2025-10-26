#!/usr/bin/env bash
# Analyze the ansilust test corpus
# Provides statistics and information about ANSI art files

set -euo pipefail

CORPUS_DIR="${1:-reference/sixteencolors}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

if [[ ! -d "$CORPUS_DIR" ]]; then
    echo "Error: Corpus directory not found: $CORPUS_DIR"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  ANSILUST TEST CORPUS ANALYSIS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Overall statistics
echo "📊 OVERALL STATISTICS"
echo "─────────────────────────────────────────────────────────────"
TOTAL_SIZE=$(du -sh "$CORPUS_DIR" 2>/dev/null | cut -f1)
echo "Total corpus size: $TOTAL_SIZE"
echo ""

# File counts by extension
echo "📁 FILE COUNTS BY TYPE"
echo "─────────────────────────────────────────────────────────────"
ANS_COUNT=$(find "$CORPUS_DIR" -type f \( -iname "*.ans" \) 2>/dev/null | wc -l)
ASC_COUNT=$(find "$CORPUS_DIR" -type f \( -iname "*.asc" \) 2>/dev/null | wc -l)
BIN_COUNT=$(find "$CORPUS_DIR" -type f \( -iname "*.bin" \) 2>/dev/null | wc -l)
PCB_COUNT=$(find "$CORPUS_DIR" -type f \( -iname "*.pcb" \) 2>/dev/null | wc -l)
XB_COUNT=$(find "$CORPUS_DIR" -type f \( -iname "*.xb" -o -iname "*.xbin" \) 2>/dev/null | wc -l)
TXT_COUNT=$(find "$CORPUS_DIR" -type f \( -iname "*.txt" \) 2>/dev/null | wc -l)
DIZ_COUNT=$(find "$CORPUS_DIR" -type f \( -iname "*.diz" \) 2>/dev/null | wc -l)

printf "  ANSI files (.ans):      %6d\n" "$ANS_COUNT"
printf "  ASCII files (.asc):     %6d\n" "$ASC_COUNT"
printf "  Binary files (.bin):    %6d\n" "$BIN_COUNT"
printf "  PCBoard files (.pcb):   %6d\n" "$PCB_COUNT"
printf "  XBin files (.xb):       %6d\n" "$XB_COUNT"
printf "  Text files (.txt):      %6d\n" "$TXT_COUNT"
printf "  DIZ files (.diz):       %6d\n" "$DIZ_COUNT"
echo ""

# ANSI file size distribution
if [[ $ANS_COUNT -gt 0 ]]; then
    echo "📏 ANSI FILE SIZE DISTRIBUTION"
    echo "─────────────────────────────────────────────────────────────"

    TEMP_SIZES=$(mktemp)
    find "$CORPUS_DIR" -type f \( -iname "*.ans" \) -exec stat -f%z {} \; 2>/dev/null > "$TEMP_SIZES" || \
    find "$CORPUS_DIR" -type f \( -iname "*.ans" \) -exec stat -c%s {} \; 2>/dev/null > "$TEMP_SIZES"

    if [[ -s "$TEMP_SIZES" ]]; then
        SMALLEST=$(sort -n "$TEMP_SIZES" | head -1)
        LARGEST=$(sort -n "$TEMP_SIZES" | tail -1)
        MEDIAN=$(sort -n "$TEMP_SIZES" | awk '{a[NR]=$0} END {print (NR%2==1)?a[(NR+1)/2]:(a[NR/2]+a[NR/2+1])/2}')

        printf "  Smallest: %'10d bytes\n" "$SMALLEST"
        printf "  Median:   %'10d bytes\n" "$MEDIAN"
        printf "  Largest:  %'10d bytes\n" "$LARGEST"
        echo ""

        # Show largest files
        echo "  Largest ANSI files:"
        find "$CORPUS_DIR" -type f \( -iname "*.ans" \) -exec stat -f"%z %N" {} \; 2>/dev/null | \
            sort -rn | head -5 | while read size path; do
                printf "    %8s  %s\n" "$(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo ${size}B)" "$(basename "$path")"
            done 2>/dev/null || \
        find "$CORPUS_DIR" -type f \( -iname "*.ans" \) -exec stat -c"%s %n" {} \; 2>/dev/null | \
            sort -rn | head -5 | while read size path; do
                printf "    %8s  %s\n" "$(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo ${size}B)" "$(basename "$path")"
            done
    fi

    rm -f "$TEMP_SIZES"
    echo ""
fi

# Directory structure
echo "📂 CORPUS STRUCTURE"
echo "─────────────────────────────────────────────────────────────"
if [[ -d "$CORPUS_DIR/animated" ]]; then
    ANI_COUNT=$(find "$CORPUS_DIR/animated" -type f \( -iname "*.ans" \) 2>/dev/null | wc -l)
    ANI_SIZE=$(du -sh "$CORPUS_DIR/animated" 2>/dev/null | cut -f1)
    printf "  animated/              %3d files, %s\n" "$ANI_COUNT" "$ANI_SIZE"
fi

for year_dir in "$CORPUS_DIR"/[0-9][0-9][0-9][0-9]; do
    if [[ -d "$year_dir" ]]; then
        year=$(basename "$year_dir")
        year_ans=$(find "$year_dir" -type f \( -iname "*.ans" \) 2>/dev/null | wc -l)
        year_size=$(du -sh "$year_dir" 2>/dev/null | cut -f1)
        pack_count=$(find "$year_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        printf "  %s/                 %3d files, %s (%d packs)\n" "$year" "$year_ans" "$year_size" "$pack_count"
    fi
done
echo ""

# Artpack listing
echo "🎨 ARTPACKS"
echo "─────────────────────────────────────────────────────────────"
for year_dir in "$CORPUS_DIR"/[0-9][0-9][0-9][0-9]; do
    if [[ -d "$year_dir" ]]; then
        year=$(basename "$year_dir")
        for pack_dir in "$year_dir"/*; do
            if [[ -d "$pack_dir" ]]; then
                pack=$(basename "$pack_dir")
                pack_ans=$(find "$pack_dir" -type f \( -iname "*.ans" \) 2>/dev/null | wc -l)

                # Try to find and display first line of FILE_ID.DIZ
                diz_file=$(find "$pack_dir" -maxdepth 1 -iname "file_id.diz" -o -iname "file_id.txt" 2>/dev/null | head -1)
                if [[ -n "$diz_file" && -f "$diz_file" ]]; then
                    diz_title=$(head -1 "$diz_file" | tr -d '\r\n' | cut -c1-40)
                    printf "  %s/%-20s  %3d .ans files  │ %s\n" "$year" "$pack" "$pack_ans" "$diz_title"
                else
                    printf "  %s/%-20s  %3d .ans files\n" "$year" "$pack" "$pack_ans"
                fi
            fi
        done
    fi
done
echo ""

# Sample files for testing
echo "🎯 RECOMMENDED TEST FILES"
echo "─────────────────────────────────────────────────────────────"
echo "  Simple ANSI (good starting point):"

# Find small-to-medium ANSI files
find "$CORPUS_DIR" -type f \( -iname "*.ans" \) -exec stat -f"%z %N" {} \; 2>/dev/null | \
    sort -n | awk '$1 > 1000 && $1 < 20000 {print}' | head -3 | while read size path; do
        rel_path=$(echo "$path" | sed "s|^$PROJECT_ROOT/||")
        printf "    %s (%s)\n" "$rel_path" "$(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo ${size}B)"
    done 2>/dev/null || \
find "$CORPUS_DIR" -type f \( -iname "*.ans" \) -exec stat -c"%s %n" {} \; 2>/dev/null | \
    sort -n | awk '$1 > 1000 && $1 < 20000 {print}' | head -3 | while read size path; do
        rel_path=$(echo "$path" | sed "s|^$PROJECT_ROOT/||")
        printf "    %s (%s)\n" "$rel_path" "$(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo ${size}B)"
    done

echo ""
echo "  Animations:"
if [[ -d "$CORPUS_DIR/animated" ]]; then
    find "$CORPUS_DIR/animated" -type f \( -iname "*.ans" \) -exec stat -f"%z %N" {} \; 2>/dev/null | \
        sort -n | head -3 | while read size path; do
            rel_path=$(echo "$path" | sed "s|^$PROJECT_ROOT/||")
            printf "    %s (%s)\n" "$rel_path" "$(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo ${size}B)"
        done 2>/dev/null || \
    find "$CORPUS_DIR/animated" -type f \( -iname "*.ans" \) -exec stat -c"%s %n" {} \; 2>/dev/null | \
        sort -n | head -3 | while read size path; do
            rel_path=$(echo "$path" | sed "s|^$PROJECT_ROOT/||")
            printf "    %s (%s)\n" "$rel_path" "$(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo ${size}B)"
        done
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  For more details, see CORPUS.md"
echo "═══════════════════════════════════════════════════════════════"
