//
//  ScreenshotSetup.swift
//  WheresTheDot
//

#if DEBUG
import UIKit

/// Configures the app into a known, clean state for App Store screenshot automation.
///
/// Activated by the `-screenshotMode` launch argument.
/// Supported arguments:
///   -screenshotMode               Enable screenshot mode (required)
///   -screenshotTheme <themeID>    Set active theme (any ThemeID raw value)
///   -screenshotDots <n>           Start games with n dots already placed
enum ScreenshotSetup {

    /// Number of dots a new game starts with in screenshot mode (1 = normal start).
    static var prefilledDots: Int {
        guard CommandLine.arguments.contains("-screenshotMode"),
              let idx = CommandLine.arguments.firstIndex(of: "-screenshotDots"),
              idx + 1 < CommandLine.arguments.count,
              let n = Int(CommandLine.arguments[idx + 1]) else { return 1 }
        return max(1, n)
    }

    static func configureIfNeeded() {
        guard CommandLine.arguments.contains("-screenshotMode") else { return }

        let defaults = UserDefaults.standard

        // Skip onboarding
        defaults.set(true, forKey: "hasSeenOnboarding")

        // Unlock all themes and set a high cumulative score so unlock progress shows correctly
        defaults.set(ThemeID.allCases.map(\.rawValue), forKey: "theme.unlockedThemeIDs")
        defaults.set(500, forKey: "theme.cumulativeScore")
        defaults.set(true, forKey: "theme.userHasSetTheme")

        // Apply theme from argument, fall back to neon
        if let idx = CommandLine.arguments.firstIndex(of: "-screenshotTheme"),
           idx + 1 < CommandLine.arguments.count {
            defaults.set(CommandLine.arguments[idx + 1], forKey: "activeThemeID")
        } else {
            defaults.set(ThemeID.neon.rawValue, forKey: "activeThemeID")
        }

        // Long arcade timer so prefilled arcade games don't time out before the capture
        defaults.set(60.0, forKey: "rc.override.arcade_time_limit_base")

        // Disable UIKit animations so screenshots catch the final settled state
        UIView.setAnimationsEnabled(false)
    }
}
#endif
