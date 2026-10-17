---
name: take-screenshots
description: Generates App Store screenshots for WheresTheDot by running the screenshot UI tests across all configured simulators and locales. Use this skill when the user asks to take, generate, capture, or refresh App Store screenshots, or when they say something like "run the screenshot tool", "capture screenshots", "update screenshots for the store", or "generate screenshots".
---

# Take App Store Screenshots

You are generating App Store screenshots for the WheresTheDot iOS app using the automated screenshot script.

## Step 1 — Read the current version and build

Run this to show the user what version/build the screenshots will be tagged with:

```bash
cd /Users/ernestosanchezkuri/WheresTheDot && xcrun agvtool what-marketing-version -terse1 && xcrun agvtool what-version -terse
```

Tell the user: "Screenshots will be saved under `screenshots/{version}/{build}/`."

## Step 2 — Check simulators are available

Run this and confirm the simulators configured in the script exist:

```bash
xcrun simctl list devices available | grep -E "iPhone Air|iPhone 17 Pro Max|iPhone 17|iPad Pro 13-inch|iPhone Duo"
```

The script requires Xcode 27.1 or newer (the app uses iPhone Duo APIs) and exits with the
exact command to run if an older Xcode is selected. On this machine Xcode 27.1 lives at
`/Applications/Xcode_27.1.app`, so prefix commands with
`DEVELOPER_DIR=/Applications/Xcode_27.1.app/Contents/Developer` when `xcodebuild -version` reports an older Xcode.

If any are missing, warn the user before proceeding. They can add them via **Xcode → Window → Devices and Simulators → Simulators → +**.

## Step 3 — Run the screenshot script

```bash
cd /Users/ernestosanchezkuri/WheresTheDot && ./scripts/take_screenshots.sh
```

This will:
- Loop over all configured locales (en, es) and simulators
- Launch the app with `-screenshotMode` on each simulator
- Capture screenshots for each screen defined in `ScreenshotTests.swift`
- Save PNGs to `screenshots/{version}/{build}/{locale}/{device}/`

The script prints progress as it runs. It takes a few minutes per device.

### iPhone Duo

The default run does not include iPhone Duo: the simulator can't fold from the command line.
Capture it separately; the user must fold/unfold it by hand in Device Hub between the two passes:

```bash
cd /Users/ernestosanchezkuri/WheresTheDot && ./scripts/take_screenshots.sh -duo
```

1. The first pass captures whichever display is active and saves it as `iPhone_Duo_outer` or
   `iPhone_Duo_inner` (detected from the image size: outer 1398x2034, inner 2007x2853).
2. The script pauses. Ask the user to fold or unfold the device in Device Hub, then press Enter.
   Typing `s` stops after one display.
3. The second pass captures the other display. If both passes captured the same display the
   script warns that the device wasn't folded/unfolded.

When running it yourself non-interactively, pipe `s` to capture only the current display:
`printf 's\n' | ./scripts/take_screenshots.sh -duo`.

App Store Connect has an iPhone Duo screenshot slot with both outer and inner sizes.

## Step 4 — Report results

After the script finishes, list what was captured:

```bash
find /Users/ernestosanchezkuri/WheresTheDot/screenshots -name "*.png" | sort
```

Tell the user:
- How many screenshots were captured total
- The full output path (e.g. `screenshots/1.0/6/en/iPhone_17_Pro_Max/`)
- If any device/locale combinations were skipped (the script prints ⚠️ for those)
- That screenshots are ready to upload to App Store Connect under **App → Screenshots** for each device size

## Troubleshooting

**Simulator not found** — the device name in `scripts/take_screenshots.sh` must match exactly what `xcrun simctl list devices available` shows. Edit the `SIMULATORS` array in the script to fix.

**Test fails to launch** — the `WheresTheDotUITests` target must have `ScreenshotTests.swift` in its Target Membership. Check in Xcode: select the file → File Inspector → confirm `WheresTheDotUITests` is checked.

**0 screenshots captured for a device** — run the test manually in Xcode first (`test01_MainMenuNeon`) to verify the single-test flow works before running the full script.

**Wrong version/build shown** — bump the version or build in Xcode (**Project → Target → General → Version/Build**) before running, then screenshots will be filed under the correct folder.
