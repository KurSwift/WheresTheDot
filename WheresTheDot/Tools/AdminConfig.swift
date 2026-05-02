//
//  AdminConfig.swift
//  WheresTheDot
//
//  Flip `isEnabled` to true locally to reveal the admin panel.
//  Never ship with true in production.
//

import Foundation

enum AdminConfig {
    static let isEnabled: Bool = false

    // MARK: - IAP simulation (only active when isEnabled == true)

    private static let simulatePremiumKey = "admin.simulatePremium"

    static var simulatePremium: Bool {
        get { isEnabled && UserDefaults.standard.bool(forKey: simulatePremiumKey) }
        set { guard isEnabled else { return }
              UserDefaults.standard.set(newValue, forKey: simulatePremiumKey) }
    }
}
