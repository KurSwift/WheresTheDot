//
//  FirebaseEventsManager.swift
//  WheresTheDot
//

import Foundation
import FirebaseAnalytics

enum FirebaseEventsManager {

    // MARK: - Main Menu

    static func logGameModeSelected(_ mode: GameMode) {
        Analytics.logEvent("select_game_mode", parameters: [
            "mode": mode.analyticsName
        ])
    }

    static func logSettingsOpened() {
        Analytics.logEvent("open_settings", parameters: nil)
    }

    // MARK: - Game Session

    static func logGameEnded(duration: TimeInterval, score: Int, mode: GameMode) {
        Analytics.logEvent("game_ended", parameters: [
            "duration_seconds": Int(duration),
            "score": score,
            "mode": mode.analyticsName
        ])
    }

    // MARK: - Settings Toggles

    static func logSoundToggled(enabled: Bool) {
        Analytics.logEvent(enabled ? "sound_enabled" : "sound_disabled", parameters: nil)
    }

    static func logHapticsToggled(enabled: Bool) {
        Analytics.logEvent(enabled ? "haptics_enabled" : "haptics_disabled", parameters: nil)
    }

    static func logColorBlindModeToggled(enabled: Bool) {
        Analytics.logEvent(
            enabled ? "color_blind_mode_enabled" : "color_blind_mode_disabled",
            parameters: nil
        )
    }
}

// MARK: - GameMode Analytics

private extension GameMode {
    var analyticsName: String {
        switch self {
        case .classic: return "classic"
        case .arcade:  return "arcade"
        case .daily:   return "daily"
        }
    }
}
