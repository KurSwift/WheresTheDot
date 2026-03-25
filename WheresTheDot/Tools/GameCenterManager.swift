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

    private init() {}

    func authenticateLocalPlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                print("[GameCenter] vc=\(viewController != nil) auth=\(GKLocalPlayer.local.isAuthenticated) error=\(String(describing: error))")
                if let vc = viewController {
                    UIApplication.shared.topViewController?.present(vc, animated: true)
                } else if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    GKAccessPoint.shared.isActive = true
                } else {
                    self?.isAuthenticated = false
                    GKAccessPoint.shared.isActive = false
                }
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

    func presentLeaderboard(for mode: GameMode) {
        guard let leaderboardID = leaderboardID(for: mode) else { return }
        GKAccessPoint.shared.trigger(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime) {}
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
