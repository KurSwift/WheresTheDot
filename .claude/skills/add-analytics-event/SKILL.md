---
name: add-analytics-event
description: Adds a new Firebase Analytics event to the WheresTheDot iOS app. Use this skill whenever the user wants to track a new user action, instrument a feature with analytics, or log something to Firebase. Trigger on any phrasing that involves adding tracking, logging, or analytics to the app — including "track when user does X", "add analytics for X", "log when X happens", "add a Firebase event for X", "I want to know when users tap X", "instrument X with analytics", or simply "add event for X". Even if the user doesn't say Firebase explicitly, use this skill whenever they want to record user behavior in the WheresTheDot app.
---

# Add Analytics Event

You are adding a new Firebase Analytics event to the WheresTheDot iOS app. The app already has a `FirebaseEventsManager` in `WheresTheDot/Tools/FirebaseEventsManager.swift` that follows a specific pattern — your job is to extend it cleanly and wire up the call at the right place.

## Step 1 — Read the current state

Before writing anything, read `WheresTheDot/Tools/FirebaseEventsManager.swift` to:
- See all existing events (avoid duplicates)
- Confirm the current code structure and import style
- Understand the event naming conventions in use

Also read the view or coordinator file where the new call will be wired — the user will usually tell you what triggered the event (a button tap, a toggle change, a game state transition). Use that to identify the right file in `WheresTheDot/Presentation/`.

## Step 2 — Choose the right event design

Apply these conventions consistently:

**Event naming** — snake_case, verb-noun style:
- User actions: `select_game_mode`, `open_settings`, `tap_leaderboard`
- State changes: `game_started`, `game_ended`, `level_completed`
- Toggle events: use **paired on/off events** — `sound_enabled` / `sound_disabled` (not `sound_toggled`)
- Selection events with variants: use **one event + parameter** — `select_game_mode` with `mode: "classic"` — rather than one event per variant

**Parameters** — add them when the value changes the meaning:
- Score, duration, level, mode — these make a `game_ended` event actually useful
- Skip parameters for binary on/off events where the event name already carries the value

**Avoid duplicates** — if the user is asking for something that's already tracked (or very similar), say so and suggest whether to extend the existing event or add a new one.

## Step 3 — Add the method to FirebaseEventsManager

Follow the existing enum-with-static-methods pattern exactly:

```swift
// Good — matches the existing pattern
static func logLeaderboardOpened() {
    Analytics.logEvent("open_leaderboard", parameters: nil)
}

static func logLevelCompleted(level: Int, score: Int) {
    Analytics.logEvent("level_completed", parameters: [
        "level": level,
        "score": score
    ])
}
```

Group the new method under an appropriate `// MARK: -` comment. If a relevant section already exists (e.g., `// MARK: - Game Session`), add it there. If not, create a new section.

## Step 4 — Wire the call at the callsite

Find the right place to call the new method:

- **Button taps** in views → add the call inside the button's action closure, before or after the existing action
- **Toggle changes** in `SettingsView` → use `.onChange(of:)` on the toggle
- **Game events** (game over, level up, round correct) → wire in `GameCoordinator`, which owns game flow
- **Navigation events** (opening a screen) → wire in the relevant view's button action or `onAppear` if appropriate

Keep calls at the closest logical point to the event — don't reach across layers unnecessarily. For example, don't log a UI tap from inside the coordinator; log it from the view.

## Step 5 — Confirm with the user

After making the changes, briefly summarize:
- The new event name and any parameters
- Where the call was added
- Any naming decision worth calling out (e.g., why you chose a parameter vs. a separate event)
