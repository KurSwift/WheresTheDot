#!/bin/bash
# =============================================================================
# take_screenshots.sh
# Captures App Store screenshots for Where's The Dot across devices and locales.
#
# Usage:
#   ./scripts/take_screenshots.sh            # all devices in parallel
#   ./scripts/take_screenshots.sh -single    # pick one device interactively
#
# Output:
#   screenshots/<version>/<build>/<locale>/<device>/<screen>.png
#
# Requirements:
#   - Xcode command line tools (xcodebuild, xcrun)
#   - Run from the repo root: cd WheresTheDot && ./scripts/take_screenshots.sh
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration — edit these to match your environment
# =============================================================================

PROJECT="WheresTheDot.xcodeproj"
SCHEME="WheresTheDot"
TEST_TARGET="WheresTheDotUITests"
TEST_CLASS="ScreenshotTests"

# Read version and build number directly from the project file
VERSION=$(grep "MARKETING_VERSION" "$PROJECT/project.pbxproj" | head -1 | sed 's/.*= //;s/;//;s/ //')
BUILD=$(grep "CURRENT_PROJECT_VERSION" "$PROJECT/project.pbxproj" | head -1 | sed 's/.*= //;s/;//;s/ //')

# Fallback if parsing fails
VERSION="${VERSION:-unknown}"
BUILD="${BUILD:-0}"

OUTPUT_DIR="screenshots/$VERSION/$BUILD"

# Locales to capture. Add more as you localise the app.
LOCALES=("en" "es")

# Simulators to target. Names must match exactly what `xcrun simctl list devices` shows.
# App Store Connect required sizes (as of 2025):
#   iPhone:  6.9" (Pro Max), 6.7" or 6.1"
#   iPad:    12.9" or 13" Pro
ALL_SIMULATORS=(
    "iPhone Air"
    "iPhone 17 Pro Max"
    "iPhone 17"
    "iPad Pro 13-inch (M5)"
)

# =============================================================================
# -single mode: prompt the user to pick one device
# =============================================================================

SIMULATORS=("${ALL_SIMULATORS[@]}")

if [ "${1:-}" = "-single" ]; then
    echo "Select a simulator:"
    for i in "${!ALL_SIMULATORS[@]}"; do
        printf "  %d) %s\n" "$((i + 1))" "${ALL_SIMULATORS[$i]}"
    done
    printf "Enter number [1-%d]: " "${#ALL_SIMULATORS[@]}"
    read -r CHOICE
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#ALL_SIMULATORS[@]}" ]; then
        echo "Invalid choice. Exiting."
        exit 1
    fi
    SIMULATORS=("${ALL_SIMULATORS[$((CHOICE - 1))]}")
    echo "Running for: ${SIMULATORS[0]}"
    echo ""
fi

# =============================================================================
# Helpers
# =============================================================================

log()  { echo "▶ $*"; }
warn() { echo "  ⚠️  $*"; }

find_simulator_udid() {
    local name="$1"
    xcrun simctl list devices available | grep "  $name (" | head -1 | grep -oE '[A-F0-9-]{36}'
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRACT_SCRIPT="$SCRIPT_DIR/extract_screenshots.py"

# =============================================================================
# Step 1 — Boot all simulators in parallel, then wait until all are ready
# =============================================================================

cd "$(dirname "$0")/.."   # always run from repo root
mkdir -p "$OUTPUT_DIR"

log "Booting simulators..."
for DEVICE in "${SIMULATORS[@]}"; do
    UDID=$(find_simulator_udid "$DEVICE")
    if [ -z "$UDID" ]; then
        warn "Simulator '$DEVICE' not found — it will be skipped."
        continue
    fi
    xcrun simctl boot "$UDID" 2>/dev/null || true   # no-op if already booted
done

log "Waiting for all simulators to reach Booted state..."
for DEVICE in "${SIMULATORS[@]}"; do
    UDID=$(find_simulator_udid "$DEVICE")
    [ -z "$UDID" ] && continue
    until xcrun simctl list devices | grep "$UDID" | grep -q "Booted"; do
        sleep 1
    done
    echo "  ✓ $DEVICE booted"
done
echo ""

# =============================================================================
# Step 2 — Build once (skips redundant per-device builds when running in parallel)
# =============================================================================

# Pick any available simulator for the build step
FIRST_UDID=$(find_simulator_udid "${SIMULATORS[0]}")
if [ -z "$FIRST_UDID" ]; then
    echo "ERROR: Could not find simulator '${SIMULATORS[0]}' for build step."
    exit 1
fi

log "Building for testing (once)..."
xcodebuild build-for-testing \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$FIRST_UDID" \
    2>&1 | grep -E "(error:|Build FAILED|Build succeeded)" || true
log "Build complete."
echo ""

# =============================================================================
# Step 3 — Run all device × locale combinations in parallel
# =============================================================================

log "Running all ${#SIMULATORS[@]} devices × ${#LOCALES[@]} locales in parallel..."
echo ""

# run_combo <locale> <device>
# Runs tests on one simulator and extracts screenshots. Designed to run in background.
run_combo() {
    local LOCALE="$1"
    local DEVICE="$2"

    local UDID
    UDID=$(find_simulator_udid "$DEVICE")
    if [ -z "$UDID" ]; then
        echo "  ⚠️  [$LOCALE / $DEVICE] Simulator not found — skipping."
        return 0
    fi

    local SAFE_DEVICE="${DEVICE// /_}"
    SAFE_DEVICE="${SAFE_DEVICE//\(/_}"
    SAFE_DEVICE="${SAFE_DEVICE//\)/_}"

    local SCREENSHOT_OUTPUT
    SCREENSHOT_OUTPUT="$(pwd)/$OUTPUT_DIR/$LOCALE/$SAFE_DEVICE"
    mkdir -p "$SCREENSHOT_OUTPUT"

    local RESULT_BUNDLE="/tmp/WheresTheDot-${SAFE_DEVICE}-${LOCALE}.xcresult"
    rm -rf "$RESULT_BUNDLE"

    local TAG="[$LOCALE / $DEVICE]"
    echo "  ▶ $TAG Starting..."

    xcodebuild test-without-building \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$UDID" \
        -only-testing:"$TEST_TARGET/$TEST_CLASS" \
        -testLanguage "$LOCALE" \
        -testRegion "$LOCALE" \
        -resultBundlePath "$RESULT_BUNDLE" \
        2>&1 | while IFS= read -r line; do
            if echo "$line" | grep -qE "Test case '.*' passed"; then
                # Extract just the test name, e.g. test03_Gameplay
                TEST_NAME=$(echo "$line" | grep -oE "ScreenshotTests\.[a-zA-Z0-9_]+" | sed 's/ScreenshotTests\.//')
                echo "    $TAG  ✓ $TEST_NAME"
            elif echo "$line" | grep -qE "Test case '.*' failed"; then
                TEST_NAME=$(echo "$line" | grep -oE "ScreenshotTests\.[a-zA-Z0-9_]+" | sed 's/ScreenshotTests\.//')
                echo "    $TAG  ✗ $TEST_NAME FAILED"
            elif echo "$line" | grep -qE "error:|Build FAILED"; then
                echo "    $TAG  ⚠️  $line"
            fi
        done || true

    if [ -d "$RESULT_BUNDLE" ]; then
        python3 "$EXTRACT_SCRIPT" "$RESULT_BUNDLE" "$SCREENSHOT_OUTPUT" > /dev/null
        rm -rf "$RESULT_BUNDLE"
        # List each captured file
        local FILES
        FILES=$(find "$SCREENSHOT_OUTPUT" -name "*.png" | sort)
        local COUNT
        COUNT=$(echo "$FILES" | grep -c ".png" || true)
        echo "  ✓ $TAG $COUNT screenshot(s) saved:"
        echo "$FILES" | while IFS= read -r f; do
            echo "      $(basename "$f")"
        done
    else
        echo "  ⚠️  $TAG No result bundle — tests may have failed to launch."
    fi
}

export -f run_combo find_simulator_udid
export PROJECT SCHEME TEST_TARGET TEST_CLASS OUTPUT_DIR EXTRACT_SCRIPT

# Spawn all combinations in parallel and collect PIDs
PIDS=()
for LOCALE in "${LOCALES[@]}"; do
    for DEVICE in "${SIMULATORS[@]}"; do
        run_combo "$LOCALE" "$DEVICE" &
        PIDS+=($!)
    done
done

# Wait for every background job to finish
FAILED=0
for PID in "${PIDS[@]}"; do
    wait "$PID" || FAILED=$((FAILED + 1))
done

echo ""

# =============================================================================
# Summary
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Screenshots saved to: $OUTPUT_DIR/  (v$VERSION build $BUILD)"
echo ""

TOTAL=$(find "$OUTPUT_DIR" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
echo "  Total PNGs: $TOTAL"
echo ""

echo "  File tree:"
find "$OUTPUT_DIR" -name "*.png" | sort | sed 's/^/    /'
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAILED" -gt 0 ]; then
    echo "  WARNING: $FAILED combination(s) exited with an error."
    exit 1
fi
