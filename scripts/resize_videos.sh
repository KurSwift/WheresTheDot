#!/bin/bash
# =============================================================================
# resize_videos.sh
# Resizes App Store preview videos (.mov) to App Store Connect accepted sizes.
#
# App Store Connect requirements:
#   - Format: H.264, .mov or .mp4
#   - Frame rate: 15–30 fps
#   - Max size: 500 MB per video
#   - Target size: 886x1920
#
# Usage:
#   ./scripts/resize_videos.sh                    # resizes latest build
#   ./scripts/resize_videos.sh screenshots/1.0/6  # resizes specific build
#   ./scripts/resize_videos.sh path/to/folder     # any folder with .mov files
#
# Output:
#   Overwrites the original .mov files in place.
#
# Requirements:
#   - ffmpeg: brew install ffmpeg
# =============================================================================

set -euo pipefail

cd "$(dirname "$0")/.."

# ---------------------------------------------------------------------------
# Check ffmpeg
# ---------------------------------------------------------------------------

if ! command -v ffmpeg &> /dev/null; then
    echo "ERROR: ffmpeg is not installed."
    echo "       Install it with: brew install ffmpeg"
    exit 1
fi

# ---------------------------------------------------------------------------
# Resolve input directory
# ---------------------------------------------------------------------------

if [ "${1:-}" != "" ]; then
    INPUT_DIR="$1"
else
    INPUT_DIR=$(find screenshots -mindepth 2 -maxdepth 2 -type d | sort | tail -1)
fi

if [ -z "$INPUT_DIR" ] || [ ! -d "$INPUT_DIR" ]; then
    echo "ERROR: Could not find input directory."
    exit 1
fi

echo "▶ Input:  $INPUT_DIR"
echo ""

echo "Select target size:"
echo "  1) iPhone  886 x 1920"
echo "  2) iPad   1200 x 1600"
printf "Enter number [1-2]: "
read -r CHOICE

case "$CHOICE" in
    1) W=886;  H=1920 ;;
    2) W=1200; H=1600 ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac

echo "▶ Target: ${W}x${H} (overwrite in place)"
echo ""

# ---------------------------------------------------------------------------
# Process each video
# ---------------------------------------------------------------------------

TOTAL=0

while IFS= read -r MOV; do
    FILE=$(basename "$MOV")
    DIR=$(dirname "$MOV")
    TMP="${DIR}/.tmp_${FILE}"

    echo "  ▶ $MOV"

    ffmpeg -i "$MOV" \
        -vf "scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2" \
        -c:v libx264 \
        -crf 18 \
        -preset slow \
        -c:a aac \
        -b:a 128k \
        -movflags +faststart \
        -y \
        "$TMP" 2>&1 | grep -E "^(ffmpeg|Error|frame=)" | tail -1 || true

    mv "$TMP" "$MOV"
    echo "  ✓ $FILE  →  ${W}x${H}"
    TOTAL=$((TOTAL + 1))
done < <(find "$INPUT_DIR" -name "*.mov" | sort)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Resized: $TOTAL video(s)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
