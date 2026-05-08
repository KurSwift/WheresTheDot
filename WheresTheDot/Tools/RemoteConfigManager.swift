//
//  RemoteConfigManager.swift
//  WheresTheDot
//

import Foundation
import FirebaseRemoteConfig

final class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    private let config = RemoteConfig.remoteConfig()
    private let defaults = UserDefaults.standard
    private let overridePrefix = "rc.override."

    private init() {
        let settings = RemoteConfigSettings()
#if DEBUG
        settings.minimumFetchInterval = 0      // always fresh in dev
#else
        settings.minimumFetchInterval = 3600   // 1 h in production
#endif
        config.configSettings = settings
        config.setDefaults(fromPlist: "remote_config_defaults")
    }

    /// Call once on launch. Fetches fresh values and activates them.
    func fetchAndActivate() async {
        _ = try? await config.fetchAndActivate()
    }

    // MARK: - Local override API (used by AdminView)

    func setOverride(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: overridePrefix + key)
    }

    func clearOverride(forKey key: String) {
        defaults.removeObject(forKey: overridePrefix + key)
    }

    func clearAllOverrides() {
        Keys.all.forEach { defaults.removeObject(forKey: overridePrefix + $0) }
    }

    func isOverridden(_ key: String) -> Bool {
        defaults.object(forKey: overridePrefix + key) != nil
    }

    // MARK: - Private helpers

    private func bool(_ key: String) -> Bool {
        if let override = defaults.object(forKey: overridePrefix + key) as? Bool { return override }
        return config[key].boolValue
    }

    private func double(_ key: String) -> Double {
        if let override = defaults.object(forKey: overridePrefix + key) as? Double { return override }
        return config[key].numberValue.doubleValue
    }

    private func int(_ key: String) -> Int {
        if let override = defaults.object(forKey: overridePrefix + key) as? Int { return override }
        return config[key].numberValue.intValue
    }

    private func string(_ key: String) -> String? {
        if let override = defaults.object(forKey: overridePrefix + key) as? String { return override }
        return config[key].stringValue
    }

    // MARK: - Key constants

    enum Keys {
        static let arcadeTimeLimitBase   = "arcade_time_limit_base"
        static let arcadeDifficultyStep  = "arcade_difficulty_step"
        static let memoryCoverDuration   = "memory_cover_duration"
        static let onboardingEnabled     = "onboarding_enabled"
        static let arcadeModeEnabled     = "arcade_mode_enabled"
        static let defaultTheme          = "default_theme"
        static let forestMilestone       = "theme_forest_milestone"
        static let oceanMilestone        = "theme_ocean_milestone"
        static let cosmosMilestone       = "theme_cosmos_milestone"

        static let all: [String] = [
            arcadeTimeLimitBase, arcadeDifficultyStep, memoryCoverDuration,
            onboardingEnabled, arcadeModeEnabled, defaultTheme,
            forestMilestone, oceanMilestone, cosmosMilestone
        ]
    }

    // MARK: - Typed accessors

    /// Base time limit (seconds) for arcade mode at level 1. Default: 2.5.
    var arcadeTimeLimitBase: Double { double(Keys.arcadeTimeLimitBase) }

    /// Points between arcade difficulty levels. Default: 5.
    var arcadeDifficultyStep: Int { int(Keys.arcadeDifficultyStep) }

    /// Memory cover duration (seconds) shown between rounds. Default: 0.45.
    var memoryCoverDuration: Double { double(Keys.memoryCoverDuration) }

    /// Whether the onboarding flow is shown to new users. Default: true.
    var onboardingEnabled: Bool { bool(Keys.onboardingEnabled) }

    /// Whether arcade mode is available in the main menu. Default: true.
    var arcadeModeEnabled: Bool { bool(Keys.arcadeModeEnabled) }

    /// ThemeID used for first-time users before they pick a theme. Default: "neon".
    var defaultTheme: ThemeID {
        ThemeID(rawValue: string(Keys.defaultTheme) ?? "neon") ?? .neon
    }

    /// Remote milestone for a theme. Returns nil for always-unlocked themes.
    /// Falls back to the Theme catalog value if no override or remote value is set.
    func milestone(for themeID: ThemeID) -> Int? {
        let key: String
        switch themeID {
        case .neon:       return nil
        case .aurora:     return nil  // IAP-unlocked, no score milestone
        case .inferno:    return nil  // IAP-unlocked, no score milestone
        case .doctorping:    return nil  // IAP-unlocked, no score milestone
        case .spacetravel:   return nil  // IAP-unlocked, no score milestone
        case .forest:  key = Keys.forestMilestone
        case .ocean:   key = Keys.oceanMilestone
        case .cosmos:  key = Keys.cosmosMilestone
        }
        let value = int(key)
        
        return value > 0 ? value : Theme.theme(for: themeID).unlockScore
    }
}
