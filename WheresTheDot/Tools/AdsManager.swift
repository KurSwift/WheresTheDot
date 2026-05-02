//
//  AdsManager.swift
//  WheresTheDot
//

import Foundation
import UIKit
internal import Combine

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
final class AdsManager: NSObject, ObservableObject {
    static let shared = AdsManager()

    private static let interstitialUnitID     = "ca-app-pub-2353567800479707/5067427797"
    private static let testInterstitialUnitID = "ca-app-pub-3940256099942544/4411468910"

    private let adFrequency = 3
    private let countKey = "ads.gameOverCount"

    @Published private(set) var isAdLoaded = false
    @Published private(set) var lastAdError: String? = nil

    var gameOverCount: Int {
        get { UserDefaults.standard.integer(forKey: countKey) }
        set { UserDefaults.standard.set(newValue, forKey: countKey) }
    }

    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    #endif

    override private init() {
        super.init()
        // Do NOT load here — AdsManager.shared is primed only after
        // MobileAds.initialize() completes in AppDelegate.
    }

    // Called by AppDelegate after MobileAds.initialize() finishes.
    func start() {
        #if canImport(GoogleMobileAds)
        loadInterstitial()
        #endif
    }

    /// Resets the game-over counter (admin/debug use only).
    func resetCounter() {
        gameOverCount = 0
    }

    /// Shows an interstitial immediately, bypassing the frequency counter (admin/debug use only).
    func forceShowAd() {
        presentAd()
    }

    /// Call on every game-over. Shows an interstitial every `adFrequency` calls
    /// unless the user has purchased Premium.
    func recordGameOver() {
        guard !StoreKitManager.shared.isAdFree else { return }
        gameOverCount += 1
        guard gameOverCount >= adFrequency else { return }
        gameOverCount = 0
        presentAd()
    }

    // MARK: - AdMob

    #if canImport(GoogleMobileAds)
    func loadInterstitial() {
        let unitID: String
        #if DEBUG
        unitID = Self.testInterstitialUnitID
        #else
        unitID = Self.interstitialUnitID
        #endif
        Task {
            do {
                let ad = try await InterstitialAd.load(with: unitID, request: Request())
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
                self.isAdLoaded = true
                self.lastAdError = nil
            } catch {
                self.isAdLoaded = false
                self.lastAdError = error.localizedDescription
            }
        }
    }

    private func presentAd() {
        guard let vc = rootViewController else {
            lastAdError = "No root view controller found"
            return
        }
        guard let ad = interstitial else {
            lastAdError = isAdLoaded ? "Ad was consumed" : "Ad not loaded yet — retrying"
            loadInterstitial()
            return
        }
        ad.present(from: vc)
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController
    }
    #else
    func loadInterstitial() {}
    private func presentAd() {}
    #endif
}

// MARK: - FullScreenContentDelegate

#if canImport(GoogleMobileAds)
extension AdsManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.interstitial = nil
            self.isAdLoaded = false
            self.loadInterstitial()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.lastAdError = "Failed to present: \(error.localizedDescription)"
            self.interstitial = nil
            self.isAdLoaded = false
            self.loadInterstitial()
        }
    }
}
#endif
