---
name: add-theme
description: Adds a new visual theme to the WheresTheDot iOS app. Use this skill whenever the user wants to create a new theme, add a color scheme, or define a new visual style for the game. Trigger on any phrasing like "add a theme", "create a new theme called X", "I want a new theme", "add a [name] theme", or "new theme with colors X Y Z".
---

# Add Theme

You are adding a new visual theme to the WheresTheDot iOS app. Themes are defined in `WheresTheDot/Domain/Theme.swift` and must be wired into several other files. Follow every step in order — do not skip any.

## Required inputs

Parse the following from `$ARGUMENTS`. If any required field is missing or ambiguous, ask the user before proceeding — do not guess.

| Field | Required | Notes |
|---|---|---|
| **Theme name** | Yes | Display name, e.g. "Midnight". The ThemeID case will be the lowercased, no-space version. |
| **Background color** | Yes | Hex string, e.g. `#040812` |
| **Grid color** | Yes | Hex string |
| **Dot colors** | Yes | Comma-separated hex strings — provide exactly 5 |
| **Accent color** | Yes | Hex string — usually matches the first or most prominent dot color |
| **Unlock type** | Yes | One of: `free`, `score:<N>` (e.g. `score:500`), or `premium` |
| **Image asset name** | No | PNG asset name in xcassets (omit if circle dots) |
| **SF Symbol fallback** | No | SF Symbol name used when the image asset is missing at runtime (required if image asset name is provided) |

If **unlock type** is `premium`, the `productID` is always `"com.optionalsankur.Dotto.premium"` (all premium themes share the bundle).

If **image asset name** is provided without an **SF Symbol fallback**, ask the user for one before continuing.

---

## Step 1 — Read the current state

Read the following files before writing anything:

- `WheresTheDot/Domain/Theme.swift` — to see the full list of existing themes and avoid duplicate ThemeID names
- `WheresTheDot/Presentation/PurchaseView.swift` — to see the current `features` array
- `WheresTheDot/Tools/RemoteConfigManager.swift` — to see the `milestone(for:)` switch

---

## Step 2 — Derive the ThemeID

Take the theme name, lowercase it, and strip all spaces and special characters:
- "Midnight" → `midnight`
- "Dark Forest" → `darkforest`
- "Doctor Ping" → `doctorping`

This becomes the `ThemeID` case and the Swift static property name.

---

## Step 3 — Update `Domain/Theme.swift`

Make three edits to this file:

### 3a — Add the case to ThemeID enum

Add the new case at the **end** of the existing case list, just before the closing `}` of the enum:

```swift
enum ThemeID: String, CaseIterable, Codable {
    // existing cases...
    case <themeID>   // ← add here
}
```

### 3b — Add the static Theme definition

Add a new `static let` inside the `extension Theme` block, after the last existing theme definition and before `static let all`. Follow this exact template:

**For circle dots (no image asset):**
```swift
static let <themeID> = Theme(
    id: .<themeID>,
    name: "<ThemeName>" as LocalizedStringResource,
    unlockScore: <nil | Int>,
    isPremium: <true | false>,
    productID: <nil | "com.optionalsankur.Dotto.premium">,
    backgroundColor: Color(UIColor(hex: "<hex>")),
    gridColor: Color(UIColor(hex: "<hex>")),
    dotColors: [
        UIColor(hex: "<hex1>"),
        UIColor(hex: "<hex2>"),
        UIColor(hex: "<hex3>"),
        UIColor(hex: "<hex4>"),
        UIColor(hex: "<hex5>")
    ],
    accentColor: Color(UIColor(hex: "<hex>")),
    dotShape: .circle
)
```

**For image-based dots:**
```swift
static let <themeID> = Theme(
    id: .<themeID>,
    name: "<ThemeName>" as LocalizedStringResource,
    unlockScore: <nil | Int>,
    isPremium: <true | false>,
    productID: <nil | "com.optionalsankur.Dotto.premium">,
    backgroundColor: Color(UIColor(hex: "<hex>")),
    gridColor: Color(UIColor(hex: "<hex>")),
    dotColors: [
        UIColor(hex: "<hex1>"),
        UIColor(hex: "<hex2>"),
        UIColor(hex: "<hex3>"),
        UIColor(hex: "<hex4>"),
        UIColor(hex: "<hex5>")
    ],
    accentColor: Color(UIColor(hex: "<hex>")),
    dotShape: .asset(named: "<assetName>", fallbackSymbol: "<sfSymbol>")
)
```

**Unlock rules:**
- `free` → `unlockScore: nil, isPremium: false, productID: nil`
- `score:<N>` → `unlockScore: <N>, isPremium: false, productID: nil`
- `premium` → `unlockScore: nil, isPremium: true, productID: "com.optionalsankur.Dotto.premium"`

### 3c — Add to Theme.all

Add `.<themeID>` to the end of the `static let all: [Theme]` array:

```swift
static let all: [Theme] = [.neon, .forest, .ocean, .cosmos, .aurora, .inferno, .doctorping, .<themeID>]
```

---

## Step 4 — Update `Tools/RemoteConfigManager.swift`

The `milestone(for:)` switch must be exhaustive. Add a case for the new ThemeID in the correct group:

- **Free or premium themes** → add `case .<themeID>: return nil` alongside the other nil-returning cases
- **Score-unlocked themes** → add a new Remote Config key constant and a `case .<themeID>: key = Keys.<themeID>Milestone` entry

For score-unlocked themes only:
1. Add a new constant to `enum Keys`:
   ```swift
   static let <themeID>Milestone = "theme_<themeID>_milestone"
   ```
2. Add it to the `Keys.all` array.
3. Add the `case .<themeID>: key = Keys.<themeID>Milestone` to the switch.

---

## Step 5 — Update `Presentation/PurchaseView.swift` (premium themes only)

Skip this step if the theme is free or score-unlocked.

Add a new entry to the `features` array. Choose an SF Symbol and color that matches the theme's accent color:

```swift
private let features: [(icon: String, color: Color, text: String)] = [
    // existing entries...
    ("<sfSymbol>", Color(UIColor(hex: "<accentHex>")), "<ThemeName> Theme — <short description>"),
]
```

Pick a descriptive short label (3–5 words) that communicates the theme's vibe, e.g.:
- "Aurora Theme — icy blue palette"
- "Inferno Theme — fire red palette"
- "Midnight Theme — deep space palette"

For the SF Symbol, pick something thematically fitting:
- Color/nature themes: `"paintpalette.fill"`, `"flame.fill"`, `"snowflake"`, `"leaf.fill"`, `"drop.fill"`
- Space: `"sparkles"`, `"moon.stars.fill"`
- Medical: `"stethoscope"`, `"cross.fill"`
- Night/dark: `"moon.fill"`, `"moon.stars.fill"`

---

## Step 6 — Update `Supporting Files/Localizable.xcstrings`

Add a localization entry for the theme name. Insert it in **alphabetical order** among the existing string keys.

Use this structure:

```json
"<ThemeName>" : {
  "comment" : "Name of the <ThemeName> <free|score-unlocked|premium> theme (<brief palette description>).<unlock description>",
  "localizations" : {
    "es" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "<Spanish translation or same name if it's a proper noun>"
      }
    },
    "es-419" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "<Spanish translation or same name if it's a proper noun>"
      }
    }
  }
},
```

Translation rules:
- Proper nouns / brand names → keep the same in all languages (e.g., "Aurora", "DoctorPing")
- Common English words → translate literally (e.g., "Forest" → "Bosque", "Ocean" → "Océano")
- Abstract/invented names → keep the same

---

## Step 7 — Verify completeness

After making all edits, confirm:

- [ ] `ThemeID` enum has the new case
- [ ] `Theme.all` includes the new theme
- [ ] `RemoteConfigManager.milestone(for:)` handles the new ThemeID (no missing switch case)
- [ ] `PurchaseView.features` updated (premium only)
- [ ] `Localizable.xcstrings` has the name entry
- [ ] If image-based: remind the user to add the PNG asset to the Xcode asset catalog under the given asset name

---

## Step 8 — Summarize for the user

After all edits, report:
- The new ThemeID case name
- The unlock type and how it's accessed
- If premium: which PurchaseView row was added
- If image-based: the asset name to add and the SF Symbol fallback
- If score-unlocked: the Remote Config key that controls the milestone
