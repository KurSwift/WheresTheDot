//
//  Haptics.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 15/02/26.
//

import Foundation
import UIKit

@MainActor
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notify = UINotificationFeedbackGenerator()

    static func prepare() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notify.prepare()
    }

    static func tap() {
        light.impactOccurred(intensity: 0.7)
    }

    static func correct() {
        medium.impactOccurred(intensity: 0.9)
    }

    static func wrong() {
        notify.notificationOccurred(.error)
    }

    static func gameOver() {
        heavy.impactOccurred(intensity: 1.0)
        notify.notificationOccurred(.error)
    }
}
