//
//  WheresTheDot.swift
//  WheresTheDot
//
//  Created by Ernesto Sánchez Kuri on 08/02/26.
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import AppTrackingTransparency

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    #if DEBUG
    ScreenshotSetup.configureIfNeeded()
    #endif
    FirebaseApp.configure()
    // Keep simulator / Xcode / screenshot runs out of production analytics.
    // Set explicitly in Release too: the flag persists on the device across installs.
    #if DEBUG
    Analytics.setAnalyticsCollectionEnabled(false)
    #else
    Analytics.setAnalyticsCollectionEnabled(true)
    #endif
    Task { await RemoteConfigManager.shared.fetchAndActivate() }

    // Prime StoreKit immediately so transaction listener starts
    _ = StoreKitManager.shared

    // Request ATT, then initialize AdMob so it has the IDFA status before
    // the first ad request. The 1-second delay ensures the main window is
    // key and visible — the system requires that before showing the prompt.
    #if canImport(GoogleMobileAds)
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        #if DEBUG
        // The tracking prompt would cover the UI in screenshot automation
        let skipTrackingPrompt = CommandLine.arguments.contains("-screenshotMode")
        #else
        let skipTrackingPrompt = false
        #endif
        if !skipTrackingPrompt {
            await ATTrackingManager.requestTrackingAuthorization()
        }
        await MobileAds.initialize()
        AdsManager.shared.start()
    }
    #endif

    return true
  }
}

@main
struct DotsGameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
