//
//  GameCenterManager.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 23/03/26.
//

internal import Combine
import GameKit
import UIKit

@MainActor
final class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    @Published private(set) var isAuthenticated = false

    private enum LeaderboardID {
        static let classic = "lastdot_classic"
        static let arcade  = "lastdot_arcade"
    }

    enum Achievement: String {
        case firstDot        = "lastdot.first_dot"
        case score10Classic  = "lastdot.score10_classic"
        case score25Classic  = "lastdot.score25_classic"
        case score50Classic  = "lastdot.score50_classic"
        case score100Classic = "lastdot.score100_classic"
        case score10Arcade   = "lastdot.score10_arcade"
        case score25Arcade   = "lastdot.score25_arcade"
        case score50Arcade   = "lastdot.score50_arcade"
        case unlockForest    = "lastdot.unlock_forest"
        case unlockOcean     = "lastdot.unlock_ocean"
        case unlockCosmos    = "lastdot.unlock_cosmos"
        case play10Games     = "lastdot.play_10_games"
    }

    private let gamesPlayedKey = "gamesPlayedForAchievement"

    private init() {}

    func authenticateLocalPlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                print("[GameCenter] vc=\(viewController != nil) auth=\(GKLocalPlayer.local.isAuthenticated) error=\(String(describing: error))")
                if let vc = viewController {
                    UIApplication.shared.topViewController?.present(vc, animated: true)
                } else if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                } else {
                    self?.isAuthenticated = false
                }
                GKAccessPoint.shared.isActive = false
            }
        }
    }

    func submitScore(_ score: Int, for mode: GameMode) {
        guard isAuthenticated, let leaderboardID = leaderboardID(for: mode) else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [leaderboardID]) { error in
            if let error {
                print("[GameCenter] Score submission failed: \(error.localizedDescription)")
            }
        }
    }

    func presentLeaderboards() {
        GKAccessPoint.shared.trigger(state: .leaderboards) {}
    }

    func presentAchievements() {
        GKAccessPoint.shared.trigger(state: .achievements) {}
    }

    func presentLeaderboard(for mode: GameMode) {
        guard let leaderboardID = leaderboardID(for: mode) else { return }
        GKAccessPoint.shared.trigger(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime) {}
    }

    func reportAchievement(_ achievement: Achievement, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }
        let gkAchievement = GKAchievement(identifier: achievement.rawValue)
        gkAchievement.percentComplete = percentComplete
        gkAchievement.showsCompletionBanner = true
        GKAchievement.report([gkAchievement]) { error in
            if let error {
                print("[GameCenter] Achievement report failed (\(achievement.rawValue)): \(error.localizedDescription)")
            }
        }
    }

    func reportScoreAchievements(score: Int, mode: GameMode) {
        if score >= 1 { reportAchievement(.firstDot) }
        switch mode {
        case .classic:
            if score >= 10  { reportAchievement(.score10Classic) }
            if score >= 25  { reportAchievement(.score25Classic) }
            if score >= 50  { reportAchievement(.score50Classic) }
            if score >= 100 { reportAchievement(.score100Classic) }
        case .arcade:
            if score >= 10 { reportAchievement(.score10Arcade) }
            if score >= 25 { reportAchievement(.score25Arcade) }
            if score >= 50 { reportAchievement(.score50Arcade) }
        case .daily:
            break
        }
    }

    func trackGamePlayed() {
        let count = UserDefaults.standard.integer(forKey: gamesPlayedKey) + 1
        UserDefaults.standard.set(count, forKey: gamesPlayedKey)
        let percent = min(Double(count) / 10.0 * 100.0, 100.0)
        reportAchievement(.play10Games, percentComplete: percent)
    }

    private func leaderboardID(for mode: GameMode) -> String? {
        switch mode {
        case .classic:    return LeaderboardID.classic
        case .arcade:     return LeaderboardID.arcade
        case .daily:      return nil
        }
    }
}

// MARK: - UIApplication helper

private extension UIApplication {
    var topViewController: UIViewController? {
        guard let scene = connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return nil }
        return root.topmostPresented
    }
}

private extension UIViewController {
    var topmostPresented: UIViewController {
        presentedViewController?.topmostPresented ?? self
    }
}
