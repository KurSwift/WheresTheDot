#!/bin/bash
# =============================================================================
# resize_screenshots.sh
# Resizes App Store screenshots to App Store Connect accepted sizes.
#
# App Store Connect accepted sizes (portrait):
#   1242 x 2688  — 6.5" (iPhone XS Max / 11 Pro Max)
#   1284 x 2778  — 6.7" (iPhone 12/13/14/15 Pro Max)
#
# Usage:
#   ./scripts/resize_screenshots.sh                    # resizes latest build
#   ./scripts/resize_screenshots.sh screenshots/1.0/6  # resizes specific build
#
# Output:
#   <input_dir>/resized/<device>/<screen>.png
#
# Requirements:
#   - sips (built into macOS)
# =============================================================================

set -euo pipefail

cd "$(dirname "$0")/.."

# ---------------------------------------------------------------------------
# Resolve input directory
# ---------------------------------------------------------------------------

if [ "${1:-}" != "" ]; then
    INPUT_DIR="$1"
else
    # Pick the latest build folder automatically
    INPUT_DIR=$(find screenshots -mindepth 2 -maxdepth 2 -type d | sort | tail -1)
fi

if [ -z "$INPUT_DIR" ] || [ ! -d "$INPUT_DIR" ]; then
    echo "ERROR: Could not find screenshots directory. Run take_screenshots.sh first."
    exit 1
fi

echo "▶ Input:  $INPUT_DIR"

OUTPUT_DIR="$INPUT_DIR/resized"
mkdir -p "$OUTPUT_DIR"

echo "▶ Output: $OUTPUT_DIR"
echo ""

# ---------------------------------------------------------------------------
# Device → target size mapping
# Picked to minimise distortion (closest aspect ratio match).
#   iPhone 17 Pro Max  1320x2868  → 1284x2778
#   iPhone Air         1260x2736  → 1284x2778
#   iPhone 17          1206x2622  → 1242x2688
# ---------------------------------------------------------------------------

target_size() {
    case "$1" in
        iPhone_17_Pro_Max) echo "1284 2778" ;;
        iPhone_Air)        echo "1284 2778" ;;
        iPhone_17)         echo "1242 2688" ;;
        *)                 echo "" ;;
    esac
}

# ---------------------------------------------------------------------------
# Process each locale / device / screenshot
# ---------------------------------------------------------------------------

TOTAL=0
SKIPPED=0

while IFS= read -r PNG; do
    DEVICE=$(basename "$(dirname "$PNG")")
    LOCALE=$(basename "$(dirname "$(dirname "$PNG")")")
    FILE=$(basename "$PNG")

    SIZE=$(target_size "$DEVICE")
    if [ -z "$SIZE" ]; then
        echo "  ⚠️  [$LOCALE / $DEVICE] No target size defined — skipping."
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    W=$(echo "$SIZE" | cut -d' ' -f1)
    H=$(echo "$SIZE" | cut -d' ' -f2)

    DEST="$OUTPUT_DIR/$LOCALE/$DEVICE"
    mkdir -p "$DEST"

    sips --resampleHeightWidth "$H" "$W" "$PNG" --out "$DEST/$FILE" > /dev/null

    echo "  ✓ [$LOCALE / $DEVICE] $FILE  →  ${W}x${H}"
    TOTAL=$((TOTAL + 1))
done < <(find "$INPUT_DIR" -path "*/resized" -prune -o -name "*.png" -print | sort)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Resized: $TOTAL screenshot(s)"
[ "$SKIPPED" -gt 0 ] && echo "  Skipped: $SKIPPED (no target size mapping)"
echo "  Saved to: $OUTPUT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
