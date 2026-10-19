//
//  PurchaseManager.swift
//  LiveCaptions
//
//  Created by Cyrus Emam on 10/11/26.
//

import SwiftUI      
import StoreKit
import Foundation
import Combine

@MainActor
final class PurchaseManager: ObservableObject {
    

    // Published state used by the UI
    @Published private(set) var isUnlocked: Bool
    @Published private(set) var trialStartDate: Date?

    private let unlockKey = "livecaptions.unlock.purchased"
    private let trialStartKey = "livecaptions.trial.startDate"
    private let trialLengthDays = 30

    // StoreKit 2 products
    private var products: [Product] = []

    
    /// Change this to match the Product ID of your non-consumable IAP
    private let productID = "com.yourcompany.livecaptions.unlock"

    init() {
        let defaults = UserDefaults.standard
        self.isUnlocked = defaults.bool(forKey: unlockKey)

        if let time = defaults.object(forKey: trialStartKey) as? TimeInterval {
            self.trialStartDate = Date(timeIntervalSince1970: time)
        } else {
            self.trialStartDate = nil
        }
    }

    // MARK: - Trial Logic

    func startTrialIfNeeded() {
        guard trialStartDate == nil else { return }
        let now = Date()
        trialStartDate = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: trialStartKey)
    }

    var isTrialStarted: Bool {
        trialStartDate != nil
    }

    var isTrialExpired: Bool {
        guard let start = trialStartDate, !isUnlocked else { return false }
        let end = Calendar.current.date(byAdding: .day, value: trialLengthDays, to: start) ?? start
        return Date() >= end
    }

    /// Number of whole days remaining in the trial, or nil if not started/expired.
    var daysRemainingInTrial: Int? {
        guard let start = trialStartDate, !isTrialExpired else { return nil }
        let end = Calendar.current.date(byAdding: .day, value: trialLengthDays, to: start) ?? start
        let comps = Calendar.current.dateComponents([.day], from: Date(), to: end)
        guard let days = comps.day else { return nil }
        return max(days, 0)
    }

    // MARK: - Purchase Flow

    private func loadProductsIfNeeded() async throws {
        if products.isEmpty {
            products = try await Product.products(for: [productID])
        }
    }

    func purchaseLifetimeUnlock() async {
        do {
            try await loadProductsIfNeeded()
            guard let product = products.first else {
                print("No product found for id \(productID)")
                return
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                do {
                    let transaction: StoreKit.Transaction = try checkVerified(verificationResult)
                    await handle(transaction: transaction)
                } catch {
                    print("Verification failed: \(error)")
                }
            case .userCancelled:
                // User cancelled the purchase
                break
            case .pending:
                // Payment is pending; you could show a message if you like
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase error: \(error)")
        }
    }

    func restorePurchases() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction: StoreKit.Transaction = try checkVerified(result)
                if transaction.productID == productID {
                    await handle(transaction: transaction)
                }
            } catch {
                print("Restore verification failed: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func handle(transaction: StoreKit.Transaction) async {
        guard transaction.productID == productID else { return }
        isUnlocked = true
        UserDefaults.standard.set(true, forKey: unlockKey)
        await transaction.finish()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}
