//
//  FirebaseEventsManager.swift
//  WheresTheDot
//

import Foundation
import FirebaseAnalytics

enum GameOverReason: String {
    case wrongTap = "wrong_tap"
    case timeUp   = "time_up"
}

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

    static func logThemesOpened() {
        Analytics.logEvent("open_themes", parameters: nil)
    }

    static func logThemeSelected(_ themeID: ThemeID) {
        Analytics.logEvent("select_theme", parameters: [
            "theme": themeID.rawValue
        ])
    }

    static func logLeaderboardOpened() {
        Analytics.logEvent("leaderboard_opened", parameters: nil)
    }

    // MARK: - Onboarding

    static func logOnboardingStarted() {
        Analytics.logEvent("onboarding_started", parameters: nil)
    }

    static func logOnboardingIntroDismissed() {
        Analytics.logEvent("onboarding_intro_dismissed", parameters: nil)
    }

    static func logOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
    }

    static func logOnboardingSkipped(atStep step: Int) {
        Analytics.logEvent("onboarding_skipped", parameters: [
            "at_step": step
        ])
    }

    // MARK: - Game Session

    static func logGameOver(reason: GameOverReason, score: Int, mode: GameMode) {
        Analytics.logEvent("game_over", parameters: [
            "reason": reason.rawValue,
            "score": score,
            "mode": mode.analyticsName
        ])
    }

    static func logGameEnded(duration: TimeInterval, score: Int, mode: GameMode) {
        Analytics.logEvent("game_ended", parameters: [
            "duration_seconds": Int(duration),
            "score": score,
            "mode": mode.analyticsName
        ])
    }

    static func logGameQuit(score: Int, mode: GameMode) {
        Analytics.logEvent("game_quit", parameters: [
            "score": score,
            "mode": mode.analyticsName
        ])
    }

    // MARK: - Themes

    static func logThemeUnlocked(_ themeID: ThemeID) {
        Analytics.logEvent("theme_unlocked", parameters: [
            "theme": themeID.rawValue
        ])
    }

    // MARK: - IAP

    static func logIAPPurchased(productID: String) {
        Analytics.logEvent("iap_purchased", parameters: [
            "product_id": productID
        ])
    }

    static func logIAPRestored() {
        Analytics.logEvent("iap_restored", parameters: nil)
    }

    static func logStoreOpened() {
        Analytics.logEvent("store_opened", parameters: nil)
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
