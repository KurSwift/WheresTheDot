//
//  StoreKitManager.swift
//  WheresTheDot
//

import Foundation
import StoreKit
internal import Combine

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    enum ProductID {
        static let premium      = "com.optionalsankur.Dotto.premium"
        // Sub-feature IDs (not sold separately — checked only against the bundle entitlement)
        static let themeAurora  = "com.optionalsankur.Dotto.theme.aurora"
        static let themeInferno = "com.optionalsankur.Dotto.theme.inferno"

        static let all: [String] = [premium]
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published var purchaseError: String? = nil

    private var transactionListenerTask: Task<Void, Never>?

    var isAdFree: Bool {
        AdminConfig.simulatePremium || purchasedProductIDs.contains(ProductID.premium)
    }

    func isPurchased(_ productID: String) -> Bool {
        guard !productID.isEmpty else { return false }
        return AdminConfig.simulatePremium || purchasedProductIDs.contains(ProductID.premium)
    }

    var premiumProduct: Product? {
        products.first { $0.id == ProductID.premium }
    }

    private init() {
        transactionListenerTask = Task { await listenForTransactions() }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Public API

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: ProductID.all)
        } catch {
            // Store unavailable — silently ignore (e.g. Simulator without StoreKit config)
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return }
                await transaction.finish()
                await refreshEntitlements()
                FirebaseEventsManager.logIAPPurchased(productID: product.id)
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            FirebaseEventsManager.logIAPRestored()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Private

    private func refreshEntitlements() async {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                ids.insert(transaction.productID)
            }
        }
        purchasedProductIDs = ids
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }
}
